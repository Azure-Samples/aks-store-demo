'use strict'

const path = require('path')
const AutoLoad = require('@fastify/autoload')

const {
  ORDER_QUEUE_PROTOCOL = 'amqp',
  ORDER_QUEUE_HOSTNAME = 'localhost',
  ORDER_QUEUE_PORT = 5672,
  ORDER_QUEUE_USERNAME = 'username',
  ORDER_QUEUE_PASSWORD = 'password'
} = process.env

module.exports = async function (fastify, opts) {
  // Place here your custom code!
  fastify.register(require('fastify-amqp'), {
    protocol: ORDER_QUEUE_PROTOCOL,
    hostname: ORDER_QUEUE_HOSTNAME,
    port: ORDER_QUEUE_PORT,
    username: ORDER_QUEUE_USERNAME,
    password: ORDER_QUEUE_PASSWORD
  })

  // Do not touch the following lines

  // This loads all plugins defined in plugins
  // those should be support plugins that are reused
  // through your application
  fastify.register(AutoLoad, {
    dir: path.join(__dirname, 'plugins'),
    options: Object.assign({}, opts)
  })

  // This loads all plugins defined in routes
  // define your routes in one of these
  fastify.register(AutoLoad, {
    dir: path.join(__dirname, 'routes'),
    options: Object.assign({}, opts)
  })
}
