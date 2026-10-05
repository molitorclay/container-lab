FROM quay.io/podman/stable

ENV USER=jerry

RUN useradd -m $USER && \
    echo "$USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

RUN dnf install -y tmux procps-ng hostname && \
    dnf clean all

COPY lab /home/$USER/lab

RUN bash /home/$USER/lab/Ch/get_alpine.sh

COPY config/tmux.conf /etc/tmux.conf

COPY config/ps1.sh /etc/lab-ps1.sh
RUN echo "source /etc/lab-ps1.sh" >> /root/.bashrc && \
    echo "source /etc/lab-ps1.sh" >> /home/$USER/.bashrc

COPY tmux-launch.sh /tmux-launch.sh
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /tmux-launch.sh /entrypoint.sh

USER $USER
WORKDIR /home/$USER

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]
