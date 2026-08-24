import os
from flask import Flask, render_template
import psycopg2

app = Flask(__name__)

DB_HOST = os.environ.get("DB_HOST", "hospital-db")
DB_NAME = os.environ.get("DB_NAME", "willowcreek")
DB_USER = os.environ.get("DB_USER", "willowcreek_admin")
DB_PASS = os.environ.get("DB_PASS", "changeme")


def get_departments():
    conn = psycopg2.connect(host=DB_HOST, dbname=DB_NAME, user=DB_USER, password=DB_PASS)
    cur = conn.cursor()
    cur.execute("""
        SELECT d.name, d.category, d.description,
               e.first_name, e.last_name, e.role, e.tier
        FROM departments d
        LEFT JOIN employees e ON e.department_id = d.id
        ORDER BY d.id, CASE e.tier WHEN 'Director' THEN 1 WHEN 'Manager' THEN 2 ELSE 3 END;
    """)
    rows = cur.fetchall()
    conn.close()

    departments = {}
    for name, category, description, fn, ln, role, tier in rows:
        if name not in departments:
            departments[name] = {"category": category, "description": description, "staff": []}
        if fn:
            departments[name]["staff"].append({"name": f"{fn} {ln}", "role": role, "tier": tier})
    return departments


@app.route("/")
def home():
    try:
        departments = get_departments()
    except Exception:
        departments = {}
    return render_template("index.html", departments=departments)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
