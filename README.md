# 🛡️ Aegis-DRE: 10Gbps FRMCS Diameter Gateway

Aegis-DRE is a high-performance, telco-grade Diameter Routing Engine designed for **FRMCS** (Future Railway Mobile Communication System). It leverages **DPDK** for zero-copy packet processing, **eBPF** for hardware-level security, and **Python/Redis** for intelligent railway functional addressing.

## 🏗️ Architecture Overview

The system is split into a high-speed data plane and a flexible control plane:

* **Data Plane (C/DPDK):** Performs MAC rewriting, AVP parsing, and 10Gbps routing.
* **Security (eBPF):** XDP-based shield for L3/L4 filtering on the Intel X710.
* **Control Plane (Python):** Manages FRMCS identities and HSS/PCRF health.
* **State Layer (Redis):** Stores IMSI-to-Node mappings and functional aliases.

---

## 🚀 Quick Start (Deployment)

### 1. Hardware Prerequisites
* **NIC:** Intel X710 (or compatible XL710/XXV710).
* **Memory:** 2GB Hugepages allocated (`2048kB` size).
* **OS:** Ubuntu 24.04+ with `vfio-pci` drivers.

### 2. One-Command Ignition
```bash
chmod +x deploy.sh
./deploy.sh
