# Smoke test for the pipx environment package.
#
# This is an env package, not an archive bundle: the composed artifact is
# pipx's wheel closure plus a private python-build-standalone interpreter, with
# `pipx` synthesized from the root package's single console_script. The
# interpreter is a PRIVATE dependency (ocx-mirror >= 0.6.5): no `python` is
# exported. So the contract to prove is (1) the entrypoint runs out of the
# composed env, (2) pipx's own configuration derivation is wired to the
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

# HOME is set to scratch on Linux as well as pipx's own vars: pipx derives
# PIPX_COMPLETION_DIR from platformdirs, which needs a writable HOME, and the
# container legs run with HOME unset. NOT on macOS: the native leg has no
# OCX_HOME, so the ocx launcher falls back to $HOME/.ocx and rejects the
# package root ("launcher exec: pkg-root must point inside …"); the runner's
# HOME is already writable there. Shared-libs auto-upgrade is pinned off so
# nothing reaches for the network on a first run against a virgin PIPX_HOME.
HOME_ENV = {} if ocx.target_platform.os == ocx.os.Darwin else {"HOME": ocx.scratch_root}
ENV = dict(HOME_ENV, **{
    "PIPX_HOME": HOME_DIR,
    "PIPX_BIN_DIR": BIN_DIR,
    "PIPX_MAN_DIR": MAN_DIR,
    "PIPX_DISABLE_SHARED_LIBS_AUTO_UPGRADE": "1",
    "PIPX_USE_EMOJI": "0",
})

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

# ── WHICH interpreter pipx runs on ────────────────────────────────────────────
# `python` is no longer exported (private dependency), so ask pipx itself: its
# default interpreter is `sys.executable`. Asserting it lives in the ocx package
# store proves the private python-build-standalone interpreter was composed in,
# not whatever the host had on PATH. POSIX also pins the minor via the
# `python3.13` filename; Windows ships a bare `python.exe`.
r_py = ocx.run("pipx", "environment", "--value", "PIPX_DEFAULT_PYTHON", env = ENV)
expect.ok(r_py)
py = r_py.stdout.strip()
expect.contains(py, "packages")

def check_minor():
    if ocx.target_platform.os != ocx.os.Windows:
        expect.true(py.endswith("python3.13"), msg = "pipx default python is not 3.13: " + py)

check_minor()
