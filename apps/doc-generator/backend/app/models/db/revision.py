from datetime import datetime, timezone

from sqlalchemy import ForeignKey, Text, DateTime, Index, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from core.database import Base


class Revision(Base):
    __tablename__ = "revision"

    id: Mapped[int] = mapped_column(primary_key=True)
    document_id: Mapped[int] = mapped_column(
        ForeignKey("document.id", ondelete="CASCADE"),
        index=True
    )
    instruction: Mapped[str] = mapped_column(Text)
    content: Mapped[str] = mapped_column(Text)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=False),
        default=func.now(),
    )

    # relationships
    document: Mapped["Document"] = relationship(back_populates="revisions")

    __table_args__ = (
        Index("ix_revision_doc_created", "document_id", "created_at"),
    )

    def __repr__(self) -> str:  # pragma: no cover
        return f"<Revision id={self.id} doc_id={self.document_id} created_at={self.created_at.isoformat()}>"
