# Base Image
FROM amazonlinux:2017.09
CMD ["/bin/bash"]

# Maintainer
MAINTAINER ProcessMaker CloudOps <cloudops@processmaker.com>

# Extra
LABEL version="3.2.1"
LABEL description="ProcessMaker 3.2.1 Docker Container."

# Initial steps
RUN yum clean all && yum install epel-release -y && yum update -y

# Required packages
RUN yum install \
  wget \
  nano \
  sendmail \
  nginx \
  php56-fpm \
  php56-opcache \
  php56-gd \
  php56-mysqlnd \
  php56-soap \
  php56-mbstring \
  php56-ldap \
  php56-mcrypt \
  -y
  
# Download ProcessMaker Enterprise Edition
RUN wget -O "/tmp/processmaker-3.2.1.tar.gz" \
      "https://bitnami.processmaker.com/official/processmaker-3.2.1.tar.gz"
	  
# Copy configuration files
COPY processmaker-fpm.conf /etc/php-fpm.d
RUN mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bk
COPY nginx.conf /etc/nginx
COPY processmaker.conf /etc/nginx/conf.d

# NGINX Ports
EXPOSE 80

# Docker entrypoint
COPY docker-entrypoint.sh /bin/
COPY processmaker.conf /etc/nginx/conf.d/
RUN chmod a+x /bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]