import os

import azure.functions as func
from azure.servicebus import ServiceBusClient, ServiceBusMessage

app = func.FunctionApp()


@app.mcp_tool()
@app.mcp_tool_property(arg_name="node_id", description="The dynamic ID of the queue or destination node.")
@app.mcp_tool_property(arg_name="region", description="Target zone descriptor.", is_required=False)
@app.mcp_tool_property(arg_name="message_body", description="The payload to send to Service Bus.", is_required=False)
def add_sb_az_mesh_route(node_id: str, region: str = "az", message_body: str = "Hello from MCP") -> str:
    """Adds a service configuration point to the mesh topology and writes to Service Bus."""
    connection_string = os.environ["ServiceBusConnection"]

    print(f"Connecting to Service Bus with connection {connection_string}")
    with ServiceBusClient.from_connection_string(connection_string,  retry_total=7, retry_backoff_factor=0.5) as client:
        with client.get_queue_sender(queue_name=node_id) as sender:
            sender.send_messages(ServiceBusMessage(message_body))

    return f"Node {node_id} attached to {region} hub and message     dispatched."