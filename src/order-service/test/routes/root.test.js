'use strict'

const { test } = require('tap')
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
