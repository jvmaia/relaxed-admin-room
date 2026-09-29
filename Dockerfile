FROM php:7.4-apache-bullseye

RUN docker-php-ext-install mysqli \
    && printf 'deb [check-valid-until=no] http://archive.debian.org/debian bullseye main\n' > /etc/apt/sources.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        sudo perl python3 netcat-openbsd openssh-server default-mysql-client \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --uid 1000 --shell /bin/bash --comment 'THM-Chal,,,' itguy \
    && mkdir -p /run/sshd /var/www/html/content /var/www/html/content/inc/mysql_backup /var/www/html/content/inc/ads \
    && ssh-keygen -A

COPY vendor/sweetrice-1.5.1.tar.gz /tmp/sweetrice.tar.gz
RUN tar -xzf /tmp/sweetrice.tar.gz -C /var/www/html/content --strip-components=1 \
    && rm /tmp/sweetrice.tar.gz \
    && sed -i 's/get_magic_quotes_gpc()/false/g' /var/www/html/content/inc/function.php

COPY vendor/mysql_bakup_20191129023059-1.5.1.sql /var/www/html/content/inc/mysql_backup/
COPY lab/db.php /var/www/html/content/inc/db.php
COPY lab/install.lock.php /var/www/html/content/inc/install.lock.php
COPY lab/index.html /var/www/html/index.html
COPY lab/php-extensions.conf /etc/apache2/conf-available/lazyadmin-php.conf
COPY lab/sudoers /etc/sudoers.d/lazyadmin
COPY lab/user.txt /home/itguy/user.txt
COPY lab/mysql_login.txt /home/itguy/mysql_login.txt
COPY lab/backup.pl /home/itguy/backup.pl
COPY lab/copy.sh /etc/copy.sh
COPY lab/root.txt /root/root.txt
COPY lab/entrypoint.sh /usr/local/bin/lazyadmin-entrypoint

RUN a2enconf lazyadmin-php \
    && chown -R www-data:www-data /var/www/html/content \
    && chown itguy:itguy /home/itguy/user.txt /home/itguy/mysql_login.txt \
    && chown root:root /home/itguy/backup.pl /etc/copy.sh /root/root.txt \
    && chmod 0664 /home/itguy/user.txt /home/itguy/mysql_login.txt \
    && chmod 0645 /home/itguy/backup.pl \
    && chmod 0647 /etc/copy.sh \
    && chmod 0750 /root \
    && chmod 0644 /root/root.txt \
    && chmod 0440 /etc/sudoers.d/lazyadmin \
    && chmod 0755 /usr/local/bin/lazyadmin-entrypoint

EXPOSE 80 22
CMD ["/usr/local/bin/lazyadmin-entrypoint"]
