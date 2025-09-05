from fastapi import Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from starlette import status

from jose import JWTError
from core.config import settings
from core.security import decode_token
from deps.common import get_db

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


def get_current_user(
        token: str = Depends(oauth2_scheme),
        db: Session = Depends(get_db)
) -> User:
    cred_exc = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid credentials",
    )
    try:
        payload = decode_token(token, settings.JWT_SECRET)
        email = payload.get("sub")
        if not email:
            raise cred_exc
    except JWTError:
        raise cred_exc
    user = db.query(User).filter_by(email=email).first()
    if not user:
        raise cred_exc
    return user


def ensure_room_member(room_id: int, user: User, db: Session):
    membership = (db.query(RoomMember)
                  .filter(RoomMember.room_id == room_id,
                          RoomMember.user_id == user.id)
                  .first())
    if not membership:
        raise HTTPException(status_code=403, detail="Not a member of this room")


def get_room_or_404(room_id: int, db: Session) -> Room:
    room = db.query(Room).filter(Room.id == room_id).first()
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
    return room
