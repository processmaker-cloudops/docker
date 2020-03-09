# Base Image
FROM amazonlinux:2
CMD ["/bin/bash"]

# Maintainer
MAINTAINER ProcessMaker CloudOps <cloudops@processmaker.com>

# Extra
LABEL version="ProcessMaker 4"
LABEL description="ProcessMaker 4 Production Build"

# Declare ARGS and ENV Variable
ARG WORKSPACE
ENV WORKSPACE $WORKSPACE
ARG EMAIL
ENV EMAIL $EMAIL

# Initial steps
RUN yum clean all -y && yum update -y
RUN yum install aws-cli
RUN amazon-linux-extras install -y epel
RUN amazon-linux-extras install -y php7.3
RUN cp /etc/hosts ~/hosts.new && sed -i "/127.0.0.1/c\127.0.0.1 localhost localhost.localdomain `hostname`" ~/hosts.new && cp -f ~/hosts.new /etc/hosts

# mysql
RUN yum localinstall -y https://repo.mysql.com//mysql57-community-release-el7-11.noarch.rpm
RUN yum install -y mysql-community-server

# Required packages
RUN yum install \
  vim \
  wget \
  curl \
  tar.x86_64 \
  sudo \
  nano \
  sendmail \
  nginx \
  redis \
  cronie \
  php-fpm \
  php-apcu \
  php-pdo \
  php-bcmath \
  php-opcache \
  php-gd \
  php-zip \
  php-mysqlnd \
  php-soap \
  php-dom \
  php-posix \
  php-mbstring \
  php-ldap \
  php-devel \
  php-pecl-apcu \
  php-xml \
  libc-client-devel \
  uw-imap-static \
  -y

# Development Tools and imap
RUN yum groupinstall -y "Development Tools"

# Nodejs Npm
RUN cd /tmp && curl -sL https://rpm.nodesource.com/setup_12.x | /bin/bash -
RUN yum install -y nodejs

# Cert dir
RUN mkdir /etc/nginx/ssl

# Composer
RUN cd /tmp && wget https://getcomposer.org/download/1.8.6/composer.phar
RUN cd /tmp && chmod 775 composer.phar && mv composer.phar /usr/local/bin/composer
RUN cp /usr/local/bin/composer /usr/bin/composer
RUN mkdir /root/.composer
RUN mkdir /root/.config
RUN mkdir /root/.config/composer/
COPY conf/auth.json /root/.config/composer/
COPY conf/auth.json /root/.composer/

# Copy configuration files
RUN mkdir /root/scripts
COPY conf/processmaker-fpm.conf /etc/php-fpm.d
RUN mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bk
COPY conf/nginx.conf /etc/nginx
COPY conf/processmaker.conf /etc/nginx/conf.d

# NGINX Ports
EXPOSE 80 443

# Docker entrypoint
COPY docker-entrypoint.sh /bin/
RUN chmod a+x /bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]