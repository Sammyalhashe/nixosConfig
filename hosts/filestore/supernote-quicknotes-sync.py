#!/usr/bin/env python3

import argparse
import json
import os
import socket
import subprocess
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path

import pymysql


DB_HOST = "127.0.0.1"
DB_PORT = 13306
DB_NAME = "supernotedb"
DB_USER = "root"
REMOTE_HOST = "11.125.37.175"
STATE_FILENAME = "state.json"


def note_status(note):
    return "completed" if note["state"] == "DONE" else "needsAction"


def task_state(task):
    return "DONE" if task["status"] == "completed" else "TODO"


def plan_sync(notes, tasks, state):
    actions = []
    claimed_notes = set()
    claimed_tasks = set()

    for filename, mapping in state.items():
        note = notes.get(filename)
        task_id = mapping.get("taskId")
        task = tasks.get(task_id)
        claimed_notes.add(filename)
        if task_id is not None:
            claimed_tasks.add(task_id)

        if task is None or task["is_deleted"] == "Y":
            actions.append({"kind": "drop_mapping", "filename": filename, "taskId": task_id})
            continue
        if note is None:
            actions.append({"kind": "soft_delete_task", "filename": filename, "taskId": task_id})
            continue

        note_changed = note["state"] != mapping.get("noteState")
        task_changed = task["last_modified"] != mapping.get("taskLastModified")

        if note_changed and task_changed:
            kind = "update_task" if note["mtimeMs"] > task["last_modified"] else "update_note"
            actions.append({"kind": kind, "filename": filename, "taskId": task_id})
        elif note_changed:
            actions.append({"kind": "update_task", "filename": filename, "taskId": task_id})
        elif task_changed:
            actions.append({"kind": "update_note", "filename": filename, "taskId": task_id})

    for filename in sorted(notes.keys() - claimed_notes):
        if notes[filename]["state"] == "TODO":
            actions.append({"kind": "create_task", "filename": filename, "taskId": None})
    for task_id in sorted(tasks.keys() - claimed_tasks):
        task = tasks[task_id]
        if task["is_deleted"] == "N" and task["status"] == "needsAction":
            actions.append({"kind": "create_note", "filename": None, "taskId": task_id})

    return actions


def load_state(path):
    try:
        data = json.loads(path.read_text())
    except FileNotFoundError:
        return {}
    if not isinstance(data, dict):
        raise ValueError(f"State file {path} must contain a JSON object")
    return data


def save_state(path, state):
    temporary = path.with_suffix(".tmp")
    temporary.write_text(json.dumps(state, indent=2, sort_keys=True) + "\n")
    os.replace(temporary, path)


def run_quick_notes(*args):
    result = subprocess.run(
        ["quick-notes", *args],
        check=True,
        stdout=subprocess.PIPE,
        text=True,
    )
    return result.stdout.strip()


def read_notes(notes_dir):
    raw_notes = json.loads(run_quick_notes("todos", str(notes_dir)))
    notes = {}
    for note in raw_notes:
        path = Path(note["path"])
        filename = path.name
        if filename in notes:
            raise ValueError(f"Duplicate quick-note filename: {filename}")
        notes[filename] = {
            **note,
            "path": str(path),
            "mtimeMs": int(note["mtimeMs"]),
        }
    return notes


def read_user_id(cursor):
    cursor.execute("SELECT user_id FROM u_user ORDER BY user_id")
    rows = cursor.fetchall()
    if len(rows) != 1:
        raise RuntimeError(f"Expected exactly one Supernote user, found {len(rows)}")
    return rows[0]["user_id"]


def read_task_list_id(cursor, user_id):
    cursor.execute(
        "SELECT task_list_id FROM t_schedule_task_group "
        "WHERE user_id = %s AND title = 'Quick Notes' AND is_deleted = 'N'",
        (user_id,),
    )
    rows = cursor.fetchall()
    if not rows:
        raise RuntimeError(
            'No active "Quick Notes" to-do list found. Create a "Quick Notes" '
            "to-do list on the Supernote and sync it."
        )
    if len(rows) > 1:
        raise RuntimeError(f'Expected one active "Quick Notes" to-do list, found {len(rows)}')
    return rows[0]["task_list_id"]


def read_tasks(cursor, user_id, task_list_id):
    cursor.execute(
        """
        SELECT task_id, task_list_id, user_id, title, detail, last_modified,
               status, due_time, completed_time, is_deleted
        FROM t_schedule_task
        WHERE user_id = %s AND task_list_id = %s
        """,
        (user_id, task_list_id),
    )
    return {
        row["task_id"]: {
            **row,
            "last_modified": int(row["last_modified"] or 0),
            "due_time": int(row["due_time"] or 0),
        }
        for row in cursor.fetchall()
    }


def deadline_to_ms(deadline):
    if not deadline:
        return 0
    parsed = datetime.strptime(deadline, "%Y-%m-%d").replace(tzinfo=timezone.utc)
    return int(parsed.timestamp() * 1000)


def due_date(task):
    if not task["due_time"]:
        return None
    return datetime.fromtimestamp(task["due_time"] / 1000, timezone.utc).date().isoformat()


def next_modified(previous=0):
    return max(int(time.time() * 1000), int(previous) + 1)


def state_entry(note, task):
    return {
        "taskId": task["task_id"],
        "noteState": note["state"],
        "noteMtimeMs": note["mtimeMs"],
        "taskLastModified": task["last_modified"],
    }


def update_task(cursor, note, task):
    modified = next_modified(task["last_modified"])
    status = note_status(note)
    completed = modified if status == "completed" else None
    cursor.execute(
        """
        UPDATE t_schedule_task
        SET title = %s, status = %s, due_time = %s, completed_time = %s,
            last_modified = %s
        WHERE task_id = %s
        """,
        (
            note["title"],
            status,
            deadline_to_ms(note.get("deadline")),
            completed,
            modified,
            task["task_id"],
        ),
    )
    task.update(
        title=note["title"],
        status=status,
        due_time=deadline_to_ms(note.get("deadline")),
        completed_time=completed,
        last_modified=modified,
    )


def create_task(cursor, note, user_id, task_list_id):
    task_id = str(uuid.uuid4())
    modified = next_modified()
    status = note_status(note)
    completed = modified if status == "completed" else None
    task = {
        "task_id": task_id,
        "task_list_id": task_list_id,
        "user_id": user_id,
        "title": note["title"],
        "detail": "",
        "last_modified": modified,
        "status": status,
        "due_time": deadline_to_ms(note.get("deadline")),
        "completed_time": completed,
        "is_deleted": "N",
    }
    cursor.execute(
        """
        INSERT INTO t_schedule_task
          (task_id, task_list_id, user_id, title, detail, last_modified,
           recurrence, is_reminder_on, status, importance, due_time,
           completed_time, links, is_deleted)
        VALUES (%s, %s, %s, %s, '', %s, '', 'N', %s, '', %s, %s, NULL, 'N')
        """,
        (
            task_id,
            task_list_id,
            user_id,
            note["title"],
            modified,
            status,
            task["due_time"],
            completed,
        ),
    )
    return task


def refresh_note(note):
    note["mtimeMs"] = int(Path(note["path"]).stat().st_mtime_ns / 1_000_000)
    os.chown(note["path"], 33, 33)


def update_note(note, task):
    run_quick_notes("set-state", note["path"], task_state(task))
    note["state"] = task_state(task)
    refresh_note(note)


def create_note(notes_dir, task):
    args = [
        "add",
        str(notes_dir),
        "--title",
        task["title"] or "Untitled task",
        "--state",
        task_state(task),
    ]
    deadline = due_date(task)
    if deadline:
        args.extend(["--deadline", deadline])
    path = Path(run_quick_notes(*args))
    note = {
        "path": str(path),
        "title": task["title"] or "Untitled task",
        "state": task_state(task),
        "deadline": deadline,
        "mtimeMs": int(path.stat().st_mtime_ns / 1_000_000),
    }
    os.chown(path, 33, 33)
    return path.name, note


def log_action(dry_run, action, filename, task_id):
    prefix = "DRY-RUN " if dry_run else ""
    print(f"{prefix}{action} note={filename or '-'} task={task_id or '-'}", flush=True)


def apply_sync(
    cursor,
    connection,
    notes_dir,
    notes,
    tasks,
    state,
    actions,
    user_id,
    task_list_id,
    dry_run,
):
    next_state = dict(state)
    nextcloud_changed = False

    for action in actions:
        kind = action["kind"]
        filename = action["filename"]
        task_id = action["taskId"]
        log_action(dry_run, kind.upper(), filename, task_id)
        if dry_run:
            continue

        if kind == "drop_mapping":
            next_state.pop(filename, None)
        elif kind == "soft_delete_task":
            cursor.execute(
                "UPDATE supernotedb.t_schedule_task SET is_deleted='Y', "
                "last_modified=ROUND(UNIX_TIMESTAMP(NOW(3))*1000) WHERE task_id=%s",
                (task_id,),
            )
            next_state.pop(filename, None)
        elif kind == "update_task":
            note = notes[filename]
            task = tasks[task_id]
            update_task(cursor, note, task)
        elif kind == "update_note":
            note = notes[filename]
            task = tasks[task_id]
            update_note(note, task)
            nextcloud_changed = True
        elif kind == "create_task":
            note = notes[filename]
            task = create_task(cursor, note, user_id, task_list_id)
            task_id = task["task_id"]
            tasks[task["task_id"]] = task
        elif kind == "create_note":
            task = tasks[task_id]
            new_filename, note = create_note(notes_dir, task)
            filename = new_filename
            notes[new_filename] = note
            nextcloud_changed = True
        else:
            raise ValueError(f"Unknown sync action: {kind}")

        if kind not in {"drop_mapping", "soft_delete_task"}:
            next_state[filename] = state_entry(note, task)

    if not dry_run:
        connection.commit()
    return next_state, nextcloud_changed


def update_nextcloud():
    subprocess.run(
        [
            "podman",
            "exec",
            "-u",
            "33",
            "nextcloud-app",
            "php",
            "occ",
            "files:scan",
            "--path",
            "salhashemi2/files/Notes/Inbox",
        ],
        check=True,
    )


def open_tunnel():
    command = [
        "ssh",
        "-N",
        "-o",
        "ExitOnForwardFailure=yes",
        "-o",
        "BatchMode=yes",
        "-o",
        "StrictHostKeyChecking=accept-new",
        "-i",
        "/etc/ssh/ssh_host_ed25519_key",
        "-L",
        "127.0.0.1:13306:127.0.0.1:3306",
        f"supernote-sync@{REMOTE_HOST}",
    ]
    process = subprocess.Popen(command)
    deadline = time.monotonic() + 15
    while time.monotonic() < deadline:
        if process.poll() is not None:
            raise RuntimeError(f"SSH tunnel exited with status {process.returncode}")
        try:
            with socket.create_connection((DB_HOST, DB_PORT), timeout=0.25):
                return process
        except OSError:
            time.sleep(0.1)
    process.terminate()
    try:
        process.wait(timeout=5)
    except subprocess.TimeoutExpired:
        process.kill()
        process.wait()
    raise TimeoutError("SSH tunnel was not ready within 15 seconds")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true", help="report changes without writing")
    args = parser.parse_args()

    notes_dir = Path(os.environ["QUICK_NOTES_DIR"])
    state_dir = Path(os.environ["STATE_DIRECTORY"])
    state_path = state_dir / STATE_FILENAME
    password = os.environ.get("MYSQL_ROOT_PASSWORD")
    if not password:
        raise RuntimeError("MYSQL_ROOT_PASSWORD is missing from the service environment file")

    tunnel = open_tunnel()
    try:
        connection = pymysql.connect(
            host=DB_HOST,
            port=DB_PORT,
            user=DB_USER,
            password=password,
            database=DB_NAME,
            cursorclass=pymysql.cursors.DictCursor,
            autocommit=False,
            connect_timeout=10,
        )
        try:
            with connection.cursor() as cursor:
                user_id = read_user_id(cursor)
                task_list_id = read_task_list_id(cursor, user_id)
                tasks = read_tasks(cursor, user_id, task_list_id)
                notes = read_notes(notes_dir)
                state = load_state(state_path)
                actions = plan_sync(notes, tasks, state)
                next_state, nextcloud_changed = apply_sync(
                    cursor,
                    connection,
                    notes_dir,
                    notes,
                    tasks,
                    state,
                    actions,
                    user_id,
                    task_list_id,
                    args.dry_run,
                )
                if not args.dry_run:
                    save_state(state_path, next_state)
                if nextcloud_changed:
                    update_nextcloud()
        except Exception:
            connection.rollback()
            raise
        finally:
            connection.close()
    finally:
        tunnel.terminate()
        try:
            tunnel.wait(timeout=5)
        except subprocess.TimeoutExpired:
            tunnel.kill()
            tunnel.wait()


if __name__ == "__main__":
    main()
