#!/bin/sh

if [ ":$1" = ":--help" ] ; then
    exit 0
fi
if in-docker-container ; then
    execgroup=`id -gn`
    if [ ":${execgroup}" != ":${SFTPGROUP}" ] ; then
        echo "Not running in group $SFTPUSER: Skipping tests"
        exit 0
    fi
else
    echo "Not in a container: Skipping tests"
    exit 0
fi

TESTDIR=`cd \`dirname $0\`; pwd`
cd $TESTDIR

. ../../sweet/lib/shtest/init.rc

SFTP_PORT=${SFTP_PORT:=22}

TSTAMP=`tstamp`
TEST_DATA_DIR=${DATA_DIR}/sweetusertest/test-connect

DEFINE_TEST "Given \$DATA_DIR, client can create test directory"
RUN mkdir -p "${TEST_DATA_DIR}/${TSTAMP}"
ls -ld "${TEST_DATA_DIR}/${TSTAMP}" >>$OUT
if gotExpectedOutput --retval 0 &&
   gotExpectedOutput --regex "drwx.*/${TSTAMP}"
then
    SUCCESS
else
    FAILURE
fi
rm -rf ${TEST_DATA_DIR}/*

echo "${TSTAMP}" >${TEST_DATA_DIR}/testfile
echo "cd sweetusertest/test-connect" >${TMPDIR}/batch
echo "ls -l" >>${TMPDIR}/batch
echo "exit" >>${TMPDIR}/batch

DEFINE_TEST "Given file in \$DATA_DIR, sftp ls -l returns expected output"
RUN sftp -i ${ID_RSA} -b ${TMPDIR}/batch -P ${SFTP_PORT} ${SFTPUSER}@${SFTP_SERVER}
if gotExpectedOutput --retval 0 &&
   gotExpectedOutput --regex "^-rw-.* ${SWEETUSER} .* testfile"
then
    SUCCESS
else
    FAILURE
fi

echo "${TSTAMP}" >${TMPDIR}/testfile
echo "cd sweetusertest/test-connect" >${TMPDIR}/batch
echo "get testfile ${TMPDIR}/fetched-file" >>${TMPDIR}/batch
echo "exit" >>${TMPDIR}/batch

DEFINE_TEST "Given file in \$DATA_DIR, sftp get fetches file"
RUN sftp -i ${ID_RSA} -b ${TMPDIR}/batch -P ${SFTP_PORT} ${SFTPUSER}@${SFTP_SERVER}
if gotExpectedOutput --retval 0 &&
   [ -f ${TMPDIR}/fetched-file ] &&
   cmp --quiet ${TMPDIR}/testfile ${TMPDIR}/fetched-file
then
    SUCCESS
else
    FAILURE
fi


rm -rf `dirname ${TEST_DATA_DIR}`

. cleanup.rc

