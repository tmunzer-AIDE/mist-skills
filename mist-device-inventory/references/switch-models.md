# Switch Model Reference

Juniper EX and QFX switch models supported by Mist Cloud.

## Model Families

| Family | Role | Models |
|---|---|---|
| EX2300 | Access | EX2300-24MP, EX2300-24P, EX2300-24T, EX2300-48MP, EX2300-48P, EX2300-48T, EX2300-C-12P, EX2300-C-12T |
| EX3400 | Access | EX3400-24P, EX3400-24T, EX3400-48P, EX3400-48T |
| EX4000 | Access | EX4000-8P, EX4000-12MP, EX4000-12MUP, EX4000-12P, EX4000-12T, EX4000-24MP, EX4000-24MUP, EX4000-24P, EX4000-24T, EX4000-48MP, EX4000-48MUP, EX4000-48P, EX4000-48T |
| EX4100 | Access | EX4100-24MP, EX4100-24P, EX4100-24T, EX4100-48MP, EX4100-48P, EX4100-48T |
| EX4100-F | Access (fiber) | EX4100-F-12P, EX4100-F-12T, EX4100-F-24P, EX4100-F-24T, EX4100-F-48P, EX4100-F-48T |
| EX4100-H | Access (high-density) | EX4100-H-12MP, EX4100-H-12T, EX4100-H-24F, EX4100-H-24MP |
| EX4300 | Distribution | EX4300-24P, EX4300-24T, EX4300-32F, EX4300-48MP, EX4300-48P, EX4300-48T |
| EX4400 | Distribution | EX4400-24MP, EX4400-24P, EX4400-24T, EX4400-24X, EX4400-48F, EX4400-48MP, EX4400-48MXP, EX4400-48P, EX4400-48XP, EX4400-48T |
| EX4600 | Aggregation | EX4600-40F |
| EX4650 | Aggregation | EX4650-48Y |
| EX5200 | Campus core | EX5200-24MP, EX5200-24T, EX5200-48MP, EX5200-48T |
| EX9200 | Data center | EX9204, EX9208, EX9214 |
| EX9251 | Data center | EX9251 |
| QFX5100 | Data center | QFX5100-24Q, QFX5100-48S, QFX5100-48T, QFX5100-96S |
| QFX5110 | Data center | QFX5110-32Q, QFX5110-48S |
| QFX5120 | Data center | QFX5120-32C, QFX5120-48T, QFX5120-48Y, QFX5120-48YM |
| QFX5130 | Data center spine | QFX5130-32CD, QFX5130-48C, QFX5130-48CM, QFX5130E-32CD |
| QFX5140 | Data center spine | QFX5140-24CD8O |
| QFX5200 | Data center spine | QFX5200-32C, QFX5200-48Y |
| QFX5230 | Data center spine | QFX5230-64CD |
| QFX5240 | Data center spine | QFX5240-64OD, QFX5240-64QD |
| QFX5241 | Data center spine | QFX5241-32OD, QFX5241-32QD, QFX5241-64OD, QFX5241-64QD |
| QFX5250 | Data center spine | QFX5250-64OE |
| QFX5700 | Data center fabric | QFX5700 |
| QFX10000 | Data center fabric | QFX10002-36Q, QFX10002-60C, QFX10002-72Q, QFX10008, QFX10016 |

## Virtual / Chassis

| Model | Type |
|---|---|
| vJunos-switch (VJUNOS) | Virtual switch |
| vJunos-EVO (VJUNOSEVO) | Virtual switch (EVO) |
| vEX9214 (VEX9214) | Virtual chassis |
| VQFX-10000 | Virtual QFX |
| JNP48Y8C-CHAS | Chassis switch |

## Model Name Decoding

The model suffix indicates port type and PoE capability:

| Suffix | Meaning |
|---|---|
| T | Copper (no PoE) |
| P | Copper with PoE |
| MP | Multi-Gig PoE (mGig / 2.5G/5G/10G) |
| MUP | Multi-Gig Universal PoE (90W) |
| MXP | Multi-Gig mixed PoE |
| XP | 10G SFP+ PoE |
| F | Fiber (SFP/SFP+) |
| X | 10G SFP+ |
| C | Compact (EX2300-C) or 100G QSFP28 |
| Q | 40G QSFP+ |
| Y | 25G SFP28 |
| S | 10G SFP+ |
| CD | 400G QSFP-DD |
| OD | 800G OSFP |
| QD | 800G QSFP-DD800 |
| OE | 800G OSFP (next-gen) |

The number before the suffix is the port count (e.g., EX4100-48P = 48 PoE ports).
