import importlib
import os
import pkgutil

from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    pass


def import_models():
    models_path = os.path.join(os.path.dirname(__file__), "../models")
    for _, module_name, _ in pkgutil.iter_modules([models_path]):
        importlib.import_module(f"app.models.{module_name}")
