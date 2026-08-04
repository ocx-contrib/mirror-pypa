---
title: pipx
description: Install and run Python applications in isolated environments
keywords: python,pypa,cli,install,virtualenv,isolation,packaging,pipx
---

# pipx

[pipx](https://github.com/pypa/pipx) installs Python **applications** — not
libraries — each into its own virtual environment, and puts their entrypoints
on your `PATH`. Two tools that need incompatible versions of the same library
never see each other. `pipx run` goes further and executes an application in a
temporary environment without installing it at all.

It is a [PyPA](https://www.pypa.io/) project.

## What's included

- **pipx** — the CLI (`pipx install`, `pipx run`, `pipx list`, `pipx inject`, …)
- **python** — the private CPython interpreter this package is composed against

## How this package differs from the other OCX mirrors

Most OCX mirrors republish an upstream release archive. pipx is distributed as
a Python application, so this package is an OCX **environment package**: the
wheels resolved for each pipx release from PyPI, composed together with a
private [python-build-standalone](https://github.com/astral-sh/python-build-standalone)
CPython 3.13 interpreter.

The practical consequence is that **no Python is required on the host**. There
is no `pip`, no `uv`, and no `venv` step at install or run time — `ocx add
ocx.sh/pypa/pipx` yields a working `pipx` on a machine with no Python at all.

pipx's own GitHub release asset, `pipx.pyz`, is deliberately **not** what this
package ships: that zipapp vendors mypyc-compiled extension modules built for
one interpreter and one platform (CPython 3.14, glibc x86_64), so it is not
portable despite looking like it.

## Platforms

Linux on amd64 and arm64, under any libc. pipx and its whole dependency closure
are pure-Python wheels, so the platform entries carry no libc requirement — the
private interpreter resolves the host's glibc or musl on its own. The published
claim is tested on Ubuntu, Alpine and Fedora.

## Versions

Upstream tags bare PEP 440 releases (`1.16.5`). The `1.16` and `1` aliases and
`latest` track the newest published release.

## Links

- [pipx on GitHub](https://github.com/pypa/pipx)
- [Documentation](https://pipx.pypa.io/)
- [pipx on PyPI](https://pypi.org/project/pipx/)
