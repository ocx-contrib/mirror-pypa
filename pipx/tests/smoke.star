# Smoke test for the pipx environment package.
#
# This is an env package, not an archive bundle: the composed artifact is
# pipx's wheel closure plus a private python-build-standalone interpreter, with
# `pipx` synthesized from the root package's single console_script and `python`
# always present. So the contract to prove is (1) both entrypoints run out of
# the composed env, (2) pipx's own configuration derivation is wired to the
# environment it was handed, and (3) the interpreter is the one this package
# declared, not one it found on the host.
#
# Every command below is verified network-free: run inside `unshare -rn` with a
# virgin PIPX_HOME, `--version`, `environment --value`, `list --json` and the
# argparse-reject path all completed offline with the exit codes asserted here.
#
# Dialect: Bazel .bzl Starlark — no top-level `if`/`for` STATEMENTS. Branch with
# an if-EXPRESSION, or a `def` plus a bare top-level call.

# A token in the scratch path so an assertion on pipx's DERIVED paths proves our
# env reached it, without depending on the platform's path separator.
HOME_DIR = ocx.scratch_root + "/ocxsmoke-pipx-home"
BIN_DIR = ocx.scratch_root + "/ocxsmoke-pipx-bin"
MAN_DIR = ocx.scratch_root + "/ocxsmoke-pipx-man"

ocx.mkdir("ocxsmoke-pipx-home")
ocx.mkdir("ocxsmoke-pipx-bin")
ocx.mkdir("ocxsmoke-pipx-man")

# HOME is set to scratch as well as pipx's own vars: pipx derives
# PIPX_COMPLETION_DIR from platformdirs, which needs a writable HOME, and the
# container legs run with HOME unset. Shared-libs auto-upgrade is pinned off so
# nothing reaches for the network on a first run against a virgin PIPX_HOME.
ENV = {
    "HOME": ocx.scratch_root,
    "PIPX_HOME": HOME_DIR,
    "PIPX_BIN_DIR": BIN_DIR,
    "PIPX_MAN_DIR": MAN_DIR,
    "PIPX_DISABLE_SHARED_LIBS_AUTO_UPGRADE": "1",
    "PIPX_USE_EMOJI": "0",
}

# ── Tier 2: the synthesized entrypoint runs, and reports a version SHAPE ──────
r_version = ocx.run("pipx", "--version", env = ENV)
expect.ok(r_version)
expect.matches(r_version.stdout, r"\d+\.\d+\.\d+")

# ── Tier 3a: configuration derivation is wired to the env we handed it ────────
# `environment --value PIPX_LOCAL_VENVS` is a value pipx COMPUTES (PIPX_HOME
# joined with "venvs"), not one it echoes back — so this reds both if the env
# never reached the process and if the derivation itself broke. Asserted by
# token + suffix rather than by full string so it holds on Windows, where
# pathlib renders the separator as a backslash.
r_venvs = ocx.run("pipx", "environment", "--value", "PIPX_LOCAL_VENVS", env = ENV)
expect.ok(r_venvs)
venvs = r_venvs.stdout.strip()
expect.contains(venvs, "ocxsmoke-pipx-home")
# `msg` is KEYWORD-ONLY on expect.* — a positional second argument is a script
# error ("Found 1 extra positional argument(s)"), not an assertion failure.
expect.true(
    venvs.endswith("venvs"),
    msg = "derived PIPX_LOCAL_VENVS did not end in venvs: " + venvs,
)

# ── Tier 3b: structured output parses to the documented empty-state shape ─────
# Counting exact tokens rather than substring-matching prose: a virgin PIPX_HOME
# must report zero installed venvs, and `--json` must emit its spec version. The
# human-facing "nothing has been installed" note goes to stderr, so stdout is
# pure JSON (measured).
r_list = ocx.run("pipx", "list", "--json", env = ENV)
expect.ok(r_list)
expect.eq(r_list.stdout.count("\"pipx_spec_version\""), 1)
expect.eq(r_list.stdout.count("\"venvs\": {}"), 1)

# ── Negative control: red is reachable ────────────────────────────────────────
# argparse rejects an unknown subcommand with exit 2. A POSITIVE code, so no
# platform branch is needed (negative codes differ: 255 on unix, -1 on Windows).
# Without this the asserts above would all still pass against a `pipx` that
# accepted literally anything.
r_bogus = ocx.run("pipx", "ocxsmoke-not-a-subcommand", env = ENV)
expect.eq(r_bogus.exit_code, 2)

# ── The always-present `python` entrypoint, and WHICH interpreter it is ───────
# An env package ships `python` (not `python3` — python-build-standalone only
# has the latter on POSIX). Asserting the computed 42 proves it executes;
# asserting the version prefix proves the private interpreter this spec pinned
# was composed in, rather than whatever the host had on PATH.
r_py = ocx.run("python", "-c", "print(6 * 7)")
expect.ok(r_py)
expect.contains(r_py.stdout, "42")

r_pyver = ocx.run("python", "-c", "import sys; print('%d.%d' % sys.version_info[:2])")
expect.ok(r_pyver)
expect.eq(r_pyver.stdout.strip(), "3.13")

# Cross-check: importing pipx through the `python` entrypoint must report the
# SAME version the `pipx` entrypoint does. That is the assertion that the app's
# wheel layers are on the composed PYTHONPATH — a bundle carrying only the
# interpreter would pass every `python` check above and fail here — and that the
# two synthesized entrypoints resolve one environment rather than two.
r_import = ocx.run("python", "-c", "from pipx.version import __version__; print(__version__)")
expect.ok(r_import)
expect.eq(r_import.stdout.strip(), r_version.stdout.strip())
