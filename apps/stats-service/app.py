"""NBA Stats Service — Internal player statistics and performance data."""

import os
import logging

from flask import Flask, jsonify

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

APP_VERSION = os.getenv("APP_VERSION", "1.0.0")

PLAYER_STATS = {
    1: [
        {"player": "LeBron James", "team": "Lakers", "points": 28, "rebounds": 7, "assists": 10},
        {"player": "Jayson Tatum", "team": "Celtics", "points": 32, "rebounds": 8, "assists": 5},
    ],
    2: [
        {"player": "Stephen Curry", "team": "Warriors", "points": 22, "rebounds": 4, "assists": 8},
        {"player": "Nikola Jokić", "team": "Nuggets", "points": 30, "rebounds": 12, "assists": 9},
    ],
    3: [
        {"player": "Giannis Antetokounmpo", "team": "Bucks", "points": 35, "rebounds": 14, "assists": 6},
        {"player": "Joel Embiid", "team": "76ers", "points": 29, "rebounds": 11, "assists": 3},
    ],
}

ALL_PLAYERS = [
    {"name": "LeBron James", "team": "Lakers", "ppg": 25.7, "rpg": 7.3, "apg": 8.3},
    {"name": "Stephen Curry", "team": "Warriors", "ppg": 26.4, "rpg": 4.5, "apg": 6.1},
    {"name": "Giannis Antetokounmpo", "team": "Bucks", "ppg": 31.1, "rpg": 11.8, "apg": 5.7},
    {"name": "Nikola Jokić", "team": "Nuggets", "ppg": 26.4, "rpg": 12.4, "apg": 9.0},
    {"name": "Jayson Tatum", "team": "Celtics", "ppg": 26.9, "rpg": 8.1, "apg": 4.6},
    {"name": "Joel Embiid", "team": "76ers", "ppg": 33.1, "rpg": 11.7, "apg": 4.2},
    {"name": "Luka Dončić", "team": "Lakers", "ppg": 33.9, "rpg": 9.2, "apg": 9.8},
    {"name": "Anthony Davis", "team": "Lakers", "ppg": 24.7, "rpg": 12.6, "apg": 3.5},
]


@app.route("/health")
def health():
    return jsonify({"status": "healthy", "service": "stats-service", "version": APP_VERSION})


@app.route("/api/stats")
def all_stats():
    return jsonify({"players": ALL_PLAYERS, "version": APP_VERSION})


@app.route("/api/stats/game/<int:game_id>")
def game_stats(game_id):
    stats = PLAYER_STATS.get(game_id, [])
    return jsonify(stats)


@app.route("/api/stats/player/<name>")
def player_stats(name):
    player = next((p for p in ALL_PLAYERS if p["name"].lower() == name.lower()), None)
    if not player:
        return jsonify({"error": "Player not found"}), 404
    return jsonify(player)


@app.route("/")
def index():
    return jsonify({
        "service": "stats-service",
        "version": APP_VERSION,
        "endpoints": ["/health", "/api/stats", "/api/stats/game/<game_id>", "/api/stats/player/<name>"],
    })


if __name__ == "__main__":
    port = int(os.getenv("PORT", "8080"))
    app.run(host="0.0.0.0", port=port)
