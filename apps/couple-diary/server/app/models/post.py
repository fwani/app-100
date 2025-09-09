from datetime import datetime
from typing import List

from sqlalchemy import BigInteger, DateTime, String, ForeignKey
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.mixins import IdPkMixin, TimestampMixin


class Post(IdPkMixin, TimestampMixin, Base):
    __tablename__ = "post"

    room_id: Mapped[int] = mapped_column(BigInteger,
                                         ForeignKey("room.id", ondelete="CASCADE"),
                                         index=True, nullable=False)
    author_id: Mapped[int | None] = mapped_column(
        BigInteger,
        ForeignKey("app_user.id", ondelete="CASCADE"),
        index=True, nullable=True)
    text: Mapped[str | None] = mapped_column(String)
    photos: Mapped[list[str]] = mapped_column(JSONB, default=list, nullable=False)
    mood: Mapped[str | None] = mapped_column(String(24))
    shot_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    room: Mapped["Room"] = relationship(back_populates="posts")
    author: Mapped["User"] = relationship(back_populates="posts")
    comments: Mapped[List["Comment"]] = relationship(back_populates="post", cascade="all, delete-orphan")


class Comment(IdPkMixin, TimestampMixin, Base):
    __tablename__ = "comment"

    post_id: Mapped[int] = mapped_column(BigInteger,
                                         ForeignKey("post.id", ondelete="CASCADE"),
                                         index=True,
                                         nullable=False)
    author_id: Mapped[int | None] = mapped_column(
        BigInteger,
        ForeignKey("app_user.id", ondelete="CASCADE"),
        index=True, nullable=True)
    text: Mapped[str] = mapped_column(String, nullable=False)

    post: Mapped["Post"] = relationship(back_populates="comments")
    author: Mapped["User"] = relationship(back_populates="comments")
