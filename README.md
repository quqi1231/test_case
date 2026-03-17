# AI-TestHub 智能测试平台

一个功能强大的接口自动化测试平台，支持接口管理、测试集执行、参数化测试、变量提取等功能。

## 项目结构

```
├── backend/           # 后端 (FastAPI + MySQL)
│   ├── app/
│   │   ├── api/      # API 路由
│   │   ├── models/   # 数据模型
│   │   ├── schemas/  # Pydantic schemas
│   │   ├── services/ # 业务逻辑
│   │   └── core/    # 核心配置
│   └── requirements.txt
│
├── frontend/         # 前端 (Vue 3 + Element Plus)
│   ├── src/
│   │   └── views/    # 页面组件
│   └── package.json
│
└── database.sql      # 数据库初始化脚本
```

## 快速开始

### 1. 环境要求

- Python 3.8+
- Node.js 16+
- MySQL 5.7+

### 2. 数据库初始化

```bash
mysql -u root -p < database.sql
```

### 3. 后端启动

```bash
cd backend

# 创建虚拟环境
python -m venv venv
source venv/bin/activate  # Linux/Mac
# venv\Scripts\activate  # Windows

# 安装依赖
pip install -r requirements.txt

# 配置环境变量
cp .env.example .env
# 编辑 .env 文件，配置数据库连接

# 启动服务
uvicorn app.main:app --host 0.0.0.0 --port 8010 --reload
```

### 4. 前端启动

```bash
cd frontend

# 安装依赖
npm install

# 启动开发服务器
npm run dev
```

访问 http://localhost:5173

## 功能特性

### 接口管理
- 接口 CRUD 操作
- 模块/集合分类
- 接口导入导出 (Excel/CSV/JSON/Postman/Swagger)
- 接口收藏与搜索

### 测试执行
- 单接口调试
- 接口链执行 (变量提取与传递)
- 测试集批量执行
- 参数化测试

### 变量提取
- JSONPath 提取
- 响应头提取
- 全局变量支持

### 定时任务
- Cron 表达式调度
- 循环间隔执行

## API 文档

启动后端后访问: http://localhost:8010/docs

## 默认配置

- 后端端口: 8010
- 前端端口: 5173
- 默认管理员: admin / admin123
- 默认项目 ID: 1

## 技术栈

### 后端
- FastAPI
- SQLAlchemy
- MySQL
- Pydantic

### 前端
- Vue 3
- Element Plus
- Axios
- Vite

## License

MIT
