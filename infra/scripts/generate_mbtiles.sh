#!/usr/bin/env bash
# Generate a placeholder note for MBTiles offline packs.
# Production: use tippecanoe / openmaptiles for Peru coastal risk zones.
set -euo pipefail
OUT_DIR="$(cd "$(dirname "$0")/../.." && pwd)/apps/rescuer_app/assets/maps"
mkdir -p "$OUT_DIR"
cat > "$OUT_DIR/README.md" <<'EOF'
# Offline maps

Place `peru_risk_elnino.mbtiles` here for MapLibre offline rendering.

Suggested bbox (Costa norte / centro Perú — huaicos e inundaciones):
- Lon: -81.5 … -76.0
- Lat: -14.5 … -3.5

Load via OfflineMapConfig.mbtilesProtocolUrl(absolutePath).
EOF
echo "Wrote $OUT_DIR/README.md"
