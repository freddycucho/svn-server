FROM ubuntu:16.04
MAINTAINER  Freddy Moran <freddycucho@gmail.com>

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
   		   apache2 \
				 apache2-utils \
                   subversion \
                   git \
                   curl \
                   zip \
		   unzip \
                   nano \
		   php \
			 php-json \
			 php-ldap \
   		   libapache2-mod-php \
				 supervisor \
     		   wget \
                   openssh-server \
                   vim \
                   libapache2-svn \
		   php-xml \
                   libsvn-perl \
          && rm -r /var/lib/apt/lists/*

RUN a2enmod dav_svn
RUN a2enmod dav
WORKDIR /var/www/html
RUN  wget -qO- -O tmp.zip http://websvn.tigris.org/files/documents/1380/49057/websvn-2.3.3.zip && unzip tmp.zip && rm tmp.zip && mv websvn-* ../
RUN mv /var/www/websvn-* /var/www/html/websvn
RUN  wget --no-check-certificate -qO- -O tmp.zip https://github.com/mfreiholz/iF.SVNAdmin/archive/stable-1.6.2.zip && unzip tmp.zip && rm tmp.zip && mv iF.SVNAdmin-stable-* ../
#RUN mkdir /etc/subversion
RUN mv /var/www/iF.SVNAdmin-stable-* /var/www/html/svnadmin
RUN chmod -R 777 /var/www/html/svnadmin/data
RUN chown -R www-data:www-data /var/www/html
RUN rm /var/www/html/index.html
RUN cp /var/www/html/websvn/include/distconfig.php /var/www/html/websvn/include/config.php
#RUN mkdir /etc/subversion
RUN mkdir /home/svn/
RUN touch /etc/subversion/passwd
RUN chmod 777 /etc/subversion/passwd
#RUN htpasswd -cbs /etc/subversion/passwd admin admin
RUN echo "\$config->parentPath(\"/home/svn\");"  >> /var/www/html/websvn/include/config.php
RUN  echo "<Location /svn> \n  DAV svn \n  SVNParentPath /home/svn \n SVNListParentPath On \n AuthType Basic \n AuthName \"Subversion Repository\" \n AuthUserFile /etc/subversion/passwd \n AuthzSVNAccessFile /etc/subversion/subversion-access-control \n Require valid-user \n </Location>" >> /etc/apache2/mods-enabled/dav_svn.conf

# Add SVNAuth file
ADD subversion-access-control /etc/subversion/subversion-access-control

# Fixing https://github.com/mfreiholz/iF.SVNAdmin/issues/118
ADD svnadmin/classes/util/global.func.php /var/www/html/svnadmin/classes/util/global.func.php

# Fix for Websvn diff tool
ADD native.php /var/www/html/websvn/lib/pear/Text/Diff/Engine/native.php
ADD Diff.php /var/www/html/websvn/lib/pear/Text/Diff.php

#ssh enabled
RUN mkdir /var/run/sshd
RUN echo 'root:gotechnies' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN  sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/g' /etc/ssh/sshd_config
# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

COPY create_svn.sh  ./websvn/create_svn.sh
RUN chmod +x ./websvn/create_svn.sh

# Ports
EXPOSE 80
EXPOSE 443
EXPOSE 22
CMD ["/usr/bin/supervisord"]
