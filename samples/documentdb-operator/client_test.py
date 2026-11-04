#!/usr/bin/env python3
"""Opt-in authenticated CRU/TLS checks through a loopback-only port-forward.

Requires pymongo. Reads credentials and ONLY the public TLS certificate into memory.
Never logs kubectl errors, connection strings or driver exceptions (may contain secrets).
This script does not restart pods. Use the same record ID for write and readback.
"""
import argparse
import base64
import json
import socket
import ssl
import subprocess
from contextlib import contextmanager
from unittest.mock import patch

from render import namespace


def read_json(command):
    result = subprocess.run(command, text=True, capture_output=True)
    if result.returncode:
        raise RuntimeError("kubectl read failed")
    return json.loads(result.stdout)


def tls_check(host, port, ca):
    with socket.create_connection((host, port), timeout=20) as sock:
        with ssl.create_default_context(cadata=ca).wrap_socket(sock, server_hostname=host) as tls:
            print("PASS: verified TLS hostname and trust (" + tls.version() + ")")
    try:
        with socket.create_connection((host, port), timeout=20) as sock:
            with ssl.create_default_context().wrap_socket(sock, server_hostname=host):
                pass
    except ssl.SSLCertVerificationError:
        print("PASS: untrusted self-signed certificate rejected")
    else:
        raise AssertionError("Untrusted certificate accepted")


@contextmanager
def loopback_dns(host):
    original = socket.getaddrinfo

    def resolve(name, port, *args, **kwargs):
        return original("127.0.0.1" if name == host else name, port, *args, **kwargs)

    # Connect locally but retain the .svc name for certificate hostname validation.
    with patch.object(socket, "getaddrinfo", resolve):
        yield


def run(args):
    if not __debug__:
        raise RuntimeError("Run without Python optimization; validation requires assertions")
    from pymongo import MongoClient
    from pymongo.errors import OperationFailure

    command = ["kubectl", "--kubeconfig", args.kubeconfig, "--context", args.context, "-n", args.namespace]
    data = read_json(command + ["get", "secret", "store-db-credentials", "-o", "json"])["data"]
    username = base64.b64decode(data["username"]).decode()
    password = base64.b64decode(data["password"]).decode()
    # jsonpath excludes tls.key entirely. No certificate Secret is mounted on this client.
    result = subprocess.run(command + ["get", "secret", "store-db-gateway-cert-tls", "-o",
                                      "jsonpath={.data.tls\\.crt}"], text=True, capture_output=True)
    if result.returncode:
        raise RuntimeError("public certificate read failed")
    ca = base64.b64decode(result.stdout).decode()
    host = "documentdb-service-store-db." + args.namespace + ".svc"
    expected = {"_id": args.record_id, "value": "synthetic-only", "counter": 2}
    # PyMongo accepts tlsCAFile, not an SSLContext/cadata. The only temporary file
    # contains the public certificate, never private key or database credentials.
    import tempfile
    from pathlib import Path
    with tempfile.TemporaryDirectory() as tmp, loopback_dns(host):
        ca_path = Path(tmp) / "ca.crt"
        ca_path.write_text(ca)
        tls_check(host, args.port, ca)

        def client(pw):
            return MongoClient(host=host, port=args.port, username=username, password=pw,
                               authSource="admin", authMechanism="SCRAM-SHA-256", directConnection=True, retryWrites=False,
                               tls=True, tlsCAFile=str(ca_path), tlsAllowInvalidCertificates=False,
                               tlsAllowInvalidHostnames=False, serverSelectionTimeoutMS=25000,
                               connectTimeoutMS=20000)

        with client(password) as db:
            db.admin.command("ping")
            collection = db["synthetic_store_eval"]["records"]
            if args.phase == "write":
                collection.insert_one(dict(expected, counter=1))
                result = collection.update_one({"_id": args.record_id}, {"$set": {"counter": 2}})
                assert result.matched_count == 1
            assert collection.find_one({"_id": args.record_id}) == expected
            print("PASS: authenticated synthetic " + ("create/read/update" if args.phase == "write" else "readback"))
        with client("invalid-" + password) as db:
            try:
                db["synthetic_store_eval"]["records"].find_one({})
            except OperationFailure as error:
                assert error.code == 18
                print("PASS: incorrect credential rejected with code 18")
            else:
                raise AssertionError("Incorrect credential accepted")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("phase", choices=["write", "readback"])
    parser.add_argument("--kubeconfig", required=True)
    parser.add_argument("--context", required=True)
    parser.add_argument("--namespace", default="store-operator", type=namespace)
    parser.add_argument("--port", type=int, default=20260)
    parser.add_argument("--record-id", required=True, help="Unique non-secret synthetic test ID; reuse for readback")
    args = parser.parse_args()
    try:
        run(args)
    except Exception:
        parser.exit(1, "FAIL: TLS/authentication/readback check failed; exception details suppressed to protect credentials. Check prerequisites and scoped resource status.\n")
