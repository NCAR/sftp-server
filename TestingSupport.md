# Running Tests Against a sftp-server Server Container

The sftp-server package supports automated testing. During development of
the `NCAR/sftp-server` project, you can use services configured in the
docker-compose `dev` directory. During automated builds and in testing for
other projects that use an SFTP client, you can use the `sbin/run-test-server`
`sbin/run-test-client` scripts.

## Using docker-compose and the "dev" environment

The `dev/docker-compose.yml' file defines a number of services. The main
services (started by `docker-compose up`) are "server" and "client".

The "server" service runs as user:group `sftp:sftp`, while the "client" service
runs as user:group `sweetuser:sftp`; because the client runs under the `sftp`
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

### Running Client Tests in Batch Mode

If you just want to run the test scripts, you can use the following `rundev`
command:

    host$ INTERACTIVE=0 rundev --logs client

## Running Tests Without docker-compose

If you don't want or need to use the docker-compose `dev` environment, you
can use the `sbin/run-test-server` and `sbin/run-test-client` scripts. This
is how automated builds with CircleCI are configured.

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
separate windows.

The following code adapted from the circleci test/build configuration
demonstrates how to run the script from a single non-interactive shell. The
`for` loop waits for a total of 10 seconds for the server to come up, and the
`run-test-client` script will default to running the `NCAR/sftp-server` test
suite:

    cd sbin
    nohup ./run-test-server </dev/null >$logdir/test-server.log 2>&1 &
    for i in 2 2 2 2 2 ; do
        if grep -q 'Server listening ' $logdir/test-server.log ; then
            break
        fi
        sleep $i
    done
    cat $logdir/test-server.log
    ./run-test-client tbin/run-sftp-tests


