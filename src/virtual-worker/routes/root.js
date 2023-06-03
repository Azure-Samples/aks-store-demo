'use strict'

module.exports = async function (fastify, opts) {
  fastify.get('/', async function (request, reply) {
    const channel = this.amqp.channel

    const queue = 'orders'

    channel.assertQueue(queue, {
      durable: false
    })

    // connect to mongodb
    const orders = this.mongo.db.collection('orders')

    // prefetch 1 message at a time
    channel.prefetch(1);

    // consume messages from queue and save to mongodb
    channel.consume(queue, function (msg) {
      if (msg !== null) {
        try {
          request.log.info(msg.content.toString());
          orders.insertOne(JSON.parse(msg.content.toString()))
          channel.ack(msg);
          reply.code(201)
        } catch (err) {
          console.log(err)
          channel.nack(msg);
          reply.code(500)
        }
      }
    })
  })
}
