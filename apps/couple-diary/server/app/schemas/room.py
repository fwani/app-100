from pydantic import BaseModel


class RoomOut(BaseModel):
    id: int
    code: str

    class Config: orm_mode = True


class RoomCreateOut(BaseModel):
    room_id: int
    code: str


class JoinRoomOut(BaseModel):
    ok: bool = True
