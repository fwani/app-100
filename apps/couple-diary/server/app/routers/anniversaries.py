from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.deps.auth import get_current_user, ensure_room_member, get_room_or_404
from app.deps.common import get_db
from app.models.anniversary import Anniversary
from app.schemas.anniversary import AnnivOut, AnnivIn

router = APIRouter()


@router.get("/{room_id}/anniversaries", response_model=list[AnnivOut])
def list_anniv(room_id: int, db: Session = Depends(get_db), user=Depends(get_current_user)):
    get_room_or_404(room_id, db);
    ensure_room_member(room_id, user, db)
    return (db.query(Anniversary)
            .filter(Anniversary.room_id == room_id)
            .order_by(Anniversary.date.asc())
            .all())


@router.post("/{room_id}/anniversaries", response_model=AnnivOut)
def add_anniv(room_id: int, payload: AnnivIn, db: Session = Depends(get_db), user=Depends(get_current_user)):
    get_room_or_404(room_id, db);
    ensure_room_member(room_id, user, db)
    a = Anniversary(room_id=room_id, kind=payload.kind, date=payload.date,
                    repeat_unit=payload.repeat_unit, note=payload.note)
    db.add(a);
    db.commit();
    db.refresh(a)
    return a
