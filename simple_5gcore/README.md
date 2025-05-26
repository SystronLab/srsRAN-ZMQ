## Setup with simple 5g core

### Refer to official documentation for installation

https://open5gs.org/open5gs/docs/guide/01-quickstart/

After the installation is done, the WebUI will be accessible. The login credentials are:

- **Username:** admin
- **Password:** 1423

After logging in, click on the `+` sign and add the following details from `ue_zmq.conf` file given in the config folder:

- **IMSI:** imsi
- **Subscriber key:** k
- **Operator key:** opc
- **DNN/APN:** apn
- **Type:** IPv4

Click on 'Save'.

### Add the Config Files in the Mentioned Locations

- **Location:** `/etc/open5gs`

  - `amf.yaml`
  - `nrf.yaml`

- **Location:** `srsRAN_Project/build/apps/gnb`

  - `gnb_zmq.yaml`

- **Location:** `srsRAN_4G/build/srsue/src`
  - `ue_zmq.conf`

### Running the Setup

#### Restarting the Core

```bash
sudo systemctl restart open5gs-*
```

_Note: Check if service is active `sudo systemctl is-active open5gs-xxxd`. If not, restart the service `sudo systemctl restart open5gs-xxxd`. The service can also be stopped by `sudo systemctl stop open5gs-xxxd`_

#### Running the gNB

```bash
cd srsRAN_Project/build/apps/gnb
sudo ip netns add ue1
sudo ./gnb -c ./gnb_zmq.yaml
```

#### Running the UE

```bash
cd srsRAN_4G/build/srsue/src
sudo ./srsue ue_zmq.conf
```

You will get an IP address for the UE indicating successful connection to gNB.

To test downlink, ping the IP address directly.

To test uplink, enter the network namespace of the UE with

```bash
 sudo ip netns exec ue1 bash
```

and ping the gNB's IP address. The uplink and downlink metrics should be visible in the trace of gNB.
