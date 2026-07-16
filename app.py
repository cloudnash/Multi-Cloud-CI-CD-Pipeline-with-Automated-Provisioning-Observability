from flask import Flask, jsonify
import os

app = Flask(__name__)


@app.route("/healthz")
def healthz():
    return jsonify(status="ok", cloud=os.environ.get("CLOUD", "unknown"))


@app.route("/")
def index():
    return jsonify(message="Multi-cloud CI/CD demo app")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
