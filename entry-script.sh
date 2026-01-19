#!/bin/bash
# Entry script for EC2 instance initialization with Nginx + HTTPS

# Update system packages
yum update -y

# Install Nginx
yum install -y nginx

# Create directory for SSL certificates
mkdir -p /etc/nginx/ssl

# Generate self-signed TLS certificate (valid for 365 days)
openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout /etc/nginx/ssl/nginx.key \
  -out /etc/nginx/ssl/nginx.crt \
  -days 365 \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"

# Create Nginx configuration with HTTP redirect to HTTPS
cat > /etc/nginx/nginx.conf <<'NGINX_CONFIG'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log notice;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    # HTTP server - redirect all traffic to HTTPS
    server {
        listen 80;
        server_name _;
        return 301 https://$host$request_uri;
    }

    # HTTPS server
    server {
        listen 443 ssl;
        server_name _;

        # SSL certificate and key
        ssl_certificate /etc/nginx/ssl/nginx.crt;
        ssl_certificate_key /etc/nginx/ssl/nginx.key;

        # SSL configuration
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers on;

        location / {
            root /var/www/html;
            index index.html index.htm;
        }

        error_page 404 /404.html;
        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
            root /usr/share/nginx/html;
        }
    }
}
NGINX_CONFIG

# Create directory for HTML content
mkdir -p /var/www/html

# Create index.html with name and Terraform reference
cat > /var/www/html/index.html <<'HTML_CONTENT'
<!DOCTYPE html>
<html>
<head>
    <title>Terraform Environment</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 50px;
            background-color: #f5f5f5;
        }
        .container {
            background-color: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
        }
        .info {
            background-color: #e8f4f8;
            padding: 15px;
            border-left: 4px solid #0066cc;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Welcome to Terraform Environment</h1>
        <p>This is Hajra Sarwar's Terraform environment.</p>
        <div class="info">
            <h2>Infrastructure Details</h2>
            <p><strong>Hostname:</strong> <span id="hostname"></span></p>
            <p><strong>Instance ID:</strong> <span id="instance-id"></span></p>
            <p><strong>Environment:</strong> Powered by Terraform</p>
        </div>
        <p style="margin-top: 30px; color: #666;">
            This instance was provisioned using Terraform with Nginx, SSL/TLS, and automated deployment.
        </p>
    </div>

    <script>
        // Attempt to fetch instance metadata
        fetch('http://169.254.169.254/latest/meta-data/instance-id')
            .then(response => response.text())
            .then(data => {
                document.getElementById('instance-id').textContent = data;
            })
            .catch(() => {
                document.getElementById('instance-id').textContent = 'Not available';
            });

        document.getElementById('hostname').textContent = window.location.hostname;
    </script>
</body>
</html>
HTML_CONTENT

# Set proper permissions
chown -R nginx:nginx /var/www/html
chmod -R 755 /var/www/html
chown -R nginx:nginx /etc/nginx/ssl
chmod 600 /etc/nginx/ssl/nginx.key
chmod 644 /etc/nginx/ssl/nginx.crt

# Enable Nginx on boot
systemctl enable nginx

# Start Nginx
systemctl start nginx

# Log completion
echo "Nginx with HTTPS configuration completed at $(date)" >> /var/log/user-data.log
