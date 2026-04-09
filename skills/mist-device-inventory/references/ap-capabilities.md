# AP Model Capabilities

Quick-reference for classifying Juniper Mist AP models by Wi-Fi standard and hardware features.

## Wi-Fi Standard Classification

| Standard | Models |
|---|---|
| Wi-Fi 7 (802.11be) | AP17, AP27, AP27E, AP36, AP36M, AP37, AP47, AP47D, AP47E, AP66, AP66D, AP723H |
| Wi-Fi 6E (6 GHz capable, 802.11ax) | AP24, AP34, AP45, AP45E, AP64 |
| Wi-Fi 6 (802.11ax, 2.4/5 GHz only) | AP12, AP32, AP32E, AP33, AP43, AP43-FIPS, AP43E, AP43E-FIPS, AP63, AP63E |
| Wi-Fi 5 (802.11ac) | AP21, AP41, AP41E, AP61, AP61E |

All Wi-Fi 7 models also support 6 GHz. Use `has_wifi_band6` to identify all 6 GHz-capable APs (Wi-Fi 7 + Wi-Fi 6E).

## Feature Flags

| Feature | Models |
|---|---|
| GPS | AP27, AP27E, AP36, AP36M, AP37, AP47, AP47D, AP47E, AP64, AP66, AP66D |
| Outdoor | AP61, AP61E, AP63, AP63E, AP64 |
| UWB (Ultra-Wideband) | AP47, AP47D, AP47E |
| Scanning radio | AP34, AP45, AP45E, AP64, AP66, AP66D |
| 160 MHz support (5 GHz) | AP33, AP34, AP43, AP43E, AP43-FIPS, AP43E-FIPS, AP45, AP45E, AP47, AP47D, AP47E, AP64, AP66, AP66D |
| PoE out | AP61, AP61E |
| Dual Ethernet uplink | AP43, AP43E, AP43-FIPS, AP43E-FIPS, AP45, AP45E, AP47, AP47D, AP47E |

## Non-AP Devices

- **BT11**: Bluetooth beacon — not a Wi-Fi AP. Exclude from Wi-Fi queries.

## Classification Logic

When `get_mist_constants(constant_type='device_models')` returns a model, classify using:

1. `has_11be == true` → Wi-Fi 7
2. `has_11ax == true && has_wifi_band6 == true` → Wi-Fi 6E
3. `has_11ax == true` → Wi-Fi 6
4. Otherwise → Wi-Fi 5

If a model is not in this reference, report it as "unclassified — check Juniper documentation" and show the raw model string.
