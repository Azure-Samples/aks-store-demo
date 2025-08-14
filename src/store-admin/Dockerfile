# Use an official Node.js runtime as a parent image
FROM node:22.14-alpine AS builder

WORKDIR /app

# Copy package.json and package-lock.json to the container
COPY package*.json ./

# Install app dependencies
RUN npm install

# Copy the rest of the app source code to the container
COPY . .

# Build the app
RUN npm run build 

# Run the app on nginx
FROM nginx:stable-alpine-slim AS runner

# Copy the build output to replace the default nginx contents
COPY --from=builder /app/dist /usr/share/nginx/html

# Expose the port the app listens on
EXPOSE 8081

# Set the build argument for the app version number
ARG APP_VERSION=0.1.0

# Set the environment variables
ENV APP_VERSION=$APP_VERSION
ENV COMPANY_NAME=Contoso
ENV PRODUCT_SERVICE_URL=http://product-service:3002/
ENV MAKELINE_SERVICE_URL=http://makeline-service:3001/

# Copy the nginx configuration template to the container
COPY nginx.conf /etc/nginx/conf.d/nginx.conf.template

# Create a startup script to substitute environment variables in both nginx config and HTML
RUN echo '#!/bin/sh' > /docker-entrypoint.d/30-substitute-env.sh && \
    echo 'envsubst '"'"'${APP_VERSION} ${COMPANY_NAME} ${PRODUCT_SERVICE_URL} ${MAKELINE_SERVICE_URL}'"'"' < /etc/nginx/conf.d/nginx.conf.template > /etc/nginx/conf.d/default.conf' >> /docker-entrypoint.d/30-substitute-env.sh && \
    echo '# Update the page title based on company name' >> /docker-entrypoint.d/30-substitute-env.sh && \
    echo 'if [ "$COMPANY_NAME" = "Zava" ]; then' >> /docker-entrypoint.d/30-substitute-env.sh && \
    echo '  sed -i "s/<title>Pet Store Admin Portal<\/title>/<title>Zava Pet Store Admin Portal<\/title>/g" /usr/share/nginx/html/index.html' >> /docker-entrypoint.d/30-substitute-env.sh && \
    echo 'elif [ "$COMPANY_NAME" = "Contoso" ]; then' >> /docker-entrypoint.d/30-substitute-env.sh && \
    echo '  sed -i "s/<title>Pet Store Admin Portal<\/title>/<title>Contoso Pet Store Admin Portal<\/title>/g" /usr/share/nginx/html/index.html' >> /docker-entrypoint.d/30-substitute-env.sh && \
    echo 'fi' >> /docker-entrypoint.d/30-substitute-env.sh && \
    chmod +x /docker-entrypoint.d/30-substitute-env.sh

# Start the app
CMD ["nginx", "-g", "daemon off;"]