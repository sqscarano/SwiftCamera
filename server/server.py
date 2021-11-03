import logging
from websocket_server import WebsocketServer
import json

servers = []

def new_client(client, server):
	server.send_message_to_all("Hey all, a new client has joined us")

def delete_client(client, server):
  servers.remove(client)

def message_received(client, server, message):
  request = json.loads(message)
  
  if "role" in request:
    role = request["role"]
    print("new " + role)
    if role == "server":
      servers.append(role)

  if "image" in request:
    print("image received")
    for c in servers:
      print("  image sent")
      server.send_message(c, message)

server = WebsocketServer(host='0.0.0.0', port=8383, loglevel=logging.INFO)
server.set_fn_new_client(new_client)
server.set_fn_client_left(delete_client)
server.set_fn_message_received(message_received)
server.run_forever()

