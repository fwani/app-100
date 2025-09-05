from datetime import datetime, timezone, timedelta

from jose import jwt
from passlib.hash import bcrypt

JWT_ALG = "HS256"


def get_password_hash(password: str) -> str:
    return bcrypt.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return bcrypt.verify(plain_password, hashed_password)


def create_access_token(subject: str, secret: str, expire_minutes: int) -> str:
    exp = datetime.now(timezone.utc) + timedelta(minutes=expire_minutes)
    return jwt.encode(
        {
            "sub": subject,
            "exp": exp,
        },
        secret,
        algorithm=JWT_ALG,
    )


def decode_token(token: str, secret: str) -> dict:
    return jwt.decode(token, secret, algorithms=[JWT_ALG])
