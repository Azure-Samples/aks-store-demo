'use strict'

const fp = require('fastify-plugin')

module.exports = fp(async function (fastify, opts) {
  fastify.decorate('sendMessage', function (message) {
    const body = message.toString()
    if (process.env.ORDER_QUEUE_USERNAME && process.env.ORDER_QUEUE_PASSWORD) {
      console.log('sending message ${body} to ${process.env.ORDER_QUEUE_NAME} on ${process.env.ORDER_QUEUE_HOSTNAME} using local auth credentials')
      
      const rhea = require('rhea')
      const container = rhea.create_container()
      var amqp_message = container.message;

      const connectOptions = {
        hostname: process.env.ORDER_QUEUE_HOSTNAME,
        host: process.env.ORDER_QUEUE_HOSTNAME,
        port: process.env.ORDER_QUEUE_PORT,
        username: process.env.ORDER_QUEUE_USERNAME,
        password: process.env.ORDER_QUEUE_PASSWORD,
        reconnect_limit: process.env.ORDER_QUEUE_RECONNECT_LIMIT || 0
      }
      
      if (process.env.ORDER_QUEUE_TRANSPORT !== undefined) {
        connectOptions.transport = process.env.ORDER_QUEUE_TRANSPORT
      }
      
      const connection = container.connect(connectOptions)
      
      container.once('sendable', function (context) {
        const sender = context.sender;
        sender.send({
          body: amqp_message.data_section(Buffer.from(body,'utf8'))
        });
        sender.close();
        connection.close();
      })

      connection.open_sender(process.env.ORDER_QUEUE_NAME)
    } else if (process.env.USE_WORKLOAD_IDENTITY_AUTH === 'true') {
      const { ServiceBusClient } = require("@azure/service-bus");
      const { DefaultAzureCredential } = require("@azure/identity");

      const fullyQualifiedNamespace = process.env.ORDER_QUEUE_HOSTNAME || process.env.AZURE_SERVICEBUS_FULLYQUALIFIEDNAMESPACE;

      console.log(`sending message ${body} to ${process.env.ORDER_QUEUE_NAME} on ${fullyQualifiedNamespace} using Microsoft Entra ID Workload Identity credentials`);
      
      if (!fullyQualifiedNamespace) {
        console.log('no hostname set for message queue. exiting.');
        return;
      }
      
      const queueName = process.env.ORDER_QUEUE_NAME

      const credential = new DefaultAzureCredential();

      async function sendMessage() {
        const sbClient = new ServiceBusClient(fullyQualifiedNamespace, credential);
        const sender = sbClient.createSender(queueName);

        try {
          await sender.sendMessages({ body: body });
        } finally {
          await sender.close();
          await sbClient.close();
        }
      }
      sendMessage().catch(console.error);
    } else {
      console.log('no credentials set for message queue. exiting.')
      return
    }
  })
})
