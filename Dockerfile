FROM golang:latest AS builder

# 设置构建环境
ENV GO111MODULE=on
ENV CGO_ENABLED=1
ENV GOPROXY=https://goproxy.cn,direct

WORKDIR /workspace

# 复制源代码和依赖
COPY . .

# 构建完整的nakama-plus二进制文件（不是插件！）
RUN CGO_ENABLED=0 go build -trimpath -mod=vendor -a -ldflags '-extldflags "-static"' -o /nakama-plus

# 运行时镜像
FROM alpine:latest

# 安装运行时依赖
RUN apk add --no-cache ca-certificates

# 创建运行用户和目录
RUN addgroup -S nakama && adduser -S nakama -G nakama
RUN mkdir -p /nakama/data/modules && chown -R nakama:nakama /nakama

# 复制构建结果
COPY --from=builder --chown=nakama:nakama /nakama-plus /nakama/
COPY --from=builder --chown=nakama:nakama /workspace/config.sample.yml /nakama/data/

# 切换到运行用户
USER nakama
WORKDIR /nakama

# 暴露端口：7349(GRPC), 7350(HTTP), 7351(Console), 7335(Cluster)
EXPOSE 7349 7350 7351 7335

ENTRYPOINT ["/nakama/nakama-plus"]