'use strict'

const { test } = require('tap')
const { Readable } = require('node:stream')
const { setImmediate } = require('node:timers/promises')
const Fastify = require('fastify')
const { build } = require('../helper')
const routes = require('../../routes/root')

function buildWithQueue (t, sendMessage) {
  const app = Fastify()
  app.decorate('sendMessage', sendMessage)
  app.register(routes)
  t.teardown(app.close.bind(app))
  return app
}

test('health route', async (t) => {
  const app = await build(t)

  const res = await app.inject({
    url: '/health'
  })
  t.equal(res.statusCode, 200)
  t.same(JSON.parse(res.payload), {
    status: 'ok',
    version: process.env.APP_VERSION || '0.1.0'
  })
})

test('accepts and publishes an order', async (t) => {
  const messages = []
  const app = buildWithQueue(t, async (message) => {
    messages.push(JSON.parse(message.toString()))
  })
  const order = { customerId: 'customer-1', items: [{ productId: 1, quantity: 2 }] }

  const res = await app.inject({
    method: 'POST',
    url: '/',
    payload: order
  })

  t.equal(res.statusCode, 201)
  t.same(messages, [order])
})

test('rejects malformed JSON without publishing an order', async (t) => {
  const messages = []
  const app = buildWithQueue(t, async (message) => {
    messages.push(message)
  })

  const res = await app.inject({
    method: 'POST',
    url: '/',
    headers: { 'content-type': 'application/json' },
    payload: '{"items":'
  })

  t.equal(res.statusCode, 400)
  t.same(messages, [])
})

test('preserves UTF-8 order data split across request chunks', async (t) => {
  const messages = []
  const app = buildWithQueue(t, async (message) => {
    messages.push(JSON.parse(message.toString()))
  })
  const order = {
    customerId: 'caf\u00e9-\u{1F680}',
    items: [{ productId: 1, quantity: 2 }]
  }
  const body = Buffer.from(JSON.stringify(order))
  const firstSplit = body.indexOf(Buffer.from('\u00e9')) + 1
  const secondSplit = body.indexOf(Buffer.from('\u{1F680}')) + 2
  const payload = Readable.from((async function * () {
    // Split inside both a two-byte and a four-byte UTF-8 character.
    yield body.subarray(0, firstSplit)
    await setImmediate()
    yield body.subarray(firstSplit, secondSplit)
    await setImmediate()
    yield body.subarray(secondSplit)
  })())

  const res = await app.inject({
    method: 'POST',
    url: '/',
    headers: { 'content-type': 'application/json' },
    payload
  })

  t.equal(res.statusCode, 201)
  t.same(messages, [order])
})

test('reports message queue failures', async (t) => {
  const app = buildWithQueue(t, async () => {
    throw new Error('Queue unavailable')
  })

  const res = await app.inject({
    method: 'POST',
    url: '/',
    payload: { customerId: 'customer-1', items: [] }
  })

  t.equal(res.statusCode, 500)
})
