from datetime import datetime

from pydantic import BaseModel


class PlaceIn(BaseModel):
    title: str
    lat: float
    lng: float
    photos: list[str] = []
    visited_at: datetime | None = None
    note: str | None = None


class PlaceOut(BaseModel):
    id: int
    room_id: int
    title: str
    lat: float
    lng: float
    photos: list[str]
    visited_at: datetime | None
    note: str | None

    class Config: orm_mode = True
