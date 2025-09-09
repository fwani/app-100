from sqlalchemy import BigInteger, ForeignKey
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base
from app.models.mixins import IdPkMixin, TimestampMixin


class RecommendCache(IdPkMixin, TimestampMixin, Base):
    __tablename__ = "recommend_cache"

    room_id: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("room.id", ondelete="CASCADE"),
        index=True,
        nullable=False)
    payload: Mapped[dict] = mapped_column(JSONB, nullable=False)  # {"cards":[...]}
