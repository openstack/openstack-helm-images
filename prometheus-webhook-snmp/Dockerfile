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

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.url="https://github.com/SUSE/prometheus-webhook-snmp" \
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
            git

RUN git clone -b v${VERSION} --single-branch --depth 1 https://github.com/SUSE/prometheus-webhook-snmp.git

RUN    pip3 --no-cache-dir install --upgrade setuptools && \
    pip3 --no-cache-dir install -r /prometheus-webhook-snmp/requirements.txt


ENV RUN_ARGS=""

EXPOSE 9099

ENTRYPOINT [ "/prometheus-webhook-snmp/prometheus-webhook-snmp", "run" ]

