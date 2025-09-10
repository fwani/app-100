from typing import Literal, Optional

from pydantic import BaseModel, Field

Category = Literal["article", "blog", "novel"]


class GenerateRequest(BaseModel):
    prompt: str = Field(..., description="사용자 입력 주제/지시")
    category: Category = Field("blog", description="문서 카테고리")
    max_tokens: int = Field(512, ge=32, le=8192)
    temperature: float = Field(0.7, ge=0.0, le=1.5)
    stream: bool = Field(False, description="스트리밍 여부")
    model: Optional[str] = Field(None, description="Ollama 모델명 (기본 env OLLAMA_MODEL)")


class GenerateResponse(BaseModel):
    id: str
    category: Category
    prompt: str
    content: str | None


class ModelInfo(BaseModel):
    name: str
    size: Optional[int | str] = None
    digest: Optional[str] = None
