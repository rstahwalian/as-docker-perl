FROM debian:11
LABEL MAINTAINER="Ahwalian M <ahwalian@rschooltoday.com>"

ARG PERLBREW_ROOT=/usr/local/perl
ARG PERL_VERSION=5.14.4
# Enable perl build options. Example: --build-arg PERL_BUILD="--thread --debug"
ARG PERL_BUILD=--thread

RUN apt-get update
RUN apt-get install -y perl bzip2 zip curl
RUN apt-get install -y build-essential procps
RUN apt-get install -y apache2 nano gcc wget libcgi-pm-perl libdbi-perl
RUN apt-get install -y perl-doc libpath-tiny-perl cpanminus
RUN apt-get install -y librest-client-perl libxml-parser-perl
RUN apt-get install -y openssl libssl-dev libnet-ssleay-perl libcrypt-ssleay-perl
RUN apt-get install -y zlib1g-dev libexpat1-dev default-libmysqlclient-dev 

RUN apt-get install -y tzdata
# Set timezone to be CST6CDT or America/Chicago
ENV TZ="America/Chicago"

#RUN apt-get install -y imagemagick perlmagick libimage-magick-perl

RUN apt-get install -y git
## Install ImageMagick
RUN pwd
RUN cd /usr/local/share/
RUN git clone -b '7.1.1-43' --depth 1 https://github.com/ImageMagick/ImageMagick.git ImageMagick
RUN cd ImageMagick && ./configure && make && make install && ldconfig /usr/local/lib

# RUN wget https://imagemagick.org/archive/ImageMagick.tar.gz
# RUN tar -xvzf ImageMagick.tar.gz
# RUN rm ImageMagick.tar.gz
# RUN cd ImageMagick-7.1.1-43 && ./configure && make && make install && ldconfig /usr/local/lib

# Install PerlBrew
RUN mkdir -p $PERLBREW_ROOT
RUN bash -c '\curl -L https://install.perlbrew.pl | bash'
ENV PATH $PERLBREW_ROOT/bin:$PATH
ENV PERLBREW_PATH $PERLBREW_ROOT/bin
RUN perlbrew --notest install $PERL_BUILD perl-$PERL_VERSION
RUN perlbrew install-cpanm
RUN bash -c 'source $PERLBREW_ROOT/etc/bashrc'

ENV PERLBREW_ROOT $PERLBREW_ROOT
ENV PATH $PERLBREW_ROOT/perls/perl-$PERL_VERSION/bin:$PATH
ENV PERLBREW_PERL perl-$PERL_VERSION
ENV PERLBREW_MANPATH $PELRBREW_ROOT/perls/perl-$PERL_VERSION/man
ENV PERLBREW_SKIP_INIT 1

RUN ln -s $PERLBREW_ROOT/perls/perl-$PERL_VERSION/bin/perl /usr/local/bin/perl

RUN cpanm --notest Archive::Zip
RUN cpanm --notest CGI
RUN cpanm --notest CGI::Enurl
RUN cpanm --notest Crypt::RC4
RUN cpanm --notest Crypt::TripleDES
RUN cpanm --notest Crypt::SSLeay
RUN cpanm --notest Data::Dumper
RUN cpanm --notest Data::Printer
RUN cpanm --notest Data::ICal
RUN cpanm --notest Data::ICal::TimeZone
RUN cpanm --notest Date::Calc
RUN cpanm --notest Date::ICal
RUN cpanm --notest Date::Manip
RUN cpanm --notest Date::Format
RUN cpanm --notest DBD::mysql@4.050
RUN cpanm --notest ExtUtils::Installed
RUN cpanm --notest HTML::CalendarMonth
RUN cpanm --notest HTTP::Cookies
RUN cpanm --notest HTML::TreeBuilder
RUN cpanm --notest HTML::Parser
RUN cpanm --notest HTML::FormatText
RUN cpanm --notest Image::Magick
RUN cpanm --notest REST::Client
RUN cpanm --notest JSON
RUN cpanm --notest LWP::UserAgent
RUN cpanm --notest MIME::Entity
RUN cpanm --notest MIME::Tools
RUN cpanm --notest Net::SMTP
RUN cpanm --notest Net::SMTP_auth
RUN cpanm --notest Spreadsheet::WriteExcel
RUN cpanm --notest Spreadsheet::ParseExcel
RUN cpanm --notest Text::CSV
RUN cpanm --notest Text::CSV_XS
RUN cpanm --notest URI@1.74
RUN cpanm --notest WWW::Mailgun
RUN cpanm --notest XML::Generator
RUN cpanm --notest XML::NamespaceSupport
RUN cpanm --notest XML::SAX
RUN cpanm --notest XML::SAX::Base
RUN cpanm --notest XML::SAX::Expat
RUN cpanm --notest XML::Simple
RUN cpanm --notest XML::XPath
RUN cpanm --notest Crypt::Bcrypt
RUN cpanm --notest Spreadsheet::XLSX
RUN cpanm --notest Spreadsheet::ParseXLSX

RUN apt-get install -y libapache2-mod-php
RUN apt-get install -y default-mysql-client

RUN wget -c https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem && mv global-bundle.pem /etc/ssl/certs/

RUN a2enmod rewrite cgi
RUN a2dissite 000-default
RUN a2enmod proxy_http
COPY apache2/ /etc/apache2
EXPOSE 80
WORKDIR /var/www

CMD ["/usr/sbin/apachectl", "-D", "FOREGROUND"]
