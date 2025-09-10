from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class CreateDocReq(BaseModel):
    title: str
    category: str = Field("blog")
    content: str

class DocRes(BaseModel):
    id: int
    title: str
    category: str
    content: str
    created_at: datetime
    updated_at: datetime

class ReviseReq(BaseModel):
    instruction: str
    target: Optional[str] = None
    temperature: float = 0.5
    max_tokens: int = 1024
    stream: bool = Field(False, description="스트리밍 여부")

class ReviseRes(BaseModel):
    document_id: int
    revision_id: int
    content: str
    created_at: datetime

class ListRevItem(BaseModel):
    id: int
    instruction: str
    created_at: datetime