import azure.functions as func
import logging
from pydantic import BaseModel, Field
from mcp_mesh import mesh
from azure.servicebus import ServiceBusClient, ServiceBusMessage
import os

app = func.FunctionApp()

class MeshRouteParams(BaseModel):
    node_id: str = Field(description="The dynamic ID of the queue or destination node.")
    region: str = Field(default="az", description="Target zone descriptor.")
    message_body: str = Field(description="The payload to send to Service Bus.")

@mesh.tool(capability="add_sb_az_mesh_route")
def add_mesh_route(params: MeshRouteParams) -> str:
    """Adds a service configuration point to the mesh topology and writes to Service Bus."""
    connection_string = os.environ["ServiceBusConnection"]
    queue_name = params.node_id
    
    # Send message to Azure Service Bus
    with ServiceBusClient.from_connection_string(connection_string) as client:
        with client.get_queue_sender(queue_name=queue_name) as sender:
            message = ServiceBusMessage(params.message_body)
            sender.send_messages(message)
            
    return f"Node {params.node_id} attached to {params.region} hub and message dispatched."

@app.route(route="mesh_trigger", auth_level=func.AuthLevel.FUNCTION)
def mesh_trigger(req: func.HttpRequest) -> func.HttpResponse:
    logging.info("Python HTTP trigger processed a request.")
    
    try:
        req_body = req.get_json()
        params = MeshRouteParams(**req_body)
        result = add_mesh_route(params)
        return func.HttpResponse(result, status_code=200)
    except Exception as e:
        return func.HttpResponse(f"Error: {str(e)}", status_code=400)