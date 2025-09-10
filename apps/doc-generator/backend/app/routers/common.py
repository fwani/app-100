from fastapi import APIRouter

router = APIRouter()


@router.get("/health", response_model=bool)
def health_check():
    return True
