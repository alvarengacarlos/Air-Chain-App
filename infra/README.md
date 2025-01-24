# Infra
## Description
...

## Requirements
- Terraform 1.10.4
- AWS CLI 2.23.2
- jq 1.7.1

## Provisioning
Initialize the directory:
```bash
terraform init
```

Create the key pair:

> **Warning:** If you change the `--key-name` parameter, do not forget to change the `main.tf` too.

```bash
aws ec2 create-key-pair \
    --key-name air-chain-server-instance-key-pair \
    --key-type rsa \
    --key-format pem \
    --query "KeyMaterial" \
    --output text > air-chain-server-instance-key-pair.pem
    
chmod 400 air-chain-server-instance-key-pair.pem
```

Set the `MY_PUBLIC_IP` variable:
```bash
MY_PUBLIC_IP=$(host -4 myip.opendns.com resolver1.opendns.com | grep "myip.opendns.com has" | awk '{print $4}')
```

Create the infrastructure:
```bash
terraform apply -var="environment=dev"  -var="my_public_ip=$MY_PUBLIC_IP/32"
# or
terraform apply -var="environment=prod"  -var="my_public_ip=$MY_PUBLIC_IP/32"
```

Save your `terraform.tfstate` file securely.

> **Carefully:** The `terraform.tfstate` file contains sensitive information. 

Set the `AIR_CHAIN_SERVER_INSTANCE_PUBLIC_IP` variable:
```bash
AIR_CHAIN_SERVER_INSTANCE_PUBLIC_IP=$(aws ec2 describe-instances --filter "Name=tag-key,Values=Name" "Name=tag-value,Values=air-chain-server-instance" | jq -csr '.[0].Reservations[0].Instances[0].NetworkInterfaces[0].Association.PublicIp')
```

Access the server the air chain server instance machine:
```bash
ssh -i "air-chain-server-instance-key-pair.pem" ec2-user@$AIR_CHAIN_SERVER_INSTANCE_PUBLIC_IP
```

Install the [MySQL server](https://dev.mysql.com/doc/refman/9.2/en/linux-installation-yum-repo.html):

> **Tip**: Change the defined database password `Root@123` to another one more secure. 

```bash
wget https://dev.mysql.com/get/mysql84-community-release-el9-1.noarch.rpm

sudo yum localinstall -y mysql84-community-release-el9-1.noarch.rpm 

sudo yum install -y mysql-community-server
sudo systemctl start mysqld

sudo grep 'temporary password' /var/log/mysqld.log

mysql -u root -p --connect-expired-password -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'Root@123'"
```

## Destroying 
Remove resources provisioned by Terraform:
```bash
terraform destroy -var="environment=prod"  -var="my_public_ip=$MY_PUBLIC_IP/32"
```

Remove key pair:
```bash
aws ec2 delete-key-pair --key-name air-chain-server-instance-key-pair

rm air-chain-server-instance-key-pair.pem
```
