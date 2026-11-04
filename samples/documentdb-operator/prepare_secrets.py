#!/usr/bin/env python3
"""Create a fresh evaluation namespace and three random Secrets, never overwrite.

Explicit kubeconfig/context required. Secret JSON goes only to kubectl stdin;
stdout/stderr are captured, not echoed even on failure. No credentials on disk.
A partial failure deliberately leaves resources intact; inspect before cleanup.
"""
import argparse
import json
import secrets
import subprocess
import urllib.parse

from render import OWNER_LABEL, OWNER_VALUE, namespace


def uri(host, user, password):
    return (
        "mongodb://" + urllib.parse.quote(user, safe="") + ":"
        + urllib.parse.quote(password, safe="") + "@" + host + ":10260/"
        "?authSource=admin&authMechanism=SCRAM-SHA-256&directConnection=true"
        "&retryWrites=false&tls=true&tlsCAFile=/var/run/documentdb-ca/ca.crt"
        "&serverSelectionTimeoutMS=10000"
    )


def create(command, obj):
    result = subprocess.run(command + ["create", "-f", "-"],
                            input=json.dumps(obj), text=True, capture_output=True)
    if result.returncode:
        # kubectl/admission errors may contain the input; do not leak them.
        raise RuntimeError("Create failed; existing resources were not overwritten. Inspect resource names/status, not Secret data.")


def prepare(kubeconfig, context, ns):
    namespace(ns)
    command = ["kubectl", "--kubeconfig", kubeconfig, "--context", context]
    # Atomic create fails on pre-existing namespaces before generating credentials.
    create(command, {"apiVersion": "v1", "kind": "Namespace", "metadata": {
        "name": ns, "labels": {OWNER_LABEL: OWNER_VALUE}}})
    user, password = "store_" + secrets.token_hex(6), secrets.token_urlsafe(32)
    data = {
        "store-db-credentials": {"username": user, "password": password},
        "store-db-uri": {"uri": uri("documentdb-service-store-db." + ns + ".svc", user, password)},
        "store-queue": {"username": "store_" + secrets.token_hex(6), "password": secrets.token_urlsafe(32)},
    }
    for name, fields in data.items():
        create(command + ["-n", ns], {"apiVersion": "v1", "kind": "Secret", "type": "Opaque",
            "metadata": {"name": name, "namespace": ns, "labels": {OWNER_LABEL: OWNER_VALUE}},
            "stringData": fields})
    print("Created fresh evaluation namespace and three Secrets. Credentials were not printed.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--kubeconfig", required=True)
    parser.add_argument("--context", required=True)
    parser.add_argument("--namespace", default="store-operator", type=namespace)
    args = parser.parse_args()
    try:
        prepare(args.kubeconfig, args.context, args.namespace)
    except (RuntimeError, OSError):
        parser.exit(1, "Create failed; no overwrite/rollback attempted. Inspect the evaluation namespace and use a new name for a retry.\n")
