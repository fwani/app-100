from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    DATABASE_URL: str = "postgresql+psycopg2://postgres:postgres@localhost:5432/app"
    JWT_SECRET: str = "change_me"
    JWT_EXPIRE_MIN: int = 60 * 24 * 30

    class Config:
        env_file = ".env"


settings = Settings()
