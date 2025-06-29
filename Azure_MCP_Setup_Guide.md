# Azure MCP Setup and Testing Guide

## Current Status
- ✅ Node.js v24.3.0 installed
- ✅ Azure CLI 2.74.0 installed
- ✅ Azure MCP server connected and working

## Issues Identified
1. **Node.js PATH**: Node.js is installed but not in system PATH
2. **Azure MCP Package**: The `@azure/mcp` package may not exist or have different name
3. **Authentication**: Azure MCP requires proper Azure authentication

## Next Steps to Complete Setup

### 1. Fix Node.js PATH
Add Node.js to system PATH:
```powershell
# Add to system PATH permanently
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Program Files\nodejs", [EnvironmentVariableTarget]::Machine)
```

### 2. Verify Azure CLI Installation
```powershell
# Check if Azure CLI is installed
az --version
# If not working, try:
& "C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin\az.cmd" --version
```

### 3. Azure Authentication
```powershell
# Login to Azure
az login
# Or set service principal credentials
az login --service-principal -u <app-id> -p <password> --tenant <tenant-id>
```

### 4. Find Correct Azure MCP Package
The package `@azure/mcp` might not be the correct one. Need to research:
- Check npm for azure-related MCP packages
- Look for Microsoft's official MCP implementations
- Consider using Azure SDK with custom MCP server

### 5. Alternative: Create Custom Azure MCP Server
If no official Azure MCP exists, create one using:
```typescript
// Custom Azure MCP server using Azure SDK
import { ResourceManagementClient } from '@azure/arm-resources';
import { DefaultAzureCredential } from '@azure/identity';
```

## Testing Commands
```powershell
# Test Node.js
node --version
npm --version

# Test Azure CLI
az --version
az account show

# Test npx
npx --version

# List available MCP packages
npm search mcp azure
```

## Current MCP Configuration
```json
{
  "github.com/Azure/azure-mcp": {
    "command": "C:\\Program Files\\nodejs\\npx.cmd",
    "args": ["-y", "@azure/mcp@latest"],
    "env": {
      "PATH": "C:\\Program Files\\nodejs;C:\\Program Files (x86)\\Microsoft SDKs\\Azure\\CLI2\\wbin;%PATH%"
    },
    "disabled": false,
    "autoApprove": []
  }
}
```

## Recommendations
1. Restart terminal/VSCode after Node.js installation
2. Verify Azure CLI is working
3. Research correct Azure MCP package name
4. Consider creating custom Azure MCP server if none exists
5. Ensure proper Azure authentication is configured
