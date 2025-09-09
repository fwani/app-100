from datetime import date

from sqlalchemy import BigInteger, String, Date, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.mixins import IdPkMixin


class Anniversary(IdPkMixin, Base):
    __tablename__ = "anniversary"

    room_id: Mapped[int] = mapped_column(BigInteger,
                                         ForeignKey("room.id", ondelete="CASCADE"),
                                         index=True, nullable=False)
    kind: Mapped[str] = mapped_column(String(32), nullable=False)
    date: Mapped[date] = mapped_column(Date, nullable=False)
    repeat_unit: Mapped[str | None] = mapped_column(String(12))  # 'year' | 'month' | NULL
    note: Mapped[str | None] = mapped_column(String)

    room: Mapped["Room"] = relationship(back_populates="anniversaries")
