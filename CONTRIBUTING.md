# Contributing

## Run the tests

```sh
python3 -m pip install -r requirements.txt   # in a virtual environment
make test      # Python contracts, then the Emacs ERT suite
make compile   # byte-compiles with warnings as errors; `make clean` after
make demo      # the tutorial on fictional data
```

Every test works in its own temporary directory; none reads or writes a real
`org-reason-directory`. CI runs the same on Linux, macOS and Windows, and checks
that the vendored Reason Commons files still match `vendor/reasoncommons/UPSTREAM.json`.

## Layout

| Path | What |
|---|---|
| `org-reason.el` | Mode, keymaps, `org-reason:` view links, tutorial launcher, Org-roam exclusion |
| `org-reason-core.el` | Paths, IDs, Org storage primitives, read-only views, Python lookup |
| `org-reason-capture.el`, `-gtd`, `-learning`, `-review`, `-metadata` | One concern each |
| `org-reason-reasoning.el` + `org_reason_commons.py` | Reason Commons: Emacs side and the JSON-in/JSON-out YAML editor |
| `org-reason-media.el` | Original imports and explicit OCR/transcription adapters |
| `org-reason-demo.el` | The fictional workspace the tutorial runs in |
| `vendor/reasoncommons/` | Pinned upstream files; **never edit** — update them from upstream and re-pin the hashes |
| `capture/` | Bookmarklet and the OS handlers for `org-protocol://` |
| `scripts/check_vendor.py` | Checks `vendor/` against `UPSTREAM.json` (CI runs it) |
| `features/`, `docs/jobs-and-acceptance.md` | Behaviour as scenarios, mapped to tests |
| `test/` | ERT and Python tests |

## Rules for changes

- New behaviour gets a job, a scenario in `features/`, and a test.
- Functions named `org-reason--…` are internal; the stable entry points are listed
  in `docs/customization.md`.
- Keep adapters optional and out of quick text capture. Nothing runs on a timer,
  sends data anywhere, or publishes.
- Package commands never overwrite originals, frozen forecasts or history files.
- Derived views bind keys through `org-reason--view-setup`, never `local-set-key`,
  which would change `org-mode-map` for every Org buffer.
- Write new files as UTF-8 with LF (`coding-system-for-write 'utf-8-unix`), save
  through `org-reason--save-buffer`, and build paths with `org-reason-path`, so
  records are identical across operating systems and Windows never prompts for
  an encoding or visits one file under two names.
- `make test` loads the sources (`load-prefer-newer`); if Emacs uses this clone
  via `package-vc-install-from-checkout`, run `M-x package-vc-rebuild` after
  editing, or it keeps loading the stale byte-compiled files.
