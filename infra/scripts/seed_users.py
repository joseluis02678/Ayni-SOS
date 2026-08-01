"""Seed demo citizen and rescuer users (run against a live DB)."""

import asyncio
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "backend"))

from sqlalchemy import select

from app.core.database import AsyncSessionLocal, Base, engine
from app.core.security import hash_password
from app.infrastructure.models import User, UserRole


async def main() -> None:
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with AsyncSessionLocal() as db:
        for email, name, role, password in [
            ("ciudadano@ayni.local", "Ciudadano Demo", UserRole.citizen, "ciudadano123"),
            ("rescatista@ayni.local", "Rescatista Demo", UserRole.rescuer, "rescatista123"),
        ]:
            existing = await db.execute(select(User).where(User.email == email))
            if existing.scalar_one_or_none() is None:
                db.add(
                    User(
                        email=email,
                        full_name=name,
                        password_hash=hash_password(password),
                        role=role,
                    )
                )
        await db.commit()
    print("Seeded ciudadano@ayni.local / rescatista@ayni.local")


if __name__ == "__main__":
    asyncio.run(main())
