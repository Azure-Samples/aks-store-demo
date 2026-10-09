#!/usr/bin/env python3
"""Real HTTP contract runner. Use port-forwards; no cloud/kubectl access.
seed creates products + order via real APIs; readback checks stored order state.
A database restart must be evidenced independently; readback alone cannot prove it.
Order DELETE does not exist upstream; this is CRU, NOT full CRUD.
"""
import argparse, json, time, uuid, urllib.request, urllib.error
from pathlib import Path

def request(base, path='/', method='GET', body=None):
    data = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(base + path, data=data, method=method, headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(req, timeout=15) as r:
        raw = r.read()
        return (r.status, json.loads(raw) if raw else None)

def eventually(f, timeout=120):
    end = time.monotonic() + timeout
    last = None
    while time.monotonic() < end:
        try:
            result = f()
            if result:
                return result
        except (urllib.error.URLError, AssertionError) as e:
            last = type(e).__name__
        time.sleep(2)
    raise AssertionError('Timed out waiting for API invariant: ' + str(last))

def run(a):
    if not __debug__:
        raise RuntimeError('Run without Python optimization; validation requires assertions')
    for base in [a.order, a.makeline, a.product]:
        eventually(lambda: request(base, '/health')[0] == 200)
    if a.phase == 'readback':
        expected = json.loads(Path(a.evidence).read_text())['order']

        def check():
            got = request(a.makeline, '/order/' + expected['orderId'])[1]
            assert got == expected, (got, expected)
            return got
        eventually(check)
        print('PASS: exact order ID, customer, items and completed status read back through makeline. DB restart must be independently evidenced.')
        return
    if Path(a.evidence).exists():
        raise FileExistsError('Refusing to overwrite smoke evidence; choose a fresh --evidence file')
    products = request(a.product)[1]
    assert len(products) >= 10
    sample = {'id': 0, 'name': 'Operator smoke ' + uuid.uuid4().hex[:8], 'price': 1.25, 'description': 'Synthetic integration test, no AI', 'image': '/catnip.jpg'}
    product = request(a.product, method='POST', body=sample)[1]
    assert product['id'] > 0
    assert request(a.product, '/' + str(product['id']))[1] == product
    product['price'] = 2.5
    request(a.product, method='PUT', body=product)
    assert request(a.product, '/' + str(product['id']))[1]['price'] == 2.5
    customer = 'operator-smoke-' + uuid.uuid4().hex
    body = {'customerId': customer, 'items': [{'productId': product['id'], 'quantity': 2, 'price': 2.5}]}
    assert request(a.order, method='POST', body=body)[0] == 201

    def pending():
        found = [o for o in request(a.makeline, '/order/fetch')[1] or [] if o['customerId'] == customer]
        assert len(found) <= 1, 'Duplicate delivery or ID collision; inspect DB'
        return found[0] if found else None
    order = eventually(pending)
    assert order['status'] == 0 and order['items'] == body['items']
    assert request(a.makeline, '/order/' + order['orderId'])[1] == order
    order['status'] = 2
    request(a.makeline, '/order', method='PUT', body=order)
    assert request(a.makeline, '/order/' + order['orderId'])[1] == order
    assert not any((o['orderId'] == order['orderId'] for o in request(a.makeline, '/order/fetch')[1] or []))
    request(a.product, '/' + str(product['id']), method='DELETE')
    try:
        request(a.product, '/' + str(product['id']))
    except urllib.error.HTTPError as e:
        e.close()
        assert e.code == 404
    else:
        raise AssertionError('Deleted product still exists')
    Path(a.evidence).write_text(json.dumps({'order': order, 'productCrud': True, 'orderCRU': True, 'orderDelete': 'unsupported', 'ai': 'not tested', 'dbRestart': 'must be independently evidenced'}, indent=2) + '\n')
    print('PASS: product in-memory CRUD and queue-to-DB order create/read/update. Evidence written. Restart/readback still required.')
if __name__ == '__main__':
    p = argparse.ArgumentParser()
    p.add_argument('phase', choices=['seed', 'readback'])
    p.add_argument('--order', default='http://127.0.0.1:13000')
    p.add_argument('--makeline', default='http://127.0.0.1:13001')
    p.add_argument('--product', default='http://127.0.0.1:13002')
    p.add_argument('--evidence', default='smoke-evidence.json')
    run(p.parse_args())
