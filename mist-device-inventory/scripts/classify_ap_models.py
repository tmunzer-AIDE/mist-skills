#!/usr/bin/env python3
"""Classify Juniper/Mist AP models by Wi-Fi standard and capabilities.

Accepts the JSON output of get_mist_constants(constant_type='device_models')
from stdin or a file, filters to APs, and outputs a classified JSON table.

Usage:
    python3 scripts/classify_ap_models.py < device_models.json
    python3 scripts/classify_ap_models.py device_models.json
    python3 scripts/classify_ap_models.py --help
"""

import json
import sys

# Wi-Fi standard classification — update when new models are released
WIFI7 = {"AP36", "AP36M", "AP37", "AP47", "AP47D", "AP47E", "AP66", "AP66D", "AP723H"}
WIFI6E = {"AP33", "AP34", "AP45", "AP45E", "AP63", "AP63E", "AP64"} | WIFI7  # Wi-Fi 7 is a superset of 6E
WIFI6 = {"AP32", "AP32E", "AP43", "AP43E", "AP43-FIPS", "AP43E-FIPS", "AP61", "AP61E"}
WIFI5 = {"AP41", "AP41E", "AP21", "AP12"}
LEGACY = {"AP17", "AP24", "AP27", "AP27E"}
GPS_MODELS = {"AP63", "AP63E", "AP64", "AP66", "AP66D"}
EXCLUDED = {"BT11"}  # Bluetooth beacon, not a Wi-Fi AP


def classify(model: str) -> dict:
    caps = []
    if model in GPS_MODELS:
        caps.append("gps")
    if model in WIFI6E:
        caps.append("6ghz")

    if model in WIFI7:
        return {"standard": "Wi-Fi 7 (802.11be)", "capabilities": caps}
    if model in WIFI6E:
        return {"standard": "Wi-Fi 6E (802.11ax)", "capabilities": caps}
    if model in WIFI6:
        return {"standard": "Wi-Fi 6 (802.11ax)", "capabilities": caps}
    if model in WIFI5:
        return {"standard": "Wi-Fi 5 (802.11ac)", "capabilities": caps}
    if model in LEGACY:
        return {"standard": "Wi-Fi 4 (802.11n)", "capabilities": caps}
    return {"standard": "unclassified", "capabilities": caps}


def main():
    if "--help" in sys.argv or "-h" in sys.argv:
        print((__doc__ or "").strip())
        print("\nOutput: JSON array of {model, standard, capabilities, classified}")
        print("Exit codes: 0 = success, 1 = parse error")
        sys.exit(0)

    # Read input from file argument or stdin
    if len(sys.argv) > 1 and sys.argv[1] not in ("--help", "-h"):
        with open(sys.argv[1]) as f:
            raw = json.load(f)
    else:
        raw = json.load(sys.stdin)

    # Accept both the full MCP response and just the data array
    models = raw.get("data", raw) if isinstance(raw, dict) else raw

    results = []
    for entry in models:
        model = entry.get("model", "")
        dev_type = entry.get("type", "")
        if dev_type != "ap" or model in EXCLUDED:
            continue
        info = classify(model)
        results.append({
            "model": model,
            "standard": info["standard"],
            "capabilities": info["capabilities"],
            "classified": info["standard"] != "unclassified",
        })

    # Sort: classified first (by standard desc), unclassified last
    standard_order = {
        "Wi-Fi 7 (802.11be)": 0,
        "Wi-Fi 6E (802.11ax)": 1,
        "Wi-Fi 6 (802.11ax)": 2,
        "Wi-Fi 5 (802.11ac)": 3,
        "Wi-Fi 4 (802.11n)": 4,
        "unclassified": 5,
    }
    results.sort(key=lambda r: (standard_order.get(r["standard"], 99), r["model"]))

    unclassified = [r for r in results if not r["classified"]]
    if unclassified:
        models_str = ", ".join(r["model"] for r in unclassified)
        print(f"WARNING: {len(unclassified)} unclassified model(s): {models_str}", file=sys.stderr)

    json.dump(results, sys.stdout, indent=2)
    print()  # trailing newline


if __name__ == "__main__":
    main()
