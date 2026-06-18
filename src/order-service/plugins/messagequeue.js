'use strict'

const fp = require('fastify-plugin')
const rabbit = require('rabbitmq-amqp-js-client')
const rhea = require('rhea')

let rabbitEnvironment = null
let rabbitConnection = null
let rabbitPublisher = null
let initPromise = null

async function ensureRabbitPublisher() {
  if (rabbitPublisher) return rabbitPublisher

  // Coalesce concurrent calls into a single init attempt
  if (initPromise) return initPromise

  initPromise = (async () => {
    let env = null
    let conn = null
    try {
      const queueName = process.env.ORDER_QUEUE_NAME
      const host = process.env.ORDER_QUEUE_HOSTNAME
      const port = parseInt(process.env.ORDER_QUEUE_PORT, 10) || 5672

      env = rabbit.createEnvironment({
        host,
        port,
        username: process.env.ORDER_QUEUE_USERNAME,
        password: process.env.ORDER_QUEUE_PASSWORD,
      })

      conn = await env.createConnection()

      const management = conn.management()
      await management.declareQueue(queueName, { type: 'classic' })
      management.close()

      const publisher = await conn.createPublisher({
        queue: { name: queueName },
      })

      rabbitEnvironment = env
      rabbitConnection = conn
      rabbitPublisher = publisher
      return publisher
    } catch (err) {
      // Clean up partially created resources
      if (conn) await conn.close().catch(() => {})
      if (env) await env.close().catch(() => {})
      throw err
    } finally {
      initPromise = null
    }
  })()

  return initPromise
}

module.exports = fp(async function (fastify, opts) {
  // Initialize RabbitMQ connection and queue on startup (skip for Azure Service Bus)
  const hostname = process.env.ORDER_QUEUE_HOSTNAME || ''
  const isServiceBus = hostname.endsWith('.servicebus.windows.net')
  if (process.env.ORDER_QUEUE_USERNAME && process.env.ORDER_QUEUE_PASSWORD && !isServiceBus) {
    try {
      await ensureRabbitPublisher()
      console.log(`connected to RabbitMQ at ${hostname}:${process.env.ORDER_QUEUE_PORT}, queue "${process.env.ORDER_QUEUE_NAME}" declared`)
    } catch (err) {
      console.error('failed to initialize RabbitMQ connection:', err.message)
    }
  }

  fastify.addHook('onClose', async () => {
    if (rabbitPublisher) {
      rabbitPublisher.close()
      rabbitPublisher = null
    }
    if (rabbitConnection) {
      await rabbitConnection.close()
      rabbitConnection = null
    }
    if (rabbitEnvironment) {
      await rabbitEnvironment.close()
      rabbitEnvironment = null
    }
  })

  fastify.decorate('sendMessage', async function (message) {
    const body = message.toString()
    const hostname = process.env.ORDER_QUEUE_HOSTNAME || ''
    const isServiceBus = hostname.endsWith('.servicebus.windows.net')

    if (process.env.ORDER_QUEUE_USERNAME && process.env.ORDER_QUEUE_PASSWORD && !isServiceBus) {
      console.log(`sending message ${body} to ${process.env.ORDER_QUEUE_NAME} on ${hostname} using local auth credentials`)

      const publisher = await ensureRabbitPublisher()
      const dataBody = rhea.message.data_section(Buffer.from(body, 'utf8'))
      const publishResult = await publisher.publish(
        rabbit.createAmqpMessage({ body: dataBody })
      )
      if (publishResult.outcome === rabbit.OutcomeState.ACCEPTED) {
        console.log('message accepted by RabbitMQ')
      } else {
        throw new Error(`message not accepted by RabbitMQ, outcome: ${publishResult.outcome}`)
      }
    } else if (isServiceBus || process.env.USE_WORKLOAD_IDENTITY_AUTH === 'true') {
      const { ServiceBusClient } = require("@azure/service-bus")
      const fullyQualifiedNamespace = hostname || process.env.AZURE_SERVICEBUS_FULLYQUALIFIEDNAMESPACE
      const queueName = process.env.ORDER_QUEUE_NAME

      if (!fullyQualifiedNamespace) {
        console.log('no hostname set for message queue. exiting.')
        return
      }

      let credential
      if (process.env.ORDER_QUEUE_USERNAME && process.env.ORDER_QUEUE_PASSWORD) {
        const { AzureNamedKeyCredential } = require("@azure/core-auth")
        credential = new AzureNamedKeyCredential(process.env.ORDER_QUEUE_USERNAME, process.env.ORDER_QUEUE_PASSWORD)
        console.log(`sending message ${body} to ${queueName} on ${fullyQualifiedNamespace} using SAS key credentials`)
      } else {
        const { DefaultAzureCredential } = require("@azure/identity")
        credential = new DefaultAzureCredential()
        console.log(`sending message ${body} to ${queueName} on ${fullyQualifiedNamespace} using Microsoft Entra ID Workload Identity credentials`)
      }

      const sbClient = new ServiceBusClient(fullyQualifiedNamespace, credential)
      const sender = sbClient.createSender(queueName)
      try {
        await sender.sendMessages({ body: body })
      } finally {
        await sender.close()
        await sbClient.close()
      }
    } else {
      console.log('no credentials set for message queue. exiting.')
      return
    }
  })
})
