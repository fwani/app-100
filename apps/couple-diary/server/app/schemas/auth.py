from pydantic import BaseModel, EmailStr


class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"


class RegisterIn(BaseModel):
    email: EmailStr
    password: str
    display_name: str | None = None
