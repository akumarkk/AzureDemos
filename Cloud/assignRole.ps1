PrincipalId=$(az identity show \
  --name "test-identity" \
  --resource-group  \
  --query "principalId" \
  --output tsv)

# 2. Add role assignment for Topic 1
az role assignment create \
  --assignee "$PrincipalId" \
  --role "Azure Service Bus Data Owner" \
  --scope "/subscriptions/YourSubscriptionId/resourceGroups/YourResourceGroup/providers/Microsoft.ServiceBus/namespaces/asb-test-enterpriseevents/topics/as.sb.events"

# 3. Add role assignment for Topic 2
az role assignment create \
  --assignee "$PrincipalId" \
  --role "Azure Service Bus Data Owner" \
  --scope "/subscriptions/YourSubscriptionId/resourceGroups/YourResourceGroup/providers/Microsoft.ServiceBus/namespaces/asb-wcu-test-enterpriseevents/topics/as.sbevents"