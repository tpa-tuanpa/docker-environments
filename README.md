# Docker Environments TPA

Hệ thống quản lý và khởi tạo tự động môi trường Docker cho các dự án PHP, sử dụng kiến trúc kết hợp giữa các dịch vụ dùng chung (Global Services như Nginx, MariaDB) và các dịch vụ chạy độc lập cho từng dự án (App PHP, Redis, RabbitMQ, Mailhog, v.v...).

## Cấu trúc thư mục

```text
docker-env/
├── docker-system/              # Chứa cấu hình các dịch vụ global và các template sinh ra cấu hình cho dự án
│   ├── .env                    # Biến môi trường chung (mật khẩu Root, tên mạng, tên container global...)
│   ├── docker-compose.yml      # Cấu hình chạy MariaDB, Nginx (Proxy chính), Portainer
│   ├── extensions/             # Chứa template cấu hình add-ons cho dự án
│   │   ├── mailhog/            # - Template cấu hình Mailhog (catch mail)
│   │   ├── rabbitmq/           # - Template cấu hình RabbitMQ
│   │   └── redis/              # - Template cấu hình Redis
│   ├── mariadb/                # Volume lưu trữ data của chung toàn bộ Database
│   ├── nginx/                  # Chứa file cấu hình (*.conf) của các dự án và logs
│   ├── php/                    # Chứa ảnh Dockerfile và config ứng với từng phiên bản PHP (như php7.4, php8.2)
│   └── setup_templates/        # Template để sinh file cấu hình nginx và docker compose cho từng dự án con
├── projects/                   # Thư mục đích lưu trữ cấu hình mạng lưới độc lập của từng dự án sau khi tạo
└── setup_project.sh            # Script tương tác CLI tự động tạo và cấu hình dự án mới
```

## Cách sử dụng

**1. Khởi động các dịch vụ dùng chung (Global System)**
Lần đầu tiên clone hoặc tải bộ source về, bạn cần khởi chạy các container hệ thống trước:
```bash
cd docker-system
cp .env.sample .env
# Chỉnh sửa các thông số trong .env nếu cần thiết
docker-compose up -d
```

**2. Khởi tạo cấu hình cho một dự án**
Sử dụng script tự động ở thư mục gốc:
```bash
./setup_project.sh
```
Hệ thống sẽ dẫn dắt qua từng bước:
- **Nhập tên dự án** (Ví dụ: `my-project`). Tên này sẽ dùng làm tiền tố (*prefix*) cho các container, file cấu hình và hostname.
- **Chọn phiên bản PHP:** Danh sách được lấy tự động từ các thư mục trong `docker-system/php/`.
- **Đường dẫn Source Code:** Nhập đường dẫn tuyệt đối trực tiếp tới thư mục project của bạn (nơi chứa code).
- **Chọn Extensions:** Đồng ý (`y`) hoặc Không (`n`) để cài đặt các công cụ đi kèm như Redis, RabbitMQ hay Mailhog.

**3. Khởi chạy dự án**
Sau khi script hoàn tất, thư mục dự án cùng file Docker cấu hình đã được tạo tại thư mục `projects/<tên-dự-án>`.
```bash
cd projects/<tên-dự-án>
docker-compose up -d
```

**4. Áp dụng Router và Host**
Để có thể truy cập bằng tên miền cục bộ (ví dụ: `my-project.test`):
- Restart Nginx dùng chung để nhận cấu hình mới:
  ```bash
  docker restart <tên-container-global-nginx> 
  # hoặc dùng docker exec <tên-container-global-nginx> nginx -s reload
  ```
- Cập nhật file hosts trên máy (nằm tại `/etc/hosts` với Linux/Mac hoặc `C:\Windows\System32\drivers\etc\hosts` với Windows):
  ```text
  127.0.0.1  <tên-dự-án>.test
  ```
  *(Đuôi `.test` có thể tuỳ thuộc vào template cấu hình nginx bạn đang thiết lập).*

---

## Phát triển thêm

Hệ thống được thiết kế dạng template lắp ghép linh hoạt. Bạn có thể tự mình thêm các thành phần mới mà không cần can thiệp quá sâu vào mã nguồn script.

### Thêm phiên bản PHP (PHP Versions)
Khi có dự án sử dụng phiên bản PHP mới (ví dụ: PHP 8.1):
1. Bạn chỉ cần tạo một thư mục mới trong `docker-system/php/` và đặt tên tương ứng (ví dụ: `docker-system/php/php8.1`).
2. Trong đó, chứa `Dockerfile` và các config như `php.ini` riêng của version này.
3. Khi chạy lại `setup_project.sh`, script sẽ scan thư mục và tự động hiển thị `php8.1` như một Option trong Menu chọn phiên bản PHP của bạn.

### Thêm tiện ích (Extensions)
Khi bạn muốn quy chuẩn hóa cấu hình cài đặt cho ElasticSearch, Kafka, MongoDB, v.v...:
1. Tạo một thư mục mới tương ứng trong `docker-system/extensions/` (Ví dụ: `docker-system/extensions/mongodb/`).
2. Bên trong mục đó, tạo file `docker-compose.yml` định nghĩa service bạn muốn dùng.
   - Sử dụng từ khoá placeholder `{{PROJECT_NAME}}` cho các trường cần định danh của dự án (như `container_name: {{PROJECT_NAME}}_mongodb`).
   - Sử dụng biến môi trường mạng dùng chung `${GLOBAL_NETWORK_NAME}` nếu dịch vụ cần kết nối tới mạng global.
3. Lần tiếp theo chạy lệnh tạo dự án, script sẽ tự động tìm thấy extension này và cung cấp tuỳ chọn `Sử dụng mongodb? (y/n)`. Nếu được chọn, nó sinh ra file extension cấu hình riêng biệt và add vào biến cục bộ `COMPOSE_FILE` của `.env` dự án.