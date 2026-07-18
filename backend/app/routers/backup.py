import os
import shutil
import sqlite3
import tempfile
from datetime import datetime, timezone

from fastapi import APIRouter, File, HTTPException, UploadFile
from fastapi.responses import FileResponse
from starlette.background import BackgroundTask

from app.config import settings as env_settings
from app.db import engine

router = APIRouter(prefix="/api/backup", tags=["backup"])


def _db_path() -> str:
    # database_url is "sqlite:///relative/path" or "sqlite:////absolute/path"
    # (the fourth slash, when present, is the leading "/" of an absolute
    # path) -- mirrors how db.py hands the same URL to SQLAlchemy.
    if not env_settings.database_url.startswith("sqlite"):
        raise HTTPException(status_code=501, detail="Backup/restore only supports SQLite databases")
    return env_settings.database_url.split("///", 1)[1]


@router.get("")
def download_backup():
    """Streams a point-in-time snapshot of the live DB, taken via sqlite3's
    backup API rather than copying the file directly -- a plain file copy
    could race a concurrent writer and ship a torn/corrupt snapshot."""
    fd, tmp_path = tempfile.mkstemp(suffix=".db")
    os.close(fd)
    source = sqlite3.connect(_db_path())
    try:
        target = sqlite3.connect(tmp_path)
        try:
            source.backup(target)
        finally:
            target.close()
    finally:
        source.close()
    filename = f"vorrat-backup-{datetime.now(timezone.utc):%Y%m%d-%H%M%S}.db"
    return FileResponse(
        tmp_path,
        media_type="application/x-sqlite3",
        filename=filename,
        background=BackgroundTask(os.unlink, tmp_path),
    )


@router.post("/restore")
async def restore_backup(file: UploadFile = File(...)):
    """Replaces the live DB file with the upload. Restoring a backup taken
    from an older schema version (before a later Alembic migration) is the
    caller's responsibility -- this endpoint does not attempt to migrate it."""
    target_path = _db_path()
    target_dir = os.path.dirname(os.path.abspath(target_path)) or "."
    fd, tmp_path = tempfile.mkstemp(dir=target_dir, suffix=".upload")
    try:
        with os.fdopen(fd, "wb") as out:
            shutil.copyfileobj(file.file, out)

        try:
            check = sqlite3.connect(tmp_path)
            try:
                check.execute("PRAGMA schema_version")
            finally:
                check.close()
        except sqlite3.DatabaseError:
            raise HTTPException(status_code=400, detail="Uploaded file is not a valid SQLite database")

        # Drop the pool's open connections to the old file first -- otherwise
        # the swap below can leave a writer holding a handle to the replaced
        # (now unlinked) file. SQLAlchemy reconnects lazily on next use.
        engine.dispose()
        os.replace(tmp_path, target_path)
    finally:
        if os.path.exists(tmp_path):
            os.unlink(tmp_path)
    return {"status": "ok"}
