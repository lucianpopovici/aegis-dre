# 🚀 Aegis-DRE: High-Performance Diameter Routing Engine

**Aegis-DRE** is a next-generation Diameter Routing Engine (DRE) built in **Rust**, powered by **DPDK**, and hardened with **eBPF**. It is designed for Tier-1 telecom environments (4G/5G) where sub-microsecond latency and physical path integrity are non-negotiable.

## 🏗 System Architecture

Aegis-DRE operates entirely in **User-Space**, bypassing the Linux kernel to eliminate context-switching overhead and "noisy neighbor" jitter.

* **Data Plane:** DPDK (PMD) for zero-copy I/O.
* **Transport:** `sctp-proto` (Sans-I/O) for RFC-compliant multihoming and ASCONF.
* **Security:** eBPF (Aya) for hardware-level Path Overlap detection.
* **Application:** Realm-based Diameter routing (RFC 6733) with lock-free peer management.

## 🛡 Key Features

* **Physical Path Guard:** Real-time detection of "Crossed Paths" (e.g., Path B traffic arriving on Path A hardware).
* **SCTP-AUTH Enforcement:** Mandatory HMAC-SHA256 validation for all address reconfiguration (`ASCONF`) chunks (RFC 4895).
* **Hybrid Role Support:** Simultaneously functions as a **Server** (listening for MME/PCRF) and a **Client** (connecting to HSS/OCS).
* **Hitless Failover:** Transport-layer healing via SCTP multihoming before Diameter DWR timers expire.
* **Lock-Free Registry:** Sharded peer management capable of handling 10,000+ concurrent associations using `DashMap` and `ArcSwap`.

## 🔧 Hardware Tuning (Intel X710 / i40e)

To achieve maximum stability and line-rate performance on Intel X710 NICs:

1.  **Firmware Version:** Minimum **9.40** is required for reliable SCTP tail-packet processing.
2.  **SCTP CRC Offload:** Ensure `tx_sctp_cksum` is enabled to offload CRC32c calculation to the hardware.
3.  **DDP Profiles:** Load the SCTP Dynamic Device Personalization (DDP) profile for advanced hardware steering:
    ```bash
    # Loading the SCTP profile using dpdk-admin or ethtool
    ddp_loader -p sctp.pkgo -i 0000:01:00.0
    ```
4.  **Queue Scaling:** Use a 1:1 mapping between NIC queues and isolated CPU cores (`isolcpus`).

## 💻 Project Structure

```text
aegis-dre/
├── crates/
│   ├── dre-core/          # DPDK Polling Loop & SCTP State Machine
│   ├── dre-diameter/      # Realm Routing & AVP Codecs
│   ├── dre-security/      # eBPF Path Guard & SCTP-AUTH logic
│   └── dre-api/           # Prometheus Exporter & Warp Metrics Server
├── ebpf/                  # XDP/Aya Path Guard code
└── config/                # peers.yaml and routing rules
```
# 🚀 Getting Started
## 1. Prerequisites

* Intel X710 or E810 NIC.
* Rust 1.80+ (Edition 2024).
* DPDK 23.11+ or 25.11.
* Linux Kernel 6.x+ with 1GB Hugepages enabled.

## 2. Hugepage Setup
```bash
echo 4 > /sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages
```
## 3. Build & Run
```bash
# Build eBPF components
cargo xtask build-ebpf --release

# Run Aegis-DRE on cores 1-4
cargo run --release -- -l 1-4 -n 4 -- --config ./config/peers.yaml
```
# 📊 Observability

Aegis-DRE exports real-time metrics for Prometheus:
* dre_path_integrity_violations_total: CRITICAL ALERT - Triggered if packets arrive on the wrong physical port.
* dre_sctp_path_status: Binary health of SCTP multihoming paths.
* dre_diameter_request_latency_seconds: End-to-end routing latency histogram.
