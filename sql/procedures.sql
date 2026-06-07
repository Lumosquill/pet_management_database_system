USE pet_management_db;

DELIMITER //

DROP PROCEDURE IF EXISTS update_foster_order_cost //

CREATE PROCEDURE update_foster_order_cost
(
    IN p_order_id VARCHAR(20)
)
BEGIN
    DECLARE v_start_date DATE;
    DECLARE v_end_date DATE;
    DECLARE v_days INT;
    DECLARE v_pet_count INT;
    DECLARE v_total_cost DECIMAL(10,2) DEFAULT 0;
    DECLARE v_daily_base DECIMAL(10,2);
    DECLARE v_pet_breed VARCHAR(20);
    DECLARE v_pet_cost DECIMAL(10,2);
    DECLARE v_discount_rate DECIMAL(3,2) DEFAULT 1.00;
    DECLARE v_done INT DEFAULT 0;
    
    DECLARE pet_cursor CURSOR FOR
        SELECT p.breed
          FROM foster_pet fp
          JOIN pet p ON fp.pet_id = p.pet_id
         WHERE fp.order_id = p_order_id;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

    -- 校验 1
    IF NOT EXISTS (SELECT 1 FROM foster_order WHERE order_id = p_order_id) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '寄养订单不存在';
    END IF;

    SELECT start_date, end_date
      INTO v_start_date, v_end_date
      FROM foster_order
     WHERE order_id = p_order_id;

    IF v_end_date IS NULL THEN
        SET v_end_date = CURDATE();
        UPDATE foster_order
           SET end_date = CURDATE(), order_status = '已完成'
         WHERE order_id = p_order_id;
    END IF;

    SET v_days = DATEDIFF(v_end_date, v_start_date);

    -- 校验 2
    IF v_days <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '寄养结束日期必须晚于开始日期';
    END IF;

    -- 校验 3
    SELECT COUNT(*) INTO v_pet_count
      FROM foster_pet
     WHERE order_id = p_order_id;

    IF v_pet_count = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '订单未关联寄养宠物，不能计算费用';
    END IF;

    OPEN pet_cursor;
    pet_loop: LOOP
        FETCH pet_cursor INTO v_pet_breed;
        IF v_done THEN LEAVE pet_loop; END IF;

        SET v_daily_base = 80;

        IF v_pet_breed IN ('藏獒', '比特犬', '罗威纳犬') THEN
            SET v_daily_base = v_daily_base + 30;
        END IF;
  
        IF v_pet_breed IN ('蟒蛇', '蜥蜴', '乌龟') THEN
            SET v_daily_base = v_daily_base + 30;
        END IF;

        IF v_days <= 30 THEN
            SET v_pet_cost = v_days * v_daily_base;
        ELSE
            SET v_pet_cost = 30 * v_daily_base
                           + (v_days - 30) * v_daily_base * 0.9;
        END IF;

        SET v_total_cost = v_total_cost + v_pet_cost;
    END LOOP;
    CLOSE pet_cursor;

    IF v_pet_count > 4 THEN
        SET v_discount_rate = 0.85;
    ELSEIF v_pet_count > 2 THEN
        SET v_discount_rate = 0.90;
    ELSE
        SET v_discount_rate = 1.00;
    END IF;

    SET v_total_cost = v_total_cost * v_discount_rate;

    UPDATE foster_order
       SET cost = v_total_cost
     WHERE order_id = p_order_id;

    SELECT p_order_id      AS order_id,
           v_days          AS foster_days,
           v_pet_count     AS pet_count,
           v_discount_rate AS discount_rate,
           v_total_cost    AS new_cost;

END //

DELIMITER ;