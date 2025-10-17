# 第一阶段：自己搭建编译环境（替代官方 nakama-pluginbuilder）
# 选择与 v1.42.0 nakama-common 兼容的 Go 版本（v1.21+，这里用 1.21-bookworm 稳定版）
FROM golang:1.22-bookworm AS builder

# 1. 设置编译必需的环境变量
# 启用模块模式（必须）
ENV GO111MODULE=on        
 # 启用 CGO（插件依赖，必须）
ENV CGO_ENABLED=1          
 # 国内加速依赖下载（可选，避免网络超时）
ENV GOPROXY=https://goproxy.cn,direct
# 关闭 Debian 交互提示（避免安装依赖卡住）
ENV DEBIAN_FRONTEND=noninteractive  

# 2. 安装编译必需的系统依赖（官方 builder 镜像里也包含这些）
# gcc/libc6-dev：CGO 编译需要的 C 编译器和库
# ca-certificates：确保能通过 HTTPS 拉取依赖（如 GitHub）
# git：拉取 Git 仓库依赖（如 nakama-common）
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get install -y --no-install-recommends gcc libc6-dev ca-certificates git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*  # 清理缓存，减小镜像体积

# 3. 设置编译工作目录
WORKDIR /backend

# 4. 复制你的插件源代码（包括 .go 文件、go.mod、go.sum 等）
COPY . .

# 5. 关键：安装指定版本的 nakama-common 依赖（按作者要求的 v1.42.0）
# 这一步会把依赖下载到容器，并更新 go.mod/go.sum
RUN go get "github.com/heroiclabs/nakama-common/runtime@v1.42.0"

# 6. 编译插件（输出为 backend.so，或你的插件名如 nakama-plus.so）
RUN go build --trimpath --buildmode=plugin -o ./backend.so


# 第二阶段：运行阶段（必须用与 v1.42.0 nakama-common 匹配的 Nakama 镜像！）
# 关键：v1.42.0 nakama-common 对应的 Nakama 服务器版本是 3.36.0（版本必须匹配，否则插件加载失败）
FROM nakama-plus:3.30.0

# 复制编译好的插件到 Nakama 插件目录（默认 /nakama/data/modules）
COPY --from=builder /backend/backend.so /nakama/data/modules/

# 复制你的自定义配置文件（如果插件需要，如 local.yml）
COPY --from=builder /backend/local.yml /nakama/data/

# 复制插件依赖的 JSON 数据文件（如果有）
COPY --from=builder /backend/*.json /nakama/data/modules/