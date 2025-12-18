#!/usr/bin/env node

const { program } = require('commander');
const Utils = require('./utils');

class ServiceStopper {
  async stop() {
    console.log('==========================================');
    console.log('         Stopping reconYa Backend        ');
    console.log('==========================================\n');

    try {
      let stoppedAny = false;

      // Check for daemon PID file first
      const daemonStopped = await this.stopDaemon();
      if (daemonStopped) stoppedAny = true;

      // Stop backend (port 3008)
      const backendStopped = await Utils.killProcessByPort(3008, 'backend');
      if (backendStopped) stoppedAny = true;

      // Also try to kill any Go processes that might be reconYa
      await this.killreconYaProcesses();

      // Final verification - check if port 3008 is still occupied
      const finalCheck = await Utils.findProcessByPort(3008);
      if (finalCheck) {
        Utils.log.error(`Warning: Port 3008 is still occupied by process ${finalCheck.pid}`);
        Utils.log.info('You may need to manually kill this process:');
        Utils.log.info(`sudo kill -9 ${finalCheck.pid}`);
        stoppedAny = true; // Still count as action taken
      }

      if (stoppedAny) {
        Utils.log.success('reconYa backend stopped');
      } else {
        Utils.log.info('No reconYa backend was running');
      }

    } catch (error) {
      Utils.log.error('Failed to stop backend: ' + error.message);
      process.exit(1);
    }
  }

  async stopDaemon() {
    const fs = require('fs');
    const path = require('path');
    const pidFile = path.join(process.cwd(), '.reconya.pid');
    
    if (fs.existsSync(pidFile)) {
      try {
        const pid = parseInt(fs.readFileSync(pidFile, 'utf8').trim());
        
        if (pid && !isNaN(pid)) {
          // Check if process exists
          try {
            process.kill(pid, 0); // Check if process exists
            process.kill(pid, 'SIGTERM'); // Kill the process
            Utils.log.info(`Stopped daemon process ${pid}`);
            
            // Remove PID file
            fs.unlinkSync(pidFile);
            return true;
          } catch (error) {
            if (error.code === 'ESRCH') {
              Utils.log.warning('Daemon PID file exists but process not found');
              fs.unlinkSync(pidFile);
            } else {
              throw error;
            }
          }
        }
      } catch (error) {
        Utils.log.warning('Failed to stop daemon: ' + error.message);
        // Clean up PID file anyway
        try {
          fs.unlinkSync(pidFile);
        } catch {}
      }
    }
    
    return false;
  }

  async killreconYaProcesses() {
    try {
      // Kill any processes that might be reconYa backend
      if (Utils.isWindows()) {
        // Windows: Find and kill Go processes running reconYa
        const { stdout } = await Utils.runCommandWithOutput('wmic', ['process', 'where', "CommandLine like '%reconya%' and Name='go.exe'", 'get', 'ProcessId,CommandLine']);
        const lines = stdout.split('\n');
        for (const line of lines) {
          if (line.includes('go.exe') && line.includes('reconya')) {
            const parts = line.trim().split(/\s+/);
            const pid = parts[parts.length - 1];
            if (pid && !isNaN(pid)) {
              await Utils.killProcess(parseInt(pid), true);
              Utils.log.info(`Killed Go process ${pid}`);
            }
          }
        }
      } else {
        // Unix-like: More specific process killing (avoid killing browsers and other apps)
        const killCommands = [
          // Kill 'go run' processes with reconya
          ['pkill', ['-f', 'go run .*reconya']],
          ['pkill', ['-f', 'go run.*main.go.*reconya']],
          ['pkill', ['-f', 'go run.*cmd/main.go']],
          // Kill compiled binaries
          ['pkill', ['-f', 'backend/cmd/reconya']],
          ['pkill', ['-f', '/reconya/backend']],
          ['pkill', ['-f', 'reconya.*main']],
          // Kill any process with reconya in the command line that's using port 3008
          ['pkill', ['-f', 'reconya.*3008']],
          // Kill processes by name patterns (only reconya, not generic 'main')
          ['killall', ['-q', 'reconya']]
        ];

        for (const [cmd, args] of killCommands) {
          try {
            await Utils.runCommand(cmd, args, { silent: true });
          } catch {
            // Ignore errors - process might not exist
          }
        }

        // Additional check: find any remaining processes on port 3008
        try {
          const proc = await Utils.findProcessByPort(3008);
          if (proc) {
            Utils.log.warning(`Found remaining process on port 3008: ${proc.pid}`);
            await Utils.killProcess(proc.pid, true);
            Utils.log.info(`Force killed process ${proc.pid}`);
          }
        } catch {
          // Ignore errors
        }
      }
    } catch (error) {
      // Ignore errors in this cleanup phase
      Utils.log.warning(`Error during process cleanup: ${error.message}`);
    }
  }
}

// Main execution
if (require.main === module) {
  program
    .name('reconya-stop')
    .description('Stop reconYa services')
    .version('1.0.0');

  program.parse();

  const stopper = new ServiceStopper();
  stopper.stop().catch(error => {
    Utils.log.error('Failed to stop services: ' + error.message);
    process.exit(1);
  });
}

module.exports = ServiceStopper;