FROM ubuntu:24.04

# Use Python 3.11 for cifsdk compatibility (avoids SafeConfigParser issue)
RUN apt-get update && apt-get install -y software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && apt-get clean

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
    && apt-get install --no-install-recommends -y python3.11 python3.11-venv python3.11-dev runit build-essential git\
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create virtual environment
RUN python3.11 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt /opt/requirements.txt
# hadolint ignore=DL3013
RUN pip install --upgrade pip setuptools wheel \
  && pip install -r /opt/requirements.txt \
  && pip install twisted==26.4.0 validators==0.35.0 \
  && pip install 'cifsdk==3.0.8' \
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

# Drop root: none of the four services need privileged access. They
# only write generated feeds/safelists under /var/www and read/run
# from /opt and /etc/service (runsvdir needs write access there to
# create its per-service supervise directories at runtime), and the
# web server binds an unprivileged port (9000).
# /etc/service is a symlink chain (-> runsvdir/current -> .../default),
# so chown the resolved real directory, not the symlink itself.
RUN mkdir -p /var/www/feeds /var/www/safelists \
  && groupadd -r chn-intel-feeds && useradd -r -g chn-intel-feeds chn-intel-feeds \
  && chown -R chn-intel-feeds:chn-intel-feeds /opt /var/www "$(readlink -f /etc/service)"
USER chn-intel-feeds

ENTRYPOINT ["/usr/bin/runsvdir", "-P", "/etc/service"]
