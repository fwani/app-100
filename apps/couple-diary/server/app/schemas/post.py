from datetime import datetime

from pydantic import BaseModel


class PostIn(BaseModel):
    text: str | None = None
    photos: list[str] = []
    mood: str | None = None
    shot_at: datetime | None = None


class PostOut(BaseModel):
    id: int
    room_id: int
    author_id: int | None
    text: str | None
    photos: list[str]
    mood: str | None
    shot_at: datetime | None
    created_at: datetime

    class Config: from_attributes = True


class CommentIn(BaseModel):
    post_id: int
    text: str


class CommentOut(BaseModel):
    id: int
    post_id: int
    author_id: int | None
    text: str
    created_at: datetime

    class Config: from_attributes = True
