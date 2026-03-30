#!/bin/bash

# Cấu hình đường dẫn gốc
GLOBAL_PATH="$(pwd)/docker-system"
PROJECTS_ROOT="$(pwd)/projects"

echo "=== Hệ thống khởi tạo dự án con (Docker Global) ==="

# 1. Nhập tên dự án
read -p "Nhập tên dự án (ví dụ: project-a): " PROJECT_NAME
PROJECT_DIR="$PROJECTS_ROOT/$PROJECT_NAME"

# 2. Chọn phiên bản PHP
echo "Chọn phiên bản PHP:"
PHP_VERSIONS=($(ls $GLOBAL_PATH/php))
select PHP_VER in "${PHP_VERSIONS[@]}"; do
    if [ -n "$PHP_VER" ]; then
        echo "Bạn đã chọn $PHP_VER"
        break
    else
        echo "Lựa chọn không hợp lệ."
    fi
done

# 3. Nhập đường dẫn Source code
read -p "Nhập đường dẫn tuyệt đối đến thư mục Source (index.php): " SOURCE_PATH

# 4. Tùy chọn tiện ích mở rộng (Extensions)
EXTENSIONS_DIR="$GLOBAL_PATH/extensions"
COMPOSE_FILES="docker-compose.yml"
SELECTED_EXTENSIONS=()

if [ -d "$EXTENSIONS_DIR" ]; then
    echo "-----------------------------------------------"
    echo "Tùy chọn tiện ích mở rộng:"
    for EXT_PATH in "$EXTENSIONS_DIR"/*; do
        if [ -d "$EXT_PATH" ]; then
            EXT_NAME=$(basename "$EXT_PATH")
            read -p "  Sử dụng $EXT_NAME? (y/n): " WITH_EXT
            if [[ "$WITH_EXT" =~ ^[Yy]$ ]]; then
                SELECTED_EXTENSIONS+=("$EXT_NAME")
            fi
        fi
    done
    echo "-----------------------------------------------"
fi

# Tạo thư mục dự án
mkdir -p "$PROJECT_DIR"

# 5. Render Docker Compose chính
sed -e "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" \
    -e "s|{{PHP_VERSION}}|$PHP_VER|g" \
    -e "s|{{SOURCE_PATH}}|$SOURCE_PATH|g" \
    -e "s|\${GLOBAL_PATH}|$GLOBAL_PATH|g" \
    "$GLOBAL_PATH/setup_templates/docker-compose.yml.template" > "$PROJECT_DIR/docker-compose.yml"

# Render các Extensions đã chọn
for EXT_NAME in "${SELECTED_EXTENSIONS[@]}"; do
    EXT_FILE="$PROJECT_DIR/docker-compose.$EXT_NAME.yml"
    sed -e "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" \
        -e "s|\${GLOBAL_PATH}|$GLOBAL_PATH|g" \
        "$EXTENSIONS_DIR/$EXT_NAME/docker-compose.yml" > "$EXT_FILE"
    COMPOSE_FILES="$COMPOSE_FILES:docker-compose.$EXT_NAME.yml"
done

# Lưu biến môi trường cho Docker Compose để tự động nhận tất cả các file được cấu hình
echo "COMPOSE_FILE=$COMPOSE_FILES" > "$PROJECT_DIR/.env"

# 6. Render Nginx Config vào thư mục global_nginx
# Lưu ý: Nginx Global cần đọc file này nên ta đẩy thẳng vào volume của nó
mkdir -p "$GLOBAL_PATH/nginx/conf.d"
sed -e "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" \
    "$GLOBAL_PATH/setup_templates/nginx.conf.template" > "$GLOBAL_PATH/nginx/conf.d/$PROJECT_NAME.conf"

echo "-----------------------------------------------"
echo "✅ Đã tạo xong dự án tại: $PROJECT_DIR"
if [ ${#SELECTED_EXTENSIONS[@]} -gt 0 ]; then
    echo "✅ Đã cài đặt các Extensions: ${SELECTED_EXTENSIONS[*]}"
fi
echo "✅ Đã thêm cấu hình Nginx: $GLOBAL_PATH/nginx/conf.d/$PROJECT_NAME.conf"
echo "🚀 Cách chạy:"
echo "   1. cd projects/$PROJECT_NAME"
echo "   2. docker-compose up -d"
echo "   3. Restart Nginx Global: docker exec global_nginx nginx -s reload"
echo "   4. Thêm '127.0.0.1 $PROJECT_NAME.test' vào file hosts."