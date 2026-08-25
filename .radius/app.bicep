extension radius

param environment string

@secure()
param rabbitmqPassword string

@secure()
param registryPassword string

@secure()
param registryUsername string

resource aksStoreDemoApp 'Radius.Core/applications@2025-08-01-preview' = {
  name: 'aks-store-demo'
  properties: {
    environment: environment
  }
}

resource mongoDb 'Radius.Data/mongoDatabases@2025-08-01-preview' = {
  name: 'mongo'
  properties: {
    environment: environment
    application: aksStoreDemoApp.id
    database: 'orderdb'
    codeReference: 'src/makeline-service/mongodb.go#L127'
  }
}

resource rabbitmqQueue 'Radius.Messaging/rabbitMQ@2025-08-01-preview' = {
  name: 'rabbitmq'
  properties: {
    environment: environment
    application: aksStoreDemoApp.id
    queue: 'orders'
    username: 'radius'
    password: rabbitmqSecret.id
    codeReference: 'src/order-service/plugins/messagequeue.js#L26'
  }
}

resource rabbitmqSecret 'Radius.Security/secrets@2025-08-01-preview' = {
  name: 'rabbitmq-secret'
  properties: {
    environment: environment
    application: aksStoreDemoApp.id
    data: {
      password: {
        value: rabbitmqPassword
      }
    }
    codeReference: 'src/order-service/plugins/messagequeue.js#L29'
  }
}

resource registryCreds 'Radius.Security/secrets@2025-08-01-preview' = {
  name: 'radius-ghcr-registry-creds'
  properties: {
    environment: environment
    application: aksStoreDemoApp.id
    data: {
      password: {
        value: registryPassword
      }
      username: {
        value: registryUsername
      }
    }
  }
}

resource storeAdminNginxConfig 'Radius.Security/secrets@2025-08-01-preview' = {
  name: 'store-admin-nginx-config'
  properties: {
    environment: environment
    application: aksStoreDemoApp.id
    data: {
      'default.conf': {
        value: replace(replace(replace('''
server {
    listen       8081;
    listen  [::]:8081;
    server_name  localhost;

    client_max_body_size 10m;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
        try_files $uri $uri/ /index.html;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }

    location /health {
        default_type application/json;
        return 200 '{"status":"ok","version":"0.1.0"}';
    }

    location ~ ^/api/makeline/order/(?<id>\w+) {
        proxy_pass http://__MAKELINE_SERVICE_HOST__:3001/order/$id;
        proxy_http_version 1.1;
    }

    location /api/makeline/order {
        proxy_pass http://__MAKELINE_SERVICE_HOST__:3001/order;
        proxy_http_version 1.1;
    }

    location /api/makeline/order/fetch {
        proxy_pass http://__MAKELINE_SERVICE_HOST__:3001/order/fetch;
        proxy_http_version 1.1;
    }

    location /api/order {
        rewrite ^/api/order$ / break;
        rewrite ^/api/order(/.*)$ $1 break;
        proxy_pass http://__ORDER_SERVICE_HOST__:3000;
        proxy_http_version 1.1;
    }

    location /api/products/ {
        proxy_pass http://__PRODUCT_SERVICE_HOST__:3002/;
        proxy_http_version 1.1;
    }

    location /api/products {
        rewrite ^/api/products$ / break;
        rewrite ^/api/products(/.*)$ $1 break;
        proxy_pass http://__PRODUCT_SERVICE_HOST__:3002;
        proxy_http_version 1.1;
    }

    location ~ ^/api/product/(?<id>\w+) {
        proxy_pass http://__PRODUCT_SERVICE_HOST__:3002/$id;
        proxy_http_version 1.1;
    }

    location /api/product {
        rewrite ^/api/product$ / break;
        rewrite ^/api/product(/.*)$ $1 break;
        proxy_pass http://__PRODUCT_SERVICE_HOST__:3002;
        proxy_http_version 1.1;
    }

    location /api/product/ {
        proxy_pass http://__PRODUCT_SERVICE_HOST__:3002/;
        proxy_http_version 1.1;
    }

    location /api/ai/health {
        proxy_pass http://__PRODUCT_SERVICE_HOST__:3002/ai/health;
        proxy_http_version 1.1;
    }

    location /api/ai/generate/description {
        proxy_pass http://__PRODUCT_SERVICE_HOST__:3002/ai/generate/description;
        proxy_http_version 1.1;
    }

    location /api/ai/generate/image {
        proxy_pass http://__PRODUCT_SERVICE_HOST__:3002/ai/generate/image;
        proxy_http_version 1.1;
        proxy_connect_timeout 30s;
        proxy_read_timeout 300s;
        proxy_send_timeout 300s;
    }
}
''', '__MAKELINE_SERVICE_HOST__', makelineServiceContainer.properties.hosts.makeline), '__ORDER_SERVICE_HOST__', orderServiceContainer.properties.hosts.order), '__PRODUCT_SERVICE_HOST__', productServiceContainer.properties.hosts.product)
      }
    }
    codeReference: 'src/store-admin/nginx.conf'
  }
}

resource storeFrontNginxConfig 'Radius.Security/secrets@2025-08-01-preview' = {
  name: 'store-front-nginx-config'
  properties: {
    environment: environment
    application: aksStoreDemoApp.id
    data: {
      'default.conf': {
        value: replace(replace('''
server {
    listen       8080;
    listen  [::]:8080;
    server_name  localhost;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
        try_files $uri $uri/ /index.html;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }

    location /health {
        default_type application/json;
        return 200 '{"status":"ok","version":"0.1.0"}';
    }

    location /api/orders {
        rewrite ^/api/orders$ / break;
        rewrite ^/api/orders(/.*)$ $1 break;
        proxy_pass http://__ORDER_SERVICE_HOST__:3000;
        proxy_http_version 1.1;
    }

    location /api/products {
        rewrite ^/api/products$ / break;
        rewrite ^/api/products(/.*)$ $1 break;
        proxy_pass http://__PRODUCT_SERVICE_HOST__:3002;
        proxy_http_version 1.1;
    }
}
''', '__ORDER_SERVICE_HOST__', orderServiceContainer.properties.hosts.order), '__PRODUCT_SERVICE_HOST__', productServiceContainer.properties.hosts.product)
      }
    }
    codeReference: 'src/store-front/nginx.conf'
  }
}

resource makelineServiceImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'makeline-service-image'
  properties: {
    environment: environment
    application: aksStoreDemoApp.id
    build: {
      source: 'git::https://github.com/Reshrahim/aks-store-demo.git//src/makeline-service?ref=867dc76c5c365c30bc8aef3ff570d7aa0c3fa522'
      platforms: [
        'linux/amd64'
      ]
    }
    codeReference: 'src/makeline-service/Dockerfile'
  }
  dependsOn: [
    registryCreds
  ]
}

resource orderServiceImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'order-service-image'
  properties: {
    environment: environment
    application: aksStoreDemoApp.id
    build: {
      source: 'git::https://github.com/Reshrahim/aks-store-demo.git//src/order-service?ref=867dc76c5c365c30bc8aef3ff570d7aa0c3fa522'
      platforms: [
        'linux/amd64'
      ]
    }
    codeReference: 'src/order-service/Dockerfile'
  }
  dependsOn: [
    registryCreds
  ]
}

resource productServiceImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'product-service-image'
  properties: {
    environment: environment
    application: aksStoreDemoApp.id
    build: {
      source: 'git::https://github.com/Reshrahim/aks-store-demo.git//src/product-service?ref=867dc76c5c365c30bc8aef3ff570d7aa0c3fa522'
      platforms: [
        'linux/amd64'
      ]
    }
    codeReference: 'src/product-service/Dockerfile'
  }
  dependsOn: [
    registryCreds
  ]
}

resource storeAdminImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'store-admin-image'
  properties: {
    environment: environment
    application: aksStoreDemoApp.id
    build: {
      source: 'git::https://github.com/Reshrahim/aks-store-demo.git//src/store-admin?ref=867dc76c5c365c30bc8aef3ff570d7aa0c3fa522'
      platforms: [
        'linux/amd64'
      ]
    }
    codeReference: 'src/store-admin/Dockerfile'
  }
  dependsOn: [
    registryCreds
  ]
}

resource storeFrontImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'store-front-image'
  properties: {
    environment: environment
    application: aksStoreDemoApp.id
    build: {
      source: 'git::https://github.com/Reshrahim/aks-store-demo.git//src/store-front?ref=867dc76c5c365c30bc8aef3ff570d7aa0c3fa522'
      platforms: [
        'linux/amd64'
      ]
    }
    codeReference: 'src/store-front/Dockerfile'
  }
  dependsOn: [
    registryCreds
  ]
}

resource virtualCustomerImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'virtual-customer-image'
  properties: {
    environment: environment
    application: aksStoreDemoApp.id
    build: {
      source: 'git::https://github.com/Reshrahim/aks-store-demo.git//src/virtual-customer?ref=867dc76c5c365c30bc8aef3ff570d7aa0c3fa522'
      platforms: [
        'linux/amd64'
      ]
    }
    codeReference: 'src/virtual-customer/Dockerfile'
  }
  dependsOn: [
    registryCreds
  ]
}

resource virtualWorkerImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'virtual-worker-image'
  properties: {
    environment: environment
    application: aksStoreDemoApp.id
    build: {
      source: 'git::https://github.com/Reshrahim/aks-store-demo.git//src/virtual-worker?ref=867dc76c5c365c30bc8aef3ff570d7aa0c3fa522'
      platforms: [
        'linux/amd64'
      ]
    }
    codeReference: 'src/virtual-worker/Dockerfile'
  }
  dependsOn: [
    registryCreds
  ]
}

resource makelineServiceContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'makeline-service'
  properties: {
    environment: environment
    application: aksStoreDemoApp.id
    containers: {
      makeline: {
        image: makelineServiceImage.properties.imageReference
        env: {
          ORDER_DB_COLLECTION_NAME: {
            value: 'orders'
          }
          ORDER_DB_NAME: {
            value: 'orderdb'
          }
          ORDER_DB_URI: {
            valueFrom: {
              secretKeyRef: {
                secretName: mongoDb.properties.secrets.name
                key: 'connectionString'
              }
            }
          }
          ORDER_QUEUE_NAME: {
            value: 'orders'
          }
          ORDER_QUEUE_PASSWORD: {
            value: rabbitmqPassword
          }
          ORDER_QUEUE_URI: {
            value: 'amqp://${rabbitmqQueue.properties.host}:${rabbitmqQueue.properties.port}'
          }
          ORDER_QUEUE_USERNAME: {
            value: 'radius'
          }
        }
        ports: {
          web: {
            containerPort: 3001
          }
        }
        readinessProbe: {
          httpGet: {
            path: '/health'
            port: 3001
          }
        }
      }
    }
    connections: {
      mongodb: {
        source: mongoDb.id
        disableDefaultEnvVars: true
      }
      rabbitmq: {
        source: rabbitmqQueue.id
        disableDefaultEnvVars: true
      }
    }
    codeReference: 'src/makeline-service/main.go#L88'
  }
}

resource orderServiceContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'order-service'
  properties: {
    environment: environment
    application: aksStoreDemoApp.id
    containers: {
      order: {
        image: orderServiceImage.properties.imageReference
        env: {
          FASTIFY_ADDRESS: {
            value: '0.0.0.0'
          }
          ORDER_QUEUE_HOSTNAME: {
            value: rabbitmqQueue.properties.host
          }
          ORDER_QUEUE_NAME: {
            value: 'orders'
          }
          ORDER_QUEUE_PASSWORD: {
            value: rabbitmqPassword
          }
          ORDER_QUEUE_PORT: {
            value: string(rabbitmqQueue.properties.port)
          }
          ORDER_QUEUE_USERNAME: {
            value: 'radius'
          }
        }
        ports: {
          web: {
            containerPort: 3000
          }
        }
        readinessProbe: {
          httpGet: {
            path: '/health'
            port: 3000
          }
        }
      }
    }
    connections: {
      rabbitmq: {
        source: rabbitmqQueue.id
        disableDefaultEnvVars: true
      }
    }
    codeReference: 'src/order-service/plugins/messagequeue.js#L26'
  }
}

resource productServiceContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'product-service'
  properties: {
    environment: environment
    application: aksStoreDemoApp.id
    containers: {
      product: {
        image: productServiceImage.properties.imageReference
        ports: {
          web: {
            containerPort: 3002
          }
        }
        readinessProbe: {
          httpGet: {
            path: '/health'
            port: 3002
          }
        }
      }
    }
    codeReference: 'src/product-service/src/config.rs#L65'
  }
}

resource storeAdminContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'store-admin'
  properties: {
    environment: environment
    application: aksStoreDemoApp.id
    containers: {
      storeadmin: {
        image: storeAdminImage.properties.imageReference
        ports: {
          web: {
            containerPort: 8081
          }
        }
        readinessProbe: {
          httpGet: {
            path: '/health'
            port: 8081
          }
        }
        volumeMounts: [
          {
            volumeName: 'nginxConfig'
            mountPath: '/etc/nginx/conf.d'
          }
        ]
      }
    }
    connections: {
      makelineservice: {
        source: makelineServiceContainer.id
        disableDefaultEnvVars: true
      }
      orderservice: {
        source: orderServiceContainer.id
        disableDefaultEnvVars: true
      }
      productservice: {
        source: productServiceContainer.id
        disableDefaultEnvVars: true
      }
    }
    volumes: {
      nginxConfig: {
        secretName: storeAdminNginxConfig.name
      }
    }
    codeReference: 'src/store-admin/nginx.conf#L1'
  }
}

resource storeFrontContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'store-front'
  properties: {
    environment: environment
    application: aksStoreDemoApp.id
    containers: {
      storefront: {
        image: storeFrontImage.properties.imageReference
        ports: {
          web: {
            containerPort: 8080
          }
        }
        readinessProbe: {
          httpGet: {
            path: '/health'
            port: 8080
          }
        }
        volumeMounts: [
          {
            volumeName: 'nginxConfig'
            mountPath: '/etc/nginx/conf.d'
          }
        ]
      }
    }
    connections: {
      orderservice: {
        source: orderServiceContainer.id
        disableDefaultEnvVars: true
      }
      productservice: {
        source: productServiceContainer.id
        disableDefaultEnvVars: true
      }
    }
    volumes: {
      nginxConfig: {
        secretName: storeFrontNginxConfig.name
      }
    }
    codeReference: 'src/store-front/nginx.conf#L1'
  }
}

resource virtualCustomerContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'virtual-customer'
  properties: {
    environment: environment
    application: aksStoreDemoApp.id
    containers: {
      virtualCustomer: {
        image: virtualCustomerImage.properties.imageReference
        env: {
          ORDERS_PER_HOUR: {
            value: '30'
          }
          ORDER_SERVICE_URL: {
            value: 'http://${orderServiceContainer.properties.hosts.order}:3000/'
          }
        }
      }
    }
    connections: {
      orderservice: {
        source: orderServiceContainer.id
        disableDefaultEnvVars: true
      }
    }
    codeReference: 'src/virtual-customer/src/main.rs#L74'
  }
}

resource virtualWorkerContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'virtual-worker'
  properties: {
    environment: environment
    application: aksStoreDemoApp.id
    containers: {
      virtualWorker: {
        image: virtualWorkerImage.properties.imageReference
        env: {
          MAKELINE_SERVICE_URL: {
            value: 'http://${makelineServiceContainer.properties.hosts.makeline}:3001'
          }
          ORDERS_PER_HOUR: {
            value: '20'
          }
        }
      }
    }
    connections: {
      makelineservice: {
        source: makelineServiceContainer.id
        disableDefaultEnvVars: true
      }
    }
    codeReference: 'src/virtual-worker/src/main.rs#L7'
  }
}

resource storeFrontRoute 'Radius.Compute/routes@2025-08-01-preview' = {
  name: 'store-front-route'
  properties: {
    environment: environment
    application: aksStoreDemoApp.id
    rules: [
      {
        matches: [
          {
            httpPath: '/'
          }
        ]
        destinationContainer: {
          resourceId: storeFrontContainer.id
          containerName: 'storefront'
          containerPort: 8080
        }
      }
    ]
    codeReference: 'src/store-front/nginx.conf#L2'
  }
}
