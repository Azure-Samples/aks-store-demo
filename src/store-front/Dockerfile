# Use an official Node.js runtime as a parent image
FROM node:18.16.0-alpine as builder
WORKDIR /app

# Copy package.json and package-lock.json to the container
COPY package*.json ./

# Install app dependencies
RUN npm install

# Copy the rest of the app source code to the container
COPY . .

# Expose the port the app listens on
EXPOSE 80

# Start the app
CMD [ "npm", "run", "serve" ]

# # Build the app
# RUN npm run build --mode production

# # Run the app on nginx
# FROM nginx:stable-alpine as runner
# WORKDIR /app

# # Copy the build output to replace the default nginx contents
# COPY --from=builder /app/dist /app

# # Copy the nginx configuration
# COPY nginx.conf /etc/nginx/nginx.conf