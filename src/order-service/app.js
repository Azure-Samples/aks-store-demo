'use strict';

const path = require('path');
const AutoLoad = require('@fastify/autoload');
const grpc = require('@grpc/grpc-js');
const protoLoader = require('@grpc/proto-loader');

module.exports = async function (fastify, opts) {

  fastify.register(require('@fastify/cors'), { origin: '*' });

  // This loads all plugins defined in plugins
  // those should be support plugins that are reused
  // through your application
  fastify.register(AutoLoad, {
    dir: path.join(__dirname, 'plugins'),
    options: Object.assign({}, opts),
  });

  // This loads all plugins defined in routes
  // define your routes in one of these
  fastify.register(AutoLoad, {
    dir: path.join(__dirname, 'routes'),
    options: Object.assign({}, opts),
  });

  // Load gRPC proto file for MensagemService
  const PROTO_PATH = path.join(__dirname, 'mensagem.proto');
  const packageDefinition = protoLoader.loadSync(PROTO_PATH, {
    keepCase: true,
    longs: String,
    enums: String,
    defaults: true,
    oneofs: true,
  });

  // Load the MensagemService definition from the proto file
  const mensagemProto = grpc.loadPackageDefinition(packageDefinition).MensagemService;

  // Implement the EnviarMensagem method
  function enviarMensagem(call, callback) {
    const mensagem = call.request;
    console.log('Received message:', mensagem);

    let parsedConteudo;
    try {
      // Replace single quotes with double quotes
      const validJson = mensagem.conteudo.replace(/'/g, '"');
      
      // Parse the corrected JSON string
      parsedConteudo = JSON.parse(validJson);
    } catch (error) {
      console.error('Failed to parse conteudo:', error);
      callback(null,{
        resposta: 'Invalid JSON format in conteudo',
      });
      return;
    }
  
    // Pass the parsed content to sendMessage
    fastify.sendMessage(Buffer.from(JSON.stringify(parsedConteudo)));

    // Simulate message processing and respond
    callback(null, {
      resposta: `Mensagem recebida com sucesso: ${mensagem.conteudo}`,
    });
  }

  // Create gRPC server
  const grpcServer = new grpc.Server();
  grpcServer.addService(mensagemProto.service, { EnviarMensagem: enviarMensagem });

  // Start gRPC server
  grpcServer.bindAsync(
    '0.0.0.0:50051',
    grpc.ServerCredentials.createInsecure(),
    (err, port) => {
      if (err) {
        console.error('Failed to start gRPC server:', err);
        process.exit(1);
      }
      console.log(`gRPC server running on port ${port}`);
    }
  );
};
