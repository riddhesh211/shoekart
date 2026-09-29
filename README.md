# ShoeKart – Online Footwear Shopping Website

A full-stack college project built with **Flask (Python)** and **MySQL**, selling
sneakers, sandals and chappals. This README explains everything needed to set up
and run the project from scratch, even on a fresh laptop.

---

## 1. Project Overview

- **Frontend:** HTML5, CSS3, JavaScript, Bootstrap 5
- **Backend:** Python, Flask
- **Database:** MySQL (all products, users, orders, cart etc. are stored in MySQL — nothing is hard-coded)

### Features
- Product browsing by category (Sneakers / Sandals / Chappals), search, filters (price, size, rating) and sorting
- User registration & login with hashed passwords
- Product details page with size & quantity selection
- Fully working cart (add / update / remove / clear) tied to the logged-in user
- Checkout with delivery details + Cash on Delivery / Demo Online Payment
- Order placement reduces stock, empties the cart, and generates an Order ID
- Order history page for customers, with order status tracking
- Admin panel: dashboard stats, product CRUD, category CRUD, order management (status updates), user list

---

## 2. Folder Structure

```
shoekart/
│
├── app.py                 # Main Flask application (all routes)
├── db.py                  # MySQL connection helper (parameterized queries)
├── config.py               # Configuration (reads DB credentials from env vars)
├── requirements.txt
├── database/
│   └── shoekart.sql        # Full schema + sample data
├── static/
│   ├── css/style.css
│   ├── js/script.js
│   └── images/             # Product images (placeholders included)
└── templates/
    ├── base.html, index.html, products.html, product_details.html
    ├── login.html, register.html, cart.html, checkout.html
    ├── orders.html, order_success.html, profile.html, 404.html
    └── admin/
        ├── login.html, dashboard.html, products.html
        ├── add_product.html, edit_product.html, categories.html
        ├── orders.html, order_details.html, users.html, user_details.html
```

---

## 3. Step-by-Step Setup

### Step 1 — Install Python
Download and install Python 3.10+ from https://www.python.org/downloads/
During installation on Windows, tick **"Add Python to PATH"**.

Verify installation:
```bash
python --version
```

### Step 2 — Create a Virtual Environment
Inside the `shoekart` project folder:
```bash
python -m venv venv
```
Activate it:
- **Windows:** `venv\Scripts\activate`
- **macOS/Linux:** `source venv/bin/activate`

### Step 3 — Install Requirements
```bash
pip install -r requirements.txt
```

### Step 4 — Install & Configure MySQL
Download MySQL Community Server from https://dev.mysql.com/downloads/mysql/
During setup, set a root password and remember it (you'll need it below).

Make sure the MySQL service is running (MySQL Workbench, XAMPP, or the command line all work).

### Step 5 — Create the Database
Open a terminal and run:
```bash
mysql -u root -p < database/shoekart.sql
```
Enter your MySQL root password when prompted. This creates the `shoekart_db`
database, all tables, and inserts sample products.

### Step 6 — Configure Database Credentials
The app reads DB credentials from environment variables (so passwords are never
hard-coded). Set them before running the app:

**Windows (PowerShell):**
```powershell
$env:MYSQL_USER="root"
$env:MYSQL_PASSWORD="your_mysql_password"
$env:MYSQL_DB="shoekart_db"
```

**macOS/Linux:**
```bash
export MYSQL_USER=root
export MYSQL_PASSWORD=your_mysql_password
export MYSQL_DB=shoekart_db
```

If you don't set these, the app defaults to `user=root`, `password=""` (empty),
`db=shoekart_db`, `host=localhost` — edit `config.py` directly if you'd rather
not use environment variables.

### Step 7 — Run the Flask Application
```bash
python app.py
```
On first run the app automatically creates/repairs the default admin account
(see below) so login works immediately.

### Step 8 — Open the Website
Go to: **http://127.0.0.1:5000/**

---

## 4. Default Logins

| Role  | Email                | Password  |
|-------|-----------------------|-----------|
| Admin | admin@shoekart.com   | admin123  |

Admin panel: http://127.0.0.1:5000/admin/login

Regular customers can register their own accounts from the **Register** page.

---

## 5. Notes for the Project Presentation

- All product, user, cart and order data lives in MySQL — check it yourself with
  `mysql -u root -p shoekart_db` then `SHOW TABLES;` / `SELECT * FROM products;`
- Every SQL query in `app.py` / `db.py` uses `%s` placeholders (parameterized
  queries), which protects the app from SQL injection.
- Passwords are never stored in plain text — `werkzeug.security.generate_password_hash`
  is used at registration and `check_password_hash` at login.
- Stock is decreased automatically inside the checkout route when an order is placed.
- To add more products/images, log in as admin and use **Admin → Products → Add Product**.

---

## 6. Troubleshooting

- **"Access denied for user 'root'@'localhost'"** → your `MYSQL_PASSWORD`
  environment variable doesn't match your actual MySQL root password.
- **"Unknown database 'shoekart_db'"** → re-run Step 5, the SQL file wasn't imported.
- **Images look like plain colored boxes** → those are placeholder images
  generated for this project; replace files in `static/images/` with real
  photos any time (keep the same filenames, or update them via the admin panel).
