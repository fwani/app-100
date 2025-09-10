# repo/backend/core/llm.py
import json
import os
import re
import subprocess
from typing import Generator, Optional, Iterator, Any

import ollama

DEFAULT_MODEL = os.getenv("OLLAMA_MODEL", "llama3.2")

SYSTEM_PREFIX = (
    "You are a helpful writing assistant. "
    "Always produce clean Markdown with headings and short paragraphs. "
    "Do not include inner thoughts, reasoning traces, or meta-commentary such as '<think>...</think>', "
    "'The user wants...', or explanations about how you will answer. "
    "Only return the final formatted content. "
    "First, write in English. Then, provide the Korean translation."
)

EDIT_SYSTEM = (
    "You are a careful editor. Apply the user's instruction to the given document. "
    "Preserve meaning and structure unless required. Output the full revised document in Markdown."
)

EDIT_PROMPT = (
    "현재 문서:\n---\n{doc}\n---\n\n"
    "사용자 지시:\n{inst}\n\n"
    "규칙:\n"
    "- 지시를 충실히 반영하되 불필요한 변경은 하지 말 것.\n"
    "- 문서 전체를 반환(부분만 반환 금지).\n"
    "{target_rule}"
)


def build_prompt(category: str, user_prompt: str) -> str:
    """Return a category-aware prompt text for single-turn draft generation."""
    if category == "article":
        guide = (
            "뉴스 기사 형식으로 작성하세요.\n"
            "형식: 헤드라인 한 줄 → 리드 문단(요약) → 본문 3~5단락 → 3줄 요약.\n"
            "중립적/사실 기반 톤을 유지하세요."
        )
    elif category == "novel":
        guide = (
            "단편 소설 초안을 작성하세요.\n"
            "형식: 로그라인 → 등장인물 → 배경 → 1장 초안(서막과 갈등).\n"
            "몰입감 있는 묘사와 대사를 적절히 섞으세요."
        )
    else:
        guide = (
            "블로그 글 형식으로 작성하세요.\n"
            "형식: 제목 → 서론(Hook) → 본문(팁/예시) → 결론(핵심요약/CTA).\n"
            "쉬운 표현과 예시 위주로 설명하세요."
        )
    return f"{guide}\n\n주제/지시: {user_prompt}"


def generate_text(
        prompt: str,
        *,
        system: Optional[str] = None,
        model: str = DEFAULT_MODEL,
        temperature: float = 0.7,
        max_tokens: int = 512,
) -> str:
    options = {"temperature": temperature, "num_predict": max_tokens}
    sys_prompt = system or SYSTEM_PREFIX
    model = model or DEFAULT_MODEL
    res = ollama.generate(
        model=model,
        prompt=prompt,
        system=sys_prompt,
        options=options,
        stream=False,
    )
    return res.get("response", "")


def generate_stream(
        prompt: str,
        *,
        system: Optional[str] = None,
        model: str = DEFAULT_MODEL,
        temperature: float = 0.7,
        max_tokens: int = 512,
) -> Iterator[str]:
    options = {"temperature": temperature, "num_predict": max_tokens}
    sys_prompt = system or SYSTEM_PREFIX
    model = model or DEFAULT_MODEL
    chunks = ollama.generate(
        model=model,
        prompt=prompt,
        system=sys_prompt,
        options=options,
        stream=True,
    )
    for ch in chunks:
        text = ch.get("response", "")
        if text:
            yield text


def list_models() -> list[dict[str, Any]]:
    """
    ollama 설치된 모델 목록을 반환.
    반환 예시: [{"name": "llama3.2", "size": 8_000_000_000, "digest": "..."}]
    """
    cmd = ["ollama", "list"]
    try:
        out = subprocess.check_output(cmd, stderr=subprocess.STDOUT).decode("utf-8")
        models = []
        for line in out.splitlines()[1:]:
            model_name, digest, size, _ = re.split(r"\s{2,}", line.strip())
            if not model_name:
                continue
            models.append({"name": model_name, "size": size, "digest": digest})
        return models
    except subprocess.CalledProcessError as e:
        return []


def build_edit_prompt(document: str, instruction: str, target: Optional[str] = None) -> tuple[str, str]:
    target_rule = f"- 특히 다음 대상에 초점을 맞춰 수정: {target}\n" if target else ""
    prompt = EDIT_PROMPT.format(doc=document, inst=instruction, target_rule=target_rule)
    return EDIT_SYSTEM, prompt
