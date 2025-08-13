FROM --platform=$BUILDPLATFORM tonistiigi/xx:1.6.1 AS xx

FROM --platform=$BUILDPLATFORM debian:10 AS build

LABEL MAINTAINER="Ahwalian Masykur <ahwalian@rschooltoday.com>"

ENV DEBIAN_FRONTEND=noninteractive

# Import cross toolchain and setup env vars
COPY --from=xx / /

RUN sed -i 's|deb.debian.org|archive.debian.org|g' /etc/apt/sources.list && \
    sed -i '/security.debian.org/d' /etc/apt/sources.list && \
    echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99disable-check-valid-until
    
# Install build and runtime dependencies, clean up apt cache in one layer
RUN apt-get update && apt-get install -y \
    autoconf \
    bash \
    bison \
    build-essential \
    ca-certificates \
    clang \
    cpanminus \
    curl \
    default-libmysqlclient-dev \
    default-mysql-client \
    git \
    libatomic1 \
    libcurl4-openssl-dev \
    libcgi-pm-perl \
    libcrypt-ssleay-perl \
    libdate-manip-perl \
    libdbi-perl \
    libexpat1-dev \
    libimage-magick-perl \
    libmagickcore-dev libmagickwand-dev libpng-dev \
    libonig-dev \
    libpcre3-dev \
    libperl-dev \
    librest-client-perl \
    libsqlite3-dev \
    libssl-dev \
    libhiredis-dev \
    libtool \
    libxml-simple-perl \
    libxml2-dev \
    libxslt1-dev \
    libzip-dev \
    nano \
    pkg-config \
    procps \
    re2c \
    redis-tools \
    tzdata \
    wget \
    zlib1g-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN xx-info

# Define versions
ARG APACHE_VERSION=2.4.65
ARG MOD_PERL_VERSION=2.0.13
ARG PHP_VERSION=8.4.7
ARG APR_VERSION=1.7.6
ARG APR_UTIL_VERSION=1.6.3

WORKDIR /build

# Download and build Apache with prefork MPM
RUN wget https://downloads.apache.org/httpd/httpd-${APACHE_VERSION}.tar.gz && \
    wget https://downloads.apache.org/apr/apr-${APR_VERSION}.tar.gz && \
    wget https://downloads.apache.org/apr/apr-util-${APR_UTIL_VERSION}.tar.gz && \
    tar xzf httpd-${APACHE_VERSION}.tar.gz && \
    tar xzf apr-${APR_VERSION}.tar.gz && \
    tar xzf apr-util-${APR_UTIL_VERSION}.tar.gz && \
    mv apr-${APR_VERSION} httpd-${APACHE_VERSION}/srclib/apr && \
    mv apr-util-${APR_UTIL_VERSION} httpd-${APACHE_VERSION}/srclib/apr-util && \
    cd httpd-${APACHE_VERSION} && \
    ./configure --enable-so --enable-cgi --enable-mods-shared=all --with-included-apr --with-mpm=prefork && \
    make -j$(nproc) && make install

# Build mod_perl with Registry and RegistryPrefork support
RUN wget https://downloads.apache.org/perl/mod_perl-${MOD_PERL_VERSION}.tar.gz && \
    tar xzf mod_perl-${MOD_PERL_VERSION}.tar.gz && \
    cd mod_perl-${MOD_PERL_VERSION} && \
    /usr/bin/perl Makefile.PL MP_APXS=/usr/local/apache2/bin/apxs MP_USE_DSO=1 && \
    make -j$(nproc) && make install

RUN ln -sf /usr/bin/perl /usr/local/bin/perl

# Build PHP
RUN wget https://www.php.net/distributions/php-${PHP_VERSION}.tar.gz && \
    tar xzf php-${PHP_VERSION}.tar.gz && \
    cd php-${PHP_VERSION} && \
    ./configure --with-apxs2=/usr/local/apache2/bin/apxs \
        --with-mysqli --with-zlib --enable-mbstring --with-xsl --with-openssl && \
    make -j$(nproc) && make install

# Clean up build artifacts
RUN cd / && rm -rf /build

# Install ImageMagick from source and clean up
RUN mkdir -p /usr/local/share && cd /usr/local/share && \
    git clone --depth 1 https://github.com/ImageMagick/ImageMagick.git ImageMagick && \
    cd ImageMagick && ./configure -with-perl && make && make install && ldconfig /usr/local/lib && \
    cd / && rm -rf /usr/local/share/ImageMagick

ENV TZ="America/Chicago"

# Install all Perl modules in one layer
RUN cpanm --notest \
    Archive::Zip \
    Authen::SASL \
    Carp::Clan \
    Redis \
    CGI \
    CGI::Session \
    CGI::Session::Driver::redis \
    CGI::Enurl \
    CGI::HTMLError \
    Class::ReturnValue \
    Class::Singleton \
    Crypt::Bcrypt \
    Crypt::RC4 \
    Crypt::TripleDES \
    Crypt::SSLeay \
    Data::Dumper \
    Data::Printer \
    Data::ICal \
    Data::ICal::TimeZone \
    Date::Calc \
    Date::ICal \
    Date::Leapyear \
    Date::Manip \
    Date::Format \
    DBD::mysql@4.050 \
    Digest::HMAC \
    Digest::Perl::MD5 \
    Graphics::ColorUtils \
    ExtUtils::Installed \
    HTML::CalendarMonth \
    HTTP::Cookies \
    HTTP::Date \
    HTML::TreeBuilder \
    HTML::Parser \
    HTML::FormatText \
    HTTP::Message \
    IO::Socket::SSL \
    Image::Magick \
    OLE::Storage_Lite \
    Params::Validate \
    REST::Client \
    JSON \
    LWP::UserAgent \
    MailTools \
    MIME::Entity \
    MIME::Tools \
    Net::HTTP \
    Net::SMTP \
    Net::SMTP_auth \
    Net::SSLeay \
    Spreadsheet::WriteExcel \
    Spreadsheet::ParseExcel \
    Text::CSV \
    Text::CSV_XS \
    Try::Tiny \
    URI \
    WWW::Mailgun \
    XML::Generator \
    XML::NamespaceSupport \
    XML::SAX \
    XML::SAX::Base \
    XML::SAX::Expat \
    XML::Simple \
    XML::XPath \
    Spreadsheet::XLSX \
    Spreadsheet::ParseXLSX \
    Spreadsheet::WriteExcel

# Install AWS RDS global SSL cert
RUN wget -c https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem -O /etc/ssl/certs/global-bundle.pem

# Copy Apache configuration (ensure mod_perl RegistryPrefork is enabled in conf)
COPY apache2/conf /usr/local/apache2/conf/

WORKDIR /dwc

# Expose HTTP port
EXPOSE 80

CMD ["/usr/local/apache2/bin/httpd", "-D", "FOREGROUND"]
