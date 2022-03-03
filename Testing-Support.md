# Running Tests Against a sftp-server Server Container

The sftp-server package supports automated testing. During development of
the `NCAR/sftp-server` project, you can use services configured in the
docker-compose `dev` directory. During automated builds and in testing for
other projects that use an SFTP client, you can use the `sbin/run-test-server`
`sbin/run-test-client` scripts, or adapt `dev/docker-compose.yml` as
appropriate.

## Using docker-compose and the "dev" environment for self testing

The `dev/docker-compose.yml' file defines a number of services. The main
services (started by `docker-compose up`) are "server" and "client".

The "server" service runs as user:group `sftp:sftp`, while the "client" service

group, it can write directly to the mounted $SFTP_DATA (/mnt) directory.

### Creating SSH Keypairs

The first step in running tests is to create host and client SSH keypairs.
Since these need to be owned by the container user and the private keys have
restricted read permissions, the `dev` configuration defines standalone
services (tagged with the "reset-keys" profile) that are used to define
SSH keypairs. Create the client keypairs first, them the server/host keypairs:

    host$ cd dev
    
    host$ docker-compose run reset-client-keys
    Creating dev_reset-client-keys_run ... done
    2021-05-07T09:43:47-06:00 ncar/sftp-server 0.0.1-20210506T213840Z.0a2469b0 Starting /usr/local/sftp-server/sbin/ssh-keysync
    client: Creating key directories
    client: Clean up previous state
    client: Create keys
    client: Done
    
    host$ docker-compose run reset-server-keys
    Creating dev_reset-server-keys_run ... done
    2021-05-07T09:43:56-06:00 ncar/sftp-server 0.0.1-20210506T213840Z.0a2469b0 S    tarting /usr/local/sftp-server/sbin/ssh-keysync
    server: Creating key directories
    server: Clean up previous keys
    server: Create keys
    server: Done

These services are set up to write host keys to the $LOCAL_SECRETS directory
tree; LOCAL_SECRETS is assumed to be defined in your own `dev/.env` file.

The "server" and "client" services expect the same directory tree to be mounted
as $SECRETS_VOL (/run/secrets).

### Interactive Testing and Development

SWEET's `rundev` script can be used to start the "server" and "client" services
and exec into either the "server" or "client" containers:

    host$ rundev server

        or

    host$ rundev client

If you exec into the client container, test scripts are under the `tbin`
directory:

    client$ cd tbin
    client$ runtests

To run the `sftp` command in the client container, you must specify the
identity file and the `sftp` user. The former is avaiable in predefined
environment variables:

    client$ sftp -i $ID_RSA sftp@server
    Connected to sftp@server.
    sftp> 

## Running Tests Without docker-compose

If you don't want or need to use the docker-compose `dev` environment, you
can use the `tbin/runtests.sh` script. To run the script, cd to the sftp-server
main directory and run

    $ ./tbin/runtests.sh

This script runs two other scripts: `sbin/run-test-server` and
`sbin/run-test-client`.

The `run-test-server` script will create and start a container running an SFTP
server. It will generate temporary keypairs and store them `/run/secrets`, and
it will serve data under `/mnt. It will also define volumes for both
`/run/secrets` and `/mnt`. The `run-test-client` script will create a container
for an SFTP client that uses the docker `--volumes-from` argument to mount
the server's `/var/secrets` and `/mnt` volumes in the client. This implies
that `run-test-server` must run *before* `run-test-client`.

Because `/run/secrets` will be shared, the containers will be ready to
communicate without any additional configuration. Because `/mnt` will be
shared, the client container can read and write the server's data by doing
direct I/O *or* by using `sftp`.

You can pass any command to `run-test-client`. Without commands and in a
non-interactive environment, `run-test-client` will run all `NCAR/sftp-server`
test scripts and then shutdown the server. If you pass command arguments to
`run-test-client`, you should be aware of how the container environment will
be set up. See the `run-test-client` documentation for details.

By default, the server container is named `testsftp`, but an alternate name
can be specified; the same name must be passed to both `run-test-server` and
`run-test-client`. Both scripts will run their containers attached, so if
you are running tests interactively, you will want to run the scripts in
separate windows. However, `run-test-server` can be made to run in background
using the `-w|--wait` option.

## Adapting dev/docker-compose.yml for other projects

It is not difficult to set up an SFTP server instance in another project, but
setting up keys and accounts can be confusing, particularly if the other project
runs under a user account other than `sweetuser`.

You can, of course, define your own static ssh keys in the other project, but
you can also generate a keypair in the same way `sftp-server/dev/docker-compose`
does. Just define client and server services like so:

```
  reset-server-keys:
    image: ncar/sftp-server:latest
    entrypoint: [ "/usr/local/sweet/sbin/sweet-entrypoint.sh" ]
    command: [ "/usr/local/sftp-server/sbin/ssh-keysync" ]
    volumes:
      - type: bind
        source: ${LOCAL_SECRETS}
        target: /mnt
    environment:
      SERVICE: server
      RUN_ENV: dev
      ENTRYPOINT_DEBUG:
    profiles: [ "reset-keys" ]

  reset-client-keys:
    image: ${OTHER_IMAGE}
    user: ${OTHERUSER}:${$OTHERGROUP}
    entrypoint: [ "/usr/local/sweet/sbin/sweet-entrypoint.sh" ]
    command: [ "/usr/local/sftp-server/sbin/ssh-keysync" ]
    volumes:
      - type: bind
        source: ${LOCAL_SECRETS}
        target: /mnt
    environment:
      SERVICE: client
      RUN_ENV: dev
      ENTRYPOINT_DEBUG:
    profiles: [ "reset-keys" ]

```

Substitute the name of your image and its user and group for the
`${OTHER_IMAGE}`, `${OTHERUSER}`, and `${OTHERGROUP}` references.

The `reset-client-keys` server should run first, then the `reset-server-keys`
service.

The corresponding `server` and `client` services should use the following basic
setup:

```
  server:
    image: ncar/sftp-server:latest
    init: true
    volumes:
      - type: volume
        source: testdata
        target: /mnt
      - type: bind
        read_only: "true"
        source: ${LOCAL_SECRETS}
        target: ${SECRETS_VOL}
      - type: tmpfs
        target: /tmp
    environment:
      SERVICE: server
      CLIENT_PACKAGE: ${OTHER_PACKAGE}
      RUN_ENV: dev
      ENTRYPOINT_DEBUG:
    networks:
      - sftp

  client:
    image: ${OTHER_IMAGE}
    user: ${OTHERUSER}:${OTHERGROUP}
    entrypoint: [ "/usr/local/sweet/sbin/sweet-entrypoint.sh", "--source=/usr/local/sftp-server/sbin/sftp-cl-entrypoint.rc" ]
    command: [ "/usr/local/sftp-server/sbin/sftp-client-shell" ]
    volumes:
      - type: volume
        source: testdata
        target: /mnt
      - type: bind
        read_only: "true"
        source: ${LOCAL_SECRETS}
        target: ${SECRETS_VOL}
      - type: tmpfs
        target: /tmp
    environment:
      SFTP_CLIENT: 1
      SERVICE: client
      RUN_ENV: dev
      SFTP_SERVER: server
      SFTP_DATA: /mnt
      INTERACTIVE: 1
      ENTRYPOINT_DEBUG: 0
    networks:
      - sftp

```

Note that the `PACKAGE`, `SERVICE`, and `RUN_ENV` environment variables are
used by `SWEET` scripts as directory components to collect secrets and
configuration files, so it is important that they are set correctly; `PACKAGE`
is set automatically by `SWEET`; `SERVICE` should generally match the name of a
`docker-compose` service; `RUN_ENV` is by convention `dev`, `test`, or `prod`.
In addition, the `sftp-server` package uses environment variable
`CLIENT_PACKAGE` in the same way; it should match the `PACKAGE` of the package
using `sftp-server`.

Note that the client service also needs to set some other special environment
variables: `SFTP_CLIENT` should be 1, `SFTP_SERVER` should be set to the name of
the `docker-compose` SFTP server service, and `SFTP_DATA` should be `/mnt`.

The last thing to remember about using the `sftp-server` server is that the
only server-side username for authentication purposes is `sftp`. That is,
the actual `sftp` command that your client uses to connect to the server
needs to specify `sftp@<servername>` as the `user@server` argument, regardless
of the username the client actually runs as.








