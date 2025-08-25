#!/usr/bin/env node
/**
 * Generate MCP configuration from template based on environment variables
 */

const fs = require('fs');
const path = require('path');

// Load environment variables from .env file (industry standard approach)
const ENV_FILE_PATH = '/workspace/.devcontainer/.env';
try {
  require('dotenv').config({ path: ENV_FILE_PATH, override: true });
  console.log(`[MCP Config Generator] Loaded environment from ${ENV_FILE_PATH}`);
} catch (error) {
  console.log(`[MCP Config Generator] dotenv not available, using process.env: ${error.message}`);
}

const CONFIG_DIR = '/workspace/.devcontainer/config/claude';
const TEMPLATE_PATH = path.join(CONFIG_DIR, 'mcp.json.template');
const OUTPUT_PATH = path.join(CONFIG_DIR, 'mcp.json');
const BACKUP_PATH = path.join(CONFIG_DIR, 'mcp.json.backup');

function log(message) {
  console.log(`[MCP Config Generator] ${message}`);
}

function parseBoolean(value, defaultValue = false) {
  if (!value) return defaultValue;
  const lowerValue = value.toLowerCase().trim();
  return lowerValue === 'true' || lowerValue === '1' || lowerValue === 'yes';
}

function expandEnvironmentVariables(text, env) {
  return text.replace(/\$\{([^}:-]+)(:-([^}]*))?\}/g, (match, varName, _, defaultValue) => {
    const envValue = env[varName];
    if (envValue !== undefined) {
      return envValue;
    }
    return defaultValue || '';
  });
}

function hasRequiredApiKeys(requires, env) {
  if (!requires || requires.length === 0) return true;
  
  return requires.every(key => {
    const value = env[key];
    return value && value.trim() !== '';
  });
}

function validateMcpConfiguration(config) {
  try {
    // Validate top-level structure
    if (!config || typeof config !== 'object') {
      log('Validation Error: Configuration must be an object');
      return false;
    }
    
    if (!config.mcpServers || typeof config.mcpServers !== 'object') {
      log('Validation Error: Configuration must have mcpServers object');
      return false;
    }
    
    // Validate each server configuration
    for (const [serverName, serverConfig] of Object.entries(config.mcpServers)) {
      if (!validateServerConfig(serverName, serverConfig)) {
        return false;
      }
    }
    
    log('MCP configuration validation passed');
    return true;
  } catch (error) {
    log(`Validation Error: ${error.message}`);
    return false;
  }
}

function validateServerConfig(serverName, config) {
  // Check for required fields based on server type
  if (config.command) {
    // Command-based server
    if (!Array.isArray(config.args)) {
      log(`Validation Error: Server ${serverName} with command must have args array`);
      return false;
    }
  } else if (config.type === 'http') {
    // HTTP-based server
    if (!config.url || typeof config.url !== 'string') {
      log(`Validation Error: HTTP server ${serverName} must have valid url`);
      return false;
    }
    
    // Validate URL format
    try {
      new URL(config.url);
    } catch (urlError) {
      log(`Validation Error: Server ${serverName} has invalid URL: ${config.url}`);
      return false;
    }
  } else {
    log(`Validation Error: Server ${serverName} must have either 'command' or 'type' field`);
    return false;
  }
  
  return true;
}

function generateMcpConfig() {
  try {
    // Check if template exists
    if (!fs.existsSync(TEMPLATE_PATH)) {
      log(`Template file not found: ${TEMPLATE_PATH}`);
      return false;
    }

    // Read template
    const templateContent = fs.readFileSync(TEMPLATE_PATH, 'utf8');
    let templateData;
    
    try {
      // First expand environment variables in the template
      const expandedTemplate = expandEnvironmentVariables(templateContent, process.env);
      templateData = JSON.parse(expandedTemplate);
    } catch (error) {
      log(`Failed to parse template: ${error.message}`);
      return false;
    }

    // Create backup of existing config if it exists
    if (fs.existsSync(OUTPUT_PATH)) {
      fs.copyFileSync(OUTPUT_PATH, BACKUP_PATH);
      log(`Created backup: ${BACKUP_PATH}`);
    }

    // Generate output configuration
    const outputConfig = {
      mcpServers: {}
    };

    let enabledCount = 0;
    let disabledCount = 0;

    // Process each server
    for (const [serverName, serverData] of Object.entries(templateData.servers)) {
      const enabled = parseBoolean(serverData.enabled, false);
      const hasApiKeys = hasRequiredApiKeys(serverData.requires, process.env);
      
      if (enabled && hasApiKeys) {
        // Server is enabled and has required API keys
        // Flatten the config structure - remove the nested "config" wrapper
        outputConfig.mcpServers[serverName] = serverData.config;
        enabledCount++;
        log(`✓ Enabled: ${serverName}`);
      } else {
        // Server is disabled or missing API keys
        disabledCount++;
        if (!enabled) {
          log(`✗ Disabled: ${serverName} (ENABLE_${serverName.toUpperCase().replace(/-/g, '_')}_MCP=false)`);
        } else {
          log(`✗ Disabled: ${serverName} (missing required API keys: ${serverData.requires?.join(', ')})`);
        }
      }
    }

    // Keep environment variables as references, don't expand them
    const finalConfigText = JSON.stringify(outputConfig, null, 2);
    
    // Write output
    fs.writeFileSync(OUTPUT_PATH, finalConfigText);
    
    // Basic validation - ensure output is valid JSON
    try {
      JSON.parse(finalConfigText);
    } catch (parseError) {
      log(`Error: Generated configuration is not valid JSON: ${parseError.message}`);
      return false;
    }
    
    // Advanced validation - validate MCP configuration structure
    if (!validateMcpConfiguration(outputConfig)) {
      log(`Error: Generated MCP configuration failed validation`);
      return false;
    }
    
    log(`Configuration generated successfully!`);
    log(`Servers enabled: ${enabledCount}, disabled: ${disabledCount}`);
    log(`Output: ${OUTPUT_PATH}`);
    
    return true;
    
  } catch (error) {
    log(`Error generating configuration: ${error.message}`);
    return false;
  }
}

// Main execution
if (require.main === module) {
  const success = generateMcpConfig();
  process.exit(success ? 0 : 1);
}

module.exports = { generateMcpConfig };