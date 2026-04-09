# Gateway & Router Model Reference

Juniper gateway, router, and SD-WAN models supported by Mist Cloud.

## Model Families

| Family | Role | Models |
|---|---|---|
| SRX300 | Branch firewall | SRX300, SRX320, SRX320-POE, SRX340, SRX345, SRX380 |
| SRX mid-range | Campus firewall | SRX400, SRX440, SRX550 |
| SRX high-end | Data center firewall | SRX1500, SRX1600, SRX2300, SRX4100, SRX4120, SRX4200, SRX4300, SRX4600, SRX4700 |
| SSR | SD-WAN / Session Smart | 128T-ROUTER, SSR, SSR-Madrid, SSR120, SSR130, SSR400, SSR440, SSR460, SSR480, SSR1200, SSR1300, SSR1400, SSR1500 |
| NFX150 | Branch CPE | NFX150-C-S1, NFX150-C-S1E, NFX150-S1, NFX150-S1E |
| NFX250 | Branch CPE | NFX250-ATT-LS1, NFX250-ATT-S1, NFX250-ATT-S2, NFX250-LS1, NFX250-S1, NFX250-S1E, NFX250-S2 |
| NFX350 | Branch CPE | NFX350-S1, NFX350-S2, NFX350-S3 |
| ACX7000 | WAN / aggregation | ACX7020, ACX7024, ACX7024X, ACX7100-32C, ACX7100-48L, ACX7332, ACX7348 |
| PTX | Service provider core | PTX10001-36MR, PTX10001-36MR-K, PTX10002-36CD, PTX10002-60MR, PTX10003-160C, PTX10003-80C, PTX10016, PTX12102-36Q, PTX12102-36QL, PTX12102-60Q, PTX12102-60QL |
| JNP | Service provider core | JNP10001-36MR, JNP10001-36MR-K, JNP10003-160C-CHAS, JNP10003-80C-CHAS, JNP10016-CHAS, JNP10016-CHAS-BB |
| MX | WAN edge / router | MX204, MX240, MX301, MX304, MX480, MX960, MX10003, MX10008 |

## Virtual Models

| Model | Type |
|---|---|
| vSRX (VSRX) | Virtual firewall |
| vSRX3 (VSRX3) | Virtual firewall (v3) |

## Notes

- **MX series** uses API type `router` (not `gateway`). When querying inventory, filter with `device_type:'gateway'` for SRX/SSR/NFX/ACX/PTX, and `device_type:'router'` for MX.
- **SSR / 128T-ROUTER**: Session Smart Routers — SD-WAN devices. `128T-ROUTER` is the legacy model name for SSR.
- **NFX**: Network Functions Virtualization platform — runs virtual network functions on-premises.
- **JNP models**: Juniper Networks Platform chassis — same hardware as PTX, different naming for Mist management.
