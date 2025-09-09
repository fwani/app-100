from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import get_password_hash, verify_password, create_access_token
from app.deps.common import get_db
from app.models.user import User
from app.schemas.auth import RegisterIn, TokenOut

router = APIRouter()


@router.post("/register", response_model=TokenOut)
def register(payload: RegisterIn, db: Session = Depends(get_db)):
    if db.query(User).filter(User.email == payload.email).first():
        raise HTTPException(status_code=400, detail="Email already registered")
    u = User(email=payload.email,
             password_hash=get_password_hash(payload.password),
             display_name=payload.display_name)
    db.add(u)
    db.commit()
    token = create_access_token(u.email, settings.JWT_SECRET, settings.JWT_EXPIRE_MIN)
    return {"access_token": token}


@router.post("/login", response_model=TokenOut)
def login(form: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    # form.username == email
    u = db.query(User).filter(User.email == form.username).first()
    if not u or not verify_password(form.password, u.password_hash):
        raise HTTPException(status_code=400, detail="Incorrect email or password")
    token = create_access_token(u.email, settings.JWT_SECRET, settings.JWT_EXPIRE_MIN)
    return {"access_token": token}
