LogMeIn host software for Linux (Beta)
======================================
[![Snap Status](https://build.snapcraft.io/badge/LogMeIn/logmein-linux-host.svg)](https://build.snapcraft.io/user/LogMeIn/logmein-linux-host)

### Overview

The LogMeIn Host Software (Beta) is available for Linux.

Each Linux host is displayed like any other host in your Computers list. When you connect to a Linux host, a remote terminal shell opens and it allows you to send commands to the host computer.

### Requirements

Python version 3.4+ is required with some PyPi dependencies. To install the dependencies run the following after cloning this repository:

```sh
$ pip3 install -r requirements.txt
```

Nodejs and yarn are needed.

```sh
$ cd reverse-proxy/
$ yarn install
```

### Installing the `logmein-host` for Linux

**Generate an Installation Package and retrieve the Deployment Code**
1.  In LogMeIn Central, go to the **Deployment** page.
2.  On the **Deployment** page, click **Add Installation Package**. The _Installation Package_ page is displayed.
3.  Fill in the necessary fields and select the appropriate options for the remote installation.
4.  Click **Save Settings**. The _Deploy Installation Package_ page is displayed.
5.  On the _Deploy Installation Package_ page, copy the **Installation Link**.
    Example: `https://secure.logmein.com/i?l=en&c=01_bma2ecmmg4coyxou9oo6yhhvw0ewi3estniee`

**Register the host in the LogMeIn Central**
Use the **Installation Link** or the deployment code itself:

```sh
# Use the whole url
$ python3 logmein_host/logmein_host.py --deployment-code 'https://secure.logmein.com/i?l=en&c=01_bma2ecmmg4coyxou9oo6yhhvw0ewi3estniee'

# or just the code
$ python3 logmein_host/logmein_host.py --deployment-code "01_bma2ecmmg4coyxou9oo6yhhvw0ewi3estniee"
```

### Running the host

Run the wetty

```sh
$ sudo node reverse-proxy/node_modules/wetty/index.js --port 23822 --title LogMeIn --base /xterm/ --host 127.0.0.1 --forcessh &
```

Run reverse proxy

```sh
$ sudo node reverse-proxy/app.js &
```

Run `pytty`, the web terminal app that will connect to the localhost using *ssh*  and forward the *tty* to the browser:

```sh
$ sudo python3 pytty/pytty.py &
```

Then run `logmein_host` which connects `pytty` to the LogMeIn gateways:

```sh
$ sudo python3 logmein_host/logmein_host.py &
```

### License

Contributed by Jerry

- Update README (11/21/2023)
- Add run.sh to run locally with snap (11/21/2023)
- Update the pytty to ask for ssh port during connection. (11/21/2023)
- Update Snap nodejs version to 16.19.1 (11/21/2023)

Copyright (c) 2018 LogMeIn, Inc.

Licensed under the MIT License
