from flask import Flask, jsonify

app = Flask(__name__)


@app.route("/", methods=["GET"])
def say_hello():
    return jsonify({"msg": "ARGOCD testing flask app vesion **3**"})


if __name__ == "__main__":
    # Please do not set debug=True in production
    app.run(host="0.0.0.0", port=8080, debug=True)