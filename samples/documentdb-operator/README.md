# Optional: evaluate the DocumentDB Kubernetes Operator on AKS

This **preview, non-production** sample adds a single-instance operator-managed
DocumentDB to a **headless** AKS Store evaluation. It does not replace
[`aks-store-all-in-one.yaml`](../../aks-store-all-in-one.yaml), the Store chart,
`azd`, or the existing quickstarts. Use a **dedicated disposable AKS cluster** and
a **fresh evaluation namespace**, with synthetic data only.

The path is `product-service` (in-memory CRUD) plus `order-service` → RabbitMQ →
`makeline-service` → DocumentDB (persisted order **create/read/update**). There is
**no order DELETE API**. There are no frontends, virtual customers/workers, ingress,
public database endpoints, AI services, model credentials, or inference calls.

> [!WARNING]
> Preview internal authentication-context hardening remains a production blocker.
> Operator 0.3.0's [PostgreSQL configuration](https://github.com/documentdb/documentdb-kubernetes-operator/blob/0.3.0/operator/src/internal/cnpg/cnpg_cluster.go)
> includes broad `trust` HBA entries, so successful gateway authentication does
> not establish isolation of the internal SQL path. The scoped NetworkPolicy
> below is a **required evaluation mitigation**, not a fix for that blocker or
> production security certification. ClusterIP alone is
> **not** access control. Do not run on an untrusted/shared cluster, allow untrusted
> users to create/relabel pods in these namespaces, or expose PostgreSQL/gateway
> ports. NetworkPolicy does not constrain cluster administrators, node traffic or
> authorized `kubectl port-forward`. Policies are additive: another allow policy
> can defeat this isolation.

## What was actually evaluated

A bounded AKS run on 2026-10-07 passed these twelve checkpoints:

1. Server-side DocumentDB CR validation.
2. Operator reconciliation to a healthy database.
3. Azure Disk PVC binding.
4. Verified TLS 1.3, including hostname verification.
5. Untrusted self-signed certificate rejection.
6. Authenticated synthetic database create/read/update.
7. Incorrect credentials rejected with authentication error code 18.
8. Product **in-memory** CRUD through the real REST API.
9. Queue-to-database order create/read/update through the real Store services.
10. Database pod replacement with a new pod UID and the same PVC UID/bound PV.
11. Exact order readback after that restart.
12. An unrelated app pod denied access to database ports 5432 and 10260.

Evaluated versions: AKS **1.35.8**, one **Standard_D4s_v5** Linux amd64 node,
Ubuntu **24.04**, containerd **2.3.3**, Azure CNI/Cilium policy enforcement,
operator chart **0.3.0**, CloudNativePG **1.29.1** (chart dependency **0.28.3**),
cert-manager **1.19.0**, DocumentDB extension/gateway **0.110.0**, PostgreSQL
**18.3-system-trixie**, Store images **2.2.0**, RabbitMQ
**4.3.2-management-alpine**. App/RabbitMQ digests are in `images.lock.json`; the
exact tested PostgreSQL digest is explicit in `render.py`. Operator/extension/
gateway versions are release-tag pinned, not independently digest-locked here.

All ten rendered resource specifications match those used in that run; only
metadata labels and packaging differ. The REST contract also derives from that
run. This portable packaging
adds namespace ownership checks, create-only installation, configurable client
arguments, and a guarded cleanup helper. **Those packaging changes were tested
locally with mocks/static checks, not rerun on AKS.** The evaluated run is not a
claim of a supported version matrix. Image manifests advertise other architectures;
only Linux amd64 was exercised.

**Not tested/claimed:** HA, multi-node or zone failover, scale, upgrades,
backup/restore/PITR, performance, frontend workflows, AI, or production readiness.
One database instance on one node proves restart persistence, not availability.
RabbitMQ has ephemeral storage; queue durability across RabbitMQ restart is not
provided. Product data is in memory and resets on product-service restart. The
order consumer uses random IDs and at-least-once delivery; this does not establish
exactly-once semantics or collision resistance.

## Prerequisites and boundaries

- An already provisioned, **dedicated disposable** AKS cluster. This sample does
  not create Azure resources. Select Kubernetes **1.35+**, Linux/containerd with
  working ImageVolume support, Azure Disk CSI (`managed-csi`), and a network
  plugin that actually enforces NetworkPolicy. The evaluated cluster used Cilium.
- `kubectl` compatible with the server, Helm **3.8+**, Python **3.10+**. Most scripts
  use only Python's standard library. The optional database client needs PyMongo.
- Capacity for the operators, database and four app deployments; the evaluated
  node size above is evidence, not a sizing recommendation.
- Rights to install cluster-scoped CRDs/webhooks and read/create Secrets, plus
  port-forward and (only for the restart exercise) delete a specific database pod.
- No existing cert-manager, CNPG, DocumentDB operator, or their CRDs/webhooks in
  this cluster. **Stop if they exist.** Do not adopt, upgrade, uninstall, or
  overwrite someone else's installation to run this sample.

From this directory, set your own **explicit** kubeconfig and context. The shell
parameter checks intentionally fail if they were not supplied; do not rely on the
current context. Keep generated evidence local and do not commit it.

```bash
: "${KUBECONFIG:?Set to your dedicated evaluation kubeconfig}"
: "${CTX:?Set to its explicit context name}"
export NS=store-operator
k() { kubectl --kubeconfig "$KUBECONFIG" --context "$CTX" "$@"; }
h() { helm --kubeconfig "$KUBECONFIG" --kube-context "$CTX" "$@"; }
k cluster-info
k get nodes -o wide
k get storageclass managed-csi
h list --all-namespaces
k get crd
k get namespaces
```

Review the target cluster and existing CRDs/namespaces **before** continuing. The
namespace helper only accepts `store-operator` or `store-operator-<suffix>`, and
fails if that namespace already exists. It intentionally offers no reuse mode.
If preparation fails part-way, inspect it; do not blindly rerun or delete it.

## 1. Install and verify the pinned dependencies

These commands are **initial installs only**, not upgrades. Do not disable the
operator's cert-manager preflight check during a live install.

```bash
h install cert-manager oci://quay.io/jetstack/charts/cert-manager \
  --version v1.19.0 --namespace cert-manager --create-namespace \
  --set crds.enabled=true --wait --timeout 10m
k -n cert-manager rollout status deployment/cert-manager --timeout=600s
k -n cert-manager rollout status deployment/cert-manager-webhook --timeout=600s
k -n cert-manager rollout status deployment/cert-manager-cainjector --timeout=600s
k wait --for=condition=Established crd/certificates.cert-manager.io --timeout=120s

h install documentdb-operator oci://ghcr.io/documentdb/documentdb-operator \
  --version 0.3.0 --namespace documentdb-operator --create-namespace \
  --wait --timeout 10m
k -n documentdb-operator rollout status deployment/documentdb-operator --timeout=600s
k -n cnpg-system rollout status deployment/documentdb-operator-cloudnative-pg --timeout=600s
k -n cnpg-system rollout status deployment/sidecar-injector --timeout=600s
k wait --for=condition=Established crd/documentdbs.documentdb.io --timeout=120s
k wait --for=condition=Established crd/clusters.postgresql.cnpg.io --timeout=120s
k -n documentdb-operator get certificates,issuers
k -n cnpg-system get certificates,issuers
```

Inspect that issued certificates are Ready, the issuer conditions are healthy,
and there are no pending pods or webhook errors. Helm `--wait` alone does **not**
prove database reconciliation, storage, TLS, authentication or data persistence.
The chart installs CNPG in **`cnpg-system`**; the policy assumes that namespace.
Changing the dependency topology requires revisiting and retesting the policy.

## 2. Create secrets, isolate the database, then create workloads

`prepare_secrets.py` first **creates** the namespace, then independently random
DB and queue credentials plus a URI Secret, through `kubectl create -f -` stdin.
It does not put credentials in argv, output or files; existing names fail rather
than being overwritten. Do not enable shell tracing or print Secret objects.
The helpers intentionally do not perform a destructive rollback on errors.

```bash
python3 prepare_secrets.py --kubeconfig "$KUBECONFIG" --context "$CTX" --namespace "$NS"
# Keep this original UID for guarded cleanup; do not recapture it at cleanup time.
export NS_UID="$(k get namespace "$NS" -o jsonpath='{.metadata.uid}')"

python3 render.py --namespace "$NS" --component policy > policy.generated.json
k create --dry-run=server -f policy.generated.json
k create -f policy.generated.json
k -n "$NS" get networkpolicy isolate-documentdb-ingress

python3 render.py --namespace "$NS" --component database > database.generated.json
k create --dry-run=server -f database.generated.json
k create -f database.generated.json
```

The policy is installed **before** the database. It allows gateway TCP 10260 only
from same-namespace `app=makeline-service` or `app=documentdb-test-client` pods;
PostgreSQL TCP 5432 only between this database's pods; and management/metrics TCP
8000/9187 from `cnpg-system`. Other ingress to the database pods is denied. The
client exception is for trusted synthetic tests only; do not grant that label to
untrusted workloads. This is ingress isolation, not an egress policy or complete
application hardening. In particular the demo REST/AMQP services are not a secure
multi-tenant application.

Wait for actual database state, not just controller deployment state:

```bash
k -n "$NS" get documentdb store-db -o jsonpath='{.status.status}{"\n"}{.status.tls.ready}{"\n"}'
k -n "$NS" get clusters.postgresql.cnpg.io,pods,pvc,services
k -n "$NS" wait --for=condition=Ready cluster.postgresql.cnpg.io/store-db --timeout=600s
k -n "$NS" wait --for=condition=Ready pod -l cnpg.io/cluster=store-db --timeout=600s
```

Require `Cluster in healthy state`, TLS ready `true`, a Bound PVC on `managed-csi`,
and the database pod Ready with both `postgres` and `documentdb-gateway`
containers. If resources are not yet created, inspect reconciliation/events and
retry the reads; do not proceed on `NotFound`. Inspect the actual image IDs and
ImageVolume mounts if startup fails. The explicit PostgreSQL image avoids relying
on a nested CRD default that may not populate when `spec.image` is absent.
Never substitute the baseline `documentdb-local` image for the CNPG image.

```bash
python3 render.py --namespace "$NS" --component apps > apps.generated.json
k create --dry-run=server -f apps.generated.json
k create -f apps.generated.json
for app in rabbitmq order-service makeline-service product-service; do
  k -n "$NS" rollout status "deployment/$app" --timeout=600s || break
done
k -n "$NS" get pods,services
```

Require **all four** deployments Ready and **every service ClusterIP**, without
external IPs. Failed rollout/health means stop and inspect, not continue to claim
success. Makeline health reflects initial DB setup, not a continuous ping; order
health alone does not prove queue delivery. The smoke test checks real data.

### Why URI-only credentials and this TLS mount?

The endpoint is `documentdb-service-store-db.<namespace>.svc:10260`. Operator
0.3.0's self-signed certificate includes that `.svc` SAN, **not**
`.svc.cluster.local`. The application mounts only public `tls.crt` as `ca.crt`,
**never `tls.key`**, and explicitly trusts that self-signed certificate. This is
not a certificate from a publicly trusted CA. No insecure TLS override is used.

`ORDER_DB_URI` includes escaped credentials, `authSource=admin`,
`authMechanism=SCRAM-SHA-256`, `directConnection=true`, `retryWrites=false`,
`tls=true`, and `tlsCAFile`. **Do not add `ORDER_DB_USERNAME` or
`ORDER_DB_PASSWORD`.** In the evaluated makeline implementation, separate
credential variables replace the URI's auth source and TLS configuration,
including its custom CA roots. Only makeline connects to DocumentDB; product
service is not a database client.

## 3. Exercise the real APIs and isolation

Open three terminals with the same explicit context and namespace; keep each
forward running and bound to loopback only:

```bash
kubectl --kubeconfig "$KUBECONFIG" --context "$CTX" -n "$NS" port-forward --address 127.0.0.1 svc/order-service 13000:3000
kubectl --kubeconfig "$KUBECONFIG" --context "$CTX" -n "$NS" port-forward --address 127.0.0.1 svc/makeline-service 13001:3001
kubectl --kubeconfig "$KUBECONFIG" --context "$CTX" -n "$NS" port-forward --address 127.0.0.1 svc/product-service 13002:3002
```

```bash
python3 smoke.py seed
```

This creates/reads/updates/deletes a synthetic **in-memory product**, posts an
order through the queue, finds it by unique synthetic customer ID, completes it,
and checks exact persisted readback. `smoke-evidence.json` contains only synthetic
order data. Use a new `--evidence` filename for a new seed run. It does not call AI
routes or try a nonexistent order DELETE API.

Check that the unrelated order-service pod cannot open either database port.
The hostname must resolve first; an NXDOMAIN is **not** isolation evidence. The
Node.js test exits nonzero on an unexpected connection, DNS error, or immediate
refusal; expected policy denial is a timeout. First establish the healthy
makeline path above so a dead database is not mistaken for policy enforcement.

```bash
k -n "$NS" exec -i deployment/order-service -- node - "$NS" <<'JS'
const dns = require('node:dns').promises;
const net = require('node:net');
(async () => {
  for (const [service, port] of [['store-db-rw', 5432], ['documentdb-service-store-db', 10260]]) {
    const host = `${service}.${process.argv[2]}.svc`;
    await dns.lookup(host);
    await new Promise((resolve, reject) => {
      const socket = net.connect({host, port});
      socket.setTimeout(5000);
      socket.on('connect', () => { socket.destroy(); reject(new Error('Unexpected connection')); });
      socket.on('timeout', () => { socket.destroy(); console.log(`PASS: denied ${port}`); resolve(); });
      socket.on('error', reject);
    });
  }
})().catch(() => { console.error('FAIL: verify DNS, database health and policy enforcement'); process.exitCode = 1; });
JS
```

### Optional direct TLS/authentication negative checks

Install PyMongo into a local virtual environment (the evaluated client was
PyMongo 4.x). Forward the database gateway in a **fourth** terminal:

```bash
kubectl --kubeconfig "$KUBECONFIG" --context "$CTX" -n "$NS" port-forward --address 127.0.0.1 svc/documentdb-service-store-db 20260:10260
```

```bash
python3 -m venv .venv
.venv/bin/python -m pip install 'pymongo>=4.10,<5'
export RECORD_ID="$(python3 -c 'import uuid; print(uuid.uuid4())')"
.venv/bin/python client_test.py write --kubeconfig "$KUBECONFIG" --context "$CTX" \
  --namespace "$NS" --record-id "$RECORD_ID"
```

The helper preserves the `.svc` name for TLS verification while resolving only
that name to loopback. It reads auth into memory and temporarily writes **only
the public certificate**, checks authenticated CRU, requires bad credentials to
fail with code 18, and requires default trust to reject the self-signed cert.
A connection timeout is not proof of bad-credential rejection. Port-forward uses
administrative access and does not itself test NetworkPolicy.

## 4. Deliberate single-pod restart and readback

This interrupts a **single-instance** database. Do this only after successful
seed checks, on your disposable evaluation, never on an existing database.
Record database pod name/UID, PVC UID and bound PV before the restart:

```bash
k -n "$NS" get pod -l cnpg.io/cluster=store-db -o json > db-before.generated.json
k -n "$NS" get pvc -l cnpg.io/cluster=store-db -o json > pvc-before.generated.json
```

Inspect those files. Identify the **one** Ready database pod. Deliberately delete
only that exact pod (not the DocumentDB CR, CNPG Cluster, PVC, PV or namespace):

```bash
: "${DB_POD:?Set to the exact inspected evaluation database pod name}"
k -n "$NS" delete pod "$DB_POD"
k -n "$NS" wait --for=condition=Ready pod -l cnpg.io/cluster=store-db --timeout=600s
k -n "$NS" get pod -l cnpg.io/cluster=store-db -o json > db-after.generated.json
k -n "$NS" get pvc -l cnpg.io/cluster=store-db -o json > pvc-after.generated.json
python3 smoke.py readback
```

Require a **changed pod UID**, **unchanged PVC UID and bound PV**, healthy
DocumentDB/TLS, and exact order readback. Re-establish the gateway port-forward
after pod replacement before rerunning the optional client:

```bash
.venv/bin/python client_test.py readback --kubeconfig "$KUBECONFIG" --context "$CTX" \
  --namespace "$NS" --record-id "$RECORD_ID"
```

A readback without independent pod/storage evidence does not establish restart
persistence. Keep the original smoke evidence for comparison.

## 5. Explicit, limited cleanup

Stop the port-forwards. **Never** run broad label-based cloud deletion, delete
CRDs, or uninstall shared controllers as sample cleanup. Inventory this
namespace's PVCs, bound PV names, reclaim policies, and Azure Disk CSI volume
handles **before** deleting anything. Keep that inventory private: it can contain
infrastructure identifiers. A retained disk can keep incurring charges.

The optional helper below operates through a loopback-only `kubectl proxy` started
with your explicit context. It is **plan-only by default** and refuses a wrong
name, original UID, ownership label or confirmation. Its namespace DELETE also
has a server-side UID precondition, protecting a namespace recreated since the
check. It does not remove PVs, disks, Helm releases, or any Azure resources.
Do not set up this proxy on a shared/untrusted host; close it afterwards.

In a separate terminal:

```bash
kubectl --kubeconfig "$KUBECONFIG" --context "$CTX" proxy --address=127.0.0.1 --port=18001
```

```bash
: "${NS_UID:?Use the original namespace UID recorded at creation}"
python3 cleanup.py --namespace "$NS" --uid "$NS_UID"
# Only after reviewing the plan and confirming this namespace contains only your evaluation:
python3 cleanup.py --namespace "$NS" --uid "$NS_UID" --confirm "$NS:$NS_UID"
k wait --for=delete "namespace/$NS" --timeout=600s
```

Verify namespace deletion completes; finalizers may delay it. **Do not remove
finalizers to force completion.** Inspect the previously recorded PVs/disks and
confirm whether their reclaim policy deleted or retained them. An owner must
explicitly dispose of only their retained resources, or delete their entire
pre-existing disposable Azure environment through its normal teardown process.
Namespace deletion is **not** proof that Azure charges have stopped. The sample
leaves cluster dependencies untouched.

## Local checks (no cluster, credentials or inference)

```bash
python3 -m unittest discover -s . -p 'test_*.py' -v
python3 render.py --namespace store-operator-check --component all > check.generated.json
python3 -m json.tool check.generated.json > /dev/null
```

The tests cover manifest pins, TLS/URI boundaries, policy selectors/ports,
create-only secret handling (including failure-output suppression), guarded
cleanup refusal/UID preconditions, and the Store contract against a **mock** API.
Mock passes are not real AKS or database evidence. Run Python without `-O`, since
the synthetic smoke checks use assertions.

See the [operator preview documentation](https://documentdb.io/documentdb-kubernetes-operator/latest/preview/)
and [operator 0.3.0 release](https://github.com/documentdb/documentdb-kubernetes-operator/releases/tag/0.3.0)
for its full API and limitations.
