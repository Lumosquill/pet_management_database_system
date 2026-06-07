USE pet_management_db;

DELIMITER //
DROP TRIGGER IF EXISTS before_adopt_application_insert //

CREATE TRIGGER before_adopt_application_insert
BEFORE INSERT ON adopt_application       
FOR EACH ROW                            
BEGIN
    DECLARE v_status VARCHAR(10);       
    DECLARE v_credit INT;                

    SELECT eligibility_status, credit_points
      INTO v_status, v_credit
      FROM customer
     WHERE user_id = NEW.user_id;


    IF v_status <> '合格' THEN
        SIGNAL SQLSTATE '45000'      
            SET MESSAGE_TEXT = '客户领养资格未通过，不能提交领养申请';
    END IF;
    
    IF v_credit < 60 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '客户信用积分不足 60，不能提交领养申请';
    END IF;


    IF NEW.apply_time IS NULL THEN
        SET NEW.apply_time = NOW();      
    END IF;
    IF NEW.audit_status IS NULL OR NEW.audit_status = '' THEN
        SET NEW.audit_status = '待审核'; 
    END IF;
END //

DELIMITER ;
