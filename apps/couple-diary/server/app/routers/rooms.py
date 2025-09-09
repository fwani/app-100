import secrets
import string

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.deps.auth import get_current_user
from app.deps.common import get_db
from app.models.room import Room, RoomMember
from app.schemas.room import RoomCreateOut, JoinRoomOut

router = APIRouter()


def _gen_code(n=6) -> str:
    chars = string.ascii_uppercase + string.digits
    return "".join(secrets.choice(chars) for _ in range(n))


@router.post("", response_model=RoomCreateOut)
def create_room(db: Session = Depends(get_db), user=Depends(get_current_user)):
    code = _gen_code()
    while db.query(Room).filter(Room.code == code).first():
        code = _gen_code()
    room = Room(code=code)
    db.add(room)
    db.flush()
    db.add(RoomMember(room_id=room.id, user_id=user.id))
    db.commit()
    return {"room_id": room.id, "code": room.code}


@router.post("/join/{code}", response_model=JoinRoomOut)
def join_room(code: str, db: Session = Depends(get_db), user=Depends(get_current_user)):
    room = db.query(Room).filter(Room.code == code).first()
    if not room:
        raise HTTPException(status_code=404, detail="Invalid code")
    exists = db.query(RoomMember).filter_by(room_id=room.id, user_id=user.id).first()
    if not exists:
        db.add(RoomMember(room_id=room.id, user_id=user.id))
        db.commit()
    return {"ok": True}
