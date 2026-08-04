# NOTICE

This repository packages and redistributes upstream software published by the
[Python Packaging Authority (PyPA)](https://www.pypa.io/). The Apache-2.0
license in [`LICENSE`](LICENSE) covers the OCX pipeline files authored here. It
does **not** cover any upstream-derived artifact — each package's redistributed
bytes carry their own license, recorded below.

Each package's logo is reproduced for catalog identification only, under
nominative fair use. The marks remain the property of their respective owners
and no endorsement is implied.

| Package | GHCR path | Upstream SPDX |
|---|---|---|
| `pipx` | `ghcr.io/ocx-contrib/pypa/pipx` | `MIT` |

---

## `pipx`

Upstream: <https://github.com/pypa/pipx>
Published to `ghcr.io/ocx-contrib/pypa/pipx`.

| Component | SPDX | Holder |
|---|---|---|
| pipx | **MIT** | Chad Smith and pipx contributors |

Verified against the upstream repository's own license metadata:

```
$ gh api repos/pypa/pipx/license --jq '{spdx: .license.spdx_id}'
{"spdx":"MIT"}
```

and the PyPI release metadata, which carries the SPDX expression `MIT`
(`license_expression` on <https://pypi.org/pypi/pipx/json>).

### What this package redistributes

Unlike the archive mirrors in this fleet, `pypa/pipx` is an OCX **environment
package**: it does not republish a GitHub release asset. It republishes the
wheels resolved for each pipx release from the Python Package Index, composed
with a private CPython interpreter. Redistributed third-party components, each
under its own license:

| Wheel | SPDX | Source of the classification | Upstream |
|---|---|---|---|
| `pipx` | MIT | `license_expression` | <https://github.com/pypa/pipx> |
| `argcomplete` | Apache-2.0 | Trove classifier | <https://github.com/kislyuk/argcomplete> |
| `click` | BSD-3-Clause | `license_expression` | <https://github.com/pallets/click> |
| `filelock` | MIT | `license_expression` | <https://github.com/tox-dev/filelock> |
| `packaging` | Apache-2.0 OR BSD-2-Clause | `license_expression` | <https://github.com/pypa/packaging> |
| `platformdirs` | MIT | `license_expression` | <https://github.com/tox-dev/platformdirs> |
| `userpath` | MIT | Trove classifier | <https://github.com/ofek/userpath> |
| `colorama` (Windows only) | BSD-3-Clause | Trove classifier (`BSD License`) | <https://github.com/tartley/colorama> |

Read from each project's own PyPI metadata, not from memory:

```
$ python3 -c "import json,urllib.request; i=json.load(urllib.request.urlopen(
    'https://pypi.org/pypi/<pkg>/json'))['info']; print(i.get('license_expression'),
    [c for c in i['classifiers'] if c.startswith('License')])"
```

Every one is permissive. The exact closure for any published version is
recorded in that version's derived PEP 751 lock, produced by the pipeline and
attached to the run.

The private interpreter is **not** redistributed by this repository — it is
pulled in by reference as a pinned dependency on
`ocx.sh/astral-sh/python-build-standalone`, whose own attribution (PSF-2.0 for
CPython, MPL-2.0 for the build recipes) lives in `ocx-contrib/mirror-astral-sh`.

The pipx logo is reproduced from the upstream repository root
(<https://github.com/pypa/pipx/blob/main/logo.svg>).
