import logging

from fastapi import APIRouter, HTTPException
from starlette.responses import StreamingResponse

from core import llm
from core.llm import build_prompt, generate_text as llm_generate_text, generate_stream as llm_generate_stream
from models.api.generate_schema import GenerateResponse, GenerateRequest, ModelInfo

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post("/generate", response_model=GenerateResponse)
async def generate(req: GenerateRequest):
    if not req.prompt.strip():
        raise HTTPException(status_code=400, detail="prompt is empty")

    built = build_prompt(req.category, req.prompt)
    logger.info(f"Request model: {req.model}")

    if req.stream:
        def stream_gen():
            # stream returns a generator; collect final at StopIteration value
            final_text = ""
            for chunk in llm_generate_stream(
                    built,
                    model=req.model or None,
                    temperature=req.temperature,
                    max_tokens=req.max_tokens,
            ):
                yield chunk
                final_text += chunk
            # no explicit trailer; client assembles full text

        return StreamingResponse(stream_gen(), media_type="text/plain; charset=utf-8")

    # non-streaming path
    full = llm_generate_text(
        built,
        model=req.model or None,
        temperature=req.temperature,
        max_tokens=req.max_tokens,
    )
    return GenerateResponse(
        id="draft_0001",
        category=req.category,
        prompt=req.prompt,
        content=full,
    )


@router.get("/models", response_model=list[ModelInfo])
async def list_supported_models():
    try:
        return llm.list_models()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list models: {e}")
