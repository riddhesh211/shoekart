"""
db.py
Small helper module that centralises all MySQL connection handling.
Every route in app.py calls get_db() to get a connection and uses
query()/execute() helpers below instead of writing raw cursor code
everywhere. All queries use parameterized placeholders (%s) so user
input is never concatenated directly into SQL (prevents SQL injection).
"""

import mysql.connector
from mysql.connector import Error
from flask import g, current_app


def get_db():
    """
    Return a MySQL connection for the current request.
    Flask's 'g' object keeps one connection per request and it is
    closed automatically at the end of the request (see close_db).
    """
    if 'db' not in g:
        g.db = mysql.connector.connect(
            host=current_app.config['MYSQL_HOST'],
            user=current_app.config['MYSQL_USER'],
            password=current_app.config['MYSQL_PASSWORD'],
            database=current_app.config['MYSQL_DB'],
            port=current_app.config['MYSQL_PORT'],
            autocommit=False
        )
    return g.db


def close_db(e=None):
    """Close the DB connection at the end of the request, if it was opened."""
    db = g.pop('db', None)
    if db is not None and db.is_connected():
        db.close()


def query(sql, params=None, fetchone=False):
    """
    Run a SELECT query and return the results as a list of dicts
    (or a single dict when fetchone=True), or None if no row found.
    """
    conn = get_db()
    cursor = conn.cursor(dictionary=True)
    cursor.execute(sql, params or ())
    result = cursor.fetchone() if fetchone else cursor.fetchall()
    cursor.close()
    return result


def execute(sql, params=None):
    """
    Run an INSERT/UPDATE/DELETE statement, commit it, and return the
    id of the last inserted row (useful for INSERTs).
    """
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute(sql, params or ())
    conn.commit()
    last_id = cursor.lastrowid
    cursor.close()
    return last_id


def init_app(app):
    """Register the close_db function to run after every request."""
    app.teardown_appcontext(close_db)
