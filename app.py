import os
from contextlib import contextmanager
from datetime import datetime

import pymysql
from flask import Flask, flash, redirect, render_template, request, url_for


app = Flask(__name__)
app.secret_key = os.getenv("APP_SECRET_KEY", "pet-management-demo-secret")


DB_CONFIG = {
    "host": os.getenv("DB_HOST", "127.0.0.1"),
    "port": int(os.getenv("DB_PORT", "3306")),
    "user": os.getenv("DB_USER", "root"),
    "password": os.getenv("DB_PASSWORD", "006315"),
    "database": os.getenv("DB_NAME", "pet_management_db"),
    "charset": "utf8mb4",                     
    "cursorclass": pymysql.cursors.DictCursor,
    "autocommit": False,                     
}

# 数据库连接接口
@contextmanager
def get_db():
    conn = pymysql.connect(**DB_CONFIG)
    try:
        yield conn
    finally:
        conn.close()

# 查询接口
def fetch_all(sql, params=None):
    with get_db() as conn:
        with conn.cursor() as cursor:
            cursor.execute(sql, params or ())
            return cursor.fetchall()


def fetch_one(sql, params=None):
    rows = fetch_all(sql, params)
    return rows[0] if rows else None


@app.template_filter("datefmt")
def datefmt(value):
    """
    日期格式化过滤器
    模板中：{{ row.apply_time|datefmt }}
    None 值显示 '-'，datetime 对象格式化为 'YYYY-MM-DD HH:MM'
    """
    if value is None:
        return "-"
    if isinstance(value, datetime):
        return value.strftime("%Y-%m-%d %H:%M")
    return str(value)


# ═══════════════════════════════════════════════════════════════
# 首页
# ═══════════════════════════════════════════════════════════════
@app.route("/")
def index():
   
    stats = {
        "pets": fetch_one("SELECT COUNT(*) AS c FROM pet")["c"],
        "customers": fetch_one("SELECT COUNT(*) AS c FROM customer")["c"],
        "employees": fetch_one("SELECT COUNT(*) AS c FROM employee")["c"],
        "foster_orders": fetch_one("SELECT COUNT(*) AS c FROM foster_order")["c"],
        "adopt_applications": fetch_one("SELECT COUNT(*) AS c FROM adopt_application")["c"],
    }
    
    recent_logs = fetch_all(
        """
        SELECT h.log_id, p.name AS pet_name, h.service_type, h.log_date, h.detail, h.cost
          FROM health_log h
          JOIN pet p ON h.pet_id = p.pet_id
         ORDER BY h.log_date DESC
         LIMIT 5
        """
    )
    return render_template("index.html", stats=stats, recent_logs=recent_logs)


# ═══════════════════════════════════════════════════════════════
# 领养申请管理（含资格校验触发器）
# ═══════════════════════════════════════════════════════════════
@app.route("/applications", methods=["GET", "POST"])
def applications():
    if request.method == "POST":
        apply_id = request.form["apply_id"].strip()
        user_id = request.form["user_id"].strip()
        audit_remarks = request.form.get("audit_remarks", "").strip()
        try:
            with get_db() as conn:
                with conn.cursor() as cursor:
                    cursor.execute(
                        """
                        INSERT INTO adopt_application
                            (apply_id, user_id, apply_time, audit_status, audit_remarks)
                        VALUES (%s, %s, NOW(), '待审核', %s)
                        """,
                        (apply_id, user_id, audit_remarks),
                    )
                conn.commit()
            flash("领养申请添加成功。", "success")
            return redirect(url_for("applications"))
        except Exception as exc:
            code = exc.args[0] if exc.args else 0
            if code == 1062:
                flash(f"添加失败：申请编号「{apply_id}」已存在，请换一个编号。", "error")
            elif code == 1644:
                flash(f"添加失败：{exc.args[1]}", "error")
            else:
                flash(f"添加失败：{exc}", "error")

    customers = fetch_all(
        """
        SELECT c.user_id, p.name, c.eligibility_status, c.credit_points
          FROM customer c
          JOIN person p ON c.user_id = p.user_id
         ORDER BY c.register_time DESC
        """
    )
    rows = fetch_all(
        """
        SELECT a.apply_id, a.apply_time, a.audit_status, a.audit_remarks,
               p.name AS customer_name, c.eligibility_status, c.credit_points
          FROM adopt_application a
          JOIN customer c ON a.user_id = c.user_id
          JOIN person p ON c.user_id = p.user_id
         ORDER BY a.apply_time DESC
        """
    )
    return render_template("applications.html", customers=customers, rows=rows)


# ═══════════════════════════════════════════════════════════════
# 寄养订单管理（含自动计价存储过程）
# ═══════════════════════════════════════════════════════════════
@app.route("/foster-orders", methods=["GET", "POST"])
def foster_orders():
    if request.method == "POST":
        order_id = request.form["order_id"].strip()
        try:
            with get_db() as conn:
                with conn.cursor() as cursor:
                    cursor.execute(
                        "CALL update_foster_order_cost(%s)",
                        (order_id,),
                    )
                    result = cursor.fetchone()
                conn.commit()
            discount_text = {1.00: "无折扣", 0.90: "多只 9 折", 0.85: "多只 85 折"}.get(
                float(result.get('discount_rate', 1.00)), ""
            )
            flash(
                f"费用计算成功：{result['foster_days']} 天 × {result['pet_count']} 只 "
                f"（{discount_text}）→ 总费用 {result['new_cost']} 元。",
                "success",
            )
            return redirect(url_for("foster_orders"))
        except Exception as exc:
            code = exc.args[0] if exc.args else 0
            if code == 1644:
                flash(f"计算失败：{exc.args[1]}", "error")
            else:
                flash(f"计算失败：{exc}", "error")


    rows = fetch_all(
        """
        SELECT fo.order_id, owner.name AS customer_name, fo.start_date, fo.end_date,
               fo.cost, fo.order_status,
               GROUP_CONCAT(p.name ORDER BY p.pet_id SEPARATOR '、') AS pet_names,
               COUNT(fp.pet_id) AS pet_count,
               DATEDIFF(fo.end_date, fo.start_date) AS foster_days
          FROM foster_order fo
          JOIN person owner ON fo.user_id = owner.user_id
          LEFT JOIN foster_pet fp ON fo.order_id = fp.order_id
          LEFT JOIN pet p ON fp.pet_id = p.pet_id
         GROUP BY fo.order_id, owner.name, fo.start_date, fo.end_date, fo.cost, fo.order_status
         ORDER BY fo.start_date DESC
        """
    )
    return render_template("foster_orders.html", rows=rows)


# ═══════════════════════════════════════════════════════════════
# 人员管理（含事务删除）
# ═══════════════════════════════════════════════════════════════
@app.route("/persons")
def persons():
    """人员列表：展示基础信息 + 身份判定（客户/员工）"""
    rows = fetch_all("""
        SELECT per.user_id, per.name, per.gender, per.phone,
               CASE WHEN c.user_id IS NOT NULL THEN '客户'
                    WHEN e.user_id IS NOT NULL THEN '员工'
                    ELSE '-' END AS role,
               CASE WHEN c.user_id IS NOT NULL THEN c.eligibility_status ELSE NULL END AS eligibility_status,
               CASE WHEN e.user_id IS NOT NULL THEN e.position ELSE NULL END AS position
          FROM person per
          LEFT JOIN customer c ON per.user_id = c.user_id
          LEFT JOIN employee e ON per.user_id = e.user_id
         ORDER BY per.user_id
    """)
    return render_template("persons.html", rows=rows)


@app.post("/persons/<user_id>/delete")
def delete_person(user_id):
    try:
        with get_db() as conn:
            with conn.cursor() as cursor:

                cursor.execute("DELETE FROM handle WHERE user_id = %s", (user_id,))
                cursor.execute("DELETE FROM care_for WHERE user_id = %s", (user_id,))

                cursor.execute(
                    "DELETE FROM foster_pet WHERE order_id IN "
                    "(SELECT order_id FROM foster_order WHERE user_id = %s)",
                    (user_id,),
                )
                cursor.execute("DELETE FROM foster_order WHERE user_id = %s", (user_id,))

                cursor.execute(
                    "UPDATE adopt_pet SET apply_id = NULL "
                    "WHERE apply_id IN (SELECT apply_id FROM adopt_application WHERE user_id = %s)",
                    (user_id,),
                )
                cursor.execute("DELETE FROM adopt_application WHERE user_id = %s", (user_id,))

                cursor.execute("DELETE FROM customer WHERE user_id = %s", (user_id,))
                cursor.execute("DELETE FROM employee WHERE user_id = %s", (user_id,))

                cursor.execute("DELETE FROM person WHERE user_id = %s", (user_id,))


            conn.commit()
        flash(f"已删除人员 {user_id} 及其全部关联数据。", "success")
    except Exception as exc:
        flash(f"删除失败，事务已回滚：{exc}", "error")
    return redirect(url_for("persons"))


# ═══════════════════════════════════════════════════════════════
# 综合查询（数据库视图）
# ═══════════════════════════════════════════════════════════════
@app.route("/pet-overview")
def pet_overview():
    keyword = request.args.get("keyword", "").strip()
    view_name = request.args.get("view", "adopt")


    views = {
        "adopt":  ("v_adopt_pet_info",    ["pet_name", "breed", "adopt_status", "applicant_name"]),
        "foster": ("v_foster_pet_info",   ["pet_name", "breed", "order_status", "customer_name"]),
        "health": ("v_pet_health_log",    ["pet_name", "breed", "service_type", "handler_name"]),
        "summary":("v_customer_summary",  ["name", "eligibility_status", None, None]),
    }
    if view_name not in views:
        view_name = "adopt"

    table, columns = views[view_name]
    params = []


    sql = f"SELECT * FROM {table}"
    search_cols = [c for c in columns if c is not None]
    if keyword and search_cols:
        conditions = " OR ".join(f"{c} LIKE %s" for c in search_cols)
        sql += f" WHERE {conditions}"
        like = f"%{keyword}%"
        params = [like] * len(search_cols)
    sql += " LIMIT 50"
    rows = fetch_all(sql, params)
    return render_template("pet_overview.html", rows=rows, keyword=keyword, view=view_name)


if __name__ == "__main__":
    app.run(debug=os.getenv("FLASK_DEBUG", "0") == "1")
