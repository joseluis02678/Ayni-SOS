"""Unit tests for SMS critical payload parsing and auth helpers."""

from app.core.security import create_access_token, decode_token, hash_password, verify_password
from app.domain.services import parse_sms_critical


def test_password_hash_roundtrip():
    hashed = hash_password("securepass123")
    assert verify_password("securepass123", hashed)
    assert not verify_password("wrong", hashed)


def test_jwt_roundtrip():
    token = create_access_token("00000000-0000-0000-0000-000000000001", "citizen")
    payload = decode_token(token)
    assert payload["role"] == "citizen"
    assert payload["type"] == "access"


def test_parse_sms_critical_valid():
    # Lima approx -12.0464, -77.0428 → -120464, -770428
    raw = "AYNI|v1|abc12345|-120464|-770428|1|L|deadbeef"
    parsed = parse_sms_critical(raw)
    assert parsed is not None
    assert parsed["priority"] == 1
    assert parsed["disaster_type"] == "landslide"
    assert abs(parsed["latitude"] - (-12.0464)) < 0.0001
    assert abs(parsed["longitude"] - (-77.0428)) < 0.0001


def test_parse_sms_critical_invalid():
    assert parse_sms_critical("HELLO|WORLD") is None
    assert parse_sms_critical("") is None
