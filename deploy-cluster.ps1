# Nakama Plus 集群部署脚本 (PowerShell版本)
param(
    [string]$Command = "help"
)

# 颜色定义
$ErrorActionPreference = "Stop"

# 日志函数
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# 显示帮助信息
function Show-Help {
    Write-Host "Nakama Plus 集群部署脚本 (PowerShell版本)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "用法: .\deploy-cluster.ps1 [命令]"
    Write-Host ""
    Write-Host "命令:"
    Write-Host "  build          构建 Nakama Plus Docker 镜像"
    Write-Host "  start          启动单节点 Nakama Plus 服务"
    Write-Host "  cluster        启动 Nakama Plus 集群（3节点）"
    Write-Host "  stop           停止所有服务"
    Write-Host "  clean          清理所有容器和镜像"
    Write-Host "  status         查看服务状态"
    Write-Host "  logs [服务名]  查看服务日志"
    Write-Host "  health         检查集群健康状态"
    Write-Host "  all            执行完整部署流程（构建 + 启动集群）"
    Write-Host ""
    Write-Host "示例:"
    Write-Host "  .\deploy-cluster.ps1 build        # 构建镜像"
    Write-Host "  .\deploy-cluster.ps1 cluster      # 启动集群"
    Write-Host "  .\deploy-cluster.ps1 all          # 完整部署"
}

# 检查 Docker 是否可用
function Check-Docker {
    Write-Info "检查 Docker 环境..."
    
    if (-not (Get-Command "docker" -ErrorAction SilentlyContinue)) {
        throw "Docker 未安装或未在 PATH 中"
    }
    
    try {
        docker info | Out-Null
        Write-Success "Docker 检查通过"
    } catch {
        throw "Docker 守护进程未运行"
    }
}

# 检查 Docker Compose 是否可用
function Check-DockerCompose {
    Write-Info "检查 Docker Compose 环境..."
    
    $composeCmd = $null
    if (Get-Command "docker-compose" -ErrorAction SilentlyContinue) {
        $script:ComposeCmd = "docker-compose"
    } elseif (docker compose version 2>$null) {
        $script:ComposeCmd = "docker compose"
    } else {
        throw "Docker Compose 未安装"
    }
    
    Write-Success "Docker Compose 检查通过 ($ComposeCmd)"
}

# 构建 Nakama Plus 镜像
function Build-Image {
    Write-Info "开始构建 Nakama Plus Docker 镜像..."
    
    # 检查 Dockerfile 是否存在
    if (-not (Test-Path "Dockerfile")) {
        throw "Dockerfile 不存在"
    }
    
    # 构建镜像
    docker build -t nakama-plus:latest .
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Nakama Plus 镜像构建成功"
    } else {
        throw "镜像构建失败"
    }
}

# 启动单节点服务
function Start-SingleNode {
    Write-Info "启动单节点 Nakama Plus 服务..."
    
    & $ComposeCmd -f docker-compose.yml up -d
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "单节点服务启动成功"
        Show-ServiceInfo "single"
    } else {
        throw "服务启动失败"
    }
}

# 启动集群
function Start-Cluster {
    Write-Info "启动 Nakama Plus 集群（3节点）..."
    
    # 创建数据目录
    if (-not (Test-Path "data/modules")) {
        New-Item -ItemType Directory -Path "data/modules" -Force | Out-Null
    }
    
    & $ComposeCmd -f docker-compose-cluster.yml up -d
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "集群启动成功"
        Show-ServiceInfo "cluster"
    } else {
        throw "集群启动失败"
    }
}

# 停止所有服务
function Stop-Services {
    Write-Info "停止所有服务..."
    
    # 停止单节点服务
    if (Test-Path "docker-compose.yml") {
        & $ComposeCmd -f docker-compose.yml down
    }
    
    # 停止集群服务
    if (Test-Path "docker-compose-cluster.yml") {
        & $ComposeCmd -f docker-compose-cluster.yml down
    }
    
    Write-Success "所有服务已停止"
}

# 清理容器和镜像
function Cleanup {
    Write-Info "开始清理..."
    
    # 停止服务
    Stop-Services
    
    # 删除镜像
    try {
        docker rmi nakama-plus:latest 2>$null
    } catch {
        # 忽略删除错误
    }
    
    # 清理未使用的容器、网络、镜像
    docker system prune -f
    
    Write-Success "清理完成"
}

# 查看服务状态
function Check-Status {
    Write-Info "服务状态:"
    
    Write-Host "`n=== 单节点服务状态 ===" -ForegroundColor Cyan
    if (Test-Path "docker-compose.yml") {
        & $ComposeCmd -f docker-compose.yml ps
    } else {
        Write-Host "docker-compose.yml 不存在"
    }
    
    Write-Host "`n=== 集群服务状态 ===" -ForegroundColor Cyan
    if (Test-Path "docker-compose-cluster.yml") {
        & $ComposeCmd -f docker-compose-cluster.yml ps
    } else {
        Write-Host "docker-compose-cluster.yml 不存在"
    }
    
    Write-Host "`n=== Docker 镜像 ===" -ForegroundColor Cyan
    docker images | Select-String "nakama-plus"
}

# 查看服务日志
function View-Logs {
    param([string]$Service)
    
    if (-not $Service) {
        throw "请指定服务名"
    }
    
    # 检查是单节点还是集群模式
    try {
        & $ComposeCmd -f docker-compose-cluster.yml ps $Service 2>$null | Out-Null
        & $ComposeCmd -f docker-compose-cluster.yml logs -f $Service
    } catch {
        try {
            & $ComposeCmd -f docker-compose.yml ps $Service 2>$null | Out-Null
            & $ComposeCmd -f docker-compose.yml logs -f $Service
        } catch {
            throw "服务 '$Service' 不存在或未运行"
        }
    }
}

# 检查集群健康状态
function Check-Health {
    Write-Info "检查集群健康状态..."
    
    # 检查 nakama1 健康状态
    try {
        Invoke-WebRequest -Uri "http://localhost:7350/healthcheck" -UseBasicParsing | Out-Null
        Write-Success "Nakama 节点1 健康检查通过"
    } catch {
        Write-Error "Nakama 节点1 健康检查失败"
    }
    
    # 检查集群状态（需要等待集群稳定）
    Start-Sleep -Seconds 10
    
    Write-Info "集群状态信息:"
    Write-Host "访问 http://localhost:7350 查看 Nakama 控制台" -ForegroundColor Yellow
    Write-Host "访问 http://localhost:9090 查看 Prometheus 监控" -ForegroundColor Yellow
    Write-Host "访问 http://localhost:8080 查看 CockroachDB 管理界面" -ForegroundColor Yellow
}

# 显示服务信息
function Show-ServiceInfo {
    param([string]$Mode)
    
    Write-Host "`n=== Nakama Plus 服务信息 ===" -ForegroundColor Green
    Write-Host "模式: $Mode" -ForegroundColor White
    Write-Host ""
    Write-Host "访问地址:" -ForegroundColor Yellow
    Write-Host "  - Nakama GRPC: localhost:7349" -ForegroundColor Gray
    Write-Host "  - Nakama HTTP: localhost:7350" -ForegroundColor Gray
    Write-Host "  - Nakama 集群: localhost:7351" -ForegroundColor Gray
    Write-Host "  - Prometheus: localhost:9090" -ForegroundColor Gray
    Write-Host "  - CockroachDB: localhost:8080" -ForegroundColor Gray
    Write-Host ""
    Write-Host "控制台:" -ForegroundColor Yellow
    Write-Host "  - 地址: http://localhost:7351" -ForegroundColor Gray
    Write-Host "  - 用户名: admin" -ForegroundColor Gray
    Write-Host "  - 密码: password" -ForegroundColor Gray
    Write-Host ""
    Write-Host "使用 '.\deploy-cluster.ps1 status' 查看服务状态" -ForegroundColor Cyan
    Write-Host "使用 '.\deploy-cluster.ps1 logs [服务名]' 查看日志" -ForegroundColor Cyan
}

# 完整部署流程
function Deploy-All {
    Write-Info "开始完整部署流程..."
    
    Check-Docker
    Check-DockerCompose
    Build-Image
    Start-Cluster
    Check-Health
    
    Write-Success "完整部署完成"
}

# 主函数
function Main {
    switch ($Command.ToLower()) {
        "build" {
            Check-Docker
            Build-Image
        }
        "start" {
            Check-Docker
            Check-DockerCompose
            Start-SingleNode
        }
        "cluster" {
            Check-Docker
            Check-DockerCompose
            Start-Cluster
        }
        "stop" {
            Stop-Services
        }
        "clean" {
            Cleanup
        }
        "status" {
            Check-Status
        }
        "logs" {
            if ($args.Count -eq 0) {
                throw "请指定服务名"
            }
            View-Logs -Service $args[0]
        }
        "health" {
            Check-Health
        }
        "all" {
            Deploy-All
        }
        { @("help", "") -contains $_ } {
            Show-Help
        }
        default {
            Write-Error "未知命令: $Command"
            Show-Help
            exit 1
        }
    }
}

# 脚本入口
try {
    Main
} catch {
    Write-Error $_.Exception.Message
    exit 1
}