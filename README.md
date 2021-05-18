# SFTP server

This project implements a simple SFTP server container. The container runs
as non-root user "sftp".

All scripts support the "--help" command-line flag for displaying help.

You can see a list of all current scripts and their help documentation along
with other documents on the [wiki](https://github.com/NCAR/sftp-server/wiki).

The repo suports basic testing with an sftp client container and an sftp
server container; see dev/docker-compose.yml.

To set up new ssh keypairs for testing, 


