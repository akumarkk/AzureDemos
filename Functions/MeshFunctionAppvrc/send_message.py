"""Send a test message to a Service Bus queue.

Usage:
    python send_message.py [queue_name] [message_body]

The connection string comes from the ServiceBusConnection environment variable,
falling back to Values.ServiceBusConnection in local.settings.json.
"""
import json
import os
import sys
from pathlib import Path

from azure.servicebus import ServiceBusClient, ServiceBusMessage


def get_connection_string() -> str:
    value = os.environ.get("ServiceBusConnection")
    if value:
        return value
    settings = Path(__file__).with_name("local.settings.json")
    return json.loads(settings.read_text(encoding="utf-8"))["Values"]["ServiceBusConnection"]


def main() -> None:
    queue_name = sys.argv[1] if len(sys.argv) > 1 else "queue-1"
    body = sys.argv[2] if len(sys.argv) > 2 else "test msg"

    with ServiceBusClient.from_connection_string(get_connection_string()) as client:
        with client.get_queue_sender(queue_name=queue_name) as sender:
            sender.send_messages(ServiceBusMessage(body))

    print(f"Sent '{body}' to queue '{queue_name}'")


if __name__ == "__main__":
    main()
