FROM node:22

# Cài git (nhiều tool frontend cần) và dọn cache
RUN apt-get update && apt-get install -y git \
    && rm -rf /var/lib/apt/lists/*

# Set thư mục làm việc
WORKDIR /var/www/html

# Tạo user tpa với UID trùng máy host để file tạo ra không bị lệch quyền
ARG UID=1000
ARG GID=1000
RUN groupmod -g $GID node 2>/dev/null || true \
    && usermod -u $UID node 2>/dev/null || true

USER node

# Giữ container sống để exec tùy ý (npm install / npm run build / npm run dev)
CMD ["tail", "-f", "/dev/null"]
