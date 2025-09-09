from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.deps.auth import get_current_user, ensure_room_member, get_room_or_404
from app.deps.common import get_db

router = APIRouter()


@router.get("/{room_id}/recommend")
def recommend(room_id: int,
              lat: float | None = None,
              lng: float | None = None,
              mood: str | None = None,
              budget: int | None = None,
              db: Session = Depends(get_db),
              user=Depends(get_current_user)):
    get_room_or_404(room_id, db);
    ensure_room_member(room_id, user, db)
    # TODO: 룰/AI 로직으로 교체
    return {"cards": [
        {"title": "전시회 → 카페", "summary": "실내 데이트", "budget": "₩₩"},
        {"title": "한강 산책 → 라면", "summary": "야외 데이트", "budget": "₩"},
    ]}
