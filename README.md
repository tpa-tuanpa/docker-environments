# Docker Environments TPA

Hệ thống quản lý và khởi tạo tự động môi trường Docker cho các dự án Web/PHP đa phiên bản. Hệ thống được thiết kế theo **Mô hình 2 lớp (Global Router + Project Container)** giúp phân tách hoàn toàn các dịch vụ dùng chung và dịch vụ riêng biệt của từng dự án.

---

## 🚀 Kiến trúc hệ thống (Architecture)

```text
                           [Trình duyệt Web]
                                  │
                                  ▼ (http://<project_name>.local)
 ┌─────────────────────────────────────────────────────────────────┐
 │ GLOBAL SYSTEM (docker-system)                                   │
 │                                                                 │
 │  ┌───────────────────────────────────────────────────────────┐  │
 │  │ Global Nginx Router (global_nginx)                        │  │
 │  │ - Wildcard Domain Routing (*.local)                       │  │
 │  │ - Port 80 / 443                                           │  │
 │  └─────────────────────────────┬─────────────────────────────┘  │
 │                                │                                │
 │  ┌─────────────────────────────┴─────────────────────────────┐  │
 │  │ Shared Services (MariaDB, Portainer, v.v...)              │  │
 │  └───────────────────────────────────────────────────────────┘  │
 └────────────────────────────────┬────────────────────────────────┘
                                  │ (Docker Internal Network: global_network)
                                  ▼
 ┌─────────────────────────────────────────────────────────────────┐
 │ DỰ ÁN CON (docker-projects/<project_name>)                      │
 │                                                                 │
 │  ┌─────────────────────────────┐  ┌──────────────────────────┐  │
 │  │ Project Nginx               │  │ App Container            │  │
 │  │ (server_<project_name>)     │─►│ (PHP 7.4/8.2/8.4, Node)  │  │
 │  └─────────────────────────────┘  └──────────────────────────┘  │
 │  ┌───────────────────────────────────────────────────────────┐  │
 │  │ Project Extensions (Redis, RabbitMQ, Mailhog, v.v...)     │  │
 │  └───────────────────────────────────────────────────────────┘  │
 └─────────────────────────────────────────────────────────────────┘
```

---

## 📂 Cấu trúc thư mục

```text
docker-environments/
├── docker-system/                          # Các dịch vụ dùng chung hệ thống (Global)
│   ├── .env                                # Biến môi trường chung (MySQL Root, Tên mạng Global...)
│   ├── docker-compose.yml                  # MariaDB, Nginx Global Proxy, Portainer...
│   ├── nginx/
│   │   └── conf.d/
│   │       └── 00-wildcard-router.conf     # Wildcard Router tự động bắt domain *.local
│   ├── php/                                # Đa phiên bản PHP (php7.4, php8.2, php8.4...)
│   ├── extensions/                         # Template cài thêm add-ons (Redis, RabbitMQ, Mailhog...)
│   └── setup_templates/                    # Template sinh cấu hình docker-compose và nginx cho project con
│
├── docker-projects/                        # Chứa cấu hình môi trường chạy độc lập của từng dự án
│   ├── mht/                                # Dự án MHT (Nginx riêng + PHP 8.4 + Node)
│   └── lme/                                # Dự án LME (Nginx riêng + PHP 7.4)
│
└── setup_project                           # Script CLI tự động khởi tạo dự án mới
```

---

## ⚙️ Hướng dẫn cài đặt & Sử dụng

### 1. Khởi chạy Dịch vụ Hệ thống (Global System)
Lần đầu tiên thiết lập máy chủ local, bạn cần khởi chạy các dịch vụ dùng chung (Global Router, Database...):

```bash
cd docker-system
cp .env.sample .env
# (Tùy chỉnh thông số trong file .env nếu cần)

docker-compose up -d
```

---

### 2. Khởi tạo một Dự án mới
Sử dụng script tự động `./setup_project` ngay tại thư mục gốc:

```bash
./setup_project
```

Script sẽ hướng dẫn bạn thiết lập qua các bước đơn giản:
1. **Nhập tên dự án**: Ví dụ `my-project`.
2. **Chọn phiên bản PHP**: Chọn phiên bản PHP mong muốn (PHP 7.4, 8.2, 8.4...).
3. **Đường dẫn Source code**: Nhập đường dẫn tuyệt đối chứa mã nguồn dự án của bạn (ví dụ `/home/tuanpa/projects/my-project`).
4. **Chọn Extension**: Lựa chọn đồng ý (`y/n`) thêm các dịch vụ bổ trợ như Redis, Mailhog, RabbitMQ...

---

### 3. Khởi chạy Dự án
Sau khi script hoàn tất, thư mục dự án đã được tạo tại `docker-projects/<tên-dự-án>`:

```bash
cd docker-projects/my-project
docker-compose up -d
```

---

### 4. Thêm tên miền Cục bộ (Local Hosts)
Bổ sung tên miền dự án vào file `hosts` của máy tính:

* **Linux / macOS**: `/etc/hosts`
* **Windows**: `C:\Windows\System32\drivers\etc\hosts`

```text
127.0.0.1  my-project.local
```

> 🎉 **Hoàn tất!** Truy cập ngay `http://my-project.local` trên trình duyệt.
> **Lưu ý:** Nhờ cơ chế Wildcard Router, bạn **KHÔNG CẦN** restart Nginx Global hay sửa thêm bất kỳ cấu hình nào ở `docker-system`!

---

## 🌟 Tính năng nổi bật

- ⚡ **Dynamic Wildcard Routing (`*.local`)**: Nginx Global tự động điều hướng tên miền `http://<tên-dự-án>.local` trực tiếp tới container Nginx của dự án đó mà không cần ghi file config hay reload Nginx hệ thống.
- 📦 **Đóng gói Độc lập**: Mỗi dự án có container Nginx và PHP/Node riêng biệt. Không lo xung đột cấu hình giữa các dự án.
- 🧹 **Không Duplicate Cấu hình**: Nginx Global chỉ làm nhiệm vụ Router (Domain Dispatcher), Project Nginx chịu trách nhiệm phục vụ static file và FastCGI PHP.
- 🔌 **Tích hợp Extensions linh hoạt**: Dễ dàng tích hợp Redis, RabbitMQ, Mailhog... cho từng dự án bằng menu bấm chọn.
- 📊 **Dễ dàng mở rộng Ops & Monitoring**: Các công cụ giám sát như Portainer, Dozzle (xem container log), Adminer có thể dễ dàng khởi chạy và truy cập qua tên miền `<service>.local`.

---

## 🛠️ Hướng dẫn Mở rộng (Advanced)

### Thêm phiên bản PHP mới
1. Tạo thư mục mới tại `docker-system/php/phpX.Y` (ví dụ: `docker-system/php/php8.1`).
2. Đặt `Dockerfile` và file cấu hình `php.ini` riêng vào thư mục đó.
3. Chạy lại `./setup_project`, phiên bản PHP mới sẽ tự động hiển thị trong danh sách lựa chọn.

### Thêm Extension mới (Ví dụ: MongoDB, Elasticsearch)
1. Tạo thư mục tương ứng trong `docker-system/extensions/<tên-extension>/`.
2. Tạo file `docker-compose.yml` sử dụng biến placeholder `{{PROJECT_NAME}}` và mạng chung `${GLOBAL_NETWORK}`.
3. Lần chạy `./setup_project` tiếp theo, hệ thống sẽ tự tìm thấy extension này và hỏi tùy chọn cài đặt.
