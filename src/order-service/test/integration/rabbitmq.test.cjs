'use strict'

const assert = require('node:assert/strict')
const { test } = require('node:test')
const { setTimeout: delay } = require('node:timers/promises')
const Fastify = require('fastify')
const appPlugin = require('../../app')

test('HTTP orders reach RabbitMQ unchanged and malformed JSON is not published', {
  timeout: 30000
}, async () => {
  for (const name of [
    'ORDER_QUEUE_HOSTNAME', 'ORDER_QUEUE_PORT', 'ORDER_QUEUE_USERNAME',
    'ORDER_QUEUE_PASSWORD', 'ORDER_QUEUE_NAME', 'RABBITMQ_MANAGEMENT_URL'
  ]) {
    assert.ok(process.env[name], `${name} must be set for the integration test`)
  }
  const app = Fastify()
  app.register(appPlugin)
  try {
    const address = await app.listen({ host: '127.0.0.1', port: 0 })
    const health = await fetch(`${address}/health`, { signal: AbortSignal.timeout(5000) })
    assert.equal(health.status, 200)
    assert.equal((await health.json()).status, 'ok')

    const invalid = await fetch(address, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: '{"items":',
      signal: AbortSignal.timeout(5000)
    })
    assert.equal(invalid.status, 400)
    await invalid.text()

    const order = { customerId: 'integration-customer', items: [{ productId: 1, quantity: 2 }] }
    const response = await fetch(address, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify(order),
      signal: AbortSignal.timeout(5000)
    })
    assert.equal(response.status, 201)
    await response.text()

    const queueUrl = new URL(
      `/api/queues/%2F/${encodeURIComponent(process.env.ORDER_QUEUE_NAME)}/get`,
      process.env.RABBITMQ_MANAGEMENT_URL
    )
    async function readMessages () {
      const result = await fetch(queueUrl, {
        method: 'POST',
        headers: {
          'content-type': 'application/json',
          authorization: `Basic ${Buffer.from(
            `${process.env.ORDER_QUEUE_USERNAME}:${process.env.ORDER_QUEUE_PASSWORD}`
          ).toString('base64')}`
        },
        body: JSON.stringify({ count: 10, ackmode: 'ack_requeue_false', encoding: 'auto' }),
        signal: AbortSignal.timeout(5000)
      })
      assert.equal(result.status, 200, 'RabbitMQ management API must succeed')
      return result.json()
    }

    let messages = []
    for (let attempt = 0; attempt < 20; attempt++) {
      messages = await readMessages()
      if (messages.length) break
      await delay(250)
    }
    assert.equal(messages.length, 1, 'Only the valid order should be queued')
    const payload = messages[0].payload_encoding === 'base64'
      ? Buffer.from(messages[0].payload, 'base64').toString('utf8')
      : messages[0].payload
    assert.deepEqual(JSON.parse(payload), order)
    assert.deepEqual(await readMessages(), [], 'No additional messages should remain')
  } finally {
    await app.close()
  }
})
