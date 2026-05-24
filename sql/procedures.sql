USE pet_management_db;

DELIMITER //

DROP PROCEDURE IF EXISTS update_foster_order_cost //

CREATE PROCEDURE update_foster_order_cost
(
	-- 入参：订单编号、每日单价
    IN p_order_id VARCHAR(20),
    IN p_daily_price DECIMAL(10,2)
)
BEGIN
    DECLARE v_days INT;
    DECLARE v_pet_count INT;
    DECLARE v_order_exists INT;

    -- 校验 1：订单是否存在
    SELECT COUNT(*)
      INTO v_order_exists
      FROM foster_order
     WHERE order_id = p_order_id;
    IF v_order_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '寄养订单不存在';
    END IF;

    -- 校验 2：单价是否合法
    IF p_daily_price <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '每日寄养单价必须大于 0';
    END IF;

    -- 计算寄养天数
    SELECT DATEDIFF(end_date, start_date)
      INTO v_days
      FROM foster_order
     WHERE order_id = p_order_id;

    -- 校验 3：日期是否有效
    IF v_days <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '寄养结束日期必须晚于开始日期';
    END IF;

    -- 统计关联宠物数量
    SELECT COUNT(*)
      INTO v_pet_count
      FROM foster_pet
     WHERE order_id = p_order_id;

    -- 校验 4：是否关联了寄养宠物
    IF v_pet_count = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '订单未关联寄养宠物，不能计算费用';
    END IF;

    -- 更新费用：费用 = 天数 × 宠物数量 × 单价
    UPDATE foster_order
       SET cost = v_days * v_pet_count * p_daily_price
     WHERE order_id = p_order_id;

    -- 返回: 订单编号、寄养天数、宠物数量、单价、新费用
    SELECT p_order_id AS order_id,
           v_days AS foster_days,
           v_pet_count AS pet_count,
           p_daily_price AS daily_price,
           v_days * v_pet_count * p_daily_price AS new_cost;
END //

DELIMITER ;
