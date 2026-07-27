"""NBA Scoreboard API — Public-facing service that aggregates stats and schedule data."""

import os
import json
import logging
from datetime import datetime

import requests
from flask import Flask, jsonify

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

STATS_SERVICE_URL = os.getenv("STATS_SERVICE_URL", "http://stats-service:8080")
SCHEDULE_SERVICE_URL = os.getenv("SCHEDULE_SERVICE_URL", "http://schedule-service:8080")
APP_VERSION = os.getenv("APP_VERSION", "1.0.0")

LIVE_SCORES = [
    {"game_id": 1, "home": "Lakers", "away": "Celtics", "home_score": 108, "away_score": 102, "quarter": "4th", "arena": "Crypto.com Arena"},
    {"game_id": 2, "home": "Warriors", "away": "Nuggets", "home_score": 95, "away_score": 99, "quarter": "3rd", "arena": "Chase Center"},
    {"game_id": 3, "home": "Bucks", "away": "76ers", "home_score": 112, "away_score": 110, "quarter": "OT", "arena": "Fiserv Forum"},
]


def fetch_json(url, fallback=None):
    """Fetch JSON from an internal service with error handling."""
    try:
        resp = requests.get(url, timeout=3)
        resp.raise_for_status()
        return resp.json()
    except Exception as e:
        logger.warning("Failed to fetch %s: %s", url, e)
        return fallback


@app.route("/health")
def health():
    return jsonify({"status": "healthy", "service": "scoreboard-api", "version": APP_VERSION})


@app.route("/scores")
def scores():
    return jsonify({"scores": LIVE_SCORES, "updated_at": datetime.utcnow().isoformat(), "version": APP_VERSION})


@app.route("/scores/<int:game_id>")
def game_detail(game_id):
    game = next((g for g in LIVE_SCORES if g["game_id"] == game_id), None)
    if not game:
        return jsonify({"error": "Game not found"}), 404

    # Enrich with stats from internal service
    stats = fetch_json(f"{STATS_SERVICE_URL}/api/stats/game/{game_id}", fallback=[])
    return jsonify({"game": game, "player_stats": stats, "version": APP_VERSION})


@app.route("/schedule")
def schedule():
    upcoming = fetch_json(f"{SCHEDULE_SERVICE_URL}/api/schedule", fallback=[])
    return jsonify({"schedule": upcoming, "version": APP_VERSION})


@app.route("/")
def index():
    return jsonify({
        "service": "scoreboard-api",
        "version": APP_VERSION,
        "endpoints": ["/health", "/scores", "/scores/<game_id>", "/schedule"],
    })


if __name__ == "__main__":
    port = int(os.getenv("PORT", "8080"))
    app.run(host="0.0.0.0", port=port)
