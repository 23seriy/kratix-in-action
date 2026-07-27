"""NBA Schedule Service — Internal game schedules and upcoming matchups."""

import os
import logging

from flask import Flask, jsonify

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

APP_VERSION = os.getenv("APP_VERSION", "1.0.0")

SCHEDULE = [
    {"game_id": 101, "home": "Celtics", "away": "Heat", "date": "2026-01-15", "time": "19:30", "arena": "TD Garden"},
    {"game_id": 102, "home": "Lakers", "away": "Clippers", "date": "2026-01-16", "time": "22:00", "arena": "Crypto.com Arena"},
    {"game_id": 103, "home": "Nuggets", "away": "Suns", "date": "2026-01-17", "time": "21:00", "arena": "Ball Arena"},
    {"game_id": 104, "home": "Bucks", "away": "Pacers", "date": "2026-01-18", "time": "20:00", "arena": "Fiserv Forum"},
    {"game_id": 105, "home": "Warriors", "away": "Mavericks", "date": "2026-01-19", "time": "20:30", "arena": "Chase Center"},
]

ARENAS = [
    {"name": "Crypto.com Arena", "city": "Los Angeles", "capacity": 18997, "team": "Lakers"},
    {"name": "TD Garden", "city": "Boston", "capacity": 19156, "team": "Celtics"},
    {"name": "Chase Center", "city": "San Francisco", "capacity": 18064, "team": "Warriors"},
    {"name": "Ball Arena", "city": "Denver", "capacity": 19520, "team": "Nuggets"},
    {"name": "Fiserv Forum", "city": "Milwaukee", "capacity": 17341, "team": "Bucks"},
]


@app.route("/health")
def health():
    return jsonify({"status": "healthy", "service": "schedule-service", "version": APP_VERSION})


@app.route("/api/schedule")
def upcoming():
    return jsonify({"games": SCHEDULE, "version": APP_VERSION})


@app.route("/api/schedule/<int:game_id>")
def game_detail(game_id):
    game = next((g for g in SCHEDULE if g["game_id"] == game_id), None)
    if not game:
        return jsonify({"error": "Game not found"}), 404
    return jsonify(game)


@app.route("/api/arenas")
def arenas():
    return jsonify({"arenas": ARENAS, "version": APP_VERSION})


@app.route("/")
def index():
    return jsonify({
        "service": "schedule-service",
        "version": APP_VERSION,
        "endpoints": ["/health", "/api/schedule", "/api/schedule/<game_id>", "/api/arenas"],
    })


if __name__ == "__main__":
    port = int(os.getenv("PORT", "8080"))
    app.run(host="0.0.0.0", port=port)
