# 宠物领养与寄养信息管理系统

数据库工程课程大作业，基于 Flask + MySQL 构建的宠物领养与寄养管理平台，覆盖人员、宠物、领养申请、寄养订单和健康日志五大业务模块。

## 技术栈

| 层级 | 技术 |
|------|------|
| 后端框架 | Python Flask |
| 数据库 | MySQL 8.0+ |
| 数据库驱动 | PyMySQL |
| 前端 | Jinja2 模板 + 原生 CSS |

## 项目结构

```
pet_management_system/
├── app.py                  # Flask 主程序（路由、业务逻辑）
├── requirements.txt        # Python 依赖
├── sql/
│   ├── init_all.sql        # 一键初始化入口（source 其余文件）
│   ├── schema.sql          # DDL + 初始数据
│   ├── triggers.sql        # 领养资格校验触发器
│   ├── procedures.sql      # 寄养费用计算存储过程
│   └── views.sql           # 四个业务视图
├── templates/
│   ├── base.html           # 公共布局（侧边栏导航）
│   ├── index.html          # 首页仪表盘
│   ├── applications.html   # 领养申请管理
│   ├── persons.html        # 人员管理
│   ├── foster_orders.html  # 寄养订单管理
│   └── pet_overview.html   # 综合查询
└── static/
    └── style.css           # 全局样式
```

## 数据库设计

共 12 张表，围绕人员（person）、宠物（pet）两条主线展开：

```
person ──┬── employee ──┬── care_for ── pet ── adopt_pet ── adopt_application
          │              │                │
          │              └── handle ── health_log
          │
          └── customer ──┬── adopt_application
                         │
                         └── foster_order ── foster_pet ── pet
```

- **person** — 人员基础档案（姓名、性别、电话、地址）
- **employee** — 员工信息（职位、薪资），外键引用 person
- **customer** — 客户信息（注册时间、资格状态、信用积分），外键引用 person
- **pet** — 宠物档案（品种、性别、年龄、健康状况、性格）
- **adopt_application** — 领养申请（申请时间、审核状态、备注），外键引用 customer
- **adopt_pet** — 待领养/已领养宠物（领养状态、绝育情况、来源、救助日期），外键引用 pet 和 adopt_application
- **foster_order** — 寄养订单（起止日期、费用、状态），外键引用 customer
- **foster_pet** — 寄养关联宠物，外键引用 pet 和 foster_order
- **health_log** — 健康服务日志（服务类型、详情、费用、复诊提醒），外键引用 pet
- **care_for** — 员工-宠物照护关系，外键引用 employee 和 pet
- **handle** — 员工-健康日志处理关系，外键引用 employee 和 health_log

## 核心功能与报告对应

| 功能页面 | 报告要求 | 数据库技术 |
|----------|----------|------------|
| `/applications` 新增领养申请 | 触发器控制下的添加操作 | `before_adopt_application_insert` 触发器自动校验客户资格状态与信用积分 |
| `/foster-orders` 更新寄养费用 | 存储过程控制下的更新操作 | `update_foster_order_cost` 存储过程计算天数 × 宠物数 × 单价 |
| `/persons` 删除人员 | 含有事务应用的删除操作 | 事务逐层删除 person→employee→customer→foster/adopt 等 8 张表的关联记录 |
| `/pet-overview` 综合查询 | 含有视图的查询操作 | 四个视图：`v_adopt_pet_info`、`v_foster_pet_info`、`v_pet_health_log`、`v_customer_summary` |

## 快速开始

### 1. 环境要求

- Python 3.10+
- MySQL 8.0+

### 2. 初始化数据库

在 MySQL 命令行中进入 `sql` 目录，执行：

```bash
mysql -u root -p < schema.sql
mysql -u root -p pet_management_db < triggers.sql
mysql -u root -p pet_management_db < procedures.sql
mysql -u root -p pet_management_db < views.sql
```

或使用一体化脚本（需在 MySQL 命令行中以 `SOURCE` 方式执行，或在 sql 目录下直接运行）：

```bash
mysql -u root -p < init_all.sql
```

> 如果 MySQL 不在 PATH 中，请替换为完整路径，例如：
> ```powershell
> & "C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe" -u root -p < schema.sql
> ```

### 3. 安装 Python 依赖

```bash
pip install -r requirements.txt
```

### 4. 配置环境变量

```bash
# Windows (cmd)
set DB_USER=root
set DB_PASSWORD=你的密码

# Windows (PowerShell)
$env:DB_USER="root"
$env:DB_PASSWORD="你的密码"
```

可选配置项：

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `DB_HOST` | 127.0.0.1 | 数据库地址 |
| `DB_PORT` | 3306 | 数据库端口 |
| `DB_USER` | root | 数据库用户名 |
| `DB_PASSWORD` | 006315 | 数据库密码 |
| `DB_NAME` | pet_management_db | 数据库名称 |
| `FLASK_DEBUG` | 0 | 调试模式（设为 1 开启） |
| `APP_SECRET_KEY` | 内置默认值 | Flask session 密钥 |

### 5. 启动

```bash
python app.py
```

浏览器访问 `http://127.0.0.1:5000`。

## 页面说明

- **首页** — 各业务表统计概览 + 最近 5 条健康日志
- **领养申请管理** — 查看客户列表（资格状态、信用积分），新增领养申请（触发资格校验）
- **寄养订单管理** — 查看寄养订单及关联宠物，更新费用（调用存储过程）
- **人员管理** — 查看所有人员（客户/员工身份自动判定），事务删除人员及全部关联数据
- **综合查询** — 按关键词搜索四个视图：领养总览、寄养总览、健康日志、客户统计

## 数据库亮点

- **触发器** `before_adopt_application_insert`：插入领养申请前自动校验客户资格状态是否为「合格」且信用积分 ≥ 60，不通过则抛出 SIGNAL 拒绝操作
- **存储过程** `update_foster_order_cost`：计算 `DATEDIFF(end_date, start_date) × 宠物数量 × 每日单价`，含订单存在性、日期合法性、宠物关联性等多重校验
- **事务**：`/persons/<id>/delete` 删除人员时手动控制 `commit/rollback`，保证 8 张关联表的一致性
- **视图**：四个 JOIN 视图封装复杂查询，应用层直接 `SELECT * FROM view`，与普通表使用方式一致
