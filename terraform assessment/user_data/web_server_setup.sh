#!/bin/bash
yum update -y
yum install -y httpd

TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  -s http://169.254.169.254/latest/meta-data/instance-id)

HOSTNAME=$(hostname)

cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
    <title>TechCorp Web Server</title>
</head>
<body>
    <h1>TechCorp Web Server is Running</h1>
    <p><strong>Hostname:</strong> $HOSTNAME</p>
    <p><strong>Instance ID:</strong> $INSTANCE_ID</p>
</body>
</html>
EOF

systemctl enable httpd
systemctl start httpd