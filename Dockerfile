FROM ubuntu:24.04

LABEL maintainer="n0xa"
LABEL name="chn-intel-feeds"
LABEL version="2.1.0"
LABEL release="1"
LABEL summary="Community Honey Network intel feeds server"
LABEL description="Small App for reading from a CIF instance and generating static feeds consumable via HTTP requests"
LABEL authoritative-source-url="https://github.com/n0xa/chn-intel-feeds"
LABEL changelog-url="https://github.com/n0xa/chn-intel-feeds/commits/master"

ENV DEBIAN_FRONTEND "noninteractive"

# hadolint ignore=DL3008,DL3005
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install --no-install-recommends -y python3 python3-pip python3-venv runit build-essential python3-dev\
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create virtual environment
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt /opt/requirements.txt
# hadolint ignore=DL3013
RUN pip install --upgrade pip setuptools wheel \
  && pip install -r /opt/requirements.txt \
  && pip install git+https://github.com/n0xa/hpfeeds3.git

COPY . /opt/

RUN mkdir /etc/service/chn-intel-feeds && chmod 0755 /etc/service/chn-intel-feeds
COPY chn-intel-feeds.run /etc/service/chn-intel-feeds/run
RUN chmod 0755 /etc/service/chn-intel-feeds/run

RUN mkdir /etc/service/simple-web-server && chmod 0755 /etc/service/simple-web-server
COPY simple-web-server.run /etc/service/simple-web-server/run
RUN chmod 0755 /etc/service/simple-web-server/run

RUN mkdir /etc/service/chn-intel-safelist && chmod 0755 /etc/service/chn-intel-safelist
COPY chn-intel-safelist.run /etc/service/chn-intel-safelist/run
RUN chmod 0755 /etc/service/chn-intel-safelist/run

RUN mkdir /etc/service/chn-api-feeds && chmod 0755 /etc/service/chn-api-feeds
COPY chn-api-feeds.run /etc/service/chn-api-feeds/run
RUN chmod 0755 /etc/service/chn-api-feeds/run

ENTRYPOINT ["/usr/bin/runsvdir", "-P", "/etc/service"]
