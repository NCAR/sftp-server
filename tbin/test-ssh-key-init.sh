#!/bin/sh
if [ ":$1" = ":--help" ] ; then
    exit 0
fi
TESTDIR=`cd \`dirname $0\`; pwd`
cd $TESTDIR

. ../../sweet/lib/shtest/init.rc

SSH_KEY_INIT=${TESTDIR}/../sbin/ssh-key-init
SSH_KEYGEN=${TESTDIR}/mock-ssh-keygen export SSH_KEYGEN
KEYDIR=${TMPDIR}/keys
PUBDIR=${TMPDIR}/pub
mkdir -p ${KEYDIR} ${PUBDIR}

DEFINE_TEST "given no args, ssh-key-init errors"
RUN ${SSH_KEY_INIT}
if gotExpectedOutput --error --contains " -c|--client or -s|--server is required" &&
   gotExpectedOutput --retval 1
then
    SUCCESS
else
    FAILURE
fi

DEFINE_TEST "given -h, ssh-key-init prints help"
RUN ${SSH_KEY_INIT} -h
if gotExpectedOutput --contains "NAME" ; then
    SUCCESS
else
    FAILURE
fi

DEFINE_TEST "given --help, ssh-key-init prints help"
RUN ${SSH_KEY_INIT} --help
if gotExpectedOutput --contains "NAME" ; then
    SUCCESS
else
    FAILURE
fi

DEFINE_TEST "given invalid option, ssh-key-init errors"
RUN ${SSH_KEY_INIT} -x
if gotExpectedOutput --error --contains "invalid option" &&
   gotExpectedOutput --retval 1
then
    SUCCESS
else
    FAILURE
fi

DEFINE_TEST "given incompatible options, ssh-key-init errors"
RUN ${SSH_KEY_INIT} -c name -s
if gotExpectedOutput --error --contains "only one of" &&
   gotExpectedOutput --retval 1
then
    SUCCESS
else
    FAILURE
fi

DEFINE_TEST "given -a without -c, ssh-key-init errors"
RUN ${SSH_KEY_INIT} -a /tmp/authorized_keys -s
if gotExpectedOutput --error --contains "auth-keys requires -c" &&
   gotExpectedOutput --retval 1
then
    SUCCESS
else
    FAILURE
fi

DEFINE_TEST "given -k without -s, ssh-key-init errors"
RUN ${SSH_KEY_INIT} -k /tmp/known_hosts -c client
if gotExpectedOutput --error --contains "known-hosts requires -s" &&
   gotExpectedOutput --retval 1
then
    SUCCESS
else
    FAILURE
fi

DEFINE_TEST "given -c but no dir, ssh-key-init errors"
RUN ${SSH_KEY_INIT} -c client
if gotExpectedOutput --error --contains "key_dir argument is required" &&
   gotExpectedOutput --retval 1
then
    SUCCESS
else
    FAILURE
fi

DEFINE_TEST "given -s but no dir, ssh-key-init errors"
RUN ${SSH_KEY_INIT} -s
if gotExpectedOutput --error --contains "key_dir argument is required" &&
   gotExpectedOutput --retval 1
then
    SUCCESS
else
    FAILURE
fi

mkdir ${TMPDIR}/baddir
chmod 555 ${TMPDIR}/baddir
DEFINE_TEST "given -a and -c, ssh-key-init accepts opts"
RUN ${SSH_KEY_INIT} -a ./authkeys -c client ${TMPDIR}/baddir/notcreatable
if gotExpectedOutput --error --contains "Permission denied" &&
   gotExpectedOutput --retval 1
then
    SUCCESS
else
    FAILURE
fi

DEFINE_TEST "given -k and -s, ssh-key-init accepts opts"
RUN ${SSH_KEY_INIT} -k ./kh -s ${TMPDIR}/baddir/notcreatable
if gotExpectedOutput --error --contains "Permission denied" &&
   gotExpectedOutput --retval 1
then
    SUCCESS
else
    FAILURE
fi

DEFINE_TEST "given -cclient, ssh-key-init creates keypairs"
RUN ${SSH_KEY_INIT} -c client ${KEYDIR}
ls -l ${KEYDIR} >$OUT
set : `ls -l ${PUBDIR} | grep -v '^total' | wc -l`
echo pubdir: $2 >>$OUT
if gotExpectedOutput --retval 0 &&
   gotExpectedOutput --regex '^-rw------- .* client-id_rsa' &&
   gotExpectedOutput --regex '^-rw-r--r-- .* client-id_rsa.pub' &&
   gotExpectedOutput --regex '^-rw------- .* client-id_ecdsa' &&
   gotExpectedOutput --regex '^-rw-r--r-- .* client-id_ecdsa.pub' &&
   gotExpectedOutput --regex '^-rw------- .* client-id_ed25519' &&
   gotExpectedOutput --regex '^-rw-r--r-- .* client-id_ed25519.pub' &&
   gotExpectedOutput --regex '^pubdir: 0'
then
    SUCCESS
else
    FAILURE
fi
rm -f ${KEYDIR}/*
rm -f ${PUBDIR}/*

DEFINE_TEST "given -cclient -aauthkeys, ssh-key-init creates keypairs+authkeys"
RUN ${SSH_KEY_INIT} -a ${PUBDIR}/authorized_keys -c client ${KEYDIR}
ls -l ${KEYDIR} >$OUT
ls -l ${PUBDIR} >>$OUT
if gotExpectedOutput --retval 0 &&
   gotExpectedOutput --regex '^-rw------- .* client-id_rsa' &&
   gotExpectedOutput --regex '^-rw-r--r-- .* client-id_rsa.pub' &&
   gotExpectedOutput --regex '^-rw------- .* client-id_ecdsa' &&
   gotExpectedOutput --regex '^-rw-r--r-- .* client-id_ecdsa.pub' &&
   gotExpectedOutput --regex '^-rw------- .* client-id_ed25519' &&
   gotExpectedOutput --regex '^-rw-r--r-- .* client-id_ed25519.pub' &&
   gotExpectedOutput --regex '^-rw-r--r-- .* authorized_keys'
then
    SUCCESS
else
    FAILURE
fi
rm -f ${KEYDIR}/*
rm -f ${PUBDIR}/*

DEFINE_TEST "given -s, ssh-key-init creates keypairs"
RUN ${SSH_KEY_INIT} -s ${KEYDIR}
ls -l ${KEYDIR} >$OUT
set : `ls -l ${PUBDIR} | grep -v '^total' | wc -l`
echo pubdir: $2 >>$OUT
if gotExpectedOutput --retval 0 &&
   gotExpectedOutput --regex '^-rw------- .* ssh_host_rsa_key' &&
   gotExpectedOutput --regex '^-rw-r--r-- .* ssh_host_rsa_key.pub' &&
   gotExpectedOutput --regex '^-rw------- .* ssh_host_ecdsa_key' &&
   gotExpectedOutput --regex '^-rw-r--r-- .* ssh_host_ecdsa_key.pub' &&
   gotExpectedOutput --regex '^-rw------- .* ssh_host_ed25519_key' &&
   gotExpectedOutput --regex '^-rw-r--r-- .* ssh_host_ed25519_key.pub' &&
   gotExpectedOutput --regex '^pubdir: 0'
then
    SUCCESS
else
    FAILURE
fi
rm -f ${KEYDIR}/*
rm -f ${PUBDIR}/*

rm -rf ${TMPDIR}/nosuch
DEFINE_TEST "given dir arg that is not a directory, ssh-key-init creates it"
RUN ${SSH_KEY_INIT} -s $TMPDIR/nosuch
if gotExpectedOutput --retval 0 &&
   [ -d ${TMPDIR}/nosuch ]
then
    SUCCESS
else
    FAILURE
fi
rm -f ${KEYDIR}/*
rm -f ${PUBDIR}/*

DEFINE_TEST "given -s -kknown_hosts, ssh-key-init creates keypairs+knownhosts"
RUN ${SSH_KEY_INIT} -s -k ${PUBDIR}/known_hosts ${KEYDIR}
ls -l ${KEYDIR} >$OUT
ls -l ${PUBDIR} >>$OUT
if gotExpectedOutput --retval 0 &&
   gotExpectedOutput --regex '^-rw------- .* ssh_host_rsa_key' &&
   gotExpectedOutput --regex '^-rw-r--r-- .* ssh_host_rsa_key.pub' &&
   gotExpectedOutput --regex '^-rw------- .* ssh_host_ecdsa_key' &&
   gotExpectedOutput --regex '^-rw-r--r-- .* ssh_host_ecdsa_key.pub' &&
   gotExpectedOutput --regex '^-rw------- .* ssh_host_ed25519_key' &&
   gotExpectedOutput --regex '^-rw-r--r-- .* ssh_host_ed25519_key.pub' &&
   gotExpectedOutput --regex '^-rw-r--r-- .* known_hosts'
then
    SUCCESS
else
    FAILURE
fi
rm -f ${KEYDIR}/*
rm -f ${PUBDIR}/*

. cleanup.rc
