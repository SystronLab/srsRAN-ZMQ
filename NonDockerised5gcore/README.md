### Add Open5GS in the Parent Folder

```bash
sudo apt update
sudo apt install gnupg
curl -fsSL https://pgp.mongodb.com/server-6.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-6.0.gpg --dearmor

echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list

sudo apt update
sudo apt install -y mongodb-org
sudo systemctl start mongod # if '/usr/bin/mongod' is not running
sudo systemctl enable mongod # ensure to automatically start it on system boot

sudo add-apt-repository ppa:open5gs/latest
sudo apt update
sudo apt install open5gs
```

#### Installing WebUI of Open5GS

```bash
sudo apt update
sudo apt install -y ca-certificates curl gnupg
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg

NODE_MAJOR=20

echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list

sudo apt update
sudo apt install nodejs -y

curl -fsSL https://open5gs.org/open5gs/assets/webui/install | sudo -E bash -
```

After the installation is done, the WebUI will be accessible on `localhost:9999`. The login credentials are:

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
