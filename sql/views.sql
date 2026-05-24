USE pet_management_db;

DROP VIEW IF EXISTS v_pet_service_overview;

-- ============================================================
-- 1. v_adopt_pet_info — 领养总览
--    待领养宠物 + 宠物基本信息 + 领养申请 + 申请人
--    连接方式：INNER JOIN 获取宠物档案，LEFT JOIN 保留暂无申请的宠物
-- ============================================================
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

-- ============================================================
-- 2. v_foster_pet_info — 寄养总览
--    寄养宠物 + 宠物基本信息 + 寄养订单 + 客户
--    连接方式：全部 INNER JOIN（仅展示已关联订单的寄养宠物）
-- ============================================================
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

-- ============================================================
-- 3. v_pet_health_log — 健康日志明细
--    健康日志 + 宠物信息 + 处理员工
--    连接方式：LEFT JOIN 保留暂无指定处理员工的日志记录
-- ============================================================
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

-- ============================================================
-- 4. v_customer_summary — 客户统计（含聚合）
--    客户信息 + 寄养订单数 + 领养申请数 + 寄养总花费
--    聚合方式：COUNT(DISTINCT) 去重计数，IFNULL 处理空值
-- ============================================================
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
