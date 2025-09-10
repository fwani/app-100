import uvicorn
from fastapi import FastAPI
from starlette.middleware.cors import CORSMiddleware

from routers import routers


def init_app():
    app = FastAPI(title="Document Generator")

    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_methods=["*"],
        allow_headers=["*"],
    )
    for route in routers:
        app.include_router(route, prefix="/api")
    return app


def run():
    uvicorn.run("main:init_app",
                host="0.0.0.0",
                port=8000,
                reload=True,
                log_level="debug"
                )


if __name__ == "__main__":
    run()
