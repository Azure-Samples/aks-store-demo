"""Offline tests only: kubectl, cleanup HTTP, TLS and MongoDB are all mocked."""
import base64
import contextlib
import io
import json
import re
import socket
import ssl
import subprocess
import sys
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import MagicMock, patch

import cleanup
import client_test
import prepare_secrets
import render


# Verbatim declaration excerpt from the chart's released CRD, not a plural
# inferred from kind/shortName. Keep the fixture offline and release-pinned:
# https://github.com/documentdb/documentdb-kubernetes-operator/blob/e05d6b1b0a0bc1fa2d79cf81ad390849d963b66c/operator/documentdb-helm-chart/crds/documentdb.io_dbs.yaml
RELEASE_CRD_DECLARATION = """---
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  annotations:
    controller-gen.kubebuilder.io/version: v0.17.2
  labels:
    app: documentdb-operator
  name: dbs.documentdb.io
spec:
  group: documentdb.io
  names:
    kind: DocumentDB
    listKind: DocumentDBList
    plural: dbs
    shortNames:
    - documentdb
    singular: documentdb
  scope: Namespaced
"""


class ManifestTests(unittest.TestCase):
    def test_database_pin_and_tls_mount(self):
        readme = (render.ROOT / "README.md").read_text()
        crd_name = re.search(r"^  name: (.+)$", RELEASE_CRD_DECLARATION, re.MULTILINE).group(1)
        self.assertIn("wait --for=condition=Established crd/" + crd_name + " --timeout=120s", readme)
        self.assertIn('k -n "$NS" delete pod "$DB_POD" --wait=true\n'
                      'k -n "$NS" wait --for=create "pod/$DB_POD" --timeout=600s\n'
                      'k -n "$NS" wait --for=condition=Ready "pod/$DB_POD" --timeout=600s', readme)

        db = render.render(component="database")["items"][0]["spec"]
        self.assertEqual(db["image"]["postgres"], render.POSTGRES)
        self.assertIn("18.3-system-trixie@sha256:", render.POSTGRES)
        self.assertEqual(db["documentDBVersion"], "0.110.0")
        self.assertEqual((db["nodeCount"], db["instancesPerNode"]), (1, 1))
        self.assertEqual(db["resource"]["storage"]["storageClass"], "managed-csi")
        self.assertEqual(db["exposeViaService"]["serviceType"], "ClusterIP")
        for item in render.render(component="apps")["items"]:
            if item["kind"] == "Deployment" and item["metadata"]["name"] == "makeline-service":
                cert = item["spec"]["template"]["spec"]["volumes"][0]["secret"]
                self.assertEqual(cert["items"], [{"key": "tls.crt", "path": "ca.crt"}])

    def test_namespace_and_policy_scoping(self):
        docs = render.render("store-operator-check")["items"]
        self.assertTrue(all(d["metadata"]["namespace"] == "store-operator-check" for d in docs))
        self.assertFalse(any(d["kind"] in ("Namespace", "Secret") for d in docs))
        policy = docs[0]["spec"]
        self.assertEqual(policy["policyTypes"], ["Ingress"])
        self.assertEqual(policy["podSelector"], {"matchLabels": {"cnpg.io/cluster": "store-db"}})
        gateway, postgres, controller = policy["ingress"]
        self.assertEqual(gateway["ports"], [{"protocol": "TCP", "port": 10260}])
        self.assertEqual(gateway["from"], [
            {"podSelector": {"matchLabels": {"app": "makeline-service"}}},
            {"podSelector": {"matchLabels": {"app": "documentdb-test-client"}}}])
        self.assertEqual(postgres["ports"], [{"protocol": "TCP", "port": 5432}])
        self.assertEqual(postgres["from"], [{"podSelector": policy["podSelector"]}])
        self.assertEqual(controller["from"], [{"namespaceSelector": {
            "matchLabels": {"kubernetes.io/metadata.name": "cnpg-system"}}}])
        self.assertEqual({p["port"] for p in controller["ports"]}, {8000, 9187})

    def test_locked_images_complete_and_offline_render_portable(self):
        locks = json.loads((render.ROOT / "images.lock.json").read_text())
        self.assertEqual(set(locks), {"rabbitmq", "order-service", "makeline-service", "product-service"})
        for value in locks.values():
            self.assertRegex(value, r"@sha256:[a-f0-9]{64}$")
        result = subprocess.run([sys.executable, str(render.ROOT / "render.py"),
                                 "--namespace", "store-operator-check"], cwd=render.ROOT.parent,
                                text=True, capture_output=True, check=True)
        self.assertEqual(json.loads(result.stdout), render.render("store-operator-check"))

    def test_forbidden_namespace_names(self):
        for value in ["default", "kube-system", "pets", "store-operator-", "store-operator/../pets", "store-operator-" + "x" * 64]:
            with self.subTest(value=value), self.assertRaises(ValueError):
                render.render(value)


class SecretTests(unittest.TestCase):
    def test_secrets_only_on_stdin_and_not_in_output(self):
        output = io.StringIO()
        with patch.object(prepare_secrets.subprocess, "run", return_value=SimpleNamespace(returncode=0)) as run:
            with contextlib.redirect_stdout(output), contextlib.redirect_stderr(output):
                prepare_secrets.prepare("test-config", "test-context", "store-operator-unit")
        self.assertEqual(run.call_count, 4)
        objects = [json.loads(c.kwargs["input"]) for c in run.call_args_list]
        self.assertEqual(objects[0]["kind"], "Namespace")
        db, uri, queue = [o["stringData"] for o in objects[1:]]
        self.assertNotEqual(db["password"], queue["password"])
        self.assertGreaterEqual(len(db["password"]), 40)
        self.assertIn(".store-operator-unit.svc:10260/", uri["uri"])
        for call in run.call_args_list:
            self.assertEqual(call.args[0][-3:], ["create", "-f", "-"])
            self.assertTrue(call.kwargs["capture_output"])
            for value in [db["password"], queue["password"], uri["uri"]]:
                self.assertNotIn(value, str(call.args))
                self.assertNotIn(value, output.getvalue())

    def test_preexisting_namespace_aborts_before_secrets(self):
        output = io.StringIO()
        with patch.object(prepare_secrets.subprocess, "run", return_value=SimpleNamespace(
                returncode=1, stdout="sensitive-test-sentinel", stderr="sensitive-test-sentinel")) as run:
            with contextlib.redirect_stdout(output), contextlib.redirect_stderr(output):
                with self.assertRaises(RuntimeError) as caught:
                    prepare_secrets.prepare("test-config", "test-context", "store-operator")
        self.assertEqual(run.call_count, 1)
        self.assertNotIn("sensitive-test-sentinel", str(caught.exception) + output.getvalue())

    def test_partial_secret_failure_has_no_rollback_or_overwrite(self):
        with patch.object(prepare_secrets.subprocess, "run", side_effect=[
                SimpleNamespace(returncode=0), SimpleNamespace(returncode=0),
                SimpleNamespace(returncode=1, stderr="sensitive-test-sentinel")]) as run:
            with self.assertRaises(RuntimeError):
                prepare_secrets.prepare("test-config", "test-context", "store-operator")
        self.assertEqual(run.call_count, 3)
        self.assertTrue(all(c.args[0][-3:] == ["create", "-f", "-"] for c in run.call_args_list))


class CleanupTests(unittest.TestCase):
    @staticmethod
    def owned(uid="unit-uid", label=render.OWNER_VALUE):
        return {"metadata": {"name": "store-operator", "uid": uid,
                             "labels": {render.OWNER_LABEL: label}}}

    def test_default_is_plan_only(self):
        output = io.StringIO()
        with patch.object(cleanup, "request", return_value=self.owned()) as request:
            with contextlib.redirect_stdout(output):
                cleanup.cleanup("store-operator", "unit-uid")
        request.assert_called_once_with(18001, "store-operator")
        self.assertIn("PLAN ONLY", output.getvalue())
        self.assertIn("indirectly delete bound PVs/Azure disks", output.getvalue())
        self.assertIn("Delete reclaim policy", output.getvalue())
        self.assertIn("Storage retention is not guaranteed", output.getvalue())

    def test_help_and_readme_warn_about_indirect_storage_deletion(self):
        result = subprocess.run([sys.executable, str(render.ROOT / "cleanup.py"), "--help"],
                                text=True, capture_output=True, check=True)
        readme = (render.ROOT / "README.md").read_text()
        for text in (cleanup.__doc__, result.stdout, readme):
            text = " ".join(text.replace("**", "").replace("`", "").split()).lower()
            self.assertIn("no direct api requests to delete cluster-scoped resources", text)
            self.assertIn("pvcs", text)
            self.assertIn("indirectly delete bound pvs and azure disks", text)
            self.assertIn("delete reclaim policy", text)
            self.assertIn("storage retention is not guaranteed", text)

    def test_http_delete_is_namespace_only_with_real_precondition_body(self):
        response = MagicMock()
        response.__enter__.return_value.read.return_value = b'{}'
        opener = MagicMock()
        opener.open.return_value = response
        body = {"apiVersion": "v1", "kind": "DeleteOptions", "preconditions": {"uid": "unit-uid"},
                "propagationPolicy": "Foreground"}
        with patch.object(cleanup.urllib.request, "build_opener", return_value=opener):
            cleanup.request(18001, "store-operator", body)
        request = opener.open.call_args.args[0]
        self.assertEqual(request.full_url, "http://127.0.0.1:18001/api/v1/namespaces/store-operator")
        self.assertEqual(request.get_method(), "DELETE")
        self.assertEqual(json.loads(request.data), body)
        self.assertEqual(opener.open.call_count, 1)

    def test_refuses_wrong_uid_label_or_confirmation(self):
        cases = [(self.owned("recreated-uid"), "store-operator:unit-uid"),
                 (self.owned(label="someone-else"), "store-operator:unit-uid"),
                 (self.owned(), "yes")]
        for obj, confirmation in cases:
            with patch.object(cleanup, "request", return_value=obj) as request:
                with self.assertRaises(ValueError):
                    cleanup.cleanup("store-operator", "unit-uid", confirm=confirmation)
                self.assertEqual(request.call_count, 1)

    def test_delete_has_server_side_uid_precondition(self):
        with patch.object(cleanup, "request", return_value=self.owned()) as request:
            with contextlib.redirect_stdout(io.StringIO()):
                cleanup.cleanup("store-operator", "unit-uid", confirm="store-operator:unit-uid")
        self.assertEqual(request.call_count, 2)
        body = request.call_args.args[2]
        self.assertEqual(body["preconditions"], {"uid": "unit-uid"})
        self.assertEqual(body["kind"], "DeleteOptions")

    def test_invalid_name_makes_no_request(self):
        with patch.object(cleanup, "request") as request:
            with self.assertRaises(ValueError):
                cleanup.cleanup("default", "unit-uid", confirm="default:unit-uid")
            request.assert_not_called()


class ClientTests(unittest.TestCase):
    def test_optimized_python_refused_before_io(self):
        for module in ["smoke", "client_test"]:
            result = subprocess.run([sys.executable, "-O", "-c", f"import {module}; {module}.run(None)"],
                                    cwd=render.ROOT, text=True, capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("Run without Python optimization", result.stderr)

    def test_loopback_dns_preserves_other_names(self):
        with patch.object(socket, "getaddrinfo", return_value=[]) as resolve:
            with client_test.loopback_dns("test.svc"):
                socket.getaddrinfo("test.svc", 20260)
                socket.getaddrinfo("other.svc", 443)
        self.assertEqual(resolve.call_args_list[0].args[:2], ("127.0.0.1", 20260))
        self.assertEqual(resolve.call_args_list[1].args[:2], ("other.svc", 443))

    def test_client_arguments_and_negative_auth_mock(self):
        class AuthFailure(Exception):
            code = 18
        module = SimpleNamespace(MongoClient=MagicMock())
        good = module.MongoClient.return_value.__enter__.return_value
        expected = {"_id": "unit-record", "value": "synthetic-only", "counter": 2}
        collection = good.__getitem__.return_value.__getitem__.return_value
        collection.find_one.side_effect = [expected, AuthFailure()]
        collection.update_one.return_value.matched_count = 1
        credentials = {"data": {key: base64.b64encode(value.encode()).decode()
                               for key, value in {"username": "unit-user", "password": "unit-secret"}.items()}}
        result = SimpleNamespace(returncode=0, stdout=base64.b64encode(b"public-certificate").decode())
        args = SimpleNamespace(kubeconfig="test-config", context="test-context", namespace="store-operator",
                               record_id="unit-record", phase="write", port=20260)
        output = io.StringIO()
        with patch.dict(sys.modules, {"pymongo": module, "pymongo.errors": SimpleNamespace(OperationFailure=AuthFailure)}):
            with patch.object(client_test, "read_json", return_value=credentials), \
                    patch.object(client_test.subprocess, "run", return_value=result) as read, \
                    patch.object(client_test, "tls_check") as tls, contextlib.redirect_stdout(output):
                client_test.run(args)
        self.assertEqual(module.MongoClient.call_count, 2)
        for call in module.MongoClient.call_args_list:
            self.assertTrue(call.kwargs["tls"])
            self.assertFalse(call.kwargs["tlsAllowInvalidCertificates"])
            self.assertFalse(call.kwargs["tlsAllowInvalidHostnames"])
            self.assertEqual(call.kwargs["authSource"], "admin")
            self.assertFalse(call.kwargs["retryWrites"])
        self.assertIn("tls\\.crt", read.call_args.args[0][-1])
        self.assertNotIn("unit-secret", output.getvalue())
        tls.assert_called_once()

    def test_untrusted_tls_must_fail(self):
        trusted, untrusted = MagicMock(), MagicMock()
        trusted.wrap_socket.return_value.__enter__.return_value.version.return_value = "TLSv1.3"
        untrusted.wrap_socket.side_effect = ssl.SSLCertVerificationError("untrusted")
        with patch.object(client_test.socket, "create_connection"), \
                patch.object(client_test.ssl, "create_default_context", side_effect=[trusted, untrusted]), \
                contextlib.redirect_stdout(io.StringIO()):
            client_test.tls_check("test.svc", 20260, "public-certificate")
        self.assertEqual(trusted.wrap_socket.call_args.kwargs["server_hostname"], "test.svc")


if __name__ == "__main__":
    unittest.main()
