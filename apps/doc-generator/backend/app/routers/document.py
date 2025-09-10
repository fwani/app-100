import logging

from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from core.database import get_db, get_db_context
from core.llm import generate_text as llm_generate_text, generate_stream as llm_generate_stream, build_edit_prompt
from models.api.document_schema import DocRes, CreateDocReq, ReviseRes, ReviseReq, ListRevItem
from models.db.document import Document
from models.db.revision import Revision

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post("/documents", response_model=DocRes)
async def create_document(req: CreateDocReq, db: Session = Depends(get_db)):
    doc = Document(title=req.title, category=req.category, content=req.content)
    db.add(doc)
    db.commit()
    db.refresh(doc)
    return DocRes(
        id=doc.id,
        title=doc.title,
        category=doc.category,
        content=doc.content,
        created_at=doc.created_at,
        updated_at=doc.updated_at,
    )


@router.get("/documents/{doc_id}", response_model=DocRes)
async def get_document(doc_id: int, db: Session = Depends(get_db)):
    doc = db.get(Document, doc_id)
    if not doc:
        raise HTTPException(404, "document not found")
    return DocRes(
        id=doc.id,
        title=doc.title,
        category=doc.category,
        content=doc.content,
        created_at=doc.created_at,
        updated_at=doc.updated_at,
    )


@router.post("/documents/{doc_id}/revise", response_model=ReviseRes)
async def revise_document(doc_id: int, req: ReviseReq, db: Session = Depends(get_db)):
    doc = db.get(Document, doc_id)
    if not doc:
        raise HTTPException(404, "document not found")

    system, prompt = build_edit_prompt(doc.content, req.instruction, req.target)

    # --- Streaming path ---
    if getattr(req, "stream", False):
        from fastapi.responses import StreamingResponse
        final_parts: list[str] = []

        def stream_gen():
            try:
                for chunk in llm_generate_stream(
                        prompt,
                        model=getattr(req, "model", None) or None,
                        system=system,
                        temperature=req.temperature,
                        max_tokens=req.max_tokens,
                ):
                    if chunk:
                        final_parts.append(chunk)
                        yield chunk
            finally:
                # persist revision after streaming completes
                full_text = "".join(final_parts)
                with get_db_context() as s:
                    d = s.get(Document, doc_id)
                    if d is not None and full_text:
                        rev = Revision(document_id=d.id, instruction=req.instruction, content=full_text)
                        d.content = full_text
                        s.add(rev)
                        s.add(d)
                        s.commit()

        return StreamingResponse(stream_gen(), media_type="text/plain; charset=utf-8")

    # --- Non-streaming path ---
    try:
        full = llm_generate_text(
            prompt,
            model=getattr(req, "model", None) or None,
            system=system,
            temperature=req.temperature,
            max_tokens=req.max_tokens,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"LLM error: {e}")

    # save revision & update document
    rev = Revision(document_id=doc.id, instruction=req.instruction, content=full)
    doc.content = full
    db.add(rev)
    db.add(doc)
    db.commit()
    db.refresh(rev)

    return ReviseRes(document_id=doc.id, revision_id=rev.id, content=full, created_at=rev.created_at)


@router.get("/documents/{doc_id}/revisions", response_model=list[ListRevItem])
async def list_revisions(doc_id: int, db: Session = Depends(get_db)):
    stmt = select(Revision).where(Revision.document_id == doc_id).order_by(Revision.created_at.desc())
    revs = db.execute(stmt).scalars().all()
    return [ListRevItem(id=r.id, instruction=r.instruction, created_at=r.created_at) for r in revs]
