# Samsung Fast Charging (AFC & USB-PD) on Linux: Galaxy Tab A8 (SM-X205)

## 1. Executive Summary: Is Fast Charging Possible on Linux?
**YES, 100%.** Samsung Adaptive Fast Charging (AFC, 9V @ 1.67A / 15W) and USB Power Delivery (USB-PD) are supported and operational at the kernel hardware driver level on the Samsung Galaxy Tab A8 (`SM-X205` / Unisoc Tiger T618).

Unlike proprietary vendors whose charging controllers rely on proprietary Android HALs or closed userspace daemons, the SM-X205 charging architecture is completely implemented inside the Linux kernel power supply subsystem.

---

## 2. Hardware Architecture & Charging Controllers

The tablet incorporates a multi-IC charge path managed by the kernel voter (`sprd_vote`):

```
       [ USB Type-C Connector / Port Controller ]
                     │
         ┌───────────┴───────────┐
         ▼                       ▼
[ Unisoc SC2730 PMIC ]    [ SG Micro SGM4154x ]
(Fast Charge Controller)  (Switching Charger IC, I2C 4-003b)
         │                       │
         └───────────┬───────────┘
                     ▼
         [ Linux charger-manager ]
         (JEITA Safety Curves & Voting Governor)
                     │
                     ▼
         [ HQ-6300NA-ATL Battery Pack ]
         (7,040 mAh / 6,804 mAh Usable, 4.34V max)
```

1. **SG Micro SGM4154x Switching Charger (`sgm4154x_charger`):**
   - Directly negotiates BC1.2 protocols (SDP, DCP, CDP) and AFC (Samsung Adaptive Fast Charging).
   - Manages input current limit (`input_current_limit`), battery charge current (`constant_charge_current`), and system power-path.
2. **Unisoc SC2730 Fast Charger Controller (`sc2730_fast_charger`):**
   - Handles USB Type-C CC pin detection and USB-PD negotiation (`tcpm-source-psy-sc27xx-pd`).
   - Supports High-Voltage (9V) mode and SFCP / BrickID detection.
3. **Charger Manager & JEITA Governor (`charger-manager`):**
   - Enforces thermal throttling and safety curves (`cm-afc-jeita-temp-table`, `cm-fchg-jeita-temp-table`).
   - High voltage is explicitly permitted by default (`hv_disable = 0`).

---

## 3. Charger Types & Negotiation Behavior

| Charger Type | Input Voltage | Max Current | Power | Kernel Detection / Status |
|---|---|---|---|---|
| **Samsung AFC Brick (Adaptive Fast Charge)** | **9.0V** | **1.67A** | **15W** | `afc_result = 1`, `hv_charger_status = 1`, `sgm4154x: AFC` |
| **USB Power Delivery (USB-PD 15W+)** | **9.0V** / 5.0V | **1.67A** / 2.0A | **15W** | `tcpm-source-psy`, `sc2730_fast_charger: PD` |
| **Standard Wall Charger (DCP)** | 5.0V | 2.0A | 10W | `sgm4154x: DCP` |
| **PC USB 3.0 / 2.0 Port (SDP)** | 5.0V | 0.5A | 2.5W | `sgm4154x: SDP` (Voter throttles to protect host USB port) |

> [!NOTE]
> When the tablet is plugged into a PC USB port (e.g. for development or ADB), the voter governor strictly limits current to 500mA (`SDP`) to prevent blowing motherboard USB fuses. Connecting a Samsung 15W AFC or 18W+ USB-PD charger immediately switches the kernel into 9V high-voltage mode.

---

## 4. Real-Time Sysfs Interface

Userspace can monitor or query charging status via `/sys/class/power_supply/battery`:

- **AFC Negotiation Flag:** `/sys/class/power_supply/battery/afc_result` (`1` = 9V AFC negotiated, `0` = 5V standard)
- **High-Voltage Status:** `/sys/class/power_supply/battery/hv_charger_status` (`1` = 9V High Voltage active)
- **High-Voltage Enable:** `/sys/class/power_supply/battery/hv_disable` (`0` = High Voltage allowed, `1` = force 5V)
- **Cell Voltage:** `/sys/class/power_supply/battery/voltage_now` (in $\mu\text{V}$, e.g. `3818000` = 3.818 V)
- **Current Flow:** `/sys/class/power_supply/battery/current_now` (in $\mu\text{A}$, positive when charging, negative when discharging)
- **Battery Temperature:** `/sys/class/power_supply/battery/temp` (in tenths of °C, e.g. `311` = 31.1 °C)
- **Battery Capacity:** `/sys/class/power_supply/battery/capacity` (e.g. `50`%)

---

## 5. CLI Monitor Tool: `gta8-charging`

The system includes a dedicated CLI utility installed at `/usr/local/bin/gta8-charging`:

```bash
# Display formatted live charging dashboard
gta8-charging

# Continuous live refresh (1s updates)
gta8-charging --watch

# Machine-readable JSON output
gta8-charging --json
```
