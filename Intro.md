# SFTP Server Container

This project implements a simple SFTP server container. The container runs
OpenSSH in sftp mode as non-root user "sftp".

This is meant to used in two ways: as a workable SFTP server that can be
easily configured to serve file data, or as a stand-in for another SFTP
server in test environments.

In the latter case, the `sbin/run-test-server` script can be helpful. The
`sbin/run-test-client` script interacts with `run-test-server` to run
tests for the `sftp-server` project itself, but it can also act as a model
for how to interact with `run-test-server` in other projects.



