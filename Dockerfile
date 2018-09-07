# Base Image
FROM amazonlinux:2018.03
CMD ["/bin/bash"]

# Maintainer
MAINTAINER ProcessMaker CloudOps <cloudops@processmaker.com>

# Extra
LABEL version="3.2.3"
LABEL description="ProcessMaker 3.2.3 Docker Container."

# Initial steps
RUN yum clean all && yum install epel-release -y && yum update -y
RUN cp /etc/hosts ~/hosts.new && sed -i "/127.0.0.1/c\127.0.0.1 localhost localhost.localdomain `hostname`" ~/hosts.new && cp -f ~/hosts.new /etc/hosts

# Required packages
RUN yum install \
  vim \
  wget \
  nano \
  sendmail \
  nginx \
  mysql56 \
  php56-fpm \
  php56-opcache \
  php56-gd \
  php56-mysqlnd \
  php56-soap \
  php56-mbstring \
  php56-ldap \
  php56-mcrypt \
  -y
  
# Download ProcessMaker Enterprise Edition, Enterprise Bundle and Plugins
RUN wget -O "/tmp/processmaker-3.2.3.tar.gz" \
      "https://artifacts.processmaker.net/official/processmaker-3.2.3.tar.gz"
RUN wget -O "/tmp/bundle.tar.gz" \
      "https://artifacts.processmaker.net/generic/bundle.tar.gz"
RUN wget --quiet --load-cookies /tmp/cookies.txt "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate 'https://docs.google.com/uc?export=download&id=1oOExGjmOzuzdm02iffwNjRjztc4qjNnV' -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=1oOExGjmOzuzdm02iffwNjRjztc4qjNnV" -O /tmp/plugins.tar.gz && rm -rf /tmp/cookies.txt
	  
# Copy configuration files
COPY processmaker-fpm.conf /etc/php-fpm.d
RUN mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bk
COPY nginx.conf /etc/nginx
COPY processmaker.conf /etc/nginx/conf.d
COPY paths_installed.php /opt/processmaker/workflow/engine/config/paths_installed.php

# NGINX Ports
EXPOSE 80

# Docker entrypoint
COPY docker-entrypoint.sh /bin/
RUN chmod a+x /bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
