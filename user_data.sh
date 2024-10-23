#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

echo "${quay_password}" | docker login -u "${quay_username}" --password-stdin quay.io
docker pull ${github_backup_image}

chown ubuntu:ubuntu /home/ubuntu/.ssh
echo "${ssh_private_key}" > /home/ubuntu/.ssh/github_backup_key
chown ubuntu:ubuntu /home/ubuntu/.ssh/github_backup_key
chmod 600 /home/ubuntu/.ssh/github_backup_key

docker run -d \
  --name github-backup \
  --restart always \
  -v /home/ubuntu/backup-data:/data \
  -v /home/ubuntu/.ssh/github_backup_key:/root/.ssh/github_backup_key \
  -e GHE_HOSTNAME="${ghe_hostname}" \
  -e GHE_EXTRA_SSH_OPTS="-i /root/.ssh/github_backup_key" \
  -e S3_BUCKET="${s3_bucket}" \
  ${github_backup_image}
