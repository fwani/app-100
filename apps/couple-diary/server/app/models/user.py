from typing import List
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import String
from db.base import Base
from models.mixins import IdPkMixin, TimestampMixin

class User(IdPkMixin, TimestampMixin, Base):
    __tablename__ = "app_user"

    email: Mapped[str] = mapped_column(String(320), unique=True, index=True, nullable=False)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    display_name: Mapped[str | None] = mapped_column(String(80))

    rooms: Mapped[List["RoomMember"]] = relationship(back_populates="user", cascade="all, delete-orphan")
    posts: Mapped[List["Post"]] = relationship(back_populates="author")
    comments: Mapped[List["Comment"]] = relationship(back_populates="author")