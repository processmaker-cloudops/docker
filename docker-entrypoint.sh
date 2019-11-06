#!/bin/bash
set -ex

# ProcessMaker required configurations
sed -i '/short_open_tag = Off/c\short_open_tag = On' /etc/php.ini
sed -i '/post_max_size = 8M/c\post_max_size = 24M' /etc/php.ini
sed -i '/upload_max_filesize = 2M/c\upload_max_filesize = 24M' /etc/php.ini
sed -i '/;date.timezone =/c\date.timezone = America/New_York' /etc/php.ini
sed -i '/expose_php = On/c\expose_php = Off' /etc/php.ini

# OpCache configurations
sed -i '/;opcache.enable_cli=0/c\opcache.enable_cli=1' /etc/php.d/10-opcache.ini
sed -i '/opcache.max_accelerated_files=4000/c\opcache.max_accelerated_files=10000' /etc/php.d/10-opcache.ini
sed -i '/;opcache.max_wasted_percentage=5/c\opcache.max_wasted_percentage=5' /etc/php.d/10-opcache.ini
sed -i '/;opcache.use_cwd=1/c\opcache.use_cwd=1' /etc/php.d/10-opcache.ini
sed -i '/;opcache.validate_timestamps=1/c\opcache.validate_timestamps=1' /etc/php.d/10-opcache.ini
sed -i '/;opcache.fast_shutdown=0/c\opcache.fast_shutdown=1' /etc/php.d/10-opcache.ini

# Decompress ProcessMaker
cd /tmp && tar -C /opt -xzvf processmaker-3.4.0.tar.gz
cd /tmp && tar -C /tmp -xzvf bundle.tar.gz
cd /tmp && cp paths_installed.php /opt/processmaker/workflow/engine/config/paths_installed.php
chown -R nginx. /opt/processmaker
mkdir /opt/processmaker/shared/sites


# Set NGINX server_name
sed -i 's,server_name ~^.*$;,server_name '"${URL}"';,g' /etc/nginx/conf.d/processmaker.conf

# Workspace restore for Enterprise Bundle
cd /tmp && tar -xvf workflow.tar
mv /tmp/test340.files /opt/processmaker/shared/sites/$WORKSPACE
sed -i 's/##WORKSPACE##/'"$WORKSPACE"'/g' /opt/processmaker/shared/sites/$WORKSPACE/db.php
mysql -u RDSPortainer -pD9PZ82hadX78dp*3 -h portainer.ckz0mnb6cuna.us-east-1.rds.amazonaws.com -e "CREATE DATABASE IF NOT EXISTS $WORKSPACE"
mysql -u RDSPortainer -pD9PZ82hadX78dp*3 -h portainer.ckz0mnb6cuna.us-east-1.rds.amazonaws.com $WORKSPACE < /tmp/wf_test340.sql

#cd /opt/processmaker && ./processmaker workspace-restore -o /tmp/workflow.tar $WORKSPACE && sleep 5
cd /opt/processmaker && ./processmaker flush-cache
cd /opt/processmaker/workflow/engine/bin
php -f cron.php calculated && php -f cron.php calculatedapp && php -f cron.php report_by_user +init-date"2018-01-01" && php -f cron.php report_by_process +init-date"2018-01-01"

# Set file ownership
chown -R nginx. /opt/processmaker

# Start services
cp /etc/hosts ~/hosts.new
sed -i "/127.0.0.1/c\127.0.0.1 localhost localhost.localdomain `hostname`" ~/hosts.new
cp -f ~/hosts.new /etc/hosts
chkconfig sendmail on && service sendmail start
chkconfig nginx on && chkconfig php-fpm on
touch /etc/sysconfig/network
cd /opt/processmaker && ./processmaker artisan queue:work --workspace=$WORKSPACE --sleep=3 --tries=3 --daemon &
service php-fpm start && nginx -g 'daemon off;'
