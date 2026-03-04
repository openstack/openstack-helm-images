ARG FROM=quay.io/airshipit/ubuntu:jammy
FROM --platform=${BUILDPLATFORM} ${FROM}

ARG TARGETOS
ARG TARGETARCH

ARG VENV=/opt/nagios_venv
ENV PATH=${VENV}/bin:$PATH

ENV APACHE_FRONTEND_PORT=8000
ENV APACHE_FRONTEND_SECURE_PORT=8443
ENV KUBE_VERSION=1.34.5
ENV ES_VERSION=8.19.3
ENV ES_DSL_VERSION=8.18.0

ENV NAGIOSADMIN_EMAIL=nagios@localhost
ENV NAGIOS_HOME=/opt/nagios
ENV NAGIOS_PLUGIN_DIR=/usr/lib/nagios/plugins
ENV VERSION=4.5.11

ENV DEBIAN_FRONTEND=noninteractive

RUN set -ex \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --install-recommends \
         ca-certificates \
         jq \
         curl \
         snmp \
         snmpd \
         unzip \
         apache2 \
         pkg-config \
         build-essential \
         libssl-dev \
         checkinstall \
         libapache2-mod-php \
         snmp-mibs-downloader \
    && apt-get install -y --no-install-recommends \
         python3-pip \
         python3-venv \
         python3-requests \
         monitoring-plugins \
    && python3 -m venv ${VENV} \
    && pip3 install --upgrade --no-cache-dir pip \
    && pip3 install --upgrade --no-cache-dir \
         requests \
         setuptools \
         kubernetes \
         elasticsearch==${ES_VERSION} \
         elasticsearch-dsl==${ES_DSL_VERSION} \
    && curl --silent -L https://dl.k8s.io/v${KUBE_VERSION}/kubernetes-client-${TARGETOS}-${TARGETARCH}.tar.gz \
       | tar -zC /usr/bin --strip-components=3 --wildcards -x "*/*/*/kubectl" \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -g 3000 nagios \
    && useradd -u 3000 -g nagios -d ${NAGIOS_HOME} -s /bin/bash -c 'Nagios Admin' nagios \
    && adduser www-data nagios

RUN set -ex \
    && cd ${TMP_DIR} \
    && curl --silent -L https://assets.nagios.com/downloads/nagioscore/releases/nagios-${VERSION}.tar.gz \
       | tar -zx --strip-components=1 \
    && ./configure --prefix=${NAGIOS_HOME} \
                   --with-nagios-user=nagios \
                   --with-nagios-group=nagios \
                   --with-command-user=nagios \
                   --with-command-group=nagios \
                   --with-lockfile=/var/run/nagios.lock \
    && make all \
    && make install \
    && make install-init \
    && make install-config \
    && make install-commandmode \
    && make install-webconf \
    && rm -rf ${TMP_DIR}

COPY apache2/sites-available/* /etc/apache2/sites-available/
COPY apache2/ports.conf /etc/apache2/

RUN a2ensite nagios && a2enmod cgi && a2dissite 000-default

COPY scripts/entrypoint.sh /entrypoint.sh
COPY plugins/* ${NAGIOS_PLUGIN_DIR}/
COPY scripts/snmp-mibs/* /usr/share/snmp/mibs/

EXPOSE ${APACHE_FRONTEND_PORT}/tcp
EXPOSE ${APACHE_FRONTEND_SECURE_PORT}/tcp

ENTRYPOINT ["/entrypoint.sh"]
