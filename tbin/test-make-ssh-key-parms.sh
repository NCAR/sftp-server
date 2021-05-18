#!/bin/sh
if [ ":$1" = ":--help" ] ; then
    exit 0
fi
TESTDIR=`cd \`dirname $0\`; pwd`
cd $TESTDIR

. ../../sweet/lib/shtest/init.rc

MAKE_SSH_KEY_PARMS=${TESTDIR}/../sbin/make-ssh-key-parms

DEFINE_TEST "given -h, make-ssh-key-parms prints help"
RUN ${MAKE_SSH_KEY_PARMS} -h
if gotExpectedOutput --contains "NAME" ; then
    SUCCESS
else
    FAILURE
fi

DEFINE_TEST "given --help, make-ssh-key-parms prints help"
RUN ${MAKE_SSH_KEY_PARMS} --help
if gotExpectedOutput --contains "NAME" ; then
    SUCCESS
else
    FAILURE
fi

DEFINE_TEST "when PARM_DB not set, fail quietly"
unset PARM_DB
RUN ${MAKE_SSH_KEY_PARMS}
if noOutput --error &&
   noOutput &&
   gotExpectedOutput --retval 1
then
    SUCCESS
else
    FAILURE
fi

EXECUSER=`id -un`
touch ${TMPDIR}/${EXECUSER}-id_rsa.pub
touch ${TMPDIR}/${EXECUSER}-id_rsa
touch ${TMPDIR}/${EXECUSER}-id_ecdsa.pub
touch ${TMPDIR}/${EXECUSER}-id_ecdsa
touch ${TMPDIR}/${EXECUSER}-id_ed25519.pub
touch ${TMPDIR}/${EXECUSER}-id_ed25519

SECRETS_DIR=${TMPDIR} export SECRETS_DIR
PARM_DB=${TMPDIR}/parmdb export PARM_DB
mkdir -p ${PARM_DB}

DEFINE_TEST "given no args, when make-ssh-key-parms, parmdb update"
RUN ${MAKE_SSH_KEY_PARMS}
if noOutput --error &&
   noOutput &&
   gotExpectedOutput --retval 0 &&
   [ -f ${PARM_DB}/ID_RSA ] &&
   [ -f ${PARM_DB}/ID_RSA.txt ] &&
   [ -f ${PARM_DB}/ID_ECDSA ] &&
   [ -f ${PARM_DB}/ID_ECDSA.txt ] &&
   [ -f ${PARM_DB}/ID_ED25519 ] &&
   [ -f ${PARM_DB}/ID_ED25519.txt ]
then
    SUCCESS
else
    FAILURE
fi
#parmdb list --verbose 

. cleanup.rc ; exit 0

 DEFINE_TEST "given invalid option, make-ssh-key-parms errors"
RUN ${MAKE_SSH_KEY_PARMS} -x
if gotExpectedOutput --error --contains "invalid option" &&
   gotExpectedOutput --retval 1
then
    SUCCESS
else
    FAILURE
fi

DEFINE_TEST "given incompatible options, make-ssh-key-parms errors"
RUN ${MAKE_SSH_KEY_PARMS} -c name -s
if gotExpectedOutput --error --contains "only one of" &&
   gotExpectedOutput --retval 1
then
    SUCCESS
else
    FAILURE
fi

DEFINE_TEST "given -a without -c, make-ssh-key-parms errors"
RUN ${MAKE_SSH_KEY_PARMS} -a /tmp/authorized_keys -s
if gotExpectedOutput --error --contains "auth-keys requires -c" &&
   gotExpectedOutput --retval 1
then
    SUCCESS
else
    FAILURE
fi

DEFINE_TEST "given -k without -s, make-ssh-key-parms errors"
RUN ${MAKE_SSH_KEY_PARMS} -k /tmp/known_hosts -c client
if gotExpectedOutput --error --contains "known-hosts requires -s" &&
   gotExpectedOutput --retval 1
then
    SUCCESS
else
    FAILURE
fi

DEFINE_TEST "given -c but no dir, make-ssh-key-parms errors"
RUN ${MAKE_SSH_KEY_PARMS} -c client
if gotExpectedOutput --error --contains "key_dir argument is required" &&
   gotExpectedOutput --retval 1
then
    SUCCESS
else
    FAILURE
fi

DEFINE_TEST "given -s but no dir, make-ssh-key-parms errors"
RUN ${MAKE_SSH_KEY_PARMS} -s
if gotExpectedOutput --error --contains "key_dir argument is required" &&
   gotExpectedOutput --retval 1
then
    SUCCESS
else
    FAILURE
fi

mkdir ${TMPDIR}/baddir
chmod 555 ${TMPDIR}/baddir
DEFINE_TEST "given -a and -c, make-ssh-key-parms accepts opts"
RUN ${MAKE_SSH_KEY_PARMS} -a ./authkeys -c client ${TMPDIR}/baddir/notcreatable
if gotExpectedOutput --error --contains "Permission denied" &&
   gotExpectedOutput --retval 1
then
    SUCCESS
else
    FAILURE
fi

DEFINE_TEST "given -k and -s, make-ssh-key-parms accepts opts"
RUN ${MAKE_SSH_KEY_PARMS} -k ./kh -s ${TMPDIR}/baddir/notcreatable
if gotExpectedOutput --error --contains "Permission denied" &&
   gotExpectedOutput --retval 1
then
    SUCCESS
else
    FAILURE
fi

DEFINE_TEST "given -cclient, make-ssh-key-parms creates keypairs"
RUN ${MAKE_SSH_KEY_PARMS} -c client ${KEYDIR}
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

DEFINE_TEST "given -cclient -aauthkeys, make-ssh-key-parms creates keypairs+authkeys"
RUN ${MAKE_SSH_KEY_PARMS} -a ${PUBDIR}/authorized_keys -c client ${KEYDIR}
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

DEFINE_TEST "given -s, make-ssh-key-parms creates keypairs"
RUN ${MAKE_SSH_KEY_PARMS} -s ${KEYDIR}
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
DEFINE_TEST "given dir arg that is not a directory, make-ssh-key-parms creates it"
RUN ${MAKE_SSH_KEY_PARMS} -s $TMPDIR/nosuch
if gotExpectedOutput --retval 0 &&
   [ -d ${TMPDIR}/nosuch ]
then
    SUCCESS
else
    FAILURE
fi
rm -f ${KEYDIR}/*
rm -f ${PUBDIR}/*

DEFINE_TEST "given -s -kknown_hosts, make-ssh-key-parms creates keypairs+knownhosts"
RUN ${MAKE_SSH_KEY_PARMS} -s -k ${PUBDIR}/known_hosts ${KEYDIR}
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
