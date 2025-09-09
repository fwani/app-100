from pydantic import BaseModel


class RoomOut(BaseModel):
    id: int
    code: str

    class Config: from_attributes = True


class RoomCreateOut(BaseModel):
    room_id: int
    code: str


class JoinRoomOut(BaseModel):
    ok: bool = True
