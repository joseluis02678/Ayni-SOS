"""Additional tests for SMS report creation helpers."""

from uuid import uuid4

from app.domain.services import DISASTER_CODES, parse_sms_critical


def test_disaster_codes_cover_scope():
    assert set(DISASTER_CODES.values()) == {
        "landslide",
        "flood",
        "el_nino_related",
    }


def test_sms_hash_and_priority():
    raw = "AYNI|v1|f00bar12|-120000|-770000|2|F|abcd1234"
    parsed = parse_sms_critical(raw)
    assert parsed is not None
    assert parsed["priority"] == 2
    assert parsed["disaster_type"] == "flood"
    assert parsed["evidence_hash_8"] == "abcd1234"
