import importlib
import logging
import os
import pkgutil
from contextlib import contextmanager
from typing import Generator

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker

from core.config import settings

logger = logging.getLogger(__name__)


class Base(DeclarativeBase):
    pass


def import_models():
    models_path = os.path.join(os.path.dirname(__file__), "../models/db")
    for _, module_name, _ in pkgutil.iter_modules([models_path]):
        importlib.import_module(f"models.db.{module_name}")


engine = create_engine(settings.DATABASE_URL, pool_pre_ping=True)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)


def get_db() -> Generator:
    with get_db_context() as db:
        yield db


@contextmanager
def get_db_context():
    logger.info("🔓 Open Meta DB Session")
    db = SessionLocal()
    try:
        yield db
    except:
        db.rollback()
        raise
    finally:
        db.close()
        logger.info("🔒 Close Meta DB Session")
