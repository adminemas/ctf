FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tashkent

# Kerakli tizim paketlari va utilitalar
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-server \
    sudo \
    cron \
    at \
    sqlite3 \
    openssl \
    python3 \
    python3-pip \
    git \
    curl \
    net-tools \
    iproute2 \
    diffutils \
    coreutils \
    gawk \
    sed \
    procps \
    supervisor \
    locales \
    ca-certificates \
    bsdextrautils \
    && rm -rf /var/lib/apt/lists/*

# UTF-8 Locale sozlash
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# python-telegram-bot kutubxonasi
RUN pip3 install --no-cache-dir --break-system-packages "python-telegram-bot==21.6"

# OpenSSH Server sozlamalari (parol orqali kirishni yoqish va Docker PAM ni to'g'rilash)
RUN mkdir -p /var/run/sshd \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd

# Loyihani ko'chirish
WORKDIR /opt/ctf
COPY . /opt/ctf/

# O'rnatish skriptlarini sozlash
RUN chmod +x /opt/ctf/install.sh /opt/ctf/docker/entrypoint.sh \
    && bash /opt/ctf/install.sh

# Portlar: SSH (22), Web Dashboard (8080)
EXPOSE 22 8080

ENTRYPOINT ["/opt/ctf/docker/entrypoint.sh"]
