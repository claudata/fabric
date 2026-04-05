# Microsoft Fabric Automation Toolkit

A collection of scripts, tools, and examples for automating Microsoft Fabric operations using PowerShell, Python, and REST APIs.

## 🎯 Overview

This repository provides ready-to-use automation scripts for Microsoft Fabric, including:
- Managing managed private endpoints
- Workspace operations
- Lakehouse management
- Data pipeline automation
- Notebook deployment

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Scripts](#scripts)
  - [PowerShell Scripts](#powershell-scripts)
- [Usage Examples](#usage-examples)
- [Authentication](#authentication)
- [Contributing](#contributing)
- [License](#license)

## 🔧 Prerequisites

### Required Software
- PowerShell 7.0 or later (recommended)
- Azure PowerShell Module (`Az.Accounts`)
- Valid Microsoft Fabric workspace access

### Azure Modules
```powershell
# Install required Azure modules
Install-Module -Name Az.Accounts -Scope CurrentUser -Force
```

### Permissions
- Fabric Administrator or Workspace Admin role
- Azure AD authentication enabled
- Appropriate RBAC permissions for Fabric API access

## 📦 Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/claudata/fabric.git
   cd fabric
   ```

2. **Authenticate with Azure:**
   ```powershell
   Connect-AzAccount
   ```

3. **Verify access to Fabric:**
   ```powershell
   Get-AzAccessToken -ResourceUrl "https://api.fabric.microsoft.com"
   ```

## 📜 Scripts

### PowerShell Scripts

#### Get-FabricManagedPrivateEndpoints.ps1
Lists all managed private endpoints in a specified Fabric workspace.

**Location:** `scripts/powershell/Get-FabricManagedPrivateEndpoints.ps1`

**Parameters:**
- `WorkspaceId` (required) - The GUID of your Fabric workspace
- `OutputFormat` (optional) - Display format: 'Table' (default) or 'List'

**Example:**
```powershell
.\scripts\powershell\Get-FabricManagedPrivateEndpoints.ps1 -WorkspaceId "12345678-1234-1234-1234-123456789012"
```

## 💡 Usage Examples

### Finding Your Workspace ID
You can find your workspace ID in the Fabric portal URL:
```
https://app.fabric.microsoft.com/groups/{workspace-id}/...
```

### List Managed Private Endpoints
```powershell
# Connect to Azure
Connect-AzAccount

# Run the script
.\scripts\powershell\Get-FabricManagedPrivateEndpoints.ps1 `
    -WorkspaceId "your-workspace-id" `
    -OutputFormat Table `
    -Verbose
```

### Using in Automation Pipelines
```powershell
# Store workspace ID as environment variable
$env:FABRIC_WORKSPACE_ID = "12345678-1234-1234-1234-123456789012"

# Run script and capture output
$endpoints = .\scripts\powershell\Get-FabricManagedPrivateEndpoints.ps1 `
    -WorkspaceId $env:FABRIC_WORKSPACE_ID

# Process results
$endpoints | Where-Object { $_.provisioningState -eq "Succeeded" }
```

## 🔐 Authentication

### Using Service Principal (CI/CD)
```powershell
$clientId = "your-client-id"
$clientSecret = "your-client-secret" | ConvertTo-SecureString -AsPlainText -Force
$tenantId = "your-tenant-id"

$credential = New-Object System.Management.Automation.PSCredential($clientId, $clientSecret)
Connect-AzAccount -ServicePrincipal -Credential $credential -Tenant $tenantId
```

### Using Managed Identity (Azure Automation)
```powershell
Connect-AzAccount -Identity
```

## 🗂️ Repository Structure

```
fabric/
├── scripts/
│   └── powershell/          # PowerShell automation scripts
│       └── Get-FabricManagedPrivateEndpoints.ps1
├── examples/                # Usage examples and templates
├── docs/                    # Additional documentation
├── .gitignore              # Git ignore file
├── LICENSE                 # MIT License
└── README.md               # This file
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Coding Standards
- Follow PowerShell best practices and style guidelines
- Include comment-based help for all scripts
- Add error handling and input validation
- Write descriptive commit messages

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Useful Links

- [Microsoft Fabric Documentation](https://learn.microsoft.com/fabric/)
- [Fabric REST API Reference](https://learn.microsoft.com/rest/api/fabric/)
- [PowerShell Documentation](https://learn.microsoft.com/powershell/)
- [Azure PowerShell Documentation](https://learn.microsoft.com/powershell/azure/)

## 📧 Support

For issues, questions, or contributions:
- Open an [issue](https://github.com/claudata/fabric/issues)
- Submit a [pull request](https://github.com/claudata/fabric/pulls)

## 🎓 Additional Resources

### Fabric API Examples
- [Authentication with Fabric APIs](https://learn.microsoft.com/fabric/admin/metadata-scanning-overview)
- [Managing Workspaces](https://learn.microsoft.com/fabric/admin/admin-overview)

---

**Note:** This repository is not officially affiliated with Microsoft. It's a community-driven project to help automate Fabric operations.
