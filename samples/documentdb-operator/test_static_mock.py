import contextlib, io, json, tempfile, unittest, urllib.error, urllib.parse
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch
import render, prepare_secrets, smoke

class PreparationTests(unittest.TestCase):

    def test_manifest_boundaries(self):
        docs = render.render()['items']
        self.assertEqual(len(docs), 10)
        for d in docs:
            if d['kind'] == 'Service':
                self.assertEqual(d['spec']['type'], 'ClusterIP')
            if d['kind'] == 'Deployment':
                for c in d['spec']['template']['spec']['containers']:
                    self.assertIn('@sha256:', c['image'])
        mk = next((d for d in docs if d['metadata']['name'] == 'makeline-service' and d['kind'] == 'Deployment'))
        envs = mk['spec']['template']['spec']['containers'][0]['env']
        self.assertFalse(any((e['name'] in ['ORDER_DB_USERNAME', 'ORDER_DB_PASSWORD'] for e in envs)))
        self.assertTrue(next((e for e in envs if e['name'] == 'ORDER_DB_URI'))['valueFrom'])
        self.assertNotIn('LoadBalancer', json.dumps(docs))
        self.assertNotIn('ai-service', json.dumps(docs))

    def test_uri_encoding_and_verification(self):
        u = urllib.parse.urlparse(prepare_secrets.uri('documentdb-service-store-db.store-operator.svc', 'u@ser', 'a:/?#%'))
        self.assertEqual(urllib.parse.unquote(u.username), 'u@ser')
        self.assertEqual(urllib.parse.unquote(u.password), 'a:/?#%')
        q = urllib.parse.parse_qs(u.query)
        self.assertEqual(q['authSource'], ['admin'])
        self.assertEqual(q['tls'], ['true'])
        self.assertIn('tlsCAFile', q)
        self.assertNotIn('tlsAllowInvalidCertificates', q)

    def test_smoke_contract_mock_not_runtime(self):
        orders = []
        products = [{'id': i} for i in range(1, 11)]

        def api(base, path='/', method='GET', body=None):
            if path == '/health':
                return (200, {'status': 'ok'})
            if base == 'p':
                if path == '/' and method == 'GET':
                    return (200, products.copy())
                if method == 'POST':
                    p = dict(body, id=11)
                    products.append(p)
                    return (200, p.copy())
                if method == 'PUT':
                    products[-1] = body.copy()
                    return (200, body.copy())
                if method == 'DELETE':
                    products.pop()
                    return (200, None)
                p = next((p for p in products if p['id'] == int(path[1:])), None)
                if p is None:
                    raise urllib.error.HTTPError(path, 404, 'not found', {}, None)
                return (200, p.copy())
            if base == 'o':
                orders.append(dict(body, orderId='123', status=0))
                return (201, None)
            if path == '/order/fetch':
                return (200, [o.copy() for o in orders if o['status'] == 0])
            if method == 'PUT':
                orders[0] = body.copy()
                return (200, None)
            return (200, orders[0].copy())
        with tempfile.TemporaryDirectory() as tmp, patch.object(smoke, 'request', api):
            a = SimpleNamespace(order='o', makeline='m', product='p', phase='seed', evidence=str(Path(tmp) / 'evidence.json'))
            with contextlib.redirect_stdout(io.StringIO()):
                smoke.run(a)
                a.phase = 'readback'
                smoke.run(a)
if __name__ == '__main__':
    unittest.main()
