# REA setup for Flam key analysis

Date: 2026-10-26. Host: Omarchy Linux, Node **26.12.1**. Goal: use [REA](https://github.com/morluto/rea) (`rea-agents`) against Flam crypto targets for fw **2.4.2**.

## Exact commands run

```bash
# CLI available via npx (no global install required)
npx --yes rea-agents@latest --help
npx --yes rea-agents@latest doctor

# Cursor MCP + skill
npx --yes rea-agents@latest setup --yes --client cursor
npx --yes rea-agents@latest setup --yes --client cursor --skill-client shared

# Ghidra 12.1.4 (REA requires 12.1.x; prior ~/ghidra was 11.2.1)
curl -L --fail -o /tmp/ghidra_12.1.4_PUBLIC_20260921.zip \
  'https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_12.1.4_build/ghidra_12.1.4_PUBLIC_20260921.zip'
echo 'ddac49f903da9d5bac833e5cc79395098b9c33cfd3279be5f31bd00387d2d4db  /tmp/ghidra_12.1.4_PUBLIC_20260921.zip' | sha256sum -c -
unzip -q -d ~/opt /tmp/ghidra_12.1.4_PUBLIC_20260921.zip

export GHIDRA_INSTALL_DIR=/home/yariminal/opt/ghidra_12.1.4_PUBLIC
# also set in ~/.cursor/mcp.json → mcpServers.rea.env.GHIDRA_INSTALL_DIR
# and appended to ~/.bashrc

npx --yes rea-agents@latest doctor   # ghidra-* checks healthy with 12.1.4
```

## What was configured

| Piece | Location / value |
|---|---|
| Package | `rea-agents@6.8.0` via `npx -y` |
| Cursor MCP | `~/.cursor/mcp.json` server `rea` |
| Skill | `~/.agents/skills/reverse-engineer-anything/` |
| Ghidra | `/home/yariminal/opt/ghidra_12.1.4_PUBLIC` |
| Env | `GHIDRA_INSTALL_DIR` (MCP + bashrc) |

## Doctor notes (after setup)

- **Ghidra 12.1.4**: healthy (headless + decompiler + JDK 27).
- **Hopper / IDA / JADX / Kuna**: not installed (optional; not required for Python-source path).
- **Binwalk**: not wired (`REA_BINWALK_COMMAND`); `inspect-firmware-regions` unavailable until set.
- Global `doctor` still reports `healthy: false` because other agent registrations (Codex, Claude, …) are unconfigured — Cursor + Ghidra path is enough for this work.

## Analysis commands used against Flam targets

```bash
export GHIDRA_INSTALL_DIR=/home/yariminal/opt/ghidra_12.1.4_PUBLIC

# Inventory host Python crypto sources into REA historical graphs
npx --yes rea-agents@latest import-reference-source \
  /home/yariminal/flam-re/luniiqt-tools/Lunii.QT/pkg/api --json
npx --yes rea-agents@latest import-reference-source \
  /home/yariminal/flam-re/Flam.RE/tools/python --json

# Desktop / tree probe of Lunii.QT checkout
npx --yes rea-agents@latest inspect-desktop-application \
  /home/yariminal/flam-re/luniiqt-tools/Lunii.QT --json

# On-device opaque blobs (layout / entropy only — no story dump)
npx --yes rea-agents@latest inspect-byte-entropy \
  /run/media/yariminal/FLAM/str/c103c95c-a852-4d8f-9c03-82f3814b572d/key --json
npx --yes rea-agents@latest inspect-byte-entropy \
  /run/media/yariminal/FLAM/.mdf --json

# Binary layout of packaged host app (not device FW)
npx --yes rea-agents@latest inspect-binary-layout \
  /home/yariminal/.local/opt/lunii-qt/lunii-qt --json
```

Evidence JSON copies: `internal/rea-flam/`. Findings: [`rea-flam-findings.md`](rea-flam-findings.md).

## Not installed / not run

- Hopper (paid; REA can install with `--install-hopper` only with explicit approval).
- No `update-main.enc` / `update-comm.enc` on disk → no Ghidra decompile of Flam MCU firmware yet.
- No device write / flash / SWD.
