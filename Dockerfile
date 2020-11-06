FROM bitnami/minideb:buster

RUN apt-get update && apt-get install --no-install-recommends -y \
    ca-certificates curl sudo openssh-server bash git \
    # Install packages you need for your dev environment, e.g.:
    # make cmake llvm clang && \
    && \
    apt autoremove -y

# Setup your SSH server daemon, copy pre-generated keys
RUN rm -rf /etc/ssh/ssh_host_*_key*
COPY etc/ssh/sshd_config /etc/ssh/sshd_config

ARG USER
RUN test -n "$USER"

# passwordless sudo for your user's group
RUN echo "%${USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Create your user
RUN useradd -m -s /bin/bash ${USER}

USER ${USER}

# Copy ssh authorized keys
COPY home/.ssh/authorized_keys /home/${USER}/.ssh/authorized_keys

USER root

ENV USER_ARG=${USER}

COPY ./entrypoint ./entrypoint

ENTRYPOINT ["./entrypoint"]

CMD ["/usr/sbin/sshd", "-D"]