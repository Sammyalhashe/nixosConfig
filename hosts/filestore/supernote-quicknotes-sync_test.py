import importlib.util
import unittest
from pathlib import Path


SCRIPT = Path(__file__).with_name("supernote-quicknotes-sync.py")
SPEC = importlib.util.spec_from_file_location("supernote_quicknotes_sync", SCRIPT)
sync = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(sync)


def note(state="TODO", modified=100):
    return {"state": state, "mtimeMs": modified, "title": "Note"}


def task(state="needsAction", modified=100):
    return {
        "status": state,
        "last_modified": modified,
        "title": "Task",
        "is_deleted": "N",
    }


def mapping(note_state="TODO", note_modified=100, task_modified=100):
    return {
        "taskId": "task-1",
        "noteState": note_state,
        "noteMtimeMs": note_modified,
        "taskLastModified": task_modified,
    }


class PlanSyncTest(unittest.TestCase):
    def test_task_deleted_on_device_drops_mapping_only(self):
        deleted_task = task()
        deleted_task["is_deleted"] = "Y"
        actions = sync.plan_sync(
            {"note.md": note()},
            {"task-1": deleted_task},
            {"note.md": mapping()},
        )
        self.assertEqual(
            actions,
            [{"kind": "drop_mapping", "filename": "note.md", "taskId": "task-1"}],
        )

    def test_task_missing_drops_mapping_without_recreating_it(self):
        actions = sync.plan_sync(
            {"note.md": note()},
            {},
            {"note.md": mapping()},
        )
        self.assertEqual(
            actions,
            [{"kind": "drop_mapping", "filename": "note.md", "taskId": "task-1"}],
        )

    def test_note_deleted_or_none_soft_deletes_task(self):
        actions = sync.plan_sync({}, {"task-1": task()}, {"note.md": mapping()})
        self.assertEqual(
            actions,
            [{"kind": "soft_delete_task", "filename": "note.md", "taskId": "task-1"}],
        )

    def test_both_gone_drops_mapping(self):
        actions = sync.plan_sync({}, {}, {"note.md": mapping()})
        self.assertEqual(
            actions,
            [{"kind": "drop_mapping", "filename": "note.md", "taskId": "task-1"}],
        )

    def test_newer_note_wins_when_both_sides_changed(self):
        actions = sync.plan_sync(
            {"note.md": note("DONE", 300)},
            {"task-1": task("completed", 200)},
            {"note.md": mapping(task_modified=50)},
        )
        self.assertEqual(actions, [{"kind": "update_task", "filename": "note.md", "taskId": "task-1"}])

    def test_newer_task_wins_when_both_sides_changed(self):
        actions = sync.plan_sync(
            {"note.md": note("DONE", 200)},
            {"task-1": task("completed", 300)},
            {"note.md": mapping(task_modified=50)},
        )
        self.assertEqual(actions, [{"kind": "update_note", "filename": "note.md", "taskId": "task-1"}])

    def test_only_note_state_changed_updates_task(self):
        actions = sync.plan_sync(
            {"note.md": note("DONE")},
            {"task-1": task()},
            {"note.md": mapping()},
        )
        self.assertEqual(actions, [{"kind": "update_task", "filename": "note.md", "taskId": "task-1"}])

    def test_only_task_changed_updates_note(self):
        actions = sync.plan_sync(
            {"note.md": note()},
            {"task-1": task(modified=200)},
            {"note.md": mapping()},
        )
        self.assertEqual(actions, [{"kind": "update_note", "filename": "note.md", "taskId": "task-1"}])

    def test_unmapped_todo_note_creates_task(self):
        actions = sync.plan_sync({"note.md": note()}, {}, {})
        self.assertEqual(
            actions,
            [{"kind": "create_task", "filename": "note.md", "taskId": None}],
        )

    def test_unmapped_done_note_does_nothing(self):
        self.assertEqual(sync.plan_sync({"note.md": note("DONE")}, {}, {}), [])

    def test_unmapped_needs_action_task_creates_note(self):
        actions = sync.plan_sync({}, {"task-1": task()}, {})
        self.assertEqual(
            actions,
            [{"kind": "create_note", "filename": None, "taskId": "task-1"}],
        )

    def test_unmapped_completed_task_does_nothing(self):
        self.assertEqual(sync.plan_sync({}, {"task-1": task("completed")}, {}), [])

    def test_unmapped_deleted_task_does_nothing(self):
        deleted_task = task()
        deleted_task["is_deleted"] = "Y"
        self.assertEqual(sync.plan_sync({}, {"task-1": deleted_task}, {}), [])

    def test_no_change_does_nothing(self):
        actions = sync.plan_sync(
            {"note.md": note(modified=999)},
            {"task-1": task()},
            {"note.md": mapping()},
        )
        self.assertEqual(actions, [])


class RecordingCursor:
    def __init__(self, rows):
        self.rows = rows
        self.calls = []

    def execute(self, sql, params):
        self.calls.append((sql, params))

    def fetchall(self):
        return self.rows


class ReadTasksTest(unittest.TestCase):
    def test_read_tasks_scopes_query_to_list_without_filtering_deleted_rows(self):
        cursor = RecordingCursor([])
        self.assertEqual(sync.read_tasks(cursor, "user-1", "list-1"), {})
        sql, params = cursor.calls[0]
        self.assertEqual(params, ("user-1", "list-1"))
        self.assertIn("task_list_id = %s", sql)
        self.assertNotIn("is_deleted =", sql)


class PlanTaskOrderTest(unittest.TestCase):
    def test_orders_priorities_before_current_sort(self):
        tasks = [
            {"task_id": "none", "sort": 0, "priority": None},
            {"task_id": "c", "sort": 1, "priority": "C"},
            {"task_id": "a", "sort": 2, "priority": "A"},
            {"task_id": "b", "sort": 3, "priority": "B"},
        ]
        self.assertEqual(
            sync.plan_task_order(tasks),
            [("a", 0), ("b", 1), ("c", 2), ("none", 3)],
        )

    def test_equal_priorities_keep_current_sort_order(self):
        tasks = [
            {"task_id": "later", "sort": 8, "priority": "A"},
            {"task_id": "first", "sort": 2, "priority": "A"},
            {"task_id": "b", "sort": 0, "priority": "B"},
        ]
        self.assertEqual(
            sync.plan_task_order(tasks),
            [("first", 0), ("later", 1), ("b", 2)],
        )

    def test_task_id_breaks_current_sort_ties(self):
        tasks = [
            {"task_id": "b", "sort": 0, "priority": "A"},
            {"task_id": "a", "sort": 0, "priority": "A"},
        ]
        self.assertEqual(sync.plan_task_order(tasks), [("b", 1)])

    def test_already_ordered_is_no_op(self):
        tasks = [
            {"task_id": "a", "sort": 0, "priority": "A"},
            {"task_id": "b", "sort": 1, "priority": "B"},
            {"task_id": "none", "sort": 2, "priority": None},
        ]
        self.assertEqual(sync.plan_task_order(tasks), [])

    def test_candidates_exclude_unmapped_completed_and_deleted_tasks(self):
        tasks = [
            {"task_id": "open", "sort": 4, "status": "needsAction", "is_deleted": "N"},
            {"task_id": "unmapped", "sort": 0, "status": "needsAction", "is_deleted": "N"},
            {"task_id": "completed", "sort": 1, "status": "completed", "is_deleted": "N"},
            {"task_id": "deleted", "sort": 2, "status": "needsAction", "is_deleted": "Y"},
        ]
        notes = {
            "open.md": {"priority": "B"},
            "completed.md": {"priority": "A"},
            "deleted.md": {"priority": "A"},
        }
        state = {
            "open.md": {"taskId": "open"},
            "completed.md": {"taskId": "completed"},
            "deleted.md": {"taskId": "deleted"},
        }
        self.assertEqual(
            sync.ordering_candidates(tasks, notes, state),
            [{"task_id": "open", "sort": 4, "priority": "B"}],
        )


if __name__ == "__main__":
    unittest.main()
