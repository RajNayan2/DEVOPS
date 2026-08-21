import os
import time

from flask import Flask, request, jsonify
import psycopg2
from psycopg2.extras import RealDictCursor

app = Flask(__name__)

DB_HOST = os.getenv("DB_HOST")
DB_NAME = os.getenv("DB_NAME", "nimbuscart")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres")
DB_PORT = os.getenv("DB_PORT", "5432")


def get_connection():
    return psycopg2.connect(
        host=DB_HOST,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        port=DB_PORT
    )


def initialize_database():
    for attempt in range(30):
        try:
            conn = get_connection()
            cursor = conn.cursor()

            cursor.execute("""
                CREATE TABLE IF NOT EXISTS products (
                    id SERIAL PRIMARY KEY,
                    name VARCHAR(255) NOT NULL,
                    price NUMERIC(10,2) NOT NULL,
                    stock INTEGER NOT NULL
                )
            """)

            conn.commit()
            cursor.close()
            conn.close()

            print("Database initialized.")
            return

        except Exception as e:
            print(f"Database not ready: {e}")
            time.sleep(5)

    raise Exception("Could not connect to database.")


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "healthy"}), 200


@app.route("/items", methods=["GET"])
def get_items():
    conn = get_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)

    cursor.execute("""
        SELECT id, name, price, stock
        FROM products
        ORDER BY id
    """)

    items = cursor.fetchall()

    cursor.close()
    conn.close()

    return jsonify(items), 200


@app.route("/items", methods=["POST"])
def add_item():
    data = request.get_json()

    name = data.get("name")
    price = data.get("price")
    stock = data.get("stock")

    if not name or price is None or stock is None:
        return jsonify({"error": "name, price and stock are required"}), 400

    conn = get_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)

    cursor.execute("""
        INSERT INTO products (name, price, stock)
        VALUES (%s, %s, %s)
        RETURNING id, name, price, stock
    """, (name, price, stock))

    item = cursor.fetchone()

    conn.commit()

    cursor.close()
    conn.close()

    return jsonify(item), 201


if __name__ == "__main__":
    initialize_database()
    app.run(host="0.0.0.0", port=8080)
