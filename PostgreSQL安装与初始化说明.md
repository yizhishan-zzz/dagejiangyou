# PostgreSQL 安装与初始化说明（打个酱油项目）

本文档说明「打个酱油」后端所使用的 PostgreSQL 数据库如何安装（Windows）、如何初始化（建库 + 建表 + 灌演示数据），以及后端如何连接。

## 一、项目数据库概况

| 项 | 值 |
|---|---|
| 数据库 | PostgreSQL |
| 库名 | community_micro_logistics |
| 默认连接 | localhost:5432，用户名 postgres，密码 postgres |
| 表数量 | 16 张（含访问统计表 visit_logs） |
| 后端 ORM | Spring Data JPA + Hibernate，ddl-auto: validate |

后端通过三个环境变量读取连接（不设则用默认值）：

| 环境变量 | 默认值 |
|---|---|
| DATABASE_URL | jdbc:postgresql://localhost:5432/community_micro_logistics |
| DATABASE_USERNAME | postgres |
| DATABASE_PASSWORD | postgres |

---

## 二、如何安装 PostgreSQL（Windows）

### 方式 A：官方安装包（图形界面，推荐新手）

1. 打开下载页：<code>https://www.postgresql.org/download/windows/</code>，下载最新版安装包（.exe）。
2. 双击安装，一路 Next；到 <b>Installation Directory</b> 那一步，把目录改成 <code>D:\PostgreSQL</code>（或 D 盘任意新文件夹）。
3. 设置超级用户 <code>postgres</code> 的密码（本项目默认用 <code>postgres</code>，请记牢）。
4. 端口保持 <code>5432</code>，其余默认，直到完成。
5. 完成后，Windows 服务 <code>postgresql-x64-XX</code> 会自动启动（服务名示例：postgresql-x64-18）。

### 方式 B：免安装 ZIP 二进制包（便携，纯解压到 D 盘）

1. 下载 PostgreSQL 的 Windows 二进制压缩包（文件名形如 <code>postgresql-18-windows-x64-binaries.zip</code>）。
2. 解压到 <code>D:\PostgreSQL</code>。
3. 在 <code>D:\PostgreSQL</code> 下初始化数据目录：

       bin\initdb.exe -D data -U postgres -E UTF8 --locale=C

4. 启动并后台运行：

       bin\pg_ctl.exe -D data -l logfile start

5. （可选）注册成 Windows 服务，开机自启：

       bin\pg_ctl.exe register -N postgresql -D data

> 方式 B 不需要管理员权限，也不写系统目录，最适合「放 D 盘一个独立文件夹」这种用法。

---

## 三、如何初始化本项目数据库

初始化只需做一次：建库 → 建表 → 灌演示数据。下面的命令都以超级用户 postgres 为例。

### 3.1 确认 PostgreSQL 已启动

    "D:\PostgreSQL\bin\pg_isready.exe" -h localhost -p 5432

看到 <code>accepting connections</code> 即正常。

### 3.2 创建数据库

    "D:\PostgreSQL\bin\psql.exe" -h localhost -p 5432 -U postgres -d postgres -c "CREATE DATABASE community_micro_logistics;"

### 3.3 建表（执行 schema.sql）

    "D:\PostgreSQL\bin\psql.exe" -h localhost -p 5432 -U postgres -d community_micro_logistics -f "backend\src\main\resources\schema.sql"

会创建 16 张表：users、tasks、wallets、wallet_transactions、pools、pool_members、chats、reviews、orders、dispute_tickets、ad_slots、communities、community_buildings、auth_otp_codes、auth_refresh_tokens、visit_logs。

### 3.4 灌演示数据（执行 data.sql）

    "D:\PostgreSQL\bin\psql.exe" -h localhost -p 5432 -U postgres -d community_micro_logistics -f "backend\src\main\resources\data.sql"

会写入演示数据：4 个用户、2 个任务、拼单、广告位等。

### 3.5 验证

    "D:\PostgreSQL\bin\psql.exe" -h localhost -p 5432 -U postgres -d community_micro_logistics -c "\dt"
    "D:\PostgreSQL\bin\psql.exe" -h localhost -p 5432 -U postgres -d community_micro_logistics -c "SELECT count(*) FROM users;"

预期：列出 16 张表；users 返回 4。

> 如果 psql 不在 PATH，用完整路径 <code>D:\PostgreSQL\bin\psql.exe</code> 即可；也可把 <code>D:\PostgreSQL\bin</code> 加入系统 PATH。

---

## 四、后端如何连接 PostgreSQL

后端连接信息由 <code>backend/src/main/resources/application.yml</code> 读取，优先级：环境变量 > 默认值。

- 用默认值（localhost:5432 / postgres / postgres）时，直接启动即可。
- 连其它地址/账号时，设置三个环境变量，例如：

      $env:DATABASE_URL="jdbc:postgresql://你的地址:5432/community_micro_logistics"
      $env:DATABASE_USERNAME="你的用户名"
      $env:DATABASE_PASSWORD="你的密码"
      .\gradlew.bat bootRun

- 也可以在 <code>启动管理员端.bat</code> 顶部的三行里直接改。

---

## 五、当前机器已完成的初始化（现状）

- PostgreSQL 18 已安装在 <code>D:\PostgreSQL</code>，Windows 服务 <code>postgresql-x64-18</code> 运行中。
- 超级用户 <code>postgres</code> / 密码 <code>postgres</code> 可用（已验证连接成功）。
- 数据库 <code>community_micro_logistics</code> 已创建。
- 16 张表已建、演示数据已灌（4 用户 / 2 任务）。
- 已修复 schema 与实体的一处不一致：<code>reviews.rating</code> 由 smallint 改为 integer（与实体 Int 对齐）。

---

## 六、常见问题

**Q1：启动后端报 Connection refused（连不上 localhost:5432）**
A：PostgreSQL 没启动。启动服务：<code>net start postgresql-x64-18</code>，或方式 B 下用 <code>pg_ctl start</code>。

**Q2：报 FATAL: database "community_micro_logistics" does not exist**
A：还没建库，执行第三节的 3.2。

**Q3：报 Schema-validation: wrong column type ... / missing table ...**
A：schema.sql 与后端实体不一致（Hibernate validate 模式会严格校验）。按报错里指出的列/表，去 <code>schema.sql</code> 和数据库里把类型/结构改成与实体一致即可。本项目已修好 reviews.rating 这一处。

**Q4：报 FATAL: password authentication failed**
A：密码不对。把 <code>启动管理员端.bat</code> 顶部（或环境变量）里的 DATABASE_PASSWORD 改成你的实际密码。

**Q5：端口 5432 被占用 / 想换端口**
A：改 postgresql.conf 里的 <code>port</code>，同时把后端的 DATABASE_URL 改成对应端口。

**Q6：想用 H2 内存库快速演示（不依赖 PostgreSQL）**
A：启动后端时加 <code>--args=--spring.profiles.active=dev</code>，dev 配置用的是 H2 内存库。
