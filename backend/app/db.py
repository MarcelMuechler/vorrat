from sqlalchemy import create_engine, event
from sqlalchemy.orm import DeclarativeBase, sessionmaker

from app.config import settings

is_sqlite = settings.database_url.startswith("sqlite")
connect_args = {"check_same_thread": False} if is_sqlite else {}
engine = create_engine(settings.database_url, connect_args=connect_args)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)

if is_sqlite:
    # SQLite ignores foreign key constraints unless explicitly enabled per
    # connection — without this, deleting a Product silently orphans any
    # StockEntry rows that reference it instead of raising an error.
    @event.listens_for(engine, "connect")
    def _enable_sqlite_fk(dbapi_connection, _):
        dbapi_connection.execute("PRAGMA foreign_keys=ON")


class Base(DeclarativeBase):
    pass


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
