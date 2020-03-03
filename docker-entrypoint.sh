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

        # certs
		cd /etc/nginx/ssl && tar -xzvf certs.tar.gz
		
		# Start services
        cp /etc/hosts ~/hosts.new
        sed -i "/127.0.0.1/c\127.0.0.1 localhost localhost.localdomain `hostname`" ~/hosts.new
        cp -f ~/hosts.new /etc/hosts
        chkconfig nginx on && chkconfig php-fpm on
        chown -R nginx:nginx /opt/processmaker
        sleep 5
        touch /etc/sysconfig/network
        /usr/sbin/php-fpm --daemonize && /usr/sbin/nginx -c /etc/nginx/nginx.conf -g 'daemon off;'