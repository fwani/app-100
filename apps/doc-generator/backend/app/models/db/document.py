from datetime import datetime, timezone

from sqlalchemy import String, Text, DateTime, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from core.database import Base


class Document(Base):
    __tablename__ = "document"

    id: Mapped[int] = mapped_column(primary_key=True)
    title: Mapped[str] = mapped_column(String(255))
    category: Mapped[str] = mapped_column(String(32), default="blog")
    content: Mapped[str] = mapped_column(Text)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=False),
        default=func.now(),
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=False),
        default=func.now(),
        onupdate=func.now(),
    )

    revisions: Mapped[list["Revision"]] = relationship(
        back_populates="document",
        cascade="all, delete-orphan",
        order_by="desc(Revision.created_at)"
    )

    def __repr__(self) -> str:  # pragma: no cover
        return f"<Document id={self.id} title={self.title!r} category={self.category!r}>"
