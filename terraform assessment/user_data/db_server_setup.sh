#!/bin/bash
yum update -y
amazon-linux-extras enable postgresql14
yum clean metadata
yum install -y postgresql postgresql-server postgresql-contrib

postgresql-setup initdb

systemctl enable postgresql
systemctl start postgresql

sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'TechCorpDB@123';"