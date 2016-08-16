# docker-compose-wait
Connects and waits for all exposed TCP ports of a Docker Compose multi-container application to become accessible.

Requires docker, docker-compose, awk and netcat. Tested with different versions of netcat on OS X and Linux.

## Usage
* Set execute permissions for the correct owners in order to be runnable:
```
$ chmod u+x docker-compose-wait.sh
```
* Print out the usage description:
```
$ ./docker-compose-wait.sh -h

Usage:
    docker-compose-wait.sh [-q] [-f file] [-r retries] [-w wait_in_secs]

Options:
    -q | --quiet                    Do not output any debug messages
    -f FILE | --file=FILE           Path to Compose file (current: docker-compose.yml)
    -r RETRY | --retry=RETRY        Retry RETRY times for each container to expose its port (current: 5)
    -w WAIT | --wait=WAIT           Wait WAIT seconds after each connection attempt (current: 1)
    -h | --help                     Print this usage info
```
