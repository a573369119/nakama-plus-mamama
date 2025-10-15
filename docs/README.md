# Nakama-plus 项目文档

## 项目概述

Nakama-plus 是基于官方 Nakama 游戏服务器的增强版本，添加了集群功能、微服务架构和扩展功能。

## 文档结构

- 📁 **01-项目结构** - 项目目录结构和文件说明
- 📁 **02-架构设计** - 系统架构和运作模式
- 📁 **03-开发指南** - 开发环境和构建方法
- 📁 **04-部署指南** - 单节点和集群部署
- 📁 **05-配置说明** - 配置文件详解
- 📁 **06-监控运维** - 监控和运维指南
- 📁 **07-插件开发** - 插件开发指南
- 📁 **08-故障排查** - 常见问题解决

## 快速开始

### 环境要求
- Docker & Docker Compose
- Go 1.25+ (仅开发需要)
- Git

### 快速部署
```bash
# 单节点部署（开发环境）
docker-compose -f docker-compose-single.yml up -d

# 集群部署（生产环境）
docker-compose -f docker-compose-cluster.yml up -d
```

## 访问地址

- **Nakama控制台**: http://localhost:7351
- **CockroachDB管理**: http://localhost:8080
- **Prometheus监控**: http://localhost:9090

## 支持与反馈

如有问题请查看详细文档或提交Issue。