'use strict'

module.exports = async function (fastify, opts) {
  fastify.post('/', async function (request, reply) {
    const channel = this.amqp.channel

    const queue = 'order-queue'
    const msg = request.body

    channel.assertQueue(queue, {
      durable: false
    })

    channel.sendToQueue(queue, Buffer.from(JSON.stringify(msg)))
    reply.code(201)
  })
}
