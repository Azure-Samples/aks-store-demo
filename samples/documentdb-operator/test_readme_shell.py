"""Execute the README setup blocks offline: no real kubectl, Helm or credentials.

The stubs log only command stages and object kind/name, never Secret data.
prepare_secrets.py and render.py themselves run; kubectl/Helm are strict fakes.
"""
import json
import re
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent
BASH = shutil.which("bash")

# PATH contains only these three executables. The Python shim delegates only to
# the two sample scripts in this private test copy. All cluster calls hit a fake.
STUB = r'''import json
import os
import subprocess
import sys
from pathlib import Path

args = sys.argv[1:]
tool = Path(sys.argv[0]).name
record = {"tool": tool}
if tool == "python3":
    if args[0] == "prepare_secrets.py":
        stage = "prepare"
    elif args[0] == "render.py":
        stage = "render-" + args[args.index("--component") + 1]
    else:
        raise SystemExit("Unexpected Python command")
elif tool in ("kubectl", "helm"):
    assert args[:4] == ["--kubeconfig", "offline-config",
                       "--context" if tool == "kubectl" else "--kube-context", "offline-context"], args
    args = args[4:]
    record["args"] = args
    if tool == "helm":
        assert args[0] == "install", args
        stage = "helm-" + args[1]
    elif args[0] == "get" and args[1] == "namespace":
        stage = "uid"
    elif args[-3:] == ["create", "-f", "-"]:
        obj = json.load(sys.stdin)
        record["kind"] = obj["kind"]
        record["name"] = obj["metadata"]["name"]
        stage = ("namespace-create" if obj["kind"] == "Namespace"
                 else "secret-" + obj["metadata"]["name"])
    elif args[0] == "create" and "-f" in args:
        filename = args[args.index("-f") + 1]
        obj = json.loads(Path(filename).read_text())
        assert obj["kind"] == "List" and obj["items"], obj
        stage = filename.split(".")[0] + ("-dryrun" if "--dry-run=server" in args else "-create")
    elif args[0] == "-n" and args[2:4] == ["get", "networkpolicy"]:
        stage = "policy-read"
    elif "rollout" in args:
        stage = "rollout-" + args[args.index("status") + 1].split("/")[1]
    elif args[0] == "wait":
        stage = "wait-" + args[2].split("/")[1]
    elif args[0] == "-n" and args[2:] == ["get", "certificates,issuers"]:
        stage = "certificates-" + args[1]
    elif args[0] == "-n" and args[2:] == ["get", "pods,services"]:
        stage = "apps-read"
    else:
        raise SystemExit("Unexpected kubectl command: " + repr(args))
else:
    raise SystemExit("Unexpected executable")
record["stage"] = stage
with open(os.environ["CALL_LOG"], "a") as log:
    log.write(json.dumps(record) + "\n")
if os.environ.get("FAIL_STAGE") == stage:
    print("offline-failure-sentinel", file=sys.stderr)
    raise SystemExit(37)
if stage == "namespace-create":
    state = Path("namespace-state.json")
    if state.exists():
        raise SystemExit(1)  # API AlreadyExists; no adoption/mutation.
    state.write_text(json.dumps(obj))
if stage == "uid" and os.environ.get("EMPTY_UID") != "1":
    print("offline-original-uid")
if tool == "python3":
    raise SystemExit(subprocess.call([os.environ["REAL_PYTHON"], *sys.argv[1:]]))
'''

DEPENDENCIES = [
    "helm-cert-manager", "rollout-cert-manager", "rollout-cert-manager-webhook",
    "rollout-cert-manager-cainjector", "wait-certificates.cert-manager.io",
    "helm-documentdb-operator", "rollout-documentdb-operator",
    "rollout-documentdb-operator-cloudnative-pg", "rollout-sidecar-injector",
    "wait-dbs.documentdb.io", "wait-clusters.postgresql.cnpg.io",
    "certificates-documentdb-operator", "certificates-cnpg-system",
]
DATABASE = [
    "prepare", "namespace-create", "secret-store-db-credentials", "secret-store-db-uri",
    "secret-store-queue", "uid", "render-policy", "policy-dryrun", "policy-create",
    "policy-read", "render-database", "database-dryrun", "database-create",
]
APPS = [
    "render-apps", "apps-dryrun", "apps-create", "rollout-rabbitmq", "rollout-order-service",
    "rollout-makeline-service", "rollout-product-service", "apps-read",
]


@unittest.skipUnless(BASH, "README commands require Bash")
class ReadmeShellTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.blocks = re.findall(r"```bash\n(.*?)\n```", (ROOT / "README.md").read_text(), re.S)
        cls.dependencies, cls.database, cls.apps = [
            next(block for block in cls.blocks if block.startswith(name + "()"))
            for name in ("install_dependencies", "create_database", "create_apps")
        ]
        # Extract the documented k/h wrappers too; don't test a hand-copied setup.
        cls.wrappers = "\n".join(line for line in cls.blocks[0].splitlines()
                                  if line.startswith(("k()", "h()")))

    def run_blocks(self, *, fail="", interactive=False, empty_uid=False,
                   existing=False, skip_dependencies=False, before_apps=""):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            bin_dir = root / "bin"
            bin_dir.mkdir()
            for name in ("kubectl", "helm", "python3"):
                stub = bin_dir / name
                stub.write_text("#!" + sys.executable + "\n" + STUB)
                stub.chmod(0o700)
            for name in ("prepare_secrets.py", "render.py", "network-policy.json", "images.lock.json"):
                shutil.copyfile(ROOT / name, root / name)
            original = '{"metadata":{"name":"store-operator-offline","uid":"someone-else","labels":{"owner":"someone-else"}},"sentinel":"unchanged"}'
            if existing:
                (root / "namespace-state.json").write_text(original)
            log = root / "calls.jsonl"
            # A deliberately minimal environment prevents accidental use of
            # ambient kubeconfig/cloud credentials or user shell startup files.
            env = {"PATH": str(bin_dir), "HOME": directory, "REAL_PYTHON": sys.executable,
                   "CALL_LOG": str(log), "FAIL_STAGE": fail, "EMPTY_UID": str(int(empty_uid)),
                   "PYTHONDONTWRITEBYTECODE": "1", "KUBECONFIG": "offline-config",
                   "CTX": "offline-context", "NS": "store-operator-offline"}
            script = "set +e\nset +o pipefail\n" + self.wrappers + "\n"
            if not skip_dependencies:
                script += self.dependencies + '\nprintf "DEPENDENCIES_STATUS=%s\\n" "$?"\n'
            script += self.database + '\nprintf "DATABASE_STATUS=%s\\n" "$?"\n'
            # Even if a user pastes the next block after an error, the marker
            # must prohibit app creation. It is not enough to stop one block.
            script += before_apps + "\n" + self.apps + '\nprintf "APPS_STATUS=%s\\n" "$?"\n'
            script += 'printf "UID=%s\\nSHELL_ALIVE\\n" "${NS_UID:-}"\n'
            result = subprocess.run([BASH, "--noprofile", "--norc", *(["-i"] if interactive else []),
                                     "-c", script], cwd=root, env=env, capture_output=True, text=True, timeout=30)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("SHELL_ALIVE", result.stdout)
            calls = [json.loads(line) for line in log.read_text().splitlines()] if log.exists() else []
            if existing:
                self.assertEqual((root / "namespace-state.json").read_text(), original)
            return result, calls

    def test_success_in_normal_and_interactive_shell(self):
        for interactive in (False, True):
            with self.subTest(interactive=interactive):
                result, calls = self.run_blocks(interactive=interactive)
                self.assertEqual([c["stage"] for c in calls], DEPENDENCIES + DATABASE + APPS)
                for name in ("DEPENDENCIES", "DATABASE", "APPS"):
                    self.assertIn(name + "_STATUS=0", result.stdout)
                self.assertIn("UID=offline-original-uid", result.stdout)

    def test_each_dependency_failure_blocks_later_installs_database_and_apps(self):
        for stage in DEPENDENCIES:
            for interactive in (False, True):
                with self.subTest(stage=stage, interactive=interactive):
                    result, calls = self.run_blocks(fail=stage, interactive=interactive)
                    self.assertEqual([c["stage"] for c in calls], DEPENDENCIES[:DEPENDENCIES.index(stage) + 1])
                    self.assertIn("DEPENDENCIES_STATUS=37", result.stdout)
                    self.assertIn("DATABASE_STATUS=1", result.stdout)
                    self.assertIn("APPS_STATUS=1", result.stdout)

    def test_each_database_failure_stops_at_failed_command_and_blocks_apps(self):
        for stage in DATABASE:
            for interactive in (False, True):
                with self.subTest(stage=stage, interactive=interactive):
                    result, calls = self.run_blocks(fail=stage, interactive=interactive)
                    self.assertEqual([c["stage"] for c in calls], DEPENDENCIES + DATABASE[:DATABASE.index(stage) + 1])
                    self.assertRegex(result.stdout, r"DATABASE_STATUS=[1-9][0-9]*\n")
                    self.assertIn("APPS_STATUS=1", result.stdout)

    def test_each_app_failure_stops_at_failed_command(self):
        for stage in APPS:
            with self.subTest(stage=stage):
                result, calls = self.run_blocks(fail=stage)
                self.assertEqual([c["stage"] for c in calls], DEPENDENCIES + DATABASE + APPS[:APPS.index(stage) + 1])
                self.assertIn("APPS_STATUS=37", result.stdout)

    def test_empty_uid_blocks_policy_database_and_apps(self):
        result, calls = self.run_blocks(empty_uid=True)
        self.assertEqual([c["stage"] for c in calls], DEPENDENCIES + DATABASE[:DATABASE.index("uid") + 1])
        self.assertIn("DATABASE_STATUS=1", result.stdout)
        self.assertIn("APPS_STATUS=1", result.stdout)

    def test_existing_namespace_is_not_adopted_or_modified(self):
        result, calls = self.run_blocks(existing=True)
        self.assertEqual([c["stage"] for c in calls], DEPENDENCIES + ["prepare", "namespace-create"])
        self.assertIn("DATABASE_STATUS=1", result.stdout)
        self.assertIn("APPS_STATUS=1", result.stdout)

    def test_missing_dependency_marker_makes_no_requests(self):
        result, calls = self.run_blocks(skip_dependencies=True)
        self.assertEqual(calls, [])
        self.assertIn("DATABASE_STATUS=1", result.stdout)
        self.assertIn("APPS_STATUS=1", result.stdout)

    def test_marker_rejects_changed_target_or_uid_and_failed_retry(self):
        for command in ('CTX=other-context', 'KUBECONFIG=other-config',
                        'NS=store-operator-other', 'NS_UID=other-uid',
                        'create_database'):  # AlreadyExists; clears old readiness.
            with self.subTest(command=command):
                result, calls = self.run_blocks(before_apps=command)
                expected = DEPENDENCIES + DATABASE
                if command == 'create_database':
                    expected += ["prepare", "namespace-create"]
                self.assertEqual([c["stage"] for c in calls], expected)
                self.assertIn("APPS_STATUS=1", result.stdout)

    def test_setup_wrappers_do_not_depend_on_errexit_or_pipelines(self):
        for block in (self.dependencies, self.database, self.apps):
            self.assertNotRegex(block, r"\bset\s+-[^\n]*e")
            # Current setup has no pipelines whose earlier status could be hidden.
            self.assertNotRegex(block, r"(?<!\|) \| (?!\|)")
        self.assertNotIn('export NS_UID="$(' , self.database)
        self.assertIn('NS_UID="$(k get namespace "$NS" -o jsonpath=\'{.metadata.uid}\')" || return',
                      self.database)

    def test_every_readme_bash_block_has_valid_syntax(self):
        for number, block in enumerate(self.blocks, 1):
            with self.subTest(block=number):
                result = subprocess.run([BASH, "--noprofile", "--norc", "-n"],
                                        input=block, text=True, capture_output=True)
                self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()
