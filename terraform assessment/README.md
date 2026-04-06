# Month One Assessment - 
The objective of this project is to create a secure, scalable, and multi-AZ environment with public and private subnets, NAT gateways, a bastion host, web servers, a database server, and an Application Load Balancer.

# Resources created:
- VPC
- 2 Public Subnets
- 2 Private Subnets
- Internet Gateway
- 2 NAT Gateways
- Bastion Host
- 2 Web Servers
- 1 Database Server
- Application Load Balancer
- Security Groups
- Route Tables and Associations

# Elements
- AWS account
- AWS CLI configured
- Terraform installed
- Existing EC2 key pair in AWS
- My public IP address in CIDR format

## Files
- `main.tf` - infrastructure resources
- `variables.tf` - variable definitions
- `outputs.tf` - output values
- `terraform.tfvars.example` - sample variable values
- `user_data/web_server_setup.sh` - installs Apache on web servers
- `user_data/db_server_setup.sh` - installs PostgreSQL on DB server

## Deployment Steps

### 1. Initialize Terraform
```bash
terraform init