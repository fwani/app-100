from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.deps.auth import get_current_user, ensure_room_member, get_room_or_404
from app.deps.common import get_db
from app.models.place import Place
from app.schemas.place import PlaceOut, PlaceIn

router = APIRouter()


@router.get("/{room_id}/places", response_model=list[PlaceOut])
def list_places(room_id: int, db: Session = Depends(get_db), user=Depends(get_current_user)):
    get_room_or_404(room_id, db);
    ensure_room_member(room_id, user, db)
    return (db.query(Place)
            .filter(Place.room_id == room_id)
            .order_by(Place.created_at.desc())
            .all())


@router.post("/{room_id}/places", response_model=PlaceOut)
def add_place(room_id: int, payload: PlaceIn, db: Session = Depends(get_db), user=Depends(get_current_user)):
    get_room_or_404(room_id, db);
    ensure_room_member(room_id, user, db)
    p = Place(room_id=room_id, title=payload.title, lat=payload.lat, lng=payload.lng,
              photos=payload.photos or [], visited_at=payload.visited_at, note=payload.note)
    db.add(p);
    db.commit();
    db.refresh(p)
    return p
