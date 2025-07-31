#!/usr/bin/env node

/**
 * Environment loader for Playwright tests
 * This script loads environment variables from various sources and outputs them as JSON
 * for use in VS Code settings or other configurations
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

function loadDotEnv() {
  const envFile = path.join(__dirname, '.env');
  const env = {};
  
  if (fs.existsSync(envFile)) {
    const content = fs.readFileSync(envFile, 'utf8');
    const lines = content.split('\n');
    
    for (const line of lines) {
      const trimmed = line.trim();
      if (trimmed && !trimmed.startsWith('#')) {
        const [key, ...valueParts] = trimmed.split('=');
        if (key && valueParts.length > 0) {
          env[key.trim()] = valueParts.join('=').trim().replace(/^["']|["']$/g, '');
        }
      }
    }
  }
  
  return env;
}

function loadAzdEnv() {
  const env = {};
  
  try {
    // Check if azd is available
    execSync('which azd', { stdio: 'ignore' });
    
    // Change to project root directory (parent of tests directory)
    const projectRoot = path.join(__dirname, '..');
    
    // Get azd environment variables from project root
    const output = execSync('azd env get-values', { 
      encoding: 'utf8',
      cwd: projectRoot
    });
    const lines = output.split('\n');
    
    for (const line of lines) {
      const trimmed = line.trim();
      if (trimmed && !trimmed.startsWith('#')) {
        const [key, ...valueParts] = trimmed.split('=');
        if (key && valueParts.length > 0) {
          env[key.trim()] = valueParts.join('=').trim().replace(/^["']|["']$/g, '');
        }
      }
    }
  } catch (error) {
    console.error('Warning: Could not load azd environment variables:', error.message);
  }
  
  return env;
}

function mergeEnvironments() {
  // Load .env file first (lower priority)
  const dotEnv = loadDotEnv();
  
  // Load azd environment (higher priority)
  const azdEnv = loadAzdEnv();
  
  // Merge environments (azd overrides .env)
  const merged = { ...dotEnv, ...azdEnv };
  
  return merged;
}

function main() {
  const args = process.argv.slice(2);
  const format = args[0] || 'json';
  
  const env = mergeEnvironments();
  
  switch (format) {
    case 'json':
      console.log(JSON.stringify(env, null, 2));
      break;
    case 'export':
      for (const [key, value] of Object.entries(env)) {
        console.log(`export ${key}="${value}"`);
      }
      break;
    case 'dotenv':
      for (const [key, value] of Object.entries(env)) {
        console.log(`${key}="${value}"`);
      }
      break;
    default:
      console.error('Usage: node load-env.js [json|export|dotenv]');
      process.exit(1);
  }
}

if (require.main === module) {
  main();
}

module.exports = { loadDotEnv, loadAzdEnv, mergeEnvironments };
