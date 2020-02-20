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


        cd /tmp && tar -C /opt -xzvf pm4-trials.tar.gz

        # Set NGINX server_name
        sed -i "s,%%WORKSPACE%%,${WORKSPACE},g" /etc/nginx/conf.d/processmaker.conf

        # Copy echo-server conf
        rm -Rf /opt/processmaker/laravel-echo-server.json
        cp /tmp/laravel-echo-server.json /opt/processmaker/laravel-echo-server.json

        # Create DB if necessary and import
        mysql -u RDSTrialsMaster -h pm4-trials-instance-1.ckz0mnb6cuna.us-east-1.rds.amazonaws.com -pl3\&9IiuyPhW\!cJl0bqk -f -e "CREATE DATABASE IF NOT EXISTS $WORKSPACE;"
        mysql -u RDSTrialsMaster -h pm4-trials-instance-1.ckz0mnb6cuna.us-east-1.rds.amazonaws.com -pl3\&9IiuyPhW\!cJl0bqk ${WORKSPACE} < /opt/processmaker/dbdump.sql

        # Update .env, Set file ownership, and seed db
        mkdir -p /opt/processmaker/tmp
        sed -i "s/%%WORKSPACE%%/${WORKSPACE}/g" /opt/processmaker/.env
		echo "PROXIES=*" >> /opt/processmaker/.env
		echo "PROXIES_AWS=true" >> /opt/processmaker/.env

        # Cron config
        echo "* * * * * nginx \"cd /opt/processmaker && /usr/bin/php artisan schedule:run >> /var/log/scheduler.log 2>&1\"" >> /etc/crontab
        /usr/sbin/crond

        touch /opt/processmaker/installCheck

        # Start services
        cp /etc/hosts ~/hosts.new
        sed -i "/127.0.0.1/c\127.0.0.1 localhost localhost.localdomain `hostname`" ~/hosts.new
        cp -f ~/hosts.new /etc/hosts
        chkconfig nginx on && chkconfig php-fpm on
        chown -R nginx:nginx /opt/processmaker
        sleep 5
        touch /etc/sysconfig/network
        /usr/sbin/php-fpm --daemonize && /usr/sbin/nginx -c /etc/nginx/nginx.conf
        redis-server --daemonize yes
        php /opt/processmaker/artisan horizon &
        rm -Rf /opt/processmaker/laravel-echo-server.lock
        sleep 1
        chown -R nginx:nginx /opt/processmaker
        cd /opt/processmaker && node /opt/processmaker/node_modules/laravel-echo-server/bin/server.js start