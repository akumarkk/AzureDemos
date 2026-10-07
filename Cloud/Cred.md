DefaultAzureCredential executes a pre-defined sequence from top to bottom until it gets a valid token:

- Environment Variables (EnvironmentCredential - Service Principal details if set)

- Workload Identity (WorkloadIdentityCredential - AKS / Kubernetes)

- Managed Identity (ManagedIdentityCredential - Azure App Service, VM, Container Apps, etc.)

- Azure Developer CLI (AzureDeveloperCliCredential)

- Visual Studio (VisualStudioCredential)

- Visual Studio Code (VisualStudioCodeCredential)

- Azure CLI (AzureCliCredential)

- Azure PowerShell (AzurePowerShellCredential)

###### EnvironmentCredential
The Environment Variables EnvironmentCredential Looks For
EnvironmentCredential checks for one of three authentication configurations using exact variable names:

1. Service Principal with Client Secret (Most Common for Local Dev/CI)
AZURE_TENANT_ID
AZURE_CLIENT_ID
AZURE_CLIENT_SECRET

2. Service Principal with Certificate
AZURE_TENANT_ID
AZURE_CLIENT_ID
AZURE_CLIENT_CERTIFICATE_PATH (or AZURE_CLIENT_CERTIFICATE_SNI)

3. Username + Password
AZURE_TENANT_ID
AZURE_CLIENT_ID
AZURE_USERNAME
AZURE_PASSWORD