# 阶段 1：基础镜像，安装基础依赖
FROM node:18-alpine AS base

# 设置清华大学的 Alpine 镜像源并安装基础依赖
RUN echo "http://mirrors.tuna.tsinghua.edu.cn/alpine/latest-stable/main" > /etc/apk/repositories && \
    echo "http://mirrors.tuna.tsinghua.edu.cn/alpine/latest-stable/community" >> /etc/apk/repositories && \
    apk update && apk add --no-cache git

# 设置工作目录
WORKDIR /app

# 拷贝 package.json 和 yarn.lock 以便利用缓存
COPY package.json yarn.lock ./

# 使用国内源加速依赖安装
RUN yarn config set registry 'https://registry.npmmirror.com/' && yarn install

# 阶段 2：构建阶段
FROM base AS builder

WORKDIR /app

# 复制项目文件并构建
COPY . .
RUN yarn build

# 阶段 3：运行时环境
FROM node:18-alpine AS runner

WORKDIR /app

# 设置环境变量
ENV PROXY_URL=""
ENV OPENAI_API_KEY=""
ENV GOOGLE_API_KEY=""
ENV CODE=""

# 复制构建产物
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next ./.next

# 暴露端口
EXPOSE 3000

# 启动应用
CMD ["node", "server.js"]
