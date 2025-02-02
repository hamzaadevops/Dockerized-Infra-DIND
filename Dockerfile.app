# Use the official Node.js 16 image as a parent image
FROM node:16

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json (or yarn.lock) into the container
COPY package*.json ./

# Install dependencies in the container
RUN npm install

# Copy the rest of your application's code into the container
COPY . .

# Install Docker CLI
RUN apt update && apt install -y docker.io

# Your application listens on port 3000 (modify if different)
EXPOSE 3000

# Command to run your app using Node.js
CMD ["npm", "run", "start"]

