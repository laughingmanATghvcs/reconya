# Use Node 18 on Debian Bullseye (Good compatibility)
FROM node:18-bullseye

# 1. Install System Dependencies
# We add 'build-essential' and 'python3' because many Node modules need them to compile.
RUN apt-get update && \
    apt-get install -y golang nmap build-essential python3 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 2. Copy files
COPY . .

# 3. Install Dependencies with FORCE flags
# --legacy-peer-deps: Ignores version conflicts
# --unsafe-perm: Prevents permission errors as root
RUN npm install --legacy-peer-deps --unsafe-perm

# 4. Build the Go backend (if required manually)
# If the project has a go.mod, we ensure dependencies are ready
RUN if [ -f go.mod ]; then go mod download; fi

# 5. Expose the port
EXPOSE 3000

# 6. Start
CMD ["npm", "run", "start"]
