import uvicorn
from fastapi import FastAPI

from app.routers import auth, rooms, posts, anniversaries, places, recommend


def init_app():
    app = FastAPI(title="Couple Diary API")
    app.include_router(auth.router, prefix="/auth", tags=["auth"])
    app.include_router(rooms.router, prefix="/rooms", tags=["rooms"])
    app.include_router(posts.router, prefix="/rooms", tags=["posts"])
    app.include_router(anniversaries.router, prefix="/rooms", tags=["anniversaries"])
    app.include_router(places.router, prefix="/rooms", tags=["places"])
    app.include_router(recommend.router, prefix="/rooms", tags=["recommend"])
    return app


def start_server():
    uvicorn.run("app.main:init_app",
                host="0.0.0.0",
                port=5050,
                reload=True,
                )


if __name__ == "__main__":
    start_server()
