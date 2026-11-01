# Story Studio — English UI (i18n)

Upstream: [Hugs11/story-studio](https://github.com/Hugs11/story-studio) (observed **v0.9.9**).  
Deliverable package: [`internal/story-studio-i18n/`](/cursor/stores/self/internal/story-studio-i18n/).

## How i18n works today (upstream)

**There is no i18n library.** The React/Tauri UI hard-codes French in JSX, dialogs, toolbars, validation, and many Tauri error strings. README docs are bilingual; the running app is French. `src/utils/frenchText.js` only normalizes search text / plural labels — it is not a locale system.

## What this package adds

Gettext-style catalogs (French string = msgid) plus a tiny runtime:

| Piece | Role |
|--------|------|
| `src/i18n/index.js` | `t()`, `setLocale()`, lazy read of `localStorage` key `storyStudio.uiLocale` |
| `src/i18n/LocaleContext.jsx` | React provider; re-render on locale change |
| `src/i18n/locales/{fr,en}.json` | ~2k UI strings (FR identity + EN) |
| `src/store/uiLocalePreference.js` | Persists locale via `KEYS.UI_LOCALE` |
| Preferences → Interface | Language selector (Français / English) |
| `rust-locales/{fr,en}.json` | Backend error catalog (optional follow-up wiring) |

French is **kept**. English is added alongside. Default remains `fr` until the user picks English.

Estimated coverage: **~93%** of extracted UI strings. Remaining gaps: ~89 template literals with `${...}` (listed in `meta/TEMPLATE_LITERALS_MANUAL.md`) and Rust errors until `translateError()` is used at call sites.

Flam / device code was not modified. No story content is included.

## Apply on a fork

1. **Fork** [Hugs11/story-studio](https://github.com/Hugs11/story-studio) under your GitHub account.
2. Clone your fork and create a branch, e.g. `feat/english-ui`.
3. **Drop in the file tree** (simplest):

```bash
cp -a /path/to/Context/internal/story-studio-i18n/file-tree/. .
```

   Or apply the unified patch from the repo root:

```bash
patch -p1 < /path/to/Context/internal/story-studio-i18n/patches/story-studio-english-ui.patch
```

   (Patch paths are `ss-fork/...` style from `diff -ruN`; if `patch` complains about prefixes, use the `file-tree/` copy instead.)

4. Install & run: `npm install` then `npm run tauri:dev` (or `npm run dev` for web-only).
5. Open **Preferences → Interface → Language → English**.

### Alternative: regenerate wraps

If you prefer to re-apply on a newer upstream tip:

```bash
# from story-studio repo root, with this package beside you
node /path/to/internal/story-studio-i18n/scripts/apply-ui-i18n.mjs
```

Then re-apply the small wiring patches in `patches/001-*.patch` … `003-*.patch` (LocaleProvider, `KEYS.UI_LOCALE`, language selector).

## Applied on Yariminal fork (2026-10-23)

- **Branch:** `feat/english-ui` on [Yariminal/story-studio](https://github.com/Yariminal/story-studio)
- **Fork PR:** https://github.com/Yariminal/story-studio/pull/1 — **merged** into `main` (2026-10-23)
- **Upstream compare (open when ready):** https://github.com/Hugs11/story-studio/compare/main...Yariminal:story-studio:feat/english-ui
- **Apply method:** `cp -a …/internal/story-studio-i18n/file-tree/. .` onto `main` @ v0.9.9 tip
- **Verify:** `npm install`, `npm run lint` clean, `npm run build` OK
- **Apply repairs (package artifacts):** restored mangled French `l'…` that the wrap script turned into fake `lt('…')`; braced JSX attrs (`title={t(...)}`); unwrapped mistaken `className=t("…")` back to plain class strings; dropped unused `t` imports

## Open a PR upstream

1. Push your branch to **your** fork (not required to push to Hugs11 directly).
2. Open a PR: `your-fork/feat/english-ui` → `Hugs11/story-studio` `main` (or their default branch). Compare link above.
3. Suggested PR title: `feat(i18n): add English UI locale alongside French`.
4. In the PR body, note: gettext-style msgids, Preferences language toggle, French preserved, template-literal follow-ups listed in the package meta.

## Package layout

```
internal/story-studio-i18n/
  locales/fr.json, en.json          # canonical JS catalogs
  rust-locales/fr.json, en.json     # backend error catalogs
  file-tree/                        # drop-in mirror of upstream paths
  patches/                          # unified + wiring diffs
  scripts/apply-ui-i18n.mjs         # optional re-wrap helper
  meta/coverage.json                # counts / coverage estimate
  meta/TEMPLATE_LITERALS_MANUAL.md  # manual follow-ups
```

## Follow-ups (optional)

- Rewrite `${...}` template UI strings to `t('… {name} …', { name })`.
- Pipe Tauri `invoke` errors through `translateError()` from `src/i18n/translateError.js`.
- Point Piper/XTTS **voice** language independently of **UI** language (already separate settings).
