FROM debian:buster
#install
#https://www.rosehosting.com/blog/how-to-install-wordpress-with-nginx-on-debian-10/
RUN apt update && apt -y upgrade; \
	apt install -y nginx \
	mariadb-server \
	mariadb-client \
	php-cgi \
	php-common \
	php-fpm \
	php-pear \
	php-mbstring \
	php-zip \
	php-net-socket \
	php-gd \
	php-xml-util \
	php-gettext \
	php-mysql \
	php-bcmath \
	unzip \
	wget \
	git \
	vim \
	openssl \
	gettext

#Self-signed certificate
#https://kitsune.blog/nginx-ssl
RUN	mkdir /etc/nginx/ssl \
&& openssl genrsa -out /etc/nginx/ssl/server.key 2048 \
&& openssl req -new -key /etc/nginx/ssl/server.key -out /etc/nginx/ssl/server.csr -subj "/CN=localhost" \
&& openssl x509 -days 3650 -req -signkey /etc/nginx/ssl/server.key -in /etc/nginx/ssl/server.csr -out /etc/nginx/ssl/server.crt

#default
#https://forhjy.medium.com/how-to-install-lemp-wordpress-on-debian-buster-by-using-dockerfile-1-75ddf3ede861
COPY ./srcs/default.template /etc/nginx/sites-available/default.template
#set an environment variable
COPY ./srcs/auto_index.sh /etc/nginx/sites-available/
#php.ini
#https://www.rosehosting.com/blog/how-to-install-wordpress-with-nginx-on-debian-10/
COPY ./srcs/php.ini /etc/php/7.3/fpm/

#create user
RUN service mysql restart \
	&& mysql -e "CREATE DATABASE wpdb;" \
	&& mysql -e "CREATE USER 'wpuser'@'localhost' identified by 'dbpassword';" \
	&& mysql -e "GRANT ALL PRIVILEGES ON  wpdb. * TO 'wpuser'@'localhost';" \
	&& mysql -e "FLUSH PRIVILEGES;" \
	&& mysql -e "EXIT"

RUN cd /var/www/html \
	&& wget https://wordpress.org/latest.tar.gz \
	&& tar -xvzf latest.tar.gz

COPY ./srcs/wp-config.php /var/www/html/wordpress/

RUN chown -R www-data:www-data /var/www/html/wordpress

COPY ./srcs/wordpress.conf /etc/nginx/sites-available/wordpress.conf

RUN ln -s /etc/nginx/sites-available/wordpress.conf /etc/nginx/sites-enabled/

#create a necessary directory
RUN mkdir /run/php/

#phpMyAdmin
#https://note.com/syamashi/n/nd296e3e46dab
RUN cd /var/www/html \
	&& wget https://files.phpmyadmin.net/phpMyAdmin/5.0.4/phpMyAdmin-5.0.4-all-languages.tar.gz \
	&& tar -xvzf phpMyAdmin-5.0.4-all-languages.tar.gz \
	&& mv phpMyAdmin-5.0.4-all-languages phpmyadmin

CMD bash /etc/nginx/sites-available/auto_index.sh \
	&& service nginx start \
	&& service php7.3-fpm start \
	&& service mysql start \
	&& tail -f /dev/null
