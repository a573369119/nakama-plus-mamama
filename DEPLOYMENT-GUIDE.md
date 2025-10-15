# Nakama Plus Docker 容器化部署指南

## 概述

本指南介绍如何使用Docker容器化部署Nakama Plus游戏服务器，支持单节点和集群模式。

## 快速开始

### 1. 单节点部署（推荐开发环境）

```bash
# 构建镜像并启动单节点
.\deploy-cluster.ps1 build
docker-compose -f docker-compose-single.yml up -d

# 查看服务状态
docker-compose -f docker-compose-single.yml ps

# 查看日志
docker-compose -f docker-compose-single.yml logs nakama

# 访问监控面板
# Prometheus: http://localhost:9090
# CockroachDB UI: http://localhost:8080
```

### 2. 集群部署（生产环境）

```bash
# 构建镜像
.\deploy-cluster.ps1 build

# 启动完整集群
docker-compose up -d

# 查看所有服务状态
docker-compose ps

# 查看集群节点日志
docker-compose logs nakama-node1
docker-compose logs nakama-node2
docker-compose logs nakama-node3
```

## 服务端口映射

### 单节点模式
- **Nakama REST API**: 7350
- **Nakama gRPC**: 7349
- **CockroachDB**: 26257
- **CockroachDB UI**: 8080

### 集群模式
- **节点1**: 7350 (REST), 7349 (gRPC)
- **节点2**: 7352 (REST), 7353 (gRPC)  
- **节点3**: 7354 (REST), 7355 (gRPC)
- **Nginx负载均衡**: 80
- **Prometheus监控**: 9090
- **etcd集群**: 2379, 2380

## 配置文件说明

### 1. Dockerfile
- 构建包含集群功能的Nakama Plus镜像
- 使用静态编译解决依赖问题
- 基于Alpine Linux，镜像体积小

### 2. docker-compose.yml
完整集群配置包含：
- **etcd**: 集群发现服务
- **cockroachdb**: 分布式数据库
- **nakama-node1/2/3**: 3个Nakama节点
- **nginx**: 负载均衡器
- **prometheus**: 监控系统

### 3. docker-compose-single.yml
简化单节点配置，适合开发和测试。

## 集群功能验证

### 检查集群状态
```bash
# 进入任意节点容器
docker exec -it nakama-plus_nakama-node1_1 /bin/sh

# 检查集群成员
/nakama/nakama-plus --cluster.etcd.endpoints http://etcd:2379 cluster members
```

### 监控指标
访问 http://localhost:9090 查看Prometheus监控面板。

## 生产环境配置

### 1. 安全配置
修改默认的安全参数：
```yaml
--session.encryption_key "your-secure-key"
--console.password "secure-password"
--socket.server_key "secure-server-key"
```

### 2. 持久化存储
确保数据卷正确挂载：
```yaml
volumes:
  - /path/to/nakama/data:/nakama/data
  - /path/to/cockroach/data:/var/lib/cockroach
```

### 3. 资源限制
为生产环境设置资源限制：
```yaml
deploy:
  resources:
    limits:
      memory: 2G
      cpus: '1.0'
```

## 故障排除

### 常见问题

1. **数据库连接失败**
   - 检查CockroachDB服务状态
   - 验证数据库连接字符串

2. **集群节点无法发现**
   - 检查etcd服务是否正常运行
   - 验证集群配置参数

3. **镜像构建失败**
   - 确保网络连接正常
   - 检查Docker守护进程状态

### 日志查看
```bash
# 查看所有服务日志
docker-compose logs

# 查看特定服务日志
docker-compose logs nakama-node1

# 实时查看日志
docker-compose logs -f nakama-node1
```

## 扩展部署

### 添加更多节点
在docker-compose.yml中添加新的节点配置：
```yaml
nakama-node4:
  image: nakama-plus:latest
  # ... 类似其他节点的配置
  ports:
    - "7356:7350"
    - "7357:7351"
```

### 自定义配置
创建自定义配置文件：
```yaml
# config.yml
name: nakama-custom
database:
  address: "root@cockroachdb:26257"
cluster:
  enabled: true
  name: "nakama-cluster"
  etcd:
    endpoints: ["http://etcd:2379"]
```

## 性能优化建议

1. **数据库优化**: 调整CockroachDB缓存大小
2. **集群缓存**: 优化集群缓存配置
3. **负载均衡**: 配置Nginx负载均衡策略
4. **监控告警**: 设置Prometheus告警规则

## 备份与恢复

### 数据库备份
```bash
# 备份CockroachDB
docker exec cockroachdb cockroach dump nakama > backup.sql

# 恢复数据库
docker exec -i cockroachdb cockroach sql < backup.sql
```

### 配置文件备份
确保重要的配置文件有版本控制备份。

---

通过本指南，你可以轻松地在Docker环境中部署和管理Nakama Plus游戏服务器集群。