ARG FROM=docker.io/ubuntu:bionic
FROM ${FROM}

ENV PYTHONUNBUFFERED 1
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PIP_NO_CACHE_DIR=1
# ensure local python is preferred over distribution python
ENV PATH /usr/local/bin:$PATH
# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV LANG C.UTF-8

LABEL maintainer="Openstack-image Authors"

ARG BUILD_DATE=now
ARG VCS_REF
ARG VCS_URL
ARG VERSION

ARG SERVER_VERSION=8.0.2
ARG CLIENT_VERSION=8.0.0
ARG WEBUI_VERSION=8.0.0

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.url="https://alerta.io" \
      org.label-schema.vcs-url=$VCS_URL \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.version=$VERSION

RUN apt-get -y update && apt-get -y upgrade && apt-get -y install --no-install-recommends \
            curl \
            wget \
            gcc \
            python3.7 \
            python3-pip \
            python3-venv \
            nginx-light \
            postgresql-client \
            supervisor \
            gnupg2 \
            gettext-base \
            libffi-dev \
            libldap2-dev \
            libpq-dev \
            libsasl2-dev \
            python3-dev

# SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=DL3008
# RUN curl -fsSL https://www.mongodb.org/static/pgp/server-4.4.asc | apt-key add - && \
#     echo "deb https://repo.mongodb.org/apt/debian buster/mongodb-org/4.4 main" | tee /etc/apt/sources.list.d/mongodb-org-4.4.list && \
#     apt-get -y clean && \
#     apt-get -y autoremove && \
#     rm -rf /var/lib/apt/lists/*


COPY requirements.txt /app/requirements.txt
# hadolint ignore=DL3013
RUN pip3 --no-cache-dir install pip virtualenv && \
    python3 -m venv /venv && \
    /venv/bin/pip --no-cache-dir install --upgrade setuptools && \
    /venv/bin/pip --no-cache-dir install -r /app/requirements.txt

ENV PATH $PATH:/venv/bin

RUN /venv/bin/pip --no-cache-dir install alerta==${CLIENT_VERSION} alerta-server==${SERVER_VERSION}

ENV ALERTA_SVR_CONF_FILE /app/alertad.conf
ENV ALERTA_CONF_FILE /app/alerta.conf

ADD https://github.com/alerta/alerta-webui/releases/download/v${WEBUI_VERSION}/alerta-webui.tar.gz /tmp/webui.tar.gz
RUN tar zxvf /tmp/webui.tar.gz -C /tmp && \
    mv /tmp/dist /web
COPY config.json /web/config.json

COPY wsgi.py /app/wsgi.py
COPY uwsgi.ini /app/uwsgi.ini
COPY nginx.conf /app/nginx.conf

RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

RUN chgrp -R 0 /app /venv /web && \
    chmod -R g=u /app /venv /web && \
    useradd -u 1001 -g 0 alerta

USER 1001

ENV HEARTBEAT_SEVERITY major

COPY docker-entrypoint.sh /usr/local/bin/
COPY supervisord.conf /app/supervisord.conf

ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 8080
CMD ["supervisord", "-c", "/app/supervisord.conf"]
