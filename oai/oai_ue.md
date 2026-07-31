# OAI NR UE (ZMQ) with OCUDU gNB

This guide describes how to replace the `srsRAN_4G` ZMQ UE with the **OpenAirInterface (OAI) NR UE** using the **OCUDU ZMQ radio interface**.

---

## Prerequisites

- OCUDU gNB configured for ZMQ operation
- Open5GS 5G Core
- OAI branch with ZMQ support (2026.w25 or later)
- ZeroMQ development library

Install ZeroMQ:

```bash
sudo apt update
sudo apt install -y libzmq3-dev
```

---

# Build the OAI NR UE

Install all required dependencies:

```bash
cd ~/OAI/ocudu_parent/openairinterface5g/cmake_targets

./build_oai -I
```

Build the ZMQ-enabled NR UE:

```bash
./build_oai -c --ninja -w ZMQ --nrUE
```

---

# Verify the Build

Check that the UE executable exists:

```bash
cd ~/OAI/ocudu_parent/openairinterface5g/cmake_targets/ran_build/build

ls -lh nr-uesoftmodem
```

Verify that the ZMQ plugin has been built:

```bash
find . -name "liboai_zmqdevif.so"
```

Expected output:

```
nr-uesoftmodem
liboai_zmqdevif.so
```

---

# UE Configuration

Create `oaiue_zmq.conf`.

```cfg
uicc0 = {
  imsi = "001010123456780";
  key = "00112233445566778899aabbccddeeff";
  opc = "63bfa50ee6523365ff14c1f45f88737d";

  pdu_sessions = ({
    dnn = "internet";
    nssai_sst = 1;
  });
};

device = {
  name = "oai_zmqdevif";
};

zmq = (
  {
    tx_channels = ("tcp://127.0.0.1:4557");
    rx_channels = ("tcp://127.0.0.1:4556");
  }
);

r = 51;
numerology = 1;
band = 78;

C = 3489420000L;

ue-scan-carrier = 1;
E = 1;

uecap_file =
  "../../../targets/PROJECTS/GENERIC-NR-5GC/CONF/uecap_ports1.xml";
```

> **Important**
>
> The carrier frequency **must** be written as:
>
> ```cfg
> C = 3489420000L;
> ```
>
> The `L` suffix forces libconfig to treat the value as a 64-bit integer. Without it, the value overflows and the UE aborts during startup.

---

# ZMQ Port Mapping

| Component | Address |
|-----------|---------|
| gNB TX | tcp://127.0.0.1:4556 |
| UE RX | tcp://127.0.0.1:4556 |
| UE TX | tcp://127.0.0.1:4557 |
| gNB RX | tcp://127.0.0.1:4557 |

---

# Startup Order

## 1. Start the 5G Core

```bash
docker compose up
```

---

## 2. Start the OCUDU gNB

Example:

```bash
sudo ./gnb -c gnb_zmq.yaml
```

---

## 3. Start the OAI NR UE

```bash
cd ~/OAI/ocudu_parent/openairinterface5g/cmake_targets/ran_build/build

sudo env LD_LIBRARY_PATH="$PWD" \
./nr-uesoftmodem -O ./oaiue_zmq.conf
```

`LD_LIBRARY_PATH` is required so that the UE can load the dynamically linked ZMQ driver:

```
liboai_zmqdevif.so
```

---

# Expected Output

Successful startup should show messages similar to:

```
SA init parameters
HW: Configuring channel 0
Initializing UE vars
```

Once the gNB is running:

```
Found SSB
Cell Synchronization successful
Random Access procedure
RRCSetup
Registration Accept
PDU Session Establishment Accept
```

---

# Common Issues

## 1. `asn1c not found`

Install the OAI dependencies:

```bash
./build_oai -I
```

---

## 2. `-gen-APER: Invalid argument`

The Ubuntu `asn1c` package is incompatible with this branch.

Use the version installed by the OAI build system.

---

## 3. `Undefined Frequency Range`

Cause:

```cfg
C = 3489420000;
```

Fix:

```cfg
C = 3489420000L;
```

---

## 4. `liboai_zmqdevif.so: cannot open shared object file`

The UE was built without ZMQ support.

Rebuild using:

```bash
./build_oai -c --ninja -w ZMQ --nrUE
```

Launch the UE with:

```bash
sudo env LD_LIBRARY_PATH="$PWD" \
./nr-uesoftmodem -O ./oaiue_zmq.conf
```

---

## 5. `oaiue_zmq.conf does not exist`

The configuration file is not generated automatically and may be deleted when the build directory is cleaned.

Recreate or restore `oaiue_zmq.conf` before launching the UE.

---

# Build Command

```bash
cd ~/OAI/ocudu_parent/openairinterface5g/cmake_targets

./build_oai -c --ninja -w ZMQ --nrUE
```

---

# Launch Command

```bash
cd ~/OAI/ocudu_parent/openairinterface5g/cmake_targets/ran_build/build

sudo env LD_LIBRARY_PATH="$PWD" \
./nr-uesoftmodem -O ./oaiue_zmq.conf
```

---

# Notes

- This setup replaces the `srsRAN_4G` ZMQ UE with the **OpenAirInterface NR UE**.
- The UE communicates with the **OCUDU gNB** over **ZeroMQ**.
- The gNB connects to the **Open5GS 5G Core** using the standard N2/N3 interfaces.
- The UE configuration (`IMSI`, `Ki`, `OPc`, `DNN`) must match the subscriber configured in Open5GS.
