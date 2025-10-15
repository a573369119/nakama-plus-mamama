# Nakama Plus 集群测试部署脚本
param(
    [string]$Action = "help",
    [string]$NodeName = "node1",
    [int]$Port = 7350
)

function Show-Help {
    Write-Host "Nakama Plus 集群测试部署脚本" -ForegroundColor Green
    Write-Host "用法: .\deploy-test-cluster.ps1 [action] [参数]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "可用操作:" -ForegroundColor Cyan
    Write-Host "  help             显示此帮助信息"
    Write-Host "  test-single      测试单节点运行"
    Write-Host "  test-cluster     测试集群配置"
    Write-Host "  show-config      显示配置示例"
    Write-Host ""
    Write-Host "示例:" -ForegroundColor Magenta
    Write-Host "  .\deploy-test-cluster.ps1 test-single"
    Write-Host "  .\deploy-test-cluster.ps1 test-cluster -NodeName node1 -Port 7350"
}

function Test-SingleNode {
    Write-Host "[INFO] 测试单节点 Nakama Plus 运行..." -ForegroundColor Cyan
    
    # 创建测试数据目录
    $TestDataDir = ".\test-data\single"
    if (Test-Path $TestDataDir) {
        Remove-Item -Recurse -Force $TestDataDir
    }
    New-Item -ItemType Directory -Path $TestDataDir -Force
    
    Write-Host "[INFO] 启动单节点测试..." -ForegroundColor Yellow
    docker run --rm `
        --name nakama-plus-test `
        -p 7350:7350 `
        -p 7351:7351 `
        -v "${PWD}\test-data\single:/nakama/data" `
        nakama-plus:latest `
        --name "test-node" `
        --database.address "root@localhost:26257" `
        --logger.level "DEBUG"
}

function Test-ClusterConfig {
    param($NodeName, $Port)
    
    Write-Host "[INFO] 测试集群配置 - 节点: $NodeName, 端口: $Port" -ForegroundColor Cyan
    
    # 创建节点数据目录
    $NodeDataDir = ".\test-data\$NodeName"
    if (Test-Path $NodeDataDir) {
        Remove-Item -Recurse -Force $NodeDataDir
    }
    New-Item -ItemType Directory -Path $NodeDataDir -Force
    
    Write-Host "[INFO] 集群配置示例:" -ForegroundColor Yellow
    Write-Host "  docker run --rm \`" -ForegroundColor White
    Write-Host "    --name nakama-plus-$NodeName \`" -ForegroundColor White
    Write-Host "    -p ${Port}:7350 \`" -ForegroundColor White
    Write-Host "    -p $($Port+1):7351 \`" -ForegroundColor White
    Write-Host "    -v `"${PWD}\test-data\$NodeName:/nakama/data`" \`" -ForegroundColor White
    Write-Host "    nakama-plus:latest \`" -ForegroundColor White
    Write-Host "    --name `"$NodeName`" \`" -ForegroundColor White
    Write-Host "    --database.address `"root@localhost:26257`" \`" -ForegroundColor White
    Write-Host "    --cluster.enabled true \`" -ForegroundColor White
    Write-Host "    --cluster.name `"nakama-cluster`" \`" -ForegroundColor White
    Write-Host "    --cluster.etcd.endpoints `"http://etcd1:2379,http://etcd2:2379,http://etcd3:2379`" \`" -ForegroundColor White
    Write-Host "    --logger.level `"DEBUG`"" -ForegroundColor White
}

function Show-Config {
    Write-Host "[INFO] Nakama Plus 集群配置示例" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "基本配置:" -ForegroundColor Yellow
    Write-Host "  --name `"node-name`"                    # 节点名称"
    Write-Host "  --database.address `"root@localhost:26257`"  # 数据库地址"
    Write-Host ""
    Write-Host "集群配置:" -ForegroundColor Green
    Write-Host "  --cluster.enabled true                 # 启用集群"
    Write-Host "  --cluster.name `"cluster-name`"         # 集群名称"
    Write-Host "  --cluster.etcd.endpoints `"http://etcd1:2379,...`"  # etcd端点"
    Write-Host "  --cluster.broadcast.host `"node-ip`"     # 广播主机"
    Write-Host "  --cluster.broadcast.port 7333          # 广播端口"
    Write-Host ""
    Write-Host "日志配置:" -ForegroundColor Magenta
    Write-Host "  --logger.level DEBUG                   # 日志级别"
    Write-Host "  --logger.format json                   # 日志格式"
}

# 主执行逻辑
switch ($Action.ToLower()) {
    "help" { Show-Help }
    "test-single" { Test-SingleNode }
    "test-cluster" { Test-ClusterConfig -NodeName $NodeName -Port $Port }
    "show-config" { Show-Config }
    default { Show-Help }
}