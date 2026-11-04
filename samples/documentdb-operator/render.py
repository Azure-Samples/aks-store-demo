#!/usr/bin/env python3
"""Render create-only, namespaced evaluation manifests (JSON accepted by kubectl).

Offline only. Install the policy BEFORE the database; see README.md.
"""
import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DB = "store-db"
OWNER_LABEL = "aks-store-demo.azure-samples.io/evaluation"
OWNER_VALUE = "documentdb-operator"
POSTGRES = (
    "ghcr.io/cloudnative-pg/postgresql:18.3-system-trixie@sha256:"
    "0f29b435fb501ee534cd0c555d122a6b8e90de477de8e8381c82c5e10d9a9de4"
)


def namespace(value):
    # Deliberately exclude shared/system namespaces from all helper operations.
    if not re.fullmatch(r"store-operator(?:-[a-z0-9](?:[-a-z0-9]*[a-z0-9])?)?", value) or len(value) > 63:
        raise ValueError("Use a fresh namespace named store-operator or store-operator-<suffix>")
    return value


def render(ns="store-operator", component="all"):
    namespace(ns)
    images = json.loads((ROOT / "images.lock.json").read_text())

    def meta(name):
        return {"name": name, "namespace": ns, "labels": {OWNER_LABEL: OWNER_VALUE}}

    def env(key, value):
        return {"name": key, "value": value}

    def secret(key, name, field):
        return {"name": key, "valueFrom": {"secretKeyRef": {"name": name, "key": field}}}

    policy = json.loads((ROOT / "network-policy.json").read_text())
    policy["metadata"] = meta("isolate-documentdb-ingress")
    database = {
        "apiVersion": "documentdb.io/preview", "kind": "DocumentDB", "metadata": meta(DB),
        "spec": {
            "nodeCount": 1, "instancesPerNode": 1, "documentDBVersion": "0.110.0",
            "documentDbCredentialSecret": "store-db-credentials",
            "environment": "aks", "image": {"postgres": POSTGRES},
            "resource": {"cpu": "1", "memory": "2Gi", "storage": {
                "pvcSize": "10Gi", "storageClass": "managed-csi"}},
            "exposeViaService": {"serviceType": "ClusterIP"},
            "tls": {"gateway": {"mode": "SelfSigned"}},
        },
    }
    queue = [secret("ORDER_QUEUE_USERNAME", "store-queue", "username"),
             secret("ORDER_QUEUE_PASSWORD", "store-queue", "password"),
             env("ORDER_QUEUE_NAME", "orders")]
    settings = {
        "rabbitmq": (5672, [secret("RABBITMQ_DEFAULT_USER", "store-queue", "username"),
                            secret("RABBITMQ_DEFAULT_PASS", "store-queue", "password")], None),
        "order-service": (3000, queue + [env("ORDER_QUEUE_HOSTNAME", "rabbitmq"),
                                        env("ORDER_QUEUE_PORT", "5672"),
                                        env("FASTIFY_ADDRESS", "0.0.0.0")], "/health"),
        "makeline-service": (3001, queue + [env("ORDER_QUEUE_URI", "amqp://rabbitmq:5672"),
                                           env("ORDER_DB_API", "mongodb"),
                                           env("ORDER_DB_NAME", "orderdb"),
                                           env("ORDER_DB_COLLECTION_NAME", "orders"),
                                           secret("ORDER_DB_URI", "store-db-uri", "uri")], "/health"),
        "product-service": (3002, [], "/health"),
    }
    apps = []
    for name, (port, envs, health) in settings.items():
        probe = {"httpGet": {"path": health, "port": port}} if health else {"tcpSocket": {"port": port}}
        container = {
            "name": name, "image": images[name], "ports": [{"containerPort": port}], "env": envs,
            "resources": {"requests": {"cpu": "50m", "memory": "128Mi"},
                          "limits": {"cpu": "500m", "memory": "512Mi"}},
            "readinessProbe": dict(probe, periodSeconds=5),
            "startupProbe": dict(probe, periodSeconds=5, failureThreshold=120),
        }
        pod = {"enableServiceLinks": False, "nodeSelector": {"kubernetes.io/os": "linux"},
               "containers": [container]}
        if name == "makeline-service":
            container["volumeMounts"] = [{"name": "db-ca", "mountPath": "/var/run/documentdb-ca", "readOnly": True}]
            pod["volumes"] = [{"name": "db-ca", "secret": {
                "secretName": DB + "-gateway-cert-tls", "items": [{"key": "tls.crt", "path": "ca.crt"}]}}]
            container["livenessProbe"] = {"httpGet": {"path": "/liveness", "port": port}, "periodSeconds": 10}
        apps.append({
            "apiVersion": "apps/v1", "kind": "Deployment", "metadata": meta(name),
            "spec": {"replicas": 1, "selector": {"matchLabels": {"app": name}},
                     "template": {"metadata": {"labels": {"app": name}}, "spec": pod}},
        })
        apps.append({
            "apiVersion": "v1", "kind": "Service", "metadata": meta(name),
            "spec": {"type": "ClusterIP", "selector": {"app": name},
                     "ports": [{"port": port, "targetPort": port}]},
        })
    parts = {"policy": [policy], "database": [database], "apps": apps}
    return {"apiVersion": "v1", "kind": "List", "items":
            [policy, database] + apps if component == "all" else parts[component]}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--namespace", default="store-operator", type=namespace)
    parser.add_argument("--component", choices=["all", "policy", "database", "apps"], default="all")
    args = parser.parse_args()
    print(json.dumps(render(args.namespace, args.component), indent=2))
