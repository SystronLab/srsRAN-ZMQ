# srsRAN with OCUDU

Guide to setup the project with various configurations (Dockerized 5G core, Non Dockerized 5G core, Single UE, Multiple UEs, Single gNB, Multiple gNBs, OSC RIC) on Ubuntu 22.04

> ⚠️ **HEADS UP!!!**  
> The config files in this repo are deprecated due to recent OCUDU updates but are kept here in case you need to refer to any values.
> You can follow the steps outlined here to install the project, but make sure to download and use the latest config files from the OCUDU website when you are running the project.

## Overview of the architecture

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

For cmake Boost error `sudo apt install build-essential libboost-system-dev libboost-thread-dev libboost-program-options-dev libboost-test-dev python3-mako`

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

### Add OCUDU in the Parent Folder

```bash
git clone https://gitlab.com/ocudu/ocudu.git
cd ocudu
mkdir build
cd build
cmake ../ -DENABLE_EXPORT=ON -DENABLE_ZEROMQ=ON
make -j`nproc`
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

### To begin RIC integration uncomment the parameters related to the E2 agent in gnb_zmq.yaml.

## OSCRIC

A minimal version of the [OSC RIC](https://github.com/srsran/oran-sc-ric/tree/main) is provided by srsRAN. Add it in the parent folder.

```bash
# Installation
git clone https://github.com/srsran/oran-sc-ric
```

<br>

# Running the Whole srsRAN Setup

Start up each of the following components in a different terminal window.

#### Run the 5G Core

```bash
cd ocudu/docker/
sudo docker compose up --build 5gc
```

#### Running the NearRT-RIC

```bash
cd oran-sc-ric
sudo docker compose up
```

#### Running the gNB

```bash
cd ocudu/build/apps/gnb
sudo ip netns add ue1

# OSCRIC
sudo ./gnb -c ./single_gnb_zmq.yaml e2 --addr="10.0.2.10" --bind_addr="10.0.2.1"
```

#### Running the UE

```bash
cd srsRAN_4G/build/srsue/src

# Option: running the setup with one UE
sudo ./srsue single_ue_zmq.conf
```

#### Running the xApp

```bash
# OSCRIC
cd oran-sc-ric
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
