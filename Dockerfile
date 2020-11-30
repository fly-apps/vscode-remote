FROM ubuntu:bionic

ARG EXTRA_PKGS

RUN apt-get update && apt-get install --no-install-recommends -y \
    ca-certificates curl sudo openssh-server bash git \
    iproute2 apt-transport-https gnupg-agent software-properties-common \
    # Install extra packages you need for your dev environment
    ${EXTRA_PKGS} && \
    apt autoremove -y

ARG USER
RUN test -n "$USER"

# Create your user
RUN adduser --disabled-password --gecos '' --home /data/home ${USER}
# passwordless sudo for your user's group
RUN echo "%${USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

ENV USER_ARG=${USER}

ARG USE_DOCKER
RUN if [ -n "${USE_DOCKER}" ] ; then \
    apt-get install --no-install-recommends -y iptables libdevmapper1.02.1 \
    && curl https://download.docker.com/linux/ubuntu/dists/bionic/pool/stable/amd64/containerd.io_1.3.7-1_amd64.deb --output containerd.deb \
    && dpkg -i containerd.deb \
    && rm containerd.deb \
    && curl https://download.docker.com/linux/ubuntu/dists/bionic/pool/stable/amd64/docker-ce-cli_19.03.12~3-0~ubuntu-bionic_amd64.deb --output docker-cli.deb \
    && dpkg -i docker-cli.deb \
    && rm docker-cli.deb \
    && curl https://download.docker.com/linux/ubuntu/dists/bionic/pool/stable/amd64/docker-ce_19.03.13~3-0~ubuntu-bionic_amd64.deb --output docker.deb \
    && dpkg -i docker.deb \
    && rm docker.deb \
    && usermod -aG docker ${USER} \
    && curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
    && chmod +x usr/local/bin/docker-compose \
    ; fi

ENV USE_DOCKER=${USE_DOCKER}

# Setup your SSH server daemon, copy pre-generated keys
RUN rm -rf /etc/ssh/ssh_host_*_key*
COPY etc/ssh/sshd_config /etc/ssh/sshd_config

COPY ./entrypoint ./entrypoint
COPY ./docker-entrypoint.d/* ./docker-entrypoint.d/

ENTRYPOINT ["./entrypoint"]

CMD ["/usr/sbin/sshd", "-D"]