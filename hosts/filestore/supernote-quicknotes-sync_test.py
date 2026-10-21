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


if __name__ == "__main__":
    unittest.main()
