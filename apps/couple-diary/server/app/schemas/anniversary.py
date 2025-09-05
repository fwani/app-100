from datetime import date

from pydantic import BaseModel


class AnnivIn(BaseModel):
    kind: str
    date: date
    repeat_unit: str | None = None
    note: str | None = None


class AnnivOut(BaseModel):
    id: int
    room_id: int
    kind: str
    date: date
    repeat_unit: str | None
    note: str | None

    class Config: orm_mode = True
