FROM node:18-bullseye

# 1. Install Basic Tools (remove 'golang' from here)
RUN apt-get update && \
    apt-get install -y nmap build-essential python3 wget && \
    rm -rf /var/lib/apt/lists/*

# 2. Install Go 1.23.4 MANUALLY (Fixes the version error)
RUN wget https://go.dev/dl/go1.23.4.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.23.4.linux-amd64.tar.gz && \
    rm go1.23.4.linux-amd64.tar.gz

# Add Go to PATH
ENV PATH=$PATH:/usr/local/go/bin

WORKDIR /app

# 3. Copy files
COPY . .

# 4. Install NPM dependencies (Fixing permissions)
RUN rm -f package-lock.json
RUN npm install --legacy-peer-deps --no-audit --ignore-scripts

# 5. Start Daemon and follow logs
CMD ["sh", "-c", "npm run start && sleep 5 && tail -f /app/logs/reconya.log"]
