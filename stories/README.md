# Community Flam stories

Original interactive stories for stock Lunii Flam (**fw 2.4.2**), minted with this repo’s [`flamtool/pack.py`](../flamtool/pack.py).

## Add your story

1. Read [`docs/authoring-full-story.md`](../docs/authoring-full-story.md) (audio lifecycle, backpack, chapter map, checklist).
2. Create `stories/<slug>/` with your sources (Lua + art + sounds) and a short `README.md` (title, license, synopsis, build notes).
3. Prefer shipping both:
   - an **editable tree** others can fork, and
   - `dist/<slug>.plain.pk` ready to mint (original / clearly licensed only).
4. Open a PR. Keep **catalog / Emily / paid Flam content** out of the tree.

### Suggested layout

```text
stories/<slug>/
  README.md
  flam.json          # title, uuid_seed, module, version
  main.lua
  script/*.lua       # story modules only (runtime comes from flam-homebrew build)
  img/               # PNG sources and/or built .lif
  sounds/            # .mp3 + .mp3map
  dist/<slug>.plain.pk
```

### Rules

- **Original or clearly licensed** prose, art, and audio only
- **No CFW**, no device keys, no `.mdf` dumps, no official catalog assets
- On-device strings: Latin-1; keep titles short
- Document which Flam features you use (choices / backpack / chapters / mini-game) and whether they were device-tested

## Examples in this repo

| Folder | What | Good for |
|--------|------|----------|
| [`lost-button/`](lost-button/) | Short original demo | list-choice + session backpack |
| [`kipodi-learns-to-ride-a-bike/`](kipodi-learns-to-ride-a-bike/) | Full open-source adventure | chapters, backpack, Box Breaker mini-game, shippable `.plain.pk` |

Build skill / runtime modules: [scarlaty/flam-player](https://github.com/scarlaty/flam-player) `skills/flam-homebrew`.
