USE pet_management_db;

-- 领养总览视图
DROP VIEW IF EXISTS v_adopt_pet_info;

CREATE VIEW v_adopt_pet_info AS
SELECT
    ap.pet_id,
    p.name AS pet_name,
    p.breed,
    p.gender,
    p.age,
    p.health_status,
    p.temper,
    ap.adopt_status,
    ap.is_neutered,
    ap.source,
    ap.rescue_date,
    aa.apply_id,
    aa.apply_time,
    aa.audit_status,
    aa.audit_remarks,
    per.user_id AS applicant_id,
    per.name AS applicant_name
FROM adopt_pet ap
JOIN pet p ON ap.pet_id = p.pet_id
LEFT JOIN adopt_application aa ON ap.apply_id = aa.apply_id
LEFT JOIN person per ON aa.user_id = per.user_id;

--寄养总览视图
DROP VIEW IF EXISTS v_foster_pet_info;

CREATE VIEW v_foster_pet_info AS
SELECT
    fp.pet_id,
    p.name AS pet_name,
    p.breed,
    p.gender,
    p.health_status,
    fo.order_id,
    fo.start_date,
    fo.end_date,
    fo.cost,
    fo.order_status,
    owner.user_id AS customer_id,
    owner.name AS customer_name
FROM foster_pet fp
JOIN pet p ON fp.pet_id = p.pet_id
JOIN foster_order fo ON fp.order_id = fo.order_id
JOIN person owner ON fo.user_id = owner.user_id;


-- 健康日志视图
DROP VIEW IF EXISTS v_pet_health_log;

CREATE VIEW v_pet_health_log AS
SELECT
    hl.log_id,
    hl.pet_id,
    p.name AS pet_name,
    p.breed,
    hl.service_type,
    hl.log_date,
    hl.detail,
    hl.cost,
    hl.next_remind_date,
    h.user_id AS handler_id,
    emp.name AS handler_name,
    e.position AS handler_position
FROM health_log hl
JOIN pet p ON hl.pet_id = p.pet_id
LEFT JOIN handle h ON hl.log_id = h.log_id
LEFT JOIN employee e ON h.user_id = e.user_id
LEFT JOIN person emp ON e.user_id = emp.user_id;


-- 客户统计视图
DROP VIEW IF EXISTS v_customer_summary;

CREATE VIEW v_customer_summary AS
SELECT
    c.user_id,
    per.name,
    per.phone,
    c.register_time,
    c.eligibility_status,
    c.credit_points,
    COUNT(DISTINCT fo.order_id) AS foster_order_count,
    COUNT(DISTINCT aa.apply_id) AS adopt_apply_count,
    IFNULL(SUM(fo.cost), 0) AS total_foster_cost
FROM customer c
JOIN person per ON c.user_id = per.user_id
LEFT JOIN foster_order fo ON c.user_id = fo.user_id
LEFT JOIN adopt_application aa ON c.user_id = aa.user_id
GROUP BY c.user_id, per.name, per.phone, c.register_time, c.eligibility_status, c.credit_points;
