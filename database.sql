-- AI-TestHub 数据库初始化脚本
-- 创建所有表结构

-- 用户表
CREATE TABLE IF NOT EXISTS `users` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `username` VARCHAR(50) NOT NULL UNIQUE,
    `email` VARCHAR(100) NOT NULL UNIQUE,
    `hashed_password` VARCHAR(255) NOT NULL,
    `full_name` VARCHAR(100),
    `is_active` BOOLEAN DEFAULT TRUE,
    `is_superuser` BOOLEAN DEFAULT FALSE,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `last_login` DATETIME
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 项目表
CREATE TABLE IF NOT EXISTS `projects` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `project_code` VARCHAR(50) NOT NULL UNIQUE,
    `project_name` VARCHAR(100) NOT NULL,
    `description` VARCHAR(500),
    `git_url` VARCHAR(255),
    `jenkins_job` VARCHAR(100),
    `owner` VARCHAR(50),
    `owner_id` INT NOT NULL,
    `is_active` BOOLEAN DEFAULT TRUE,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`owner_id`) REFERENCES `users`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 功能模块表
CREATE TABLE IF NOT EXISTS `modules` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `project_id` INT NOT NULL,
    `module_code` VARCHAR(50) NOT NULL,
    `module_name` VARCHAR(100) NOT NULL,
    `parent_id` INT DEFAULT 0,
    `level` INT DEFAULT 1,
    `sort_order` INT DEFAULT 0,
    `is_active` BOOLEAN DEFAULT TRUE,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`project_id`) REFERENCES `projects`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 接口集合表
CREATE TABLE IF NOT EXISTS `interface_collections` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `project_id` INT NOT NULL,
    `module_id` INT,
    `name` VARCHAR(200) NOT NULL,
    `description` TEXT,
    `sort_order` INT DEFAULT 0,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`project_id`) REFERENCES `projects`(`id`),
    FOREIGN KEY (`module_id`) REFERENCES `modules`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 接口定义表
CREATE TABLE IF NOT EXISTS `interfaces` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `project_id` INT NOT NULL,
    `module_id` INT,
    `collection_id` INT,
    `name` VARCHAR(200),
    `api_code` VARCHAR(100),
    `api_name` VARCHAR(200),
    `method` VARCHAR(10),
    `url` VARCHAR(500),
    `path` VARCHAR(500),
    `protocol` VARCHAR(10) DEFAULT 'http',
    `content_type` VARCHAR(50) DEFAULT 'application/json',
    `description` TEXT,
    `request_example` TEXT,
    `response_example` TEXT,
    `is_deprecated` BOOLEAN DEFAULT FALSE,
    `is_active` BOOLEAN DEFAULT TRUE,
    `is_favorite` BOOLEAN DEFAULT FALSE,
    `headers` JSON,
    `params` JSON,
    `body` JSON,
    `body_type` VARCHAR(20) DEFAULT 'json',
    `var_extracts` JSON,
    `assertions` JSON,
    `last_status_code` INT,
    `priority` VARCHAR(10),
    `last_response_time` INT,
    `last_response_body` TEXT,
    `last_executed_at` DATETIME,
    `created_by` VARCHAR(50),
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`project_id`) REFERENCES `projects`(`id`),
    FOREIGN KEY (`module_id`) REFERENCES `modules`(`id`),
    FOREIGN KEY (`collection_id`) REFERENCES `interface_collections`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 测试用例表
CREATE TABLE IF NOT EXISTS `test_cases` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `project_id` INT NOT NULL,
    `module_id` INT,
    `interface_id` INT,
    `case_code` VARCHAR(100),
    `case_title` VARCHAR(200) NOT NULL,
    `case_type` VARCHAR(20) DEFAULT 'single',
    `priority` VARCHAR(10) DEFAULT 'P1',
    `status` VARCHAR(20) DEFAULT 'draft',
    `request_config` TEXT,
    `data_source` VARCHAR(20),
    `data_file` VARCHAR(255),
    `data_sheet` VARCHAR(50),
    `setup_script` TEXT,
    `teardown_script` TEXT,
    `assertions` TEXT,
    `description` TEXT,
    `tags` VARCHAR(200),
    `is_smoke` BOOLEAN DEFAULT FALSE,
    `is_ci` BOOLEAN DEFAULT TRUE,
    `timeout` INT DEFAULT 30,
    `retry_times` INT DEFAULT 0,
    `created_by` VARCHAR(50),
    `updated_by` VARCHAR(50),
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`project_id`) REFERENCES `projects`(`id`),
    FOREIGN KEY (`module_id`) REFERENCES `modules`(`id`),
    FOREIGN KEY (`interface_id`) REFERENCES `interfaces`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 测试结果表
CREATE TABLE IF NOT EXISTS `test_results` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `case_id` INT NOT NULL,
    `status` VARCHAR(20) NOT NULL,
    `response` JSON,
    `error_message` VARCHAR(1000),
    `duration_ms` INT,
    `executed_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`case_id`) REFERENCES `test_cases`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 测试用例依赖关系表
CREATE TABLE IF NOT EXISTS `test_case_dependencies` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `case_id` INT NOT NULL,
    `depend_case_id` INT NOT NULL,
    `depend_type` VARCHAR(20) DEFAULT 'hard',
    `extract_vars` TEXT,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`case_id`) REFERENCES `test_cases`(`id`),
    FOREIGN KEY (`depend_case_id`) REFERENCES `test_cases`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 测试用例参数变量表
CREATE TABLE IF NOT EXISTS `test_case_params` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `case_id` INT NOT NULL,
    `param_name` VARCHAR(50) NOT NULL,
    `param_value` TEXT,
    `param_type` VARCHAR(20) DEFAULT 'string',
    `is_dynamic` BOOLEAN DEFAULT FALSE,
    `faker_rule` VARCHAR(100),
    `description` VARCHAR(200),
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`case_id`) REFERENCES `test_cases`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 测试执行批次表
CREATE TABLE IF NOT EXISTS `test_executions` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `execution_no` VARCHAR(50) NOT NULL,
    `project_id` INT NOT NULL,
    `env_id` INT NOT NULL,
    `trigger_type` VARCHAR(20),
    `trigger_by` VARCHAR(50),
    `build_no` VARCHAR(50),
    `git_branch` VARCHAR(50),
    `git_commit` VARCHAR(100),
    `case_filter` TEXT,
    `parallel_num` INT DEFAULT 1,
    `timeout_total` INT DEFAULT 3600,
    `total_cases` INT DEFAULT 0,
    `passed_cases` INT DEFAULT 0,
    `failed_cases` INT DEFAULT 0,
    `skipped_cases` INT DEFAULT 0,
    `error_cases` INT DEFAULT 0,
    `pass_rate` DECIMAL(5,2),
    `start_time` DATETIME,
    `end_time` DATETIME,
    `duration_sec` INT,
    `allure_report_url` VARCHAR(500),
    `log_archive_url` VARCHAR(500),
    `status` VARCHAR(20) DEFAULT 'running',
    `result_summary` TEXT,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`project_id`) REFERENCES `projects`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 执行详情表
CREATE TABLE IF NOT EXISTS `test_execution_details` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `execution_id` INT NOT NULL,
    `case_id` INT NOT NULL,
    `status` VARCHAR(20),
    `duration_ms` INT,
    `retry_count` INT DEFAULT 0,
    `request_url` TEXT,
    `request_method` VARCHAR(10),
    `request_headers` TEXT,
    `request_body` TEXT,
    `response_status` INT,
    `response_headers` TEXT,
    `response_body` TEXT,
    `response_time_ms` INT,
    `assertion_results` TEXT,
    `error_type` VARCHAR(50),
    `error_message` TEXT,
    `error_traceback` TEXT,
    `screenshot_url` VARCHAR(500),
    `execution_log` TEXT,
    `attachments` TEXT,
    `start_time` DATETIME,
    `end_time` DATETIME,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`execution_id`) REFERENCES `test_executions`(`id`),
    FOREIGN KEY (`case_id`) REFERENCES `test_cases`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 测试数据池
CREATE TABLE IF NOT EXISTS `test_data_pool` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `project_id` INT NOT NULL,
    `data_type` VARCHAR(20) NOT NULL,
    `data_key` VARCHAR(100) NOT NULL,
    `data_value` JSON NOT NULL,
    `status` VARCHAR(20) DEFAULT 'available',
    `locked_by` VARCHAR(50),
    `locked_at` DATETIME,
    `expire_at` DATETIME,
    `usage_count` INT DEFAULT 0,
    `max_usage` INT DEFAULT 1,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`project_id`) REFERENCES `projects`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 系统配置表
CREATE TABLE IF NOT EXISTS `system_configs` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `config_key` VARCHAR(100) NOT NULL,
    `config_value` TEXT,
    `config_type` VARCHAR(20) DEFAULT 'string',
    `description` VARCHAR(500),
    `is_encrypted` BOOLEAN DEFAULT FALSE,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 插件表
CREATE TABLE IF NOT EXISTS `plugins` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `name` VARCHAR(100) NOT NULL,
    `description` VARCHAR(500),
    `version` VARCHAR(20),
    `config` JSON,
    `is_enabled` BOOLEAN DEFAULT TRUE,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 环境配置表
CREATE TABLE IF NOT EXISTS `environments` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `project_id` INT NOT NULL,
    `env_code` VARCHAR(20) NOT NULL,
    `env_name` VARCHAR(50) NOT NULL,
    `base_url` VARCHAR(255) NOT NULL,
    `frontend_lang` VARCHAR(20),
    `frontend_ver` VARCHAR(20),
    `backend_lang` VARCHAR(20),
    `backend_ver` VARCHAR(20),
    `description` VARCHAR(200),
    `variables` JSON,
    `headers` JSON,
    `is_active` BOOLEAN DEFAULT FALSE,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`project_id`) REFERENCES `projects`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 环境数据库配置表
CREATE TABLE IF NOT EXISTS `env_databases` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `env_id` INT NOT NULL,
    `db_type` VARCHAR(20) NOT NULL,
    `db_name` VARCHAR(50) NOT NULL,
    `host` VARCHAR(100) NOT NULL,
    `port` INT NOT NULL,
    `database_name` VARCHAR(50) NOT NULL,
    `username` VARCHAR(50) NOT NULL,
    `password` VARCHAR(255) NOT NULL,
    `pool_size` INT DEFAULT 10,
    `is_active` BOOLEAN DEFAULT TRUE,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`env_id`) REFERENCES `environments`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 环境Redis配置表
CREATE TABLE IF NOT EXISTS `env_redis` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `env_id` INT NOT NULL,
    `redis_name` VARCHAR(50) NOT NULL,
    `mode` VARCHAR(20) DEFAULT 'standalone',
    `host` VARCHAR(100) NOT NULL,
    `port` INT DEFAULT 6379,
    `password` VARCHAR(255),
    `db_index` INT DEFAULT 0,
    `sentinel_master` VARCHAR(50),
    `cluster_nodes` TEXT,
    `is_active` BOOLEAN DEFAULT TRUE,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`env_id`) REFERENCES `environments`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 环境变量表
CREATE TABLE IF NOT EXISTS `env_variables` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `project_id` INT NOT NULL,
    `env_name` VARCHAR(100) NOT NULL,
    `var_key` VARCHAR(100) NOT NULL,
    `var_value` TEXT,
    `description` VARCHAR(255),
    `is_secret` BOOLEAN DEFAULT FALSE,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`project_id`) REFERENCES `projects`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 接口链表
CREATE TABLE IF NOT EXISTS `interface_chains` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `project_id` INT NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `description` VARCHAR(500),
    `steps` JSON NOT NULL,
    `global_vars` JSON,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`project_id`) REFERENCES `projects`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 数据源表
CREATE TABLE IF NOT EXISTS `data_sources` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `project_id` INT NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `source_type` VARCHAR(20) NOT NULL,
    `file_path` VARCHAR(500),
    `data` JSON,
    `description` VARCHAR(500),
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`project_id`) REFERENCES `projects`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 定时任务表
CREATE TABLE IF NOT EXISTS `schedule_tasks` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `project_id` INT NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `description` VARCHAR(500),
    `cron_expression` VARCHAR(100),
    `interval_minutes` INT,
    `task_type` VARCHAR(20) NOT NULL,
    `target_id` INT NOT NULL,
    `is_enabled` BOOLEAN DEFAULT TRUE,
    `last_run_at` DATETIME,
    `next_run_at` DATETIME,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`project_id`) REFERENCES `projects`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 定时任务执行记录表
CREATE TABLE IF NOT EXISTS `schedule_runs` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `task_id` INT NOT NULL,
    `status` VARCHAR(20) NOT NULL,
    `result` JSON,
    `error_message` VARCHAR(1000),
    `duration_ms` INT,
    `started_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `finished_at` DATETIME,
    FOREIGN KEY (`task_id`) REFERENCES `schedule_tasks`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 测试集表
CREATE TABLE IF NOT EXISTS `test_suites` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `project_id` INT NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `description` VARCHAR(500),
    `module_id` INT,
    `environment` JSON,
    `created_by` VARCHAR(50),
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`project_id`) REFERENCES `projects`(`id`),
    FOREIGN KEY (`module_id`) REFERENCES `modules`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 测试集项目表（接口）
CREATE TABLE IF NOT EXISTS `test_suite_items` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `suite_id` INT NOT NULL,
    `interface_id` INT,
    `name` VARCHAR(200),
    `method` VARCHAR(10),
    `url` VARCHAR(500),
    `headers` JSON,
    `params` JSON,
    `body` JSON,
    `body_type` VARCHAR(20) DEFAULT 'json',
    `var_extracts` JSON,
    `assertions` JSON,
    `order_index` INT DEFAULT 0,
    `enabled` BOOLEAN DEFAULT TRUE,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`suite_id`) REFERENCES `test_suites`(`id`),
    FOREIGN KEY (`interface_id`) REFERENCES `interfaces`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 测试集结果表
CREATE TABLE IF NOT EXISTS `test_suite_results` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `suite_id` INT NOT NULL,
    `status` VARCHAR(20) NOT NULL,
    `total_count` INT DEFAULT 0,
    `success_count` INT DEFAULT 0,
    `fail_count` INT DEFAULT 0,
    `duration_ms` INT,
    `details` JSON,
    `environment` JSON,
    `started_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `finished_at` DATETIME,
    FOREIGN KEY (`suite_id`) REFERENCES `test_suites`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 初始化默认用户 (密码: admin123)
INSERT INTO `users` (`username`, `email`, `hashed_password`, `full_name`, `is_superuser`) VALUES
('admin', 'admin@example.com', '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9', 'Administrator', TRUE);

-- 初始化默认项目
INSERT INTO `projects` (`project_code`, `project_name`, `description`, `owner_id`) VALUES
('default', '默认项目', '默认测试项目', 1);

-- 初始化默认模块
INSERT INTO `modules` (`project_id`, `module_code`, `module_name`) VALUES
(1, 'default', '默认模块');
