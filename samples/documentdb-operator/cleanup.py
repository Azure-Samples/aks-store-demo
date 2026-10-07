#!/usr/bin/env python3
"""Plan-only by default. Opt-in deletion of one freshly created evaluation namespace.

Never deletes cluster-scoped resources, PVs, disks, Helm releases or Azure resources.
Requires a recorded namespace UID and an exact confirmation; a recreated namespace
cannot match. Deletion goes through the Kubernetes API with a UID precondition.
Use a loopback kubectl proxy scoped to your explicit kubeconfig/context (README).
"""
import argparse
import json
import urllib.error
import urllib.request

from render import OWNER_LABEL, OWNER_VALUE, namespace


def request(port, ns, body=None):
    url = "http://127.0.0.1:" + str(port) + "/api/v1/namespaces/" + ns
    req = urllib.request.Request(url, method="GET" if body is None else "DELETE",
                                 data=None if body is None else json.dumps(body).encode(),
                                 headers={"Content-Type": "application/json"})
    # Ignore HTTP_PROXY: the explicitly loopback-only kubectl proxy is the boundary.
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    with opener.open(req, timeout=30) as response:
        return json.load(response)


def cleanup(ns, uid, port=18001, confirm=None):
    namespace(ns)
    obj = request(port, ns)
    meta = obj["metadata"]
    if (not uid or meta.get("uid") != uid or meta.get("name") != ns
            or meta.get("labels", {}).get(OWNER_LABEL) != OWNER_VALUE):
        raise ValueError("Refusing: namespace name, recorded UID or evaluation label does not match")
    if confirm is None:
        print("PLAN ONLY: would delete evaluation namespace " + ns + "; retained PVs/disks and cluster dependencies are NOT deleted.")
        return
    if confirm != ns + ":" + uid:
        raise ValueError("Refusing: confirmation must equal namespace:recorded-uid")
    request(port, ns, {"apiVersion": "v1", "kind": "DeleteOptions",
                      "preconditions": {"uid": uid}, "propagationPolicy": "Foreground"})
    print("Namespace deletion requested; wait for completion and independently inventory retained storage. This is not proof of cloud cleanup.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--namespace", required=True, type=namespace)
    parser.add_argument("--uid", required=True, help="Namespace UID recorded immediately after creation")
    parser.add_argument("--proxy-port", type=int, default=18001)
    parser.add_argument("--confirm", help="Explicit destructive confirmation: namespace:recorded-uid")
    args = parser.parse_args()
    try:
        cleanup(args.namespace, args.uid, args.proxy_port, args.confirm)
    except (ValueError, KeyError, OSError, urllib.error.URLError):
        parser.exit(1, "Refused or failed cleanup. Verify proxy context, namespace UID/label and explicit confirmation; no broader cleanup attempted.\n")
