"""
ShoeKart - Online Footwear Shopping Website
=============================================
Main Flask application file. Contains every route for the customer-facing
site and the admin panel. All database access goes through db.py, which
uses parameterized queries to stay safe from SQL injection.

Run with:  python app.py
"""

import os
from functools import wraps
from datetime import datetime

from flask import (
    Flask, render_template, request, redirect, url_for,
    session, flash, g, jsonify
)
from werkzeug.security import generate_password_hash, check_password_hash
from werkzeug.utils import secure_filename

from config import Config
import db

app = Flask(__name__)
app.config.from_object(Config)
db.init_app(app)

UPLOAD_FOLDER = os.path.join('static', 'images')
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'webp', 'gif'}
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER


# ---------------------------------------------------------------
# Helpers & decorators
# ---------------------------------------------------------------

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


def login_required(view):
    @wraps(view)
    def wrapped(*args, **kwargs):
        if not session.get('user_id'):
            flash('Please log in to continue.', 'warning')
            return redirect(url_for('login', next=request.path))
        return view(*args, **kwargs)
    return wrapped


def admin_required(view):
    @wraps(view)
    def wrapped(*args, **kwargs):
        if not session.get('user_id') or not session.get('is_admin'):
            flash('Admin access required.', 'danger')
            return redirect(url_for('admin_login'))
        return view(*args, **kwargs)
    return wrapped


def get_cart_id(user_id):
    """Return the cart id for a user, creating a cart row if needed."""
    cart = db.query('SELECT id FROM cart WHERE user_id = %s', (user_id,), fetchone=True)
    if cart:
        return cart['id']
    return db.execute('INSERT INTO cart (user_id) VALUES (%s)', (user_id,))


def get_cart_items(user_id):
    """Return the list of items in the user's cart, joined with product info."""
    sql = """
        SELECT ci.id AS cart_item_id, ci.size, ci.quantity,
               p.id AS product_id, p.name, p.image,
               p.price, p.discount_price, p.stock
        FROM cart_items ci
        JOIN cart c ON ci.cart_id = c.id
        JOIN products p ON ci.product_id = p.id
        WHERE c.user_id = %s
        ORDER BY ci.id DESC
    """
    items = db.query(sql, (user_id,))
    for item in items:
        effective_price = item['discount_price'] if item['discount_price'] else item['price']
        item['effective_price'] = float(effective_price)
        item['subtotal'] = float(effective_price) * item['quantity']
    return items


def cart_totals(items):
    subtotal = sum(i['subtotal'] for i in items)
    delivery = 0.0 if subtotal == 0 or subtotal >= Config.FREE_DELIVERY_ABOVE else Config.DELIVERY_CHARGE
    total = subtotal + delivery
    return round(subtotal, 2), round(delivery, 2), round(total, 2)


@app.context_processor
def inject_globals():
    """Makes cart item count and categories available to every template."""
    cart_count = 0
    if session.get('user_id'):
        result = db.query("""
            SELECT COALESCE(SUM(ci.quantity), 0) AS cnt
            FROM cart_items ci JOIN cart c ON ci.cart_id = c.id
            WHERE c.user_id = %s
        """, (session['user_id'],), fetchone=True)
        cart_count = result['cnt'] if result else 0
    categories = db.query('SELECT * FROM categories ORDER BY name')
    return dict(cart_count=cart_count, nav_categories=categories, current_year=datetime.now().year)


def ensure_admin_account():
    """Make sure a working admin account exists (admin@shoekart.com / admin123)."""
    admin = db.query('SELECT id FROM users WHERE email = %s', ('admin@shoekart.com',), fetchone=True)
    hashed = generate_password_hash('admin123')
    if admin:
        db.execute('UPDATE users SET password_hash = %s, is_admin = 1 WHERE id = %s',
                   (hashed, admin['id']))
    else:
        db.execute("""
            INSERT INTO users (full_name, email, phone, password_hash, is_admin)
            VALUES (%s, %s, %s, %s, 1)
        """, ('Admin User', 'admin@shoekart.com', '9999999999', hashed))


# ---------------------------------------------------------------
# Public routes
# ---------------------------------------------------------------

@app.route('/')
def index():
    featured = db.query('SELECT * FROM products WHERE is_popular = 1 LIMIT 8')
    new_arrivals = db.query('SELECT * FROM products WHERE is_new = 1 LIMIT 8')
    discounted = db.query('SELECT * FROM products WHERE discount_price IS NOT NULL LIMIT 8')
    return render_template('index.html', featured=featured, new_arrivals=new_arrivals, discounted=discounted)


@app.route('/products')
@app.route('/category/<slug>')
def products(slug=None):
    """Product listing page with filter, search and sort support."""
    category = None
    if slug:
        category = db.query('SELECT * FROM categories WHERE slug = %s', (slug,), fetchone=True)
        if not category:
            flash('Category not found.', 'danger')
            return redirect(url_for('products'))

    q = request.args.get('q', '').strip()
    category_id = request.args.get('category_id', type=int)
    min_price = request.args.get('min_price', type=float)
    max_price = request.args.get('max_price', type=float)
    size = request.args.get('size', '')
    min_rating = request.args.get('min_rating', type=float)
    sort = request.args.get('sort', 'newest')

    sql = """
        SELECT DISTINCT p.* FROM products p
        LEFT JOIN product_sizes ps ON p.id = ps.product_id
        WHERE 1=1
    """
    params = []

    if category:
        sql += ' AND p.category_id = %s'
        params.append(category['id'])
    if category_id:
        sql += ' AND p.category_id = %s'
        params.append(category_id)
    if q:
        sql += ' AND (p.name LIKE %s OR p.description LIKE %s)'
        params += [f'%{q}%', f'%{q}%']
    if min_price is not None:
        sql += ' AND COALESCE(p.discount_price, p.price) >= %s'
        params.append(min_price)
    if max_price is not None:
        sql += ' AND COALESCE(p.discount_price, p.price) <= %s'
        params.append(max_price)
    if size:
        sql += ' AND ps.size = %s AND ps.stock > 0'
        params.append(size)
    if min_rating is not None:
        sql += ' AND p.rating >= %s'
        params.append(min_rating)

    sort_map = {
        'price_low': ' ORDER BY COALESCE(p.discount_price, p.price) ASC',
        'price_high': ' ORDER BY COALESCE(p.discount_price, p.price) DESC',
        'newest': ' ORDER BY p.created_at DESC',
        'popular': ' ORDER BY p.is_popular DESC, p.rating DESC',
    }
    sql += sort_map.get(sort, sort_map['newest'])

    items = db.query(sql, params)
    categories = db.query('SELECT * FROM categories ORDER BY name')

    return render_template('products.html', products=items, categories=categories,
                            category=category, q=q, sort=sort,
                            min_price=min_price, max_price=max_price,
                            size=size, min_rating=min_rating)


@app.route('/product/<int:product_id>')
def product_details(product_id):
    prod = db.query('SELECT p.*, c.name AS category_name FROM products p '
                     'JOIN categories c ON p.category_id = c.id WHERE p.id = %s',
                     (product_id,), fetchone=True)
    if not prod:
        flash('Product not found.', 'danger')
        return redirect(url_for('products'))
    sizes = db.query('SELECT * FROM product_sizes WHERE product_id = %s ORDER BY size', (product_id,))
    related = db.query('SELECT * FROM products WHERE category_id = %s AND id != %s LIMIT 4',
                        (prod['category_id'], product_id))
    return render_template('product_details.html', product=prod, sizes=sizes, related=related)


# ---------------------------------------------------------------
# Auth routes
# ---------------------------------------------------------------

@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        full_name = request.form.get('full_name', '').strip()
        email = request.form.get('email', '').strip().lower()
        phone = request.form.get('phone', '').strip()
        password = request.form.get('password', '')
        confirm = request.form.get('confirm_password', '')

        errors = []
        if not full_name or not email or not phone or not password:
            errors.append('All fields are required.')
        if password != confirm:
            errors.append('Passwords do not match.')
        if len(password) < 6:
            errors.append('Password must be at least 6 characters.')

        existing = db.query('SELECT id FROM users WHERE email = %s', (email,), fetchone=True)
        if existing:
            errors.append('An account with this email already exists.')

        if errors:
            for e in errors:
                flash(e, 'danger')
            return render_template('register.html', form=request.form)

        hashed = generate_password_hash(password)
        db.execute("""
            INSERT INTO users (full_name, email, phone, password_hash, is_admin)
            VALUES (%s, %s, %s, %s, 0)
        """, (full_name, email, phone, hashed))

        flash('Registration successful! Please log in.', 'success')
        return redirect(url_for('login'))

    return render_template('register.html', form={})


@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        email = request.form.get('email', '').strip().lower()
        password = request.form.get('password', '')

        user = db.query('SELECT * FROM users WHERE email = %s', (email,), fetchone=True)
        if user and check_password_hash(user['password_hash'], password):
            session['user_id'] = user['id']
            session['full_name'] = user['full_name']
            session['is_admin'] = bool(user['is_admin'])
            flash(f"Welcome back, {user['full_name']}!", 'success')
            next_url = request.args.get('next')
            if user['is_admin']:
                return redirect(next_url or url_for('admin_dashboard'))
            return redirect(next_url or url_for('index'))

        flash('Invalid email or password.', 'danger')

    return render_template('login.html')


@app.route('/logout')
def logout():
    session.clear()
    flash('You have been logged out.', 'info')
    return redirect(url_for('index'))


# ---------------------------------------------------------------
# Cart routes
# ---------------------------------------------------------------

@app.route('/cart')
@login_required
def cart_view():
    items = get_cart_items(session['user_id'])
    subtotal, delivery, total = cart_totals(items)
    return render_template('cart.html', items=items, subtotal=subtotal,
                            delivery=delivery, total=total,
                            free_delivery_above=Config.FREE_DELIVERY_ABOVE)


@app.route('/cart/add', methods=['POST'])
@login_required
def cart_add():
    product_id = request.form.get('product_id', type=int)
    size = request.form.get('size', '')
    quantity = request.form.get('quantity', 1, type=int) or 1

    product = db.query('SELECT * FROM products WHERE id = %s', (product_id,), fetchone=True)
    if not product:
        flash('Product not found.', 'danger')
        return redirect(url_for('products'))

    if not size:
        flash('Please select a size.', 'warning')
        return redirect(url_for('product_details', product_id=product_id))

    cart_id = get_cart_id(session['user_id'])
    existing = db.query('SELECT * FROM cart_items WHERE cart_id = %s AND product_id = %s AND size = %s',
                         (cart_id, product_id, size), fetchone=True)
    if existing:
        db.execute('UPDATE cart_items SET quantity = quantity + %s WHERE id = %s',
                   (quantity, existing['id']))
    else:
        db.execute('INSERT INTO cart_items (cart_id, product_id, size, quantity) VALUES (%s, %s, %s, %s)',
                   (cart_id, product_id, size, quantity))

    flash(f"{product['name']} added to cart.", 'success')
    if request.form.get('buy_now'):
        return redirect(url_for('checkout'))
    return redirect(url_for('cart_view'))


@app.route('/cart/update', methods=['POST'])
@login_required
def cart_update():
    cart_item_id = request.form.get('cart_item_id', type=int)
    action = request.form.get('action')

    item = db.query("""
        SELECT ci.*, c.user_id FROM cart_items ci
        JOIN cart c ON ci.cart_id = c.id WHERE ci.id = %s
    """, (cart_item_id,), fetchone=True)

    if item and item['user_id'] == session['user_id']:
        if action == 'increase':
            db.execute('UPDATE cart_items SET quantity = quantity + 1 WHERE id = %s', (cart_item_id,))
        elif action == 'decrease':
            if item['quantity'] > 1:
                db.execute('UPDATE cart_items SET quantity = quantity - 1 WHERE id = %s', (cart_item_id,))
            else:
                db.execute('DELETE FROM cart_items WHERE id = %s', (cart_item_id,))
    return redirect(url_for('cart_view'))


@app.route('/cart/remove/<int:cart_item_id>')
@login_required
def cart_remove(cart_item_id):
    item = db.query("""
        SELECT ci.*, c.user_id FROM cart_items ci
        JOIN cart c ON ci.cart_id = c.id WHERE ci.id = %s
    """, (cart_item_id,), fetchone=True)
    if item and item['user_id'] == session['user_id']:
        db.execute('DELETE FROM cart_items WHERE id = %s', (cart_item_id,))
        flash('Item removed from cart.', 'info')
    return redirect(url_for('cart_view'))


@app.route('/cart/clear')
@login_required
def cart_clear():
    cart_id = get_cart_id(session['user_id'])
    db.execute('DELETE FROM cart_items WHERE cart_id = %s', (cart_id,))
    flash('Cart cleared.', 'info')
    return redirect(url_for('cart_view'))


# ---------------------------------------------------------------
# Checkout / Orders
# ---------------------------------------------------------------

@app.route('/checkout', methods=['GET', 'POST'])
@login_required
def checkout():
    items = get_cart_items(session['user_id'])
    if not items:
        flash('Your cart is empty.', 'warning')
        return redirect(url_for('cart_view'))

    subtotal, delivery, total = cart_totals(items)

    if request.method == 'POST':
        full_name = request.form.get('full_name', '').strip()
        mobile = request.form.get('mobile', '').strip()
        address = request.form.get('address', '').strip()
        city = request.form.get('city', '').strip()
        state = request.form.get('state', '').strip()
        pincode = request.form.get('pincode', '').strip()
        payment_method = request.form.get('payment_method', 'COD')

        if not all([full_name, mobile, address, city, state, pincode]):
            flash('Please fill in all delivery details.', 'danger')
            return render_template('checkout.html', items=items, subtotal=subtotal,
                                    delivery=delivery, total=total, form=request.form)

        # Re-check stock right before placing the order
        for item in items:
            size_row = db.query('SELECT stock FROM product_sizes WHERE product_id = %s AND size = %s',
                                 (item['product_id'], item['size']), fetchone=True)
            if not size_row or size_row['stock'] < item['quantity']:
                flash(f"Sorry, {item['name']} (size {item['size']}) is out of stock.", 'danger')
                return redirect(url_for('cart_view'))

        address_id = db.execute("""
            INSERT INTO addresses (user_id, full_name, mobile, address, city, state, pincode)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, (session['user_id'], full_name, mobile, address, city, state, pincode))

        order_id = db.execute("""
            INSERT INTO orders (user_id, address_id, subtotal, delivery_charge, total_amount, payment_method, status)
            VALUES (%s, %s, %s, %s, %s, %s, 'Pending')
        """, (session['user_id'], address_id, subtotal, delivery, total, payment_method))

        for item in items:
            db.execute("""
                INSERT INTO order_items (order_id, product_id, product_name, size, quantity, price)
                VALUES (%s, %s, %s, %s, %s, %s)
            """, (order_id, item['product_id'], item['name'], item['size'],
                  item['quantity'], item['effective_price']))

            db.execute("""
                UPDATE product_sizes SET stock = stock - %s
                WHERE product_id = %s AND size = %s
            """, (item['quantity'], item['product_id'], item['size']))
            db.execute('UPDATE products SET stock = stock - %s WHERE id = %s',
                       (item['quantity'], item['product_id']))

        cart_id = get_cart_id(session['user_id'])
        db.execute('DELETE FROM cart_items WHERE cart_id = %s', (cart_id,))

        flash('Order placed successfully!', 'success')
        return redirect(url_for('order_success', order_id=order_id))

    return render_template('checkout.html', items=items, subtotal=subtotal,
                            delivery=delivery, total=total, form={})


@app.route('/order/success/<int:order_id>')
@login_required
def order_success(order_id):
    order = db.query('SELECT * FROM orders WHERE id = %s AND user_id = %s',
                      (order_id, session['user_id']), fetchone=True)
    if not order:
        return redirect(url_for('index'))
    order_items = db.query('SELECT * FROM order_items WHERE order_id = %s', (order_id,))
    return render_template('order_success.html', order=order, order_items=order_items)


@app.route('/orders')
@login_required
def orders():
    my_orders = db.query('SELECT * FROM orders WHERE user_id = %s ORDER BY created_at DESC',
                          (session['user_id'],))
    for order in my_orders:
        order['items'] = db.query('SELECT * FROM order_items WHERE order_id = %s', (order['id'],))
    return render_template('orders.html', orders=my_orders)


# ---------------------------------------------------------------
# Profile
# ---------------------------------------------------------------

@app.route('/profile', methods=['GET', 'POST'])
@login_required
def profile():
    user = db.query('SELECT * FROM users WHERE id = %s', (session['user_id'],), fetchone=True)
    addresses = db.query('SELECT * FROM addresses WHERE user_id = %s', (session['user_id'],))

    if request.method == 'POST':
        full_name = request.form.get('full_name', '').strip()
        phone = request.form.get('phone', '').strip()
        if full_name and phone:
            db.execute('UPDATE users SET full_name = %s, phone = %s WHERE id = %s',
                       (full_name, phone, session['user_id']))
            session['full_name'] = full_name
            flash('Profile updated.', 'success')
            return redirect(url_for('profile'))

    return render_template('profile.html', user=user, addresses=addresses)


# ---------------------------------------------------------------
# Admin routes
# ---------------------------------------------------------------

@app.route('/admin/login', methods=['GET', 'POST'])
def admin_login():
    if request.method == 'POST':
        email = request.form.get('email', '').strip().lower()
        password = request.form.get('password', '')
        user = db.query('SELECT * FROM users WHERE email = %s AND is_admin = 1', (email,), fetchone=True)
        if user and check_password_hash(user['password_hash'], password):
            session['user_id'] = user['id']
            session['full_name'] = user['full_name']
            session['is_admin'] = True
            return redirect(url_for('admin_dashboard'))
        flash('Invalid admin credentials.', 'danger')
    return render_template('admin/login.html') if os.path.exists('templates/admin/login.html') else render_template('login.html')


@app.route('/admin')
@admin_required
def admin_dashboard():
    stats = {
        'total_products': db.query('SELECT COUNT(*) AS c FROM products', fetchone=True)['c'],
        'total_users': db.query('SELECT COUNT(*) AS c FROM users WHERE is_admin = 0', fetchone=True)['c'],
        'total_orders': db.query('SELECT COUNT(*) AS c FROM orders', fetchone=True)['c'],
        'total_sales': db.query('SELECT COALESCE(SUM(total_amount),0) AS s FROM orders', fetchone=True)['s'],
    }
    recent_orders = db.query('SELECT * FROM orders ORDER BY created_at DESC LIMIT 5')
    return render_template('admin/dashboard.html', stats=stats, recent_orders=recent_orders)


@app.route('/admin/products')
@admin_required
def admin_products():
    items = db.query("""
        SELECT p.*, c.name AS category_name FROM products p
        JOIN categories c ON p.category_id = c.id ORDER BY p.id DESC
    """)
    return render_template('admin/products.html', products=items)


@app.route('/admin/products/add', methods=['GET', 'POST'])
@admin_required
def admin_add_product():
    categories = db.query('SELECT * FROM categories ORDER BY name')

    if request.method == 'POST':
        name = request.form.get('name', '').strip()
        category_id = request.form.get('category_id', type=int)
        description = request.form.get('description', '').strip()
        price = request.form.get('price', type=float)
        discount_price = request.form.get('discount_price', type=float) or None
        stock = request.form.get('stock', 0, type=int)
        is_new = 1 if request.form.get('is_new') else 0
        is_popular = 1 if request.form.get('is_popular') else 0
        sizes = request.form.getlist('sizes')

        image_filename = 'default_shoe.jpg'
        file = request.files.get('image')
        if file and file.filename and allowed_file(file.filename):
            image_filename = secure_filename(file.filename)
            os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
            file.save(os.path.join(app.config['UPLOAD_FOLDER'], image_filename))

        if not name or not category_id or not price:
            flash('Name, category and price are required.', 'danger')
            return render_template('admin/add_product.html', categories=categories, form=request.form)

        product_id = db.execute("""
            INSERT INTO products (category_id, name, description, price, discount_price,
                                   image, is_new, is_popular, stock)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (category_id, name, description, price, discount_price,
              image_filename, is_new, is_popular, stock))

        for size in sizes:
            db.execute('INSERT INTO product_sizes (product_id, size, stock) VALUES (%s, %s, %s)',
                       (product_id, size, stock))

        flash('Product added successfully.', 'success')
        return redirect(url_for('admin_products'))

    return render_template('admin/add_product.html', categories=categories, form={})


@app.route('/admin/products/edit/<int:product_id>', methods=['GET', 'POST'])
@admin_required
def admin_edit_product(product_id):
    product = db.query('SELECT * FROM products WHERE id = %s', (product_id,), fetchone=True)
    if not product:
        flash('Product not found.', 'danger')
        return redirect(url_for('admin_products'))

    categories = db.query('SELECT * FROM categories ORDER BY name')
    sizes = db.query('SELECT * FROM product_sizes WHERE product_id = %s ORDER BY size', (product_id,))

    if request.method == 'POST':
        name = request.form.get('name', '').strip()
        category_id = request.form.get('category_id', type=int)
        description = request.form.get('description', '').strip()
        price = request.form.get('price', type=float)
        discount_price = request.form.get('discount_price', type=float) or None
        stock = request.form.get('stock', 0, type=int)
        is_new = 1 if request.form.get('is_new') else 0
        is_popular = 1 if request.form.get('is_popular') else 0

        image_filename = product['image']
        file = request.files.get('image')
        if file and file.filename and allowed_file(file.filename):
            image_filename = secure_filename(file.filename)
            os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
            file.save(os.path.join(app.config['UPLOAD_FOLDER'], image_filename))

        db.execute("""
            UPDATE products SET category_id=%s, name=%s, description=%s, price=%s,
                   discount_price=%s, image=%s, is_new=%s, is_popular=%s, stock=%s
            WHERE id=%s
        """, (category_id, name, description, price, discount_price,
              image_filename, is_new, is_popular, stock, product_id))

        flash('Product updated successfully.', 'success')
        return redirect(url_for('admin_products'))

    return render_template('admin/edit_product.html', product=product, categories=categories, sizes=sizes)


@app.route('/admin/products/delete/<int:product_id>')
@admin_required
def admin_delete_product(product_id):
    db.execute('DELETE FROM products WHERE id = %s', (product_id,))
    flash('Product deleted.', 'info')
    return redirect(url_for('admin_products'))


@app.route('/admin/products/update-stock/<int:product_id>', methods=['POST'])
@admin_required
def admin_update_stock(product_id):
    stock = request.form.get('stock', type=int)
    if stock is not None:
        db.execute('UPDATE products SET stock = %s WHERE id = %s', (stock, product_id))
        flash('Stock updated.', 'success')
    return redirect(url_for('admin_products'))


@app.route('/admin/categories', methods=['GET', 'POST'])
@admin_required
def admin_categories():
    if request.method == 'POST':
        name = request.form.get('name', '').strip()
        slug = name.lower().replace(' ', '-')
        if name:
            existing = db.query('SELECT id FROM categories WHERE slug = %s', (slug,), fetchone=True)
            if not existing:
                db.execute('INSERT INTO categories (name, slug) VALUES (%s, %s)', (name, slug))
                flash('Category added.', 'success')
            else:
                flash('Category already exists.', 'warning')
        return redirect(url_for('admin_categories'))

    categories = db.query('SELECT * FROM categories ORDER BY name')
    return render_template('admin/categories.html', categories=categories)


@app.route('/admin/categories/delete/<int:category_id>')
@admin_required
def admin_delete_category(category_id):
    db.execute('DELETE FROM categories WHERE id = %s', (category_id,))
    flash('Category deleted.', 'info')
    return redirect(url_for('admin_categories'))


@app.route('/admin/orders')
@admin_required
def admin_orders():
    all_orders = db.query("""
        SELECT o.*, u.full_name, u.email FROM orders o
        JOIN users u ON o.user_id = u.id ORDER BY o.created_at DESC
    """)
    return render_template('admin/orders.html', orders=all_orders)


@app.route('/admin/orders/<int:order_id>')
@admin_required
def admin_order_details(order_id):
    order = db.query("""
        SELECT o.*, u.full_name, u.email, u.phone, a.address, a.city, a.state, a.pincode, a.mobile
        FROM orders o
        JOIN users u ON o.user_id = u.id
        JOIN addresses a ON o.address_id = a.id
        WHERE o.id = %s
    """, (order_id,), fetchone=True)
    if not order:
        flash('Order not found.', 'danger')
        return redirect(url_for('admin_orders'))
    items = db.query('SELECT * FROM order_items WHERE order_id = %s', (order_id,))
    return render_template('admin/order_details.html', order=order, items=items)


@app.route('/admin/orders/<int:order_id>/status', methods=['POST'])
@admin_required
def admin_update_order_status(order_id):
    status = request.form.get('status')
    valid_statuses = ['Pending', 'Confirmed', 'Shipped', 'Delivered', 'Cancelled']
    if status in valid_statuses:
        db.execute('UPDATE orders SET status = %s WHERE id = %s', (status, order_id))
        flash('Order status updated.', 'success')
    return redirect(url_for('admin_order_details', order_id=order_id))


@app.route('/admin/users')
@admin_required
def admin_users():
    users = db.query('SELECT * FROM users WHERE is_admin = 0 ORDER BY created_at DESC')
    return render_template('admin/users.html', users=users)


@app.route('/admin/users/<int:user_id>')
@admin_required
def admin_user_details(user_id):
    user = db.query('SELECT * FROM users WHERE id = %s', (user_id,), fetchone=True)
    orders_list = db.query('SELECT * FROM orders WHERE user_id = %s ORDER BY created_at DESC', (user_id,))
    return render_template('admin/user_details.html', user=user, orders=orders_list)


# ---------------------------------------------------------------
# API helper for live search suggestions (used by script.js)
# ---------------------------------------------------------------

@app.route('/api/search-suggestions')
def search_suggestions():
    q = request.args.get('q', '').strip()
    if not q:
        return jsonify([])
    results = db.query("""
        SELECT id, name, price, discount_price, image FROM products
        WHERE name LIKE %s LIMIT 6
    """, (f'%{q}%',))
    return jsonify(results)


# ---------------------------------------------------------------
# Error handlers
# ---------------------------------------------------------------

@app.errorhandler(404)
def not_found(e):
    return render_template('404.html'), 404


if __name__ == '__main__':
    with app.app_context():
        try:
            ensure_admin_account()
        except Exception as exc:
            print(f"Warning: could not verify admin account automatically ({exc}).")
            print("Make sure shoekart_db has been imported and MySQL is running.")
    app.run(debug=True)
