# Lost Button — first AI-assisted Flam homebrew

Original 3-beat Flam-native story (fw 2.4.2 mint). No Flam/Lunii catalog assets.

| | |
|---|---|
| **Title** | Lost Button |
| **Subtitle** | A rainy stop |
| **UUID** | `6c35f0b4-1319-b1c5-f81b-1cc39db96de9` |
| **uuid_seed** | `8c12327f-7f5b-4122-aeb8-04571c45d765` |
| **Host project** | `/home/yariminal/flam-re/stories/lost-button/` |
| **Pack** | `/home/yariminal/flam-re/stories/lost-button/_out/lost-button.plain.pk` |
| **Store mirror** | `internal/lost-button/` (+ `_out/lost-button.plain.pk`) |
| **Check** | `flam_build` / `flam_check`: **0 ERR, 0 WARN** (2026-11-01) |
| **On device** | Packed 2026-11-01 via `flamtool/pack.py` (fw2 SNU32 + C0/C1); synced; clean eject |

## How to play

1. Power Flam into the library (not mass-storage). Title should read **Lost Button**.
2. Open story → **Begin**.
3. Bus-stop scene: click (or wheel) to continue.
4. Choose **Left puddle** or **Right puddle**.
5. Find the shiny button → it goes into the **Backpack** list (session inventory on `Global.LB`, no `state` writes).
6. Click the backpack entry (plays short tone) → **Keep it** or **Leave it**.
7. Title-card ending → returns to **Begin**. Back from the start menu exits to the library.

Device verify (owner): readable title; full path; exit → relaunch ×2 without reboot.

## Rebuild / repack

```bash
export HB=/home/yariminal/flam-re/flam-player/skills/flam-homebrew
export FT=/home/yariminal/flam-re/flamtool
export PY=/home/yariminal/flam-re/luniiqt-tools/venv/bin/python
export FLAM_ROOT=/run/media/yariminal/FLAM

python3 "$HB/scripts/flam_build.py" ~/flam-re/stories/lost-button
# mount Flam, then:
$PY "$FT/pack.py" "$FLAM_ROOT" ~/flam-re/stories/lost-button/_out/lost-button.plain.pk
sync && udisksctl unmount -b /dev/sda1 && udisksctl power-off -b /dev/sda
```

If UUID already exists under `str/`, remove it first (`cleanup.py` or delete `str/<uuid>` + list line).

## Modules

| Module | Role |
|---|---|
| `lost_button_1_0_0` | Orchestrator + `Global.LB` backpack; start / choices / ending |
| `lb_bus_1_0_0` | Rainy bus-stop scene |
| `lb_find_1_0_0` | Button pickup |
| `list-choice_1_0_0` | Runtime: puddle + backpack + keep/leave |
| `title-card` | Runtime: ending card |

## Features exercised

- Wheel / click scene advance  
- `list-choice` with `silent.mp3` / `tone.mp3` rows  
- Light backpack (in-memory, relaunch-safe)  
- `title-card` ending  

Not yet claimed **device-proven** until owner play-test (see [`ai-flam-pipeline.md`](ai-flam-pipeline.md) feature map).
