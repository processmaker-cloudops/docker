#!/bin/bash
set -ex

# ProcessMaker required configurations
sed -i '/short_open_tag = Off/c\short_open_tag = On' /etc/php.ini
sed -i '/post_max_size = 8M/c\post_max_size = 24M' /etc/php.ini
sed -i '/upload_max_filesize = 2M/c\upload_max_filesize = 24M' /etc/php.ini
sed -i '/;date.timezone =/c\date.timezone = America/New_York' /etc/php.ini
sed -i 's/memory_limit = 128M/memory_limit = 512M/g' /etc/php.ini
sed -i '/expose_php = On/c\expose_php = Off' /etc/php.ini

# OpCache configurations
sed -i '/;opcache.enable_cli=0/c\opcache.enable_cli=1' /etc/php.d/10-opcache.ini
sed -i '/opcache.max_accelerated_files=4000/c\opcache.max_accelerated_files=10000' /etc/php.d/10-opcache.ini
sed -i '/;opcache.max_wasted_percentage=5/c\opcache.max_wasted_percentage=5' /etc/php.d/10-opcache.ini
sed -i '/;opcache.use_cwd=1/c\opcache.use_cwd=1' /etc/php.d/10-opcache.ini
sed -i '/;opcache.validate_timestamps=1/c\opcache.validate_timestamps=1' /etc/php.d/10-opcache.ini
sed -i '/;opcache.fast_shutdown=0/c\opcache.fast_shutdown=1' /etc/php.d/10-opcache.ini

# Decompress ProcessMaker and Plugins
cd /tmp && tar -C /opt -xzvf processmaker-3.3.1.tar.gz
cd /tmp && tar -C /tmp -xzvf bundle.tar.gz

# Set user email for Intercom
sed -i 's,se@processmaker.com,'"${EMAIL}"',g' /opt/processmaker/workflow/engine/plugins/intercom/getUserInfo.php

# Add sleep to allow processes to finish
sleep 3

# Workspace Restore for Enterprise Bundle
cd /opt/processmaker && ./processmaker workspace-restore -o /tmp/workflow.tar $WORKSPACE
cd /opt/processmaker && ./processmaker flush-cache

# Set file ownership
chown -R nginx. /opt/processmaker
chown root. /opt/processmaker/workflow/engine/config/blacklist.ini

# Start services
cp /etc/hosts ~/hosts.new
sed -i "/127.0.0.1/c\127.0.0.1 localhost localhost.localdomain `hostname`" ~/hosts.new
cp -f ~/hosts.new /etc/hosts
chkconfig sendmail on && service sendmail start
chkconfig nginx on && chkconfig php-fpm on
touch /etc/sysconfig/network
service php-fpm start && nginx -g 'daemon off;'
