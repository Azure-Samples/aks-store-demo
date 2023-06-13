# Use an official Node.js runtime as a parent image
FROM node:18

# Copy package.json and package-lock.json to the container
COPY package*.json ./

# Install app dependencies
RUN npm install

# Copy the rest of the app source code to the container
COPY . .

# Build the app
RUN npm run build

# Expose the port the app listens on
EXPOSE 8081

# Start the app
CMD [ "npm", "run", "serve" ]