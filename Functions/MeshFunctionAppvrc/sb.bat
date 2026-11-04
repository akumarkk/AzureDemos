@echo off
:: Usage: setup_sb.bat <ResourceGroup> [Location]

IF "%1"=="" (
    echo [ERROR] Resource Group name is required.
    echo Usage: setup_sb.bat MyResourceGroup [location]
    EXIT /b 1
)

SET ResourceGroup=%1
SET Location=%2
IF "%Location%"=="" SET Location=eastus

SET NamespaceName=sb-mesh-%RANDOM%
SET QueueName=queue-1

echo ====================================================
echo Provisioning Azure Service Bus Resources
echo Resource Group: %ResourceGroup%
echo Location:       %Location%
echo Namespace:      %NamespaceName%
echo ====================================================

echo [1/4] Creating Resource Group...
call az group create --name %ResourceGroup% --location %Location%

echo [2/4] Creating Service Bus Namespace (Standard Tier)...
call az servicebus namespace create --resource-group %ResourceGroup% --name %NamespaceName% --location %Location% --sku Standard

echo [3/4] Creating Queue (%QueueName%)...
call az servicebus queue create --resource-group %ResourceGroup% --namespace-name %NamespaceName% --name %QueueName%

echo [4/4] Retrieving Primary Connection String:
echo ----------------------------------------------------
call az servicebus namespace authorization-rule keys list --resource-group %ResourceGroup% --namespace-name %NamespaceName% --name RootManageSharedAccessKey --query primaryConnectionString --output tsv

echo ====================================================
echo Done! Copy the connection string above into your config.
pause
