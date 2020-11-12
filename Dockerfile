FROM ubuntu:20.04
RUN apt-get update
RUN apt-get -y install python \
             wget \
             bash \
             net-tools \
             netbase \
             strace \
             iproute2 \
             iputils-ping \
             pciutils \
             vim
RUN wget http://trex-tgn.cisco.com/trex/release/v2.85.tar.gz && \
    tar -zxvf v2.85.tar.gz -C / && \
    chown root:root /v2.85  && \
    rm v2.85.tar.gz
#COPY trex_cfg_cat9k.yaml /etc/trex_cfg_cat9k.yaml
WORKDIR /v2.85
CMD ["/bin/bash"]
#CMD ["./t-rex-64", "-i"]
#CMD ["./t-rex-64", "-i", "--cfg", "/etc/trex_cfg_cat9k.yaml"]
