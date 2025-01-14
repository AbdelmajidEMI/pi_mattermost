#!/bin/bash

echo "********** Starting AWS CLI and jq installation **********"

# Install AWS CLI
sudo apt update
sudo apt install -y awscli jq

echo "********** Fetching EC2 instance region from metadata **********"

# Fetch the region from EC2 instance metadata
REGION=$(curl http://169.254.169.254/latest/meta-data/placement/region)

echo "********** Fetching parameters from AWS Systems Manager Parameter Store **********"

# Fetch parameters from AWS Systems Manager Parameter Store
DB_CONNECTION=$(aws ssm get-parameter --name "/mattermost/db_connection" --with-decryption --query "Parameter.Value" --output text --region ${REGION})
DOMAIN_NAME=$(aws ssm get-parameter --name "/mattermost/domain" --query "Parameter.Value" --output text --region ${REGION})

echo "********** Installing Mattermost dependencies **********"

# Install Mattermost dependencies
curl -sL -o- https://deb.packages.mattermost.com/pubkey.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/mattermost-archive-keyring.gpg > /dev/null
curl -o- https://deb.packages.mattermost.com/repo-setup.sh | sudo bash -s mattermost
sudo apt update
sudo apt install mattermost -y

echo "********** Installing the Mattermost config file **********"

# Install the config file
install -C -m 600 -o mattermost -g mattermost /opt/mattermost/config/config.defaults.json /opt/mattermost/config/config.json

echo "********** Modifying Mattermost config with parameters **********"

# Modify config.json file with parameters
jq --arg domain "$DOMAIN_NAME" \
   --arg db_conn "$DB_CONNECTION" \
   --arg region "$REGION" \
   '.ServiceSettings.SiteURL = "https://\($domain)" | 
    .SqlSettings.DataSource = $db_conn | 
    .FileSettings.AmazonS3Bucket = $domain | 
    .FileSettings.AmazonS3Region = $region | 
    .FileSettings.DriverName = "amazons3" |
    .ClusterSettings.Enable = true |
    .ClusterSettings.ClusterName = "production" |
    .ClusterSettings.ReadOnlyConfig = false' \
   /opt/mattermost/config/config.json > /opt/mattermost/config/config_tmp.json \
   && mv /opt/mattermost/config/config_tmp.json /opt/mattermost/config/config.json

# Get the instance's local IP address
ip_address=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

jq --arg ip_address "$ip_address" \
   '.ClusterSettings.OverrideHostname = "\($ip_address)" | 
    .ClusterSettings.AdvertiseAddress = "\($ip_address)" | 
    .ClusterSettings.BindAddress = "0.0.0.0"' \
   /opt/mattermost/config/config.json > /opt/mattermost/config/config_tmp.json \
   && mv /opt/mattermost/config/config_tmp.json /opt/mattermost/config/config.json




echo "********** Changing ownership of the config.json file **********"

# Change ownership of the config file
chown mattermost:mattermost /opt/mattermost/config/config.json

echo "********** Starting Mattermost service **********"

# Start Mattermost service
sudo systemctl start mattermost

echo "********** Configuring system limits **********"

# Define the lines to append
LIMITS_CONFIG="* soft nofile 65536
* hard nofile 65536
* soft nproc 8192
* hard nproc 8192"

# Append the configuration to the end of /etc/security/limits.conf
echo "$LIMITS_CONFIG" | sudo tee -a /etc/security/limits.conf > /dev/null

echo "********** Limits appended to /etc/security/limits.conf **********"

# Reload system settings
sysctl -p

echo "********** Configuring sysctl parameters **********"

# Define the sysctl configuration to append
SYSCTL_CONFIG="
# Extending default port range to handle lots of concurrent connections.
net.ipv4.ip_local_port_range = 1025 65000

# Lowering the timeout to faster recycle connections in the FIN-WAIT-2 state.
net.ipv4.tcp_fin_timeout = 30

# Reuse TIME-WAIT sockets for new outgoing connections.
net.ipv4.tcp_tw_reuse = 1

# Bumping the limit of a listen() backlog.
net.core.somaxconn = 4096

# Increasing the maximum number of connection requests which have not received an acknowledgment from the client.
net.ipv4.tcp_max_syn_backlog = 8192

# This is tuned to be 2% of the available memory.
vm.min_free_kbytes = 167772

# Disabling slow start helps increasing overall throughput and performance of persistent single connections.
net.ipv4.tcp_slow_start_after_idle = 0

# Performance improvements with these settings.
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq
net.ipv4.tcp_notsent_lowat = 16384

# TCP buffer sizes are tuned for 10Gbit/s bandwidth and 0.5ms RTT.
net.ipv4.tcp_rmem = 4096 156250 625000
net.ipv4.tcp_wmem = 4096 156250 625000
net.core.rmem_max = 312500
net.core.wmem_max = 312500
net.core.rmem_default = 312500
net.core.wmem_default = 312500
net.ipv4.tcp_mem = 1638400 1638400 1638400
"

# Append the configuration to the end of /etc/sysctl.conf
echo "$SYSCTL_CONFIG" | sudo tee -a /etc/sysctl.conf > /dev/null

echo "********** Sysctl configuration appended to /etc/sysctl.conf **********"

# Reload sysctl settings to apply changes
sysctl -p

echo "********** Time synchronization with NTP **********"

# Ensure NTP is installed and running
sudo apt install -y ntp
sudo systemctl enable ntp
sudo systemctl start ntp

echo "********** Time synchronization enabled for all servers in the cluster **********"


echo "********** Test ClusterDiscovery **********"

# sudo apt install -y postgresql-client
# psql postgres://abood:00000000@mattermost-postgres.c9oe2yaim47a.us-east-1.rds.amazonaws.com:5432/mattermost -c "SELECT * FROM ClusterDiscovery"


echo "********** All configurations applied successfully! **********"
