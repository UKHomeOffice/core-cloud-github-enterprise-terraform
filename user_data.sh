#!/bin/bash
apt-get update
apt-get install -y docker.io

echo "${quay_password}" | docker login -u "${quay_username}" --password-stdin quay.io
docker pull ${github_backup_image}

sudo chown ubuntu:ubuntu /home/ubuntu/.ssh
sudo chmod 700 /home/ubuntu/.ssh

echo "${ssh_private_key}" > /home/ubuntu/.ssh/github_backup_key

sudo chown ubuntu:ubuntu /home/ubuntu/.ssh/github_backup_key
sudo chmod 600 /home/ubuntu/.ssh/github_backup_key

docker run -d \
  --name github-backup \
  --restart always \
  -v /home/ubuntu/backup-data:/data \
  -v /home/ubuntu/.ssh/github_backup_key:/root/.ssh/github_backup_key \
  -e GHE_HOSTNAME="${ghe_hostname}" \
  -e GHE_EXTRA_SSH_OPTS="-i /root/.ssh/github_backup_key" \
  -e AWS_ACCESS_KEY_ID="${aws_access_key_id}" \
  -e AWS_SECRET_ACCESS_KEY="${aws_secret_access_key}" \
  -e S3_BUCKET="${s3_bucket}" \
  ${github_backup_image}