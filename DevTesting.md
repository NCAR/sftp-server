## Running Tests in the "dev" environment

The sftp-server package supports automated testing. The docker-compose
configuration in the `dev` directory is set up to do this. (But see the
`sbin/run-test-server` and `sbin/run-test-client` scripts as well.)

The `dev/docker-compose.yml' file defines a number of services. The main
services (started by `docker-compose up`) are "server" and "client".

The "server" service runs as user:group `sftp:sftp`, while the "client" service
runs as user:group `sweetuser:sftp`; because the client runs under the `sftp`
group, it can write directly to the mounted $DATA_DIR directory.

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

