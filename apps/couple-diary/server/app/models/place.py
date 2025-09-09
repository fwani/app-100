from datetime import datetime
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import BigInteger, Float, String, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import JSONB
from app.db.base import Base
from app.models.mixins import IdPkMixin, TimestampMixin


class Place(IdPkMixin, TimestampMixin, Base):
    __tablename__ = "place"

    room_id: Mapped[int] = mapped_column(BigInteger,
                                         ForeignKey("room.id", ondelete="CASCADE"),
                                         index=True,
                                         nullable=False)
    title: Mapped[str] = mapped_column(String(120), nullable=False)
    lat: Mapped[float] = mapped_column(Float, nullable=False)
    lng: Mapped[float] = mapped_column(Float, nullable=False)
    photos: Mapped[list[str]] = mapped_column(JSONB, default=list, nullable=False)
    visited_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    note: Mapped[str | None] = mapped_column(String)

    room: Mapped["Room"] = relationship(back_populates="places")
