# srsRAN Setup Guide

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

_Note: For cmake [error](https://github.com/EttusResearch/uhd/issues/153), deactivate conda base environment `conda deactivate` to prevent the error._

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
make test # This step is optional
sudo make install
srsran_install_configs.sh user
```

### Installation of the 5g Core

Pick between [Dockerised 5g core (recommended)](dockerised_5gcore/README.md) and [Simple 5g core](simple_5gcore/README.md)

Once the 5g core, gNB and ue are connected successfully, we can move ahead and add RIC to this setup

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

_Note: The used FlexRIC version can be built only with gcc-10, switch gcc version using update-alternatives if needed._

```sh
# install gcc-10, g++-10, gcc-11, g++-11
sudo apt update
sudo apt install gcc-10 g++-10 gcc-11 g++-11
# configure update-alternatives
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 10
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 20
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-11 10
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-10 20
# select gcc-10 as default
sudo update-alternatives --config gcc
sudo update-alternatives --auto gcc
sudo update-alternatives --auto g++
# verify the version
gcc --version
g++ --version
```

## OSCRIC

A minimal version of the [OSC RIC](https://github.com/srsran/oran-sc-ric/tree/main) is provided by srsRAN. Add it in the parent folder.

```bash
# Installation
git clone https://github.com/srsran/oran-sc-ric
cd ./oran-sc-ric

# IF you wish to deploy it
sudo docker compose up
```
<br>

# Running the Whole srsRAN Setup

Start up each of the following components in a different terminal window.

#### Run the 5G Core

```bash
cd srsRAN_parent/srsRAN_Project/docker/
sudo docker compose up --build 5gc
```

#### Running the NearRT-RIC

```bash
# Option 1: FlexRIC
./flexric/build/examples/ric/nearRT-RIC

# Option 2: OSCRIC
cd srsRAN_parent/oran-sc-ric
sudo docker compose up
```

#### Running the gNB

```bash
cd srsRAN_parent/srsRAN_Project/build/apps/gnb
sudo ip netns add ue1
# Option: FlexRIC
sudo ./gnb -c ./gnb_zmq.yaml e2 --addr="127.0.0.1" --bind_addr="127.0.0.1"

# Option: OSCRIC AND running with one gNB
sudo ./gnb -c ./single_gnb_zmq.yaml e2 --addr="10.0.2.10" --bind_addr="10.0.2.1"

# Option: OSCRIC AND multiple gNB
```

#### Running the UE

```bash
cd srsRAN_parent/srsRAN_4G/build/srsue/src

# Option: running the setup with one UE
sudo ./srsue single_ue_zmq.conf
```

#### Running the xApp

```bash
# Option: FlexRIC
./flexric/build/examples/xApp/c/helloworld/xapp_hw
```

On successful connection of the xApp, the following will be displayed on the NearRT-RIC console:

[iApp]: E42 SETUP-REQUEST received
[iApp]: E42 SETUP-RESPONSE sent

```bash
# Option: OSCRIC
cd srsRAN_parent/oran-sc-ric
sudo docker compose exec python_xapp_runner ./kpm_mon_xapp.py --metrics=DRB.UEThpDl,DRB.UEThpUl --kpm_report_style=5
```

The xApp console output should be similar to:

```bash
RIC Indication Received from gnb_001_001_00019b for Subscription ID: 5, KPM Report Style: 5
E2SM_KPM RIC Indication Content:
-ColletStartTime:  2024-04-02 13:24:56
-Measurements Data:
--UE_id: 0
---granulPeriod: 1000
---Metric: DRB.UEThpDl, Value: [7]
---Metric: DRB.UEThpUl, Value: [7]
```

## Grafana UI

Add the following in the gnb_zmq.yaml config file

```bash
metrics:
enable_json_metrics: true # Enable reporting metrics in JSON format
addr: 172.19.1.4 # Metrics-server IP
port: 55555 # Metrics-server Port
```

To launch the docker image for the Grafana UI,

```bash
cd srsRAN_Project
sudo docker compose -f docker/docker-compose.yml up grafana
```

The following output should be observed:

```bash
Creating network "docker_ran" with the default driver
Starting metrics_server ...
Starting metrics_server ... done
Creating grafana        ... done
Attaching to grafana
```

Navigating to http://localhost:3300/ in your preferred web browser will allow you to view the UI.

You can then run srsRAN as normal. As the UE(s) connect to the network you will begin to see an output for each. These figures and graphics will update automatically during runtime, showing plots for each UE on the network.
