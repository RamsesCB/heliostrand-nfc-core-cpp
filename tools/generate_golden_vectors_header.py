#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
src = ROOT / "test/vectors/golden_telemetry_vectors.json"
dst = ROOT / "test/generated/golden_vectors.h"
dst.parent.mkdir(parents=True, exist_ok=True)

motor_map = {"STOPPED": 0, "FORWARD": 1, "REVERSE": 2}
dir_map = {"BALANCED": 0, "NORTH": 1, "SOUTH": 2, "EAST": 3, "WEST": 4}

doc = json.loads(src.read_text(encoding="utf-8"))
valid = [v for v in doc["vectors"] if v["expected"].get("valid") is True]
invalid = [v for v in doc["vectors"] if v["expected"].get("valid") is False]

lines = [
    "#pragma once",
    "#include <stdint.h>",
    "",
    "struct GeneratedGoldenVector {",
    "    const char *id;",
    "    uint8_t payload[12];",
    "    uint8_t version, motor, direction, sequence;",
    "    uint8_t ldrN, ldrS, ldrW, ldrE;",
    "    uint8_t pitch, yaw;",
    "    uint16_t batteryMv;",
    "    uint8_t reversals;",
    "};",
    "",
    "static const GeneratedGoldenVector GENERATED_GOLDEN_VECTORS[] = {",
]

for v in valid:
    e=v["expected"]
    raw=bytes.fromhex(v["hex"])
    arr=", ".join(f"0x{x:02X}" for x in raw)
    lines.append(
        f'    {{"{v["id"]}", {{{arr}}}, {e["version"]}, '
        f'{motor_map[e["motor_state"]]}, {dir_map[e["light_direction"]]}, '
        f'{e["sequence_number"]}, {e["ldr_north"]}, {e["ldr_south"]}, '
        f'{e["ldr_west"]}, {e["ldr_east"]}, {e["servo_pitch"]}, '
        f'{e["servo_yaw"]}, {e["battery_millivolts"]}, {e["polarity_reversals"]}}},'
    )

lines += [
    "};",
    f"static const uint8_t GENERATED_GOLDEN_VECTOR_COUNT = {len(valid)};",
    "",
]

if invalid:
    raw=bytes.fromhex(invalid[0]["hex"])
    arr=", ".join(f"0x{x:02X}" for x in raw)
    lines += [
        f"static const uint8_t GENERATED_CORRUPTED_PAYLOAD[12] = {{{arr}}};",
        "",
    ]

dst.write_text("\n".join(lines), encoding="utf-8")
print(dst)
