# srsRAN setup guide

Guide to setup the srsRAN with FlexRIC and OSCRIC on Ubuntu 22.04

## Overview of the base srsRAN architecture

![Alt text](https://docs.srsran.com/projects/project/en/latest/_images/gNB_srsUE_zmq.png)

### Updating the system

```bash
sudo apt update
sudo apt upgrade
```

Restart the system so that updated daemons are up and running

### Create Parent Folder

```bash
mkdir srsRAN_parent
cd srsRAN_parent
```

### Install Dependencies

```bash
sudo apt-get install git cmake make gcc g++ pkg-config libfftw3-dev libmbedtls-dev libsctp-dev libyaml-cpp-dev libgtest-dev
```

### Add UHD in the Parent Folder (we don't need an external USRP but we need the UHD related libraries given below)

```bash
sudo apt-get install autoconf automake build-essential ccache cmake cpufrequtils doxygen ethtool \
g++ git inetutils-tools libboost-all-dev libncurses5 libncurses5-dev libusb-1.0-0 libusb-1.0-0-dev \
libusb-dev python3-dev python3-mako python3-numpy python3-requests python3-scipy python3-setuptools \
python3-ruamel.yaml

git clone https://github.com/EttusResearch/uhd.git
cd uhd/host
mkdir build
cd build
cmake ../
make
make test # This step is optional
sudo make install
sudo ldconfig
```

\*Note: For cmake [error](https://github.com/EttusResearch/uhd/issues/153), navigate to `uhd/host/CMakeLists.txt` line 434, change "Boost_FOUND;HAVE_PYTHON_PLAT_MIN_VERSION;HAVE_PYTHON_MODULE_MAKO" OFF ON) to "Boost_FOUND;HAVE_PYTHON_PLAT_MIN_VERSION;HAVE_PYTHON_MODULE_MAKO" ON ON)

### Add ZMQ in the Parent Folder

```bash
sudo apt-get install libzmq3-dev

git clone https://github.com/zeromq/libzmq.git
cd libzmq
./autogen.sh
./configure
make
sudo make install
sudo ldconfig

git clone https://github.com/zeromq/czmq.git
cd czmq
./autogen.sh
./configure
make
sudo make install
sudo ldconfig
```

### Add 5g in the Parent Folder

```bash
git clone https://github.com/srsran/srsRAN_Project.git
cd srsRAN_Project
mkdir build
cd build
cmake ../ -DENABLE_EXPORT=ON -DENABLE_ZEROMQ=ON
make -j`nproc`
sudo make install
sudo ldconfig
```

### Add 4g in the Parent Folder (we need it for the UE simulator)

```bash
sudo apt-get install build-essential cmake libfftw3-dev libmbedtls-dev libboost-program-options-dev libconfig++-dev libsctp-dev

git clone https://github.com/srsRAN/srsRAN_4G.git
cd srsRAN_4G
mkdir build
cd build
cmake ../
make
make test
sudo make install
srsran_install_configs.sh user
```

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

# Adding NearRT-RIC and xApp to the base srsRAN architecture

![Alt text](https://docs.srsran.com/projects/project/en/latest/_images/gNB_srsUE_zmq_near_rt_RIC.png)

### To begin RIC integration uncomment the parameters related to the E2 agent in gnb_zmq.yaml. Then pick the RIC you want to integrate

- [FlexRIC](#flexric)
- [OSCRIC](#oscric)

## FlexRIC

```bash
sudo apt-get update
sudo apt-get install swig libsctp-dev python3 cmake-curses-gui python3-dev pkg-config libconfig-dev libconfig++-dev


git clone https://gitlab.eurecom.fr/mosaic5g/flexric.git
cd flexric
git checkout br-flexric
mkdir build
cd build
cmake -DKPM_VERSION=KPM_V3 -DXAPP_DB=NONE_XAPP ../
make
sudo make install
```

### Running the Setup

#### Restarting the Core

```bash
sudo systemctl restart open5gs-*
```

#### Running the NearRT-RIC

```bash
./flexric/build/examples/ric/nearRT-RIC
```

#### Running the gNB

```bash
cd srsRAN_Project/build/apps/gnb
sudo ip netns add ue1
sudo ./gnb -c ./gnb_zmq.yaml e2 --addr="127.0.0.1" --bind_addr="127.0.0.1"
```

#### Running the UE

```bash
cd srsRAN_4G/build/srsue/src
sudo ./srsue ue_zmq.conf
```

#### Running the xApp

```bash
./flexric/build/examples/xApp/c/helloworld/xapp_hw
```

On successful connection of the xApp, the following will be displayed on the NearRT-RIC console:

[iApp]: E42 SETUP-REQUEST received
[iApp]: E42 SETUP-RESPONSE sent

## OSCRIC

Will be added soon
