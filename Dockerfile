FROM quay.io/podman/stable:v5.8.7

ENV USER=jerry

# WARNING: ip and nsenter are GTFOBins — sudo access is intentional for lab use only
RUN echo 'root:$6$gKoDlHAH5/mfa4N5$q/WZ0ws.E9Xcvw6.AS/EMvY2Fk3b7n2iNqXrK2PPFJBLk9xjPIhHH3js6.n2MqymMYTv2c2OFOWaz8lx5PLc10' | chpasswd -e && \
    useradd -m $USER && \
    passwd -d $USER && \
    echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/unshare" >> /etc/sudoers && \
    echo "$USER ALL=(ALL) NOPASSWD: /usr/sbin/ip" >> /etc/sudoers && \
    echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/nsenter --net=*" >> /etc/sudoers && \
    echo "$USER ALL=(ALL) NOPASSWD: /usr/sbin/iptables" >> /etc/sudoers

RUN dnf install -y tmux procps-ng hostname iputils iproute which fish nmap-ncat && \
    dnf clean all

COPY --chown=$USER:$USER lab /home/$USER/lab

RUN bash /home/$USER/lab/Ch/get_alpine.sh && \
    chown -R $USER:$USER /home/$USER/lab/Ch/alpine && \
    chown root:root /home/$USER/lab/flag_public /home/$USER/lab/flag_private && \
    chmod 666 /home/$USER/lab/flag_public /home/$USER/lab/flag_private

COPY config/tmux.conf /etc/tmux.conf

COPY config/ps1.sh /etc/lab-ps1.sh
RUN echo "source /etc/lab-ps1.sh" >> /root/.bashrc && \
    echo "source /etc/lab-ps1.sh" >> /home/$USER/.bashrc

COPY tmux-launch.sh /tmux-launch.sh
COPY flag-writer.sh /flag-writer.sh
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /tmux-launch.sh /flag-writer.sh /entrypoint.sh

USER $USER
WORKDIR /home/$USER

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]
