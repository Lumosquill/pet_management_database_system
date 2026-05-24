USE pet_management_db;

DELIMITER //
DROP TRIGGER IF EXISTS before_adopt_application_insert //

-- 领养申请资格校验触发器
CREATE TRIGGER before_adopt_application_insert

-- 时机：INSERT 之前
BEFORE INSERT ON adopt_application
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(10);
    DECLARE v_credit INT;

    -- 查询申请者的资质信息
    SELECT eligibility_status, credit_points
      INTO v_status, v_credit
      FROM customer
     WHERE user_id = NEW.user_id;

    -- 校验一：资格状态必须为"合格"
    IF v_status <> '合格' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '客户领养资格未通过，不能提交领养申请';
    END IF;

    -- 校验二：信用积分必须 ≥ 60
    IF v_credit < 60 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '客户信用积分不足 60，不能提交领养申请';
    END IF;

    -- 通过校验 → 自动填入申请时间和初始审核状态默认值
    IF NEW.apply_time IS NULL THEN
        SET NEW.apply_time = NOW();
    END IF;
    IF NEW.audit_status IS NULL OR NEW.audit_status = '' THEN
        SET NEW.audit_status = '待审核';
    END IF;
END //

DELIMITER ;
