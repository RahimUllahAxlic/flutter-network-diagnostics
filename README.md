# 📡 Flutter Network Diagnostics & Observability Suite

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![State Management](https://img.shields.io/badge/State_Management-Bloc_%26_Cubit-00D2FF)
![Security](https://img.shields.io/badge/Privacy-Zero--PII_Redacted-00C853)

A production-grade mobile network observability application built with **Flutter**, **`flutter_bloc` (Bloc + Cubit)**, and **`dart:io` low-level socket instrumentation**.

Designed to diagnose connectivity failures across **Layer 3 (Network), Layer 4 (Transport/TCP), Layer 6 (TLS Presentation), and Layer 7 (HTTPS Application)** without requiring root privileges or collecting sensitive user identifiers.

---

## 🏗️ Architectural Highlights: Why Both `Bloc` and `Cubit`?

Rather than forcing every state change into a single pattern, this codebase demonstrates idiomatic `flutter_bloc` architecture:

1. **`DiagnosticRunnerBloc` (Event-Driven State Machine):**
   * Orchestrates the sequential, multi-stage diagnostic pipeline (`DNS Lookup` $\rightarrow$ `5x TCP SYN/ACK + TLS Handshake Probes` $\rightarrow$ `HTTPS Application Verification` $\rightarrow$ `Report Generation`).
   * Prevents race conditions by ignoring duplicate trigger events while a probe suite is in flight.
2. **`ReachabilityCubit` (Reactive Interface & Egress Monitor):**
   * Subscribes to OS network interface changes (`connectivity_plus`) and verifies real internet egress via an HTTP `204 No Content` probe (`cp.cloudflare.com/generate_204`) to distinguish true connectivity from **Captive Portals**.
3. **`HistoryCubit` (Structured Audit Log & Sanitized Export):**
   * Maintains an in-memory ring buffer of structured `DiagnosticReport` records and exports sanitized **JSON** and **Markdown** incident reports.

---

## 🔬 How Latency & Jitter Are Measured (No `http.get` Approximations)

Many mobile apps mistakenly measure latency by timing a full `http.get()` request, which conflates DNS lookup, TCP handshake, TLS negotiation, and server processing time.

`NetworkProbeEngine` isolates each phase independently:

1. **Stub Resolver DNS Timing (`InternetAddress.lookup`):**
   * Measures exact resolution latency and enumerates both IPv4 (`A`) and IPv6 (`AAAA`) records.
2. **True TCP 3-Way Handshake RTT (`Socket.connect`):**
   * Measures the time from `SYN` transmission to `SYN-ACK` receipt on port `443`.
3. **TLS 1.2/1.3 Handshake Timing (`SecureSocket.secure`):**
   * Upgrades the existing raw TCP socket to measure TLS handshake and X.509 certificate verification overhead independently of TCP connect time.
4. **Statistical Jitter & p95 Calculation:**
   * Computes mean inter-packet delay variation across $N=5$ consecutive probes:
     $$\text{Jitter} = \frac{1}{N-1} \sum_{i=2}^{N} \vert{}RTT_i - RTT_{i-1}\vert{}$$

---

## 🎯 Controlled Test Endpoints & Fault Injection

To ensure reproducible testing without probing arbitrary third-party infrastructure, the app uses five controlled targets:

| Preset Name | Host / Endpoint | Purpose |
| :--- | :--- | :--- |
| **Cloudflare Anycast DNS** | `one.one.one.one:443` | High-availability anycast baseline |
| **Google Public DNS** | `dns.google:443` | DoH / Public resolver reachability check |
| **Cloudflare 204 Check** | `cp.cloudflare.com:443` | Captive portal & HTTP 204 verification |
| **RFC 5737 Blackhole** | `192.0.2.1:443` | Deterministic `ETIMEDOUT` & 100% packet loss simulation |
| **NXDOMAIN Simulation** | `nonexistent.invalid.domain.test` | Deterministic DNS `NXDOMAIN` error handling |

---

## 🔒 Permissions & Privacy-by-Design Architecture

Security and privacy are first-class engineering requirements in network tooling. This application enforces strict data minimization:

### Minimal OS Permissions
* **Android (`AndroidManifest.xml`):**
  ```xml
  <uses-permission android:name="android.permission.INTERNET" />
  <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
  ```

### Deliberately Omitted Permissions:
* ❌ `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` (Required on Android/iOS to read Wi-Fi SSID/BSSID—never requested).
* ❌ `READ_PHONE_STATE` (Cellular IMEI/IMSI/Carrier tower IDs—never requested).

### Sanitized Report Exports
Exported JSON and Markdown diagnostic reports contain only target endpoint performance metrics and transport type (Wi-Fi, Cellular, VPN Tunnel), ensuring users and QA engineers can attach diagnostic logs to support tickets without leaking subscriber IPs or physical location metadata.
