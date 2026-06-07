DROP DATABASE IF EXISTS pet_management_db;
CREATE DATABASE IF NOT EXISTS pet_management_db
  DEFAULT CHARSET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE pet_management_db;

CREATE TABLE person
(
    user_id VARCHAR(18) NOT NULL,
    name VARCHAR(20) NOT NULL,
    gender CHAR(2),
    phone VARCHAR(11),
    address VARCHAR(50),
    PRIMARY KEY(user_id)
);

CREATE TABLE employee
(
    user_id VARCHAR(18) NOT NULL,
    position VARCHAR(10),
    salary DECIMAL(10,2),
    PRIMARY KEY(user_id),
    FOREIGN KEY(user_id) REFERENCES person(user_id)
);

CREATE TABLE customer
(
    user_id VARCHAR(18) NOT NULL,
    register_time DATETIME,
    eligibility_status VARCHAR(10),
    credit_points INT,
    PRIMARY KEY(user_id),
    FOREIGN KEY(user_id) REFERENCES person(user_id)
);

CREATE TABLE pet
(
   pet_id VARCHAR(20) NOT NULL,
   name VARCHAR(10) NOT NULL,
   breed VARCHAR(20),
   gender CHAR(2),
   age INT,
   health_status VARCHAR(30),
   temper VARCHAR(20),
   PRIMARY KEY (pet_id)
);

CREATE TABLE adopt_application (
    apply_id VARCHAR(20) NOT NULL,
    user_id VARCHAR(18) NOT NULL,
    apply_time DATETIME,
    audit_status VARCHAR(10),
    audit_remarks VARCHAR(30),
    PRIMARY KEY (apply_id),
    FOREIGN KEY (user_id) REFERENCES customer(user_id)
);

CREATE TABLE adopt_pet (
    pet_id VARCHAR(20) NOT NULL,
    apply_id VARCHAR(20),
    adopt_status VARCHAR(20),
    is_neutered VARCHAR(10),
    source VARCHAR(20),
    rescue_date DATE,
    PRIMARY KEY (pet_id),
    FOREIGN KEY (pet_id) REFERENCES pet(pet_id),
    FOREIGN KEY (apply_id) REFERENCES adopt_application(apply_id)
);

CREATE TABLE foster_order (
    order_id VARCHAR(20) NOT NULL,
    user_id VARCHAR(18) NOT NULL,
    start_date DATE,
    end_date DATE,
    cost DECIMAL(10,2),
    order_status VARCHAR(10),
    PRIMARY KEY (order_id),
    FOREIGN KEY (user_id) REFERENCES customer(user_id)
);

CREATE TABLE foster_pet (
    pet_id VARCHAR(20) NOT NULL,
    order_id VARCHAR(20),
    PRIMARY KEY (pet_id),
    FOREIGN KEY (pet_id) REFERENCES pet(pet_id),
    FOREIGN KEY (order_id) REFERENCES foster_order(order_id)
);

CREATE TABLE health_log (
    log_id VARCHAR(20) NOT NULL,
    pet_id VARCHAR(20) NOT NULL,
    service_type VARCHAR(20),
    log_date DATE,
    detail VARCHAR(100),
    cost DECIMAL(10,2),
    next_remind_date DATE,
    PRIMARY KEY (log_id),
    FOREIGN KEY (pet_id) REFERENCES pet(pet_id)
);

CREATE TABLE care_for (
    user_id VARCHAR(18) NOT NULL,
    pet_id VARCHAR(20) NOT NULL,
    PRIMARY KEY (user_id, pet_id),
    FOREIGN KEY (user_id) REFERENCES employee(user_id),
    FOREIGN KEY (pet_id) REFERENCES pet(pet_id)
);

CREATE TABLE handle (
    user_id VARCHAR(18) NOT NULL,
    log_id VARCHAR(20) NOT NULL,
    PRIMARY KEY (user_id, log_id),
    FOREIGN KEY (user_id) REFERENCES employee(user_id),
    FOREIGN KEY (log_id) REFERENCES health_log(log_id)
);

INSERT INTO person VALUES
('110101200001010011','李晴','女','13800000001','天津市南开区'),
('110101200002020022','周远','男','13800000002','天津市和平区'),
('120101199901010033','王建国','男','13900000003','天津市河西区'),
('120101199802020044','赵丽芳','女','13900000004','天津市河北区'),
('120101199803030055','孙志强','男','13900000005','天津市河东区'),
('120101199904040066','吴永辉','男','13900000006','天津市红桥区'),
('120101199905050077','杨晓燕','女','13900000007','天津市西青区'),
('110101200003030033','张美琳','女','13800000005','天津市北辰区'),
('110101200004040044','刘建国','男','13800000006','天津市津南区'),
('110101200005050055','陈小红','女','13800000007','天津市武清区');

INSERT INTO customer VALUES
('110101200001010011','2026-05-01 09:30:00','合格',90),
('110101200002020022','2026-05-05 15:00:00','未通过',55),
('110101200003030033','2026-05-10 11:00:00','合格',85),
('110101200004040044','2026-05-12 14:30:00','待审核',78),
('110101200005050055','2026-05-15 10:00:00','未通过',82);

INSERT INTO employee VALUES
('120101199901010033','医生',8500.00),
('120101199802020044','护理',6200.00),
('120101199803030055','兽医',9000.00),
('120101199904040066','主管',12000.00),
('120101199905050077','护理',5800.00);

INSERT INTO pet VALUES
('P001','团团','中华田园猫','公',2,'健康','亲人'),
('P002','年年','金毛','母',4,'需复查','温顺'),
('P003','豆包','柯基','公',3,'健康','活泼'),
('P004','小橘','橘猫','母',1,'健康','胆小'),
('P005','小黑','拉布拉多','公',5,'健康','忠诚'),
('P006','雪球','布偶猫','母',2,'健康','粘人'),
('P007','旺财','泰迪','公',3,'需接种疫苗','好动'),
('P008','花花','英短','母',1,'健康','安静'),
('P009','大壮','哈士奇','公',4,'健康','活泼'),
('P010','咪咪','暹罗猫','母',2,'需驱虫','亲人');

INSERT INTO adopt_application VALUES
('A001','110101200001010011','2026-05-12 10:00:00','通过','适合领养'),
('A002','110101200001010011','2026-05-16 09:00:00','未通过','居住环境不适合养宠'),
('A003','110101200003030033','2026-05-18 14:00:00','待审核',NULL),
('A004','110101200003030033','2026-05-20 11:00:00','未通过','工作不稳定，不适合领养');

INSERT INTO adopt_pet VALUES
('P001','A001','已领养','是','救助站','2026-04-12'),
('P004',NULL,'待领养','是','社区救助','2026-05-08'),
('P005','A002','已领养','是','救助站','2026-05-16'),
('P006',NULL,'待领养','否','爱心人士送养','2026-05-20'),
('P008',NULL,'待领养','否','社区救助','2026-05-22');

INSERT INTO foster_order VALUES
('F001','110101200001010011','2026-05-20','2026-05-25',1000.00,'进行中'),
('F002','110101200003030033','2026-05-18','2026-05-22',400.00,'已完成'),
('F003','110101200005050055','2026-05-22','2026-05-28',1200.00,'进行中');

INSERT INTO foster_pet VALUES
('P002','F001'),
('P003','F001'),
('P007','F002'),
('P009','F003'),
('P010','F003');

INSERT INTO health_log VALUES
('H001','P002','体检','2026-05-18','耳部复查，建议一周后复诊',80.00,'2026-05-25'),
('H002','P001','疫苗','2026-05-10','完成年度疫苗',120.00,'2027-05-10'),
('H003','P005','体检','2026-05-14','常规体检，各项指标正常',60.00,'2027-05-14'),
('H004','P007','疫苗','2026-05-17','狂犬疫苗接种',100.00,'2027-05-17'),
('H005','P003','驱虫','2026-05-19','体内外驱虫',45.00,'2026-08-19'),
('H006','P009','体检','2026-05-21','常规体检，轻微牙结石',70.00,'2026-11-21'),
('H007','P002','治疗','2026-05-22','耳道感染治疗',150.00,'2026-05-29');

INSERT INTO care_for VALUES
('120101199802020044','P002'),
('120101199802020044','P003'),
('120101199905050077','P007'),
('120101199905050077','P009'),
('120101199905050077','P010');

INSERT INTO handle VALUES
('120101199901010033','H001'),
('120101199803030055','H002'),
('120101199901010033','H003'),
('120101199803030055','H004'),
('120101199802020044','H005'),
('120101199905050077','H006'),
('120101199901010033','H007');

INSERT INTO pet VALUES
('P011','大黑','藏獒','公',3,'健康','烈性'),
('P012','小青','蟒蛇','母',2,'健康','温顺'),
('P013','飞飞','边境牧羊犬','公',2,'健康','活泼'),
('P014','小白','波斯猫','母',3,'健康','粘人'),
('P015','慢慢','乌龟','公',2,'健康','安静');

INSERT INTO foster_order VALUES
('F004','110101200005050055','2026-06-01','2026-07-05',NULL,'进行中'),
('F005','110101200003030033','2026-06-10','2026-06-20',NULL,'进行中');

INSERT INTO foster_pet VALUES
('P011','F004'),
('P012','F004'),
('P014','F004'),
('P013','F005'),
('P015','F005');

INSERT INTO care_for VALUES
('120101199802020044','P011'),
('120101199802020044','P012');
