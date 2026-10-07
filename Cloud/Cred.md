DefaultAzureCredential executes a pre-defined sequence from top to bottom until it gets a valid token:

- Environment Variables (EnvironmentCredential - Service Principal details if set)

- Workload Identity (WorkloadIdentityCredential - AKS / Kubernetes)

- Managed Identity (ManagedIdentityCredential - Azure App Service, VM, Container Apps, etc.)

- Azure Developer CLI (AzureDeveloperCliCredential)

- Visual Studio (VisualStudioCredential)

- Visual Studio Code (VisualStudioCodeCredential)

- Azure CLI (AzureCliCredential)

- Azure PowerShell (AzurePowerShellCredential)