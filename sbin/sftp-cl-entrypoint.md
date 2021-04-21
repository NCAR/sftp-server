```text
NAME
        sftp-client-entrypoint.rc - ENTRYPOINT script for an sftp-server client

SYNOPSIS
        sweet-entrypoint.sh --source=sftp-client-entrypoint.rc <cmd>

DESCRIPTION
        This is a sourceable ENTRYPOINT script for a client of the
        sftp-server package. It can/should be sourced from
        \"sweet-entrypoint.sh\".

        The client container is for testing, so we assume it can create data
        being served (under ${DATA_DIR}) as well as being the sftp client.
        In the general case, it is possible to have a separate data owner
        and client.

        This entrypoint script ensures that it has SSH keys and a known_hosts
        file under \$SECRETS_DIR; it will create a known_hosts file if a
        "known_host_keys" file exists (see sbin/ssh-key-init).

        It also creates parameters of the form "ID_<TYPE>" that identify
        SSH identity files. It stores these in the parmdb parameter store and
        adds them to the environment.

        It also lists the top-level contents of ${DATA_DIR} and ${SECRETS_DIR}
        to aid in debugging.

ENVIRONMENT
        DATA_DIR
            Data directory for sftp.

        SECRETS_DIR
            Directory containing secrets (ssh keys).

```
