```text
NAME
        sftp-sv-entrypoint.rc - ENTRYPOINT script for sftp-server

SYNOPSIS
        sweet-entrypoint.sh --source=sftp-sv-entrypoint.rc /usr/sbin/sshd

DESCRIPTION
        This is a sourceable ENTRYPOINT script for a sftp-server container.
        It can/should be sourced from \"sweet-entrypoint.sh\".

        The script verifies that host SSH keys exist under ${SECRETS_DIR}.

        It also lists the top-level contents of ${DATA_DIR} and ${SECRETS_DIR}
        to aid in debugging.

ENVIRONMENT
        SECRETS_DIR
            Directory containing secrets (ssh keys).

```
