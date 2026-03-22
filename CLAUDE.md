# RC Construction Idle — Claude Code Project Context

## Project Overview
A mobile idle/incremental game for Android (Google Play Store) built in Godot 4.x.
Players manage a construction job site, purchasing and upgrading RC-scale equipment
that passively earns currency. Completing project phases unlocks new equipment and
eventually triggers a prestige loop.

---

## Tech Stack
- **Engine:** Godot 4.x (GDScript)
- **Target Platform:** Android (APK export)
- **Testing:** Godot editor play mode + Android device via USB debug
- **Version Control:** Git

---

## Architecture Decisions

### Singletons (Autoloads)
| Singleton | File | Responsibility |
|---|---|---|
| `GameManager` | `src/core/GameManager.gd` | Central game state, currency, earnings/sec |
| `SaveSystem` | `src/core/SaveSystem.gd` | Persist/load all game state to disk |
| `OfflineEarnings` | `src/core/OfflineEarnings.gd` | Calculate idle income on app resume |
| `MachineRegistry` | `src/machines/MachineRegistry.gd` | All machine definitions and base stats |

### Signal Convention
- All cross-system communication via Godot signals
- UI never modifies game state directly — always goes through GameManager
- Example: `GameManager.currency_changed.emit(new_amount)`

### Naming Conventions
- GDScript files: PascalCase (`GameManager.gd`)
- Variables: snake_case (`earnings_per_second`)
- Constants: SCREAMING_SNAKE_CASE (`MAX_OFFLINE_SECONDS`)
- Signals: past_tense verbs (`currency_changed`, `machine_purchased`)
- Scene files: PascalCase (`MainSiteView.tscn`)

---

## Economy Constants (DO NOT CHANGE without updating all references)

### Machine Roster
| ID | Name | Base $/sec | Purchase Cost | Unlock Condition |
|---|---|---|---|---|
| `dump_truck` | Dump Truck | 0.10 | 10.00 | Always available |
| `skid_steer` | Skid Steer | 0.60 | 120.00 | Site Clear phase complete |
| `excavator` | Excavator | 4.00 | 1300.00 | Site Clear phase complete |
| `concrete_mixer` | Concrete Mixer | 25.00 | 14000.00 | Foundation phase complete |
| `tower_crane` | Tower Crane | 150.00 | 200000.00 | Pour phase complete |
| `compactor` | Compactor | 1000.00 | 3300000.00 | Frame phase complete |

### Upgrade Tiers (applied per machine)
| Tier | Cost Multiplier (of base purchase) | Earnings Multiplier |
|---|---|---|
| 1 | 2x | 1.5x |
| 2 | 5x | 2.0x |
| 3 | 20x | 3.0x |

### Project Phase Thresholds (Site 1 — cumulative earnings)
| Phase | Threshold | Unlocks |
|---|---|---|
| Site Clear | $500 | Skid Steer + Excavator |
| Foundation | $25,000 | Concrete Mixer |
| Pour | $750,000 | Tower Crane |
| Frame | $20,000,000 | Compactor |
| Complete | $500,000,000 | Prestige prompt |

### Prestige Multipliers (cumulative)
| Prestige # | Global Earnings Bonus |
|---|---|
| 1 | +25% |
| 2 | +50% |
| 3 | +100% |

### Offline Earnings
- Cap: 4 hours (14,400 seconds)
- Formula: `total_eps * min(elapsed_seconds, 14400)`

---

## Current Milestone
**M2 — Playable Game**
- [x] MachinePanel — reusable buy/upgrade row for all machines
- [x] MainSiteView shows all machines, phase progress, scrollable list
- [x] Auto-save every 30s + save on close/focus-loss
- [ ] Offline earnings popup on return
- [ ] Prestige button when Complete phase reached

## Completed Milestones
**M1 — Core Loop Foundation**
- [x] Project structure created
- [x] GameManager singleton scaffolded
- [x] Dump Truck purchasable and earning passively
- [x] Currency display updating in real time
- [x] Basic save/load working

---

## Key Files Map
```
src/
├── core/
│   ├── GameManager.gd       ← START HERE — central state
│   ├── SaveSystem.gd        ← File I/O for persistence
│   └── OfflineEarnings.gd  ← Called on app resume
├── machines/
│   ├── Machine.gd           ← Base resource class
│   └── MachineRegistry.gd  ← All machine definitions
├── ui/
│   ├── MainSiteView.tscn   ← Primary game screen
│   ├── MachinePanel.tscn   ← Per-machine buy/upgrade row
│   └── OfflinePopup.tscn   ← Welcome back earnings summary
└── scenes/
    └── Site1.tscn           ← Main scene
```

---

## Testing Approach
- **Unit logic:** GdUnit4 test runner (`tests/` directory)
- **In-editor:** F5 to run, use DebugPanel overlay to inspect live state
- **Android:** USB debug via `adb`, Godot one-click export to device
- **Offline earnings:** Use `DebugPanel.simulate_offline(seconds)` helper

---

## Contacts / Context
- Developer: Joshua Fritzjunker
- Side project of Fritz Automation / Two Makers Co ecosystem
- Target: Google Play Store, Android, free-to-play idle
- Sessions with Claude: continue from this file + git history
