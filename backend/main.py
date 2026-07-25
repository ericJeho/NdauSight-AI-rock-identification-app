"""
NdauSight AI — reference FastAPI backend (stub).

This is the server the Flutter app talks to when "Use real vision backend" is
switched on in Settings. It defines the exact request/response contract the app
expects, with a placeholder analyzer you replace with your real model
(YOLO for mineral/rock detection, a Vision Transformer classifier, plus a
geology-aware model that fuses image features with GPS + geological layers).

Run:
    pip install fastapi uvicorn python-multipart pillow
    uvicorn main:app --host 0.0.0.0 --port 8000

Then in the app: Settings → Use real vision backend → URL = http://<your-ip>:8000
"""
from __future__ import annotations

import random
from datetime import datetime, timezone
from typing import List, Optional

from fastapi import FastAPI, File, Form, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

app = FastAPI(title="NdauSight AI API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


# --- Response schema (must match ScanResult.fromJson in the Flutter app) ------

class Detection(BaseModel):
    name: str
    confidence: float  # 0–100


class MineralPotential(BaseModel):
    mineral: str
    probability: float  # 0–100


class ScanResponse(BaseModel):
    rockType: str
    rockConfidence: float
    detectedMinerals: List[Detection]
    potentials: List[MineralPotential]
    recommendations: List[str]
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    source: str = "backend"


@app.get("/health")
def health() -> dict:
    return {"status": "ok", "time": datetime.now(timezone.utc).isoformat()}


@app.post("/analyze", response_model=ScanResponse)
async def analyze(
    images: List[UploadFile] = File(default=[]),
    latitude: Optional[float] = Form(default=None),
    longitude: Optional[float] = Form(default=None),
) -> ScanResponse:
    """
    Replace the body of this function with real inference:

        1. Read/decode each uploaded image.
        2. Run rock-type classifier (ViT) + mineral detector (YOLO).
        3. Fuse with `latitude`/`longitude` against your geological database
           to weight precious-mineral probabilities.
        4. Generate recommendations from the fused result.
    """
    _ = [await img.read() for img in images]  # consume uploads

    # --- Placeholder inference ------------------------------------------------
    def pct(base: float) -> float:
        return round(min(100.0, max(0.0, base + random.uniform(-5, 5))), 1)

    return ScanResponse(
        rockType="Quartz Vein",
        rockConfidence=pct(94),
        detectedMinerals=[
            Detection(name="Quartz", confidence=pct(98)),
            Detection(name="Iron Oxides", confidence=pct(87)),
            Detection(name="Pyrite", confidence=pct(43)),
        ],
        potentials=[
            MineralPotential(mineral="Gold", probability=pct(71)),
            MineralPotential(mineral="Copper", probability=pct(24)),
            MineralPotential(mineral="Silver", probability=pct(16)),
            MineralPotential(mineral="Lithium", probability=pct(8)),
            MineralPotential(mineral="Rare Earth Elements", probability=pct(6)),
            MineralPotential(mineral="Gemstones", probability=pct(12)),
        ],
        recommendations=[
            "High-priority sample — collect fresh rock chips.",
            "Confirm with XRF or a laboratory assay before excavation.",
            "Pan stream sediments nearby to trace the source.",
        ],
        latitude=latitude,
        longitude=longitude,
    )


@app.post("/scans")
async def store_scan(payload: dict) -> dict:
    """Receives a synced scan from the app. Persist to your DB here."""
    return {"stored": True, "id": payload.get("id")}
