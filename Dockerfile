ARG SWEET_QUALIFIER=:latest
FROM ncar/sweet${SWEET_QUALIFIER}

RUN apt-get -y --allow-releaseinfo-change update && \
    apt-get -y install \
      dnsutils \
      openssh-server \
      rsyslog

ARG PACKAGE=sftp-server
ARG IMAGE=ncar/sftp-server
ARG IMAGE_VERSION=snapshot
ARG BRANCH=main
ARG PACKAGE_DIR=/usr/local/sftp-server
ARG LOG_LEVEL=DEBUG3

# -R makes the server read-only
#ARG SFTP_SERVER_OPTS=-R
ARG SFTP_SERVER_OPTS=

#
# The sshd/sftp server runs as $SFTPUSER:nogroup.
#
ARG SFTPUSER=sftp
ARG SFTPUSERID=901
ARG SFTPGROUP=sftp
ARG SFTPGROUPID=901

ENV SFTPUSER=${SFTPUSER} \
    SFTPUSERID=${SFTPUSERID} \
    SFTPGROUP=${SFTPGROUP} \
    SFTPGROUPID=${SFTPGROUPID} \
    SFTP_DATA=/mnt \
    NOGROUPID=65534 \
    LOG_LEVEL=${LOG_LEVEL}

#
# SFTP_DATA is the directory served via sftp. Its user:group is
#  root:${SFTPGROUP} and its permissions are 775.
# CONFIG_DIR is populated at runtime and is expected to include
#  authorized_keys; in test environments it can also include known_hosts.
# SECRETS_DIR is populated at runtime and is expected to contain all ssh key
#  files.
#

COPY sbin ${PACKAGE_DIR}/sbin/
COPY tbin ${PACKAGE_DIR}/tbin/
COPY rshbin ${PACKAGE_DIR}/rshbin/
COPY Intro.md Testing-Support.md gendoc-src ${PACKAGE_DIR}/

RUN set -e ; \
    make-local-links ${PACKAGE_DIR} /usr/local ; \
    sweet-build-init $SFTPUSERID ; \
    echo "/bin/false" >> /etc/shells ; \
    addgroup --gid ${SFTPGROUPID} ${SFTPGROUP} ; \
    adduser --disabled-password \
            --uid ${SFTPUSERID} \
            --gid ${SFTPGROUPID} \
            --gecos "SFTP user" \
            --home /home/${SFTPUSER} \
            --shell /bin/rbash \
            $SFTPUSER ; \
    usermod -G ${SFTPGROUPID} ${SWEETUSER} ; \
    ln -s /bin/ls \
          /usr/bin/printenv \
          ${PACKAGE_DIR}/rshbin/HELP \
          ${PACKAGE_DIR}/rshbin/shutdown \
                /home/${SFTPUSER} ; \
    cp ${PACKAGE_DIR}/rshbin/bashrc /home/${SFTPUSER}/.bashrc ; \
    rm -f /home/${SFTPUSER}/.bash_logout ; \
    mkdir -p /home/${SFTPUSER}/.ssh ; \
    chown ${SFTPUSER}:${SFTPGROUP} /home/${SFTPUSER}/.ssh ; \
    ln -s ${SECRETS_DIR}/known_hosts /home/${SFTPUSER}/.ssh ; \
    chown root:${SFTPGROUP} "${SFTP_DATA}" ; \
    chmod 775 "${SFTP_DATA}" ; \
    sed \
     -e "s:^[# ]*HostKey.*_rsa_.*:HostKey ${SECRETS_DIR}/ssh_host_rsa_key:" \
     -e "s:^[# ]*HostKey.*_ecdsa_.*:HostKey ${SECRETS_DIR}/ssh_host_ecdsa_key:" \
     -e "s:^[# ]*HostKey.*_ed25519_.*:HostKey ${SECRETS_DIR}/ssh_host_ed25519_key:" \
     -e "s:^[# ]*SyslogFacility.*:SyslogFacility AUTH:" \
     -e "s:^[# ]*LogLevel.*:LogLevel ${LOG_LEVEL}:" \
     -e "s:^[# ]*StrictModes.*:StrictModes no:" \
     -e "s:^[# ]*AuthorizedKeysFile.*:AuthorizedKeysFile ${SECRETS_DIR}/authorized_keys:" \
     -e "s:^[# ]*PasswordAuthentication .*:PasswordAuthentication no:" \
     -e "s:^[# ]*UsePAM.*:UsePAM no:" \
     -e "s:^[# ]*AllowAgentForwarding.*:AllowAgentForwarding no:" \
     -e "s:^[# ]*AllowTcpForwarding.*:AllowTcpForwarding no:" \
     -e "s:^[# ]*X11Forwarding.*:X11Forwarding no:" \
     -e "s:^[# ]*Subsystem.*sftp.*:Subsystem   sftp internal-sftp -d ${SFTP_DATA} ${SFTP_SERVER_OPTS}:" \
     -e "s:^[# ]*PidFile.*:PidFile /tmp/sshd.pid:" \
      /etc/ssh/sshd_config >/etc/ssh/sshd_config.new ; \
    mv /etc/ssh/sshd_config.new /etc/ssh/sshd_config ; \
    rm /etc/ssh/ssh_host*_key* ; \
    sed -e '/module(load=.imklog.)/s/^/#/' \
         /etc/rsyslog.conf >/etc/rsyslog.conf.new ; \
    mv /etc/rsyslog.conf.new /etc/rsyslog.conf
    
RUN cd $PACKAGE_DIR ; \
    /usr/local/sweet/sbin/gendoc -v >gendoc/.log 2>&1 ; \
    chown -R $SFTPUSER:$SFTPGROUP gendoc


USER $SFTPUSER

WORKDIR ${PACKAGE_DIR}

ENTRYPOINT [ "/usr/local/sweet/sbin/sweet-entrypoint.sh", "--source=/usr/local/sftp-server/sbin/sftp-sv-entrypoint.rc" ]

EXPOSE 22

#VOLUME $SFTP_DATA
#VOLUME $SECRETS_VOL
#VOLUME $SFTP_DATA

CMD [ "/usr/sbin/sshd", "-D", "-e" ]
