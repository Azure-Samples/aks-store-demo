# Use an official Node.js runtime as a parent image
FROM node:18.16.0-alpine as builder

# Set the working directory to /app
WORKDIR /app

# Copy package.json and package-lock.json to the container
COPY package*.json ./

# Install app dependencies
RUN npm install --production

# Copy the rest of the app source code to the container
COPY . .

# Expose the port the app listens on
EXPOSE 3000

# Start the app
CMD [ "npm", "start" ]