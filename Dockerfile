FROM quay.io/podman/stable:v5.8.7

COPY depth /depth
RUN echo $(($(cat /depth) + 1)) > /depth

ENV USER=jerry

# WARNING: ip and nsenter are GTFOBins — sudo access is intentional for lab use only
RUN echo 'root:$6$gKoDlHAH5/mfa4N5$q/WZ0ws.E9Xcvw6.AS/EMvY2Fk3b7n2iNqXrK2PPFJBLk9xjPIhHH3js6.n2MqymMYTv2c2OFOWaz8lx5PLc10' | chpasswd -e && \
    useradd -m $USER && \
    passwd -d $USER && \
    echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/unshare" >> /etc/sudoers && \
    echo "$USER ALL=(ALL) NOPASSWD: /usr/sbin/ip" >> /etc/sudoers && \
    echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/nsenter --net=*" >> /etc/sudoers && \
    echo "$USER ALL=(ALL) NOPASSWD: /usr/sbin/nft" >> /etc/sudoers

RUN dnf install -y tmux procps-ng hostname iputils iproute which fish nmap-ncat nftables && \
    dnf clean all

COPY --chown=$USER:$USER lab /home/$USER/lab

RUN bash /home/$USER/lab/Ch/get_alpine.sh && \
    chown -R $USER:$USER /home/$USER/lab/Ch/alpine

COPY config/tmux.conf /etc/tmux.conf

COPY config/ps1.sh /etc/lab-ps1.sh
RUN echo "source /etc/lab-ps1.sh" >> /root/.bashrc && \
    echo "source /etc/lab-ps1.sh" >> /home/$USER/.bashrc

# Dockerfile stays in layer
COPY Dockerfile /Dockerfile
RUN base64 Dockerfile >> Dockerfile.base64 && \
    rm Dockerfile

COPY tmux-launch.sh /tmux-launch.sh
COPY helper-B.sh /helper-B.sh
COPY helper-C.sh /helper-C.sh
COPY entrypoint.sh /entrypoint.sh
RUN cp /tmux-launch.sh /home/$USER/tmux-launch.sh && \
    chown $USER:$USER /home/$USER/tmux-launch.sh && \
    chmod +x /tmux-launch.sh /home/$USER/tmux-launch.sh /helper-B.sh /helper-C.sh /entrypoint.sh

# Expose build-context pieces in ~ so jerry can rebuild the image from home
RUN mkdir -p /home/$USER/config && \
    ln -s /etc/tmux.conf        /home/$USER/config/tmux.conf && \
    ln -s /etc/lab-ps1.sh       /home/$USER/config/ps1.sh && \
    ln -s /helper-B.sh          /home/$USER/helper-B.sh && \
    ln -s /helper-C.sh          /home/$USER/helper-C.sh && \
    ln -s /entrypoint.sh        /home/$USER/entrypoint.sh && \
    ln -s /Dockerfile.base64    /home/$USER/Dockerfile.base64 && \
    chown -h $USER:$USER /home/$USER/config /home/$USER/config/* \
                         /home/$USER/helper-B.sh /home/$USER/helper-C.sh \
                         /home/$USER/entrypoint.sh /home/$USER/Dockerfile.base64

USER $USER
WORKDIR /home/$USER

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]
