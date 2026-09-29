"""
Configuration for the ShoeKart Flask application.
Database credentials are read from environment variables so that
sensitive information is never hard-coded into the source files.
If an environment variable is not set, a sensible local default is used
(handy for quick testing on a college lab PC).
"""

import os


class Config:
    # Flask secret key - used to sign session cookies
    SECRET_KEY = os.environ.get('SECRET_KEY', 'shoekart-dev-secret-key-change-me')

    # MySQL connection details
    MYSQL_HOST = os.environ.get('MYSQL_HOST', 'localhost')
    MYSQL_USER = os.environ.get('MYSQL_USER', 'root')
    MYSQL_PASSWORD = os.environ.get('MYSQL_PASSWORD', '')
    MYSQL_DB = os.environ.get('MYSQL_DB', 'shoekart_db')
    MYSQL_PORT = int(os.environ.get('MYSQL_PORT', 3306))

    # Business rules
    DELIVERY_CHARGE = 50.00          # flat delivery charge in Rs.
    FREE_DELIVERY_ABOVE = 999.00     # orders above this amount get free delivery
