FROM node:18-bullseye

# 1. Install System Tools
RUN apt-get update && \
    apt-get install -y golang nmap build-essential python3 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 2. Copy files
COPY . .

# 3. CRITICAL FIXES:
# Delete the lock file (it causes mismatches)
RUN rm -f package-lock.json

# Install dependencies but IGNORE scripts (prevents crashing on missing folders)
RUN npm install --legacy-peer-deps --no-audit --ignore-scripts

# 4. Expose Port
EXPOSE 3000

# Start the daemon, wait 5 seconds for logs to appear, then follow the logs forever (keeping container alive)
CMD ["sh", "-c", "npm run start && sleep 5 && tail -f /app/logs/reconya.log"]
