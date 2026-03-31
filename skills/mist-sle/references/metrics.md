# SLE Metric Reference

## Wireless Metrics (sle: "wifi")

| Metric | Description | Key Classifiers |
|---|---|---|
| `coverage` | % client-time with adequate RSSI | weak-signal, asymmetry-uplink, asymmetry-downlink |
| `capacity` | % client-time with adequate airtime | channel-interference, channel-utilization, non-wifi-interference, insufficient-coverage |
| `time-to-connect` | % connections completing within threshold | dhcp-nack, dhcp-unresponsive, dhcp-stuck, authorization, association, IP-Services |
| `roaming` | % roam events completing successfully | roam-slow, roam-failed, fast-roam-okc-slow, fast-roam-11r-slow, fast-roam-failed |
| `throughput` | % client-time with adequate throughput | insufficient-bandwidth, slow-link-speed |
| `ap-health` | AP hardware + RF health composite | (query classifiers at runtime) |
| `ap-availability` | % time APs are online | reboots, outages |
| `successful-connect` / `failed-to-connect` | Connection success rate | (query classifiers at runtime) |

### Wireless Classifier Fixes

| Classifier | Meaning | Fix |
|---|---|---|
| weak-signal | RSSI below threshold | AP placement, Tx power, roaming thresholds |
| asymmetry-uplink | AP can't hear client | Client Tx too low, distance |
| dhcp-nack / dhcp-unresponsive | DHCP failures | Scope exhaustion, relay config, server reachability |
| authorization | 802.1X / PSK auth fail | RADIUS config, certificate, password |
| roam-failed | Can't join new AP | 802.11r/k/v config, neighbor lists |
| channel-interference | Co-channel interference | RRM tuning, channel plan |
| reboots | APs rebooting | Power, firmware, crash loop |
| outages | APs going offline | Uplink switch, PoE, connectivity |

## Wired Metrics (sle: "wired")

| Metric | Description | Key Classifiers |
|---|---|---|
| `switch-health-v2` | Switch health composite (CPU, memory, temp) | switch-unreachable, system-cpu, system-memory, system-temp, system-power, capacity-route-table, capacity-arp-table, capacity-mac-address-table, network-wan-latency, network-wan-jitter |
| `switch-throughput` | Port throughput health | (query at runtime) |
| `switch-bandwidth-v2` | Bandwidth utilization health | (query at runtime) |
| `switch-stc-v4` | Wired client connect success | (query at runtime) |

Prefer `switch-health-v2`, `switch-bandwidth-v2`, `switch-stc-v4` over non-versioned equivalents.

### Wired Classifier Fixes

| Classifier | Meaning | Fix |
|---|---|---|
| switch-unreachable | Switch disconnected | Check uplink, power, management VLAN |
| system-cpu | CPU above threshold | Broadcast storms, spanning tree issues |
| system-memory | Memory exhaustion | Reboot, check for leak |
| system-temp | Temperature alarm | Rack ventilation, fan status |
| system-power | PoE/PSU issue | PoE budget, PSU redundancy |
| capacity-arp-table | ARP table near full | Too many hosts, ARP flooding |
| capacity-mac-address-table | MAC table near full | MAC flooding, oversized L2 domain |

## WAN Metrics (sle: "wan")

| Metric | Description | Key Classifiers |
|---|---|---|
| `gateway-health` | Gateway health (CPU, memory, temp, DHCP pool) | gateway-disconnected, system-cpu-control-plane, system-cpu-data-plane, system-memory, system-temp-cpu, system-temp-chassis, system-power, table-capacity-fib, table-capacity-flow, dhcp-pool-dhcp-denied, dhcp-pool-dhcp-headroom |
| `wan-link-health-v2` | WAN link quality (latency, jitter, loss) | interface-congestion, interface-port-down, interface-cable-issues, network-latency, network-jitter, network-loss, network-vpn-path-down, isp-reachability-arp, isp-reachability-dhcp |
| `application-health` | App performance via gateway | (query at runtime) |
| `gateway-bandwidth` | Gateway bandwidth utilization | (query at runtime) |

Prefer `wan-link-health-v2` over `wan-link-health`.

Note: `wan-link-health-v2 = 0` often means no WAN paths monitored, not an outage.

### WAN Classifier Fixes

| Classifier | Meaning | Fix |
|---|---|---|
| gateway-disconnected | Gateway offline | Management connectivity, power |
| system-cpu-control-plane | Control plane CPU spike | Routing churn, BGP reconvergence |
| interface-port-down | WAN port down | Cable, SFP, ISP CPE |
| interface-congestion | WAN saturated | Upgrade bandwidth, QoS |
| network-latency | RTT above threshold | ISP routing, path change |
| network-loss | Packet loss | Physical layer, congestion |
| isp-reachability-arp | ISP gateway not responding | CPE/ISP issue |
| dhcp-pool-dhcp-denied | DHCP pool exhausted | Expand pool |
