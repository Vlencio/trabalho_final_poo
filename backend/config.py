from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # Postgres
    postgres_user: str = 'postgres'
    postgres_password: str
    postgres_db: str = 'atendente'
    postgres_host: str = 'localhost'
    postgres_port: int = 5432

    # Anthropic
    anthropic_api_key: str

    history_max_messages: int = 15

    @property
    def postgres_dsn(self) -> str:
        return (
            f'postgresql://{self.postgres_user}:{self.postgres_password}'
            f'@{self.postgres_host}:{self.postgres_port}/{self.postgres_db}'
        )

settings = Settings()
