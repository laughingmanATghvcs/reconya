# We use a base image that is easy to install tools on
FROM node:18-bullseye

# 1. Install Go and Nmap (Required by Reconya)
RUN apt-get update && \
    apt-get install -y golang nmap && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 2. Copy all your code files
COPY . .

# 3. Install dependencies (This runs 'npm install' as per README)
RUN npm install

# 4. The app runs on port 3000
EXPOSE 3000

# 5. Start command (From README)
CMD ["npm", "run", "start"]
