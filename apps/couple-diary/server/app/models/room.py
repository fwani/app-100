from typing import List

from sqlalchemy import String, DateTime, func, ForeignKey, BigInteger
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.mixins import IdPkMixin, TimestampMixin


class Room(IdPkMixin, TimestampMixin, Base):
    __tablename__ = "room"

    code: Mapped[str] = mapped_column(String(16), unique=True, index=True, nullable=False)

    members: Mapped[List["RoomMember"]] = relationship(back_populates="room", cascade="all, delete-orphan")
    posts: Mapped[List["Post"]] = relationship(back_populates="room", cascade="all, delete-orphan")
    anniversaries: Mapped[List["Anniversary"]] = relationship(back_populates="room", cascade="all, delete-orphan")
    places: Mapped[List["Place"]] = relationship(back_populates="room", cascade="all, delete-orphan")


class RoomMember(Base):
    __tablename__ = "room_member"

    # 복합 PK (room_id, user_id)
    room_id: Mapped[int] = mapped_column(BigInteger,
                                         ForeignKey("room.id"),
                                         primary_key=True,
                                         )
    user_id: Mapped[int] = mapped_column(BigInteger,
                                         ForeignKey("app_user.id"),
                                         primary_key=True,
                                         )
    role: Mapped[str] = mapped_column(String(20), default="member", nullable=False)
    joined_at = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    room: Mapped["Room"] = relationship(back_populates="members")
    user: Mapped["User"] = relationship(back_populates="rooms")
