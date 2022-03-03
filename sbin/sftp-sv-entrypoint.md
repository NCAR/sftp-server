```text
NAME
        sftp-sv-entrypoint.rc - ENTRYPOINT script for sftp-server

SYNOPSIS
        sweet-entrypoint.sh --source=sftp-sv-entrypoint.rc /usr/sbin/sshd

DESCRIPTION
        This is a sourceable ENTRYPOINT script for a sftp-server container.
        It can/should be sourced from \"sweet-entrypoint.sh\".

        The script verifies that host SSH keys exist under ${SECRETS_DIR}.
        If there is no \${SECRETS_DIR}/authorized_keys file, or if there is
        a newer authorized_keys file under
        \${SECRETS_DIR}/\${CLIENT_PACKAGE}/\${RUN_ENV}, the client
        authorized_keys file is copied to \${SECRETS_DIR}/authorized_keys.

        It also lists the top-level contents of ${DATA_DIR} and ${SECRETS_DIR}
        to aid in debugging.

ENVIRONMENT
        SECRETS_DIR
            Directory containing secrets (ssh keys).

        CLIENT_PACKAGE
            The name of the client package (default is \${PACKAGE}

        PACKAGE
            The name of the server package (usually "sftp-server").

```
