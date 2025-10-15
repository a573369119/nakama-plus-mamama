# Nakama Plus 构建部署工具

Nakama Plus 是基于官方 Nakama 游戏服务器的扩展版本，增加了集群功能、微服务架构和增强的管理能力。

## 项目概述

Nakama Plus 在官方 Nakama 的基础上增加了以下核心功能：

- **集群支持**：多节点部署，自动节点发现和负载均衡
- **微服务架构**：支持服务间通信和分布式处理
- **增强监控**：集成了 Prometheus 指标收集
- **扩展配置**：支持更复杂的运行时配置

## 快速开始

### 前置要求

- Docker 和 Docker Compose
- Git
- Bash 环境（Linux/macOS/WSL）

### 一键部署

```bash
# 克隆项目（如果尚未克隆）
git clone <repository-url>
cd nakama-plus

# 执行完整部署
./deploy-cluster.sh all
```

### 分步部署

1. **构建镜像**
```bash
./deploy-cluster.sh build
```

2. **启动集群**
```bash
./deploy-cluster.sh cluster
```

3. **验证部署**
```bash
./test-cluster.sh full
```

## 文件结构

```
nakama-plus/
├── Dockerfile                    # 自定义构建镜像
├── docker-compose.yml           # 单节点部署配置
├── docker-compose-cluster.yml   # 多节点集群配置
├── cluster-config.yml           # 集群配置文件
├── build-nakama-plus.sh         # 构建脚本
├── deploy-cluster.sh            # 部署管理脚本
├── test-cluster.sh              # 功能测试脚本
└── README.md                    # 本文档
```

## 部署模式

### 单节点模式

适用于开发和测试环境：

```bash
./deploy-cluster.sh start
```

访问地址：
- Nakama HTTP API: http://localhost:7350
- Nakama GRPC: localhost:7349
- CockroachDB UI: http://localhost:8080

### 集群模式（推荐）

适用于生产环境，支持高可用：

```bash
./deploy-cluster.sh cluster
```

集群包含3个节点：
- nakama1: 主节点，负责数据库迁移
- nakama2: 工作节点
- nakama3: 工作节点

## 配置说明

### 集群配置

编辑 `cluster-config.yml` 文件调整集群参数：

```yaml
cluster:
  enable: true
  name: "nakama-cluster"
  gossip_bind_addr: "0.0.0.0:7350"
  port: 7351
  discovery:
    static:
      servers:
        - "nakama1:7351"
        - "nakama2:7351"
        - "nakama3:7351"
```

### 环境变量

可以通过环境变量覆盖配置：

```bash
export NAKAMA_CLUSTER_ENABLE=true
export NAKAMA_DATABASE_ADDRESS="root@cockroachdb:26257"
```

## 监控和日志

### 监控面板

- **Prometheus**: http://localhost:9090
- **Grafana**（可选）: 可配置为数据源

### 日志查看

查看特定服务日志：

```bash
# 查看 nakama1 日志
./deploy-cluster.sh logs nakama1

# 查看数据库日志
./deploy-cluster.sh logs cockroachdb

# 查看所有日志（实时）
./deploy-cluster.sh logs
```

## 故障排除

### 常见问题

1. **端口冲突**
   - 确保 7349、7350、7351、8080、9090 端口未被占用

2. **构建失败**
   - 检查网络连接，确保能访问 Docker Hub
   - 验证 Docker 守护进程运行状态

3. **集群节点无法发现**
   - 检查防火墙设置
   - 验证 `cluster-config.yml` 中的节点地址配置

### 健康检查

```bash
# 快速健康检查
./test-cluster.sh quick

# 完整功能测试
./test-cluster.sh full

# 检查服务状态
./deploy-cluster.sh status
```

## 管理命令

### 服务管理

```bash
# 启动服务
./deploy-cluster.sh start|cluster

# 停止服务
./deploy-cluster.sh stop

# 重启服务
./deploy-cluster.sh stop && ./deploy-cluster.sh cluster

# 清理所有资源
./deploy-cluster.sh clean
```

### 数据备份

```bash
# 备份数据库
docker exec -it nakama-plus_cockroachdb_1 cockroach dump nakama > backup.sql

# 恢复数据库
docker exec -i nakama-plus_cockroachdb_1 cockroach sql -e "CREATE DATABASE IF NOT EXISTS nakama;"
docker exec -i nakama-plus_cockroachdb_1 cockroach sql -d nakama < backup.sql
```

## 扩展开发

### 自定义模块

在 `data/modules/` 目录中添加 Lua 模块：

```lua
-- data/modules/example.lua
local nk = require("nakama")

local function my_rpc_function(context, payload)
    nk.logger_info("自定义 RPC 函数被调用")
    return { success = true, message = "Hello from custom module!" }
end

nk.register_rpc(my_rpc_function, "my_custom_function")
```

### API 扩展

通过 GRPC 或 HTTP 端点扩展功能：

```go
// 参考 internal/ 目录中的示例代码
```

## 性能优化

### 数据库优化

```sql
-- 在 CockroachDB 中创建索引
CREATE INDEX IF NOT EXISTS idx_users_username ON users (username);
CREATE INDEX IF NOT EXISTS idx_matches_create_time ON matches (create_time);
```

### 内存配置

调整 Docker 内存限制：

```yaml
# 在 docker-compose 文件中添加
deploy:
  resources:
    limits:
      memory: 2G
    reservations:
      memory: 1G
```

## 安全建议

1. **修改默认密码**
   - 控制台默认密码：admin/password
   - 生产环境务必修改

2. **网络隔离**
   - 使用 Docker 网络隔离服务
   - 配置防火墙规则

3. **TLS/SSL**
   - 生产环境启用 HTTPS
   - 配置证书和密钥

## 支持与贡献

### 问题报告

遇到问题时请提供：

1. 部署环境信息
2. 错误日志内容
3. 复现步骤

### 开发贡献

欢迎提交 Pull Request 和功能建议。

## 许可证

本项目基于 Nakama 开源项目，遵循相应的开源协议。

---

**注意**: 生产环境部署前请务必进行充分测试和安全性评估。