# mirror-pypa

OCX mirrors for [PyPA](https://www.pypa.io/) (Python Packaging Authority)
tooling.

| Package | Coordinate | Upstream | Source type |
|---|---|---|---|
| `pipx` | [`ocx.sh/pypa/pipx`](https://index.ocx.sh/pypa/pipx) | [pypa/pipx](https://github.com/pypa/pipx) | `pypi` |

```console
$ ocx add ocx.sh/pypa/pipx
$ pipx --version
```

## These are environment packages, not archive mirrors

Every other repository in this fleet republishes an upstream release archive.
PyPA ships Python **applications**, so this repository uses ocx-mirror's
`source.type: pypi` instead:

1. versions are discovered from the PyPI JSON API,
2. a [PEP 751](https://peps.python.org/pep-0751/) lock is derived per version
   in-pipeline by `uv pip compile --universal`,
3. the resolved wheels are composed with a private
   [python-build-standalone](https://github.com/astral-sh/python-build-standalone)
   interpreter into a runnable environment package,
4. entrypoints are synthesized from the root package's `console_scripts`, plus
   an always-present `python`.

Consequences worth knowing before editing a spec here:

- **No `metadata.json`.** Env metadata is *composed* from the resolved lock;
  a hand-authored `metadata:` key is rejected at spec load with exit 65. The
  same goes for `assets:`, `variants:` and `bin_scan:`.
- **`wheels:` replaces `assets:`.** Its keys are OCI platform strings and its
  values are PEP 425 platform-tag prefix filters (`~` takes the key-derived
  default). Every `wheels:` key's base `os/arch` must appear in `platforms:`,
  and vice versa.
- **`uv` is a required toolchain entry** in [`ocx.toml`](ocx.toml) — the lock
  derivation spawns it off `PATH`.
- **Wheel layers are shared.** Each wheel is pushed once to a content-addressed
  repository under `pip-packages/files.pythonhosted.org/<name>` and
  cross-repository-mounted into every app that depends on it.

## Layout

```
mirror-pypa/
├── mirror-base.yml         # repo-wide policy, inherited via `extends:`
├── logo.svg / logo.png     # shared describe assets — named per spec via catalog.logo
├── ocx.toml / ocx.lock     # pinned toolchain (cli, mirror, uv)
├── pipx/
│   ├── mirror.yml          # the spec
│   ├── CATALOG.md          # → `ocx package describe`
│   └── tests/smoke.star    # Starlark smoke test
└── .github/workflows/      # ALL GENERATED — never hand-edit
```

## Editing

Change the **spec**, never the generated workflow YAML — `verify-generated.yml`
fails CI with exit 65 on any hand-edit. After touching a spec, regenerate,
naming **every** spec in the repo (`--spec` appends rather than replaces):

```console
$ direnv allow                       # once, to activate the pinned toolchain
$ ocx-mirror package validate pipx/mirror.yml
$ ocx-mirror package pipeline generate ci --spec pipx/mirror.yml
$ ocx-mirror package pipeline generate ci --check --spec pipx/mirror.yml
```

Run the smoke test locally against a real bundle before pushing — it costs
nothing and catches every Starlark dialect error, which would otherwise red
every version on every platform at once:

```console
$ ocx-mirror package pipeline plan --spec pipx/mirror.yml \
    --output .ocx-mirror/plan.json --locks-dir .ocx-mirror/locks
$ ocx-mirror package pipeline prepare --spec pipx/mirror.yml \
    --plan .ocx-mirror/plan.json --work-dir .ocx-mirror/work
$ ocx package test --platform linux/amd64 \
    --identifier ghcr.io/ocx-contrib/pypa/pipx:<version> \
    <bundle> --script pipx/tests/smoke.star
```

Commits go straight to `main` — mirror repositories take no PRs. The one
exception is a package claim against
[`ocx-sh/index`](https://github.com/ocx-sh/index), which is human-lane by
governance rule G-04.

## License

Pipeline files: Apache-2.0 ([`LICENSE`](LICENSE)). Redistributed upstream
wheels carry their own licenses — see [`NOTICE.md`](NOTICE.md).
