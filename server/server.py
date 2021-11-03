import logging
from websocket_server import WebsocketServer
import json

browsers = []

def new_client(client, server):
	print("new_client")

def send_message(server, client, message):
  server.send_message(client, message)
  print(message)

def delete_client(client, server):
  print("delete_client")
  if client in browsers:
    browsers.remove(client)

def message_received(client, server, message):
  print(message)
  # request = json.loads(message)
  
  # if "role" in request:
  #   role = request["role"]
  #   response = "OK " + role
  #   send_message(server, client, response)
    
  #   if role == "browser":
  #     browsers.append(role)

  # if "image" in request:
  #   print("image received")
  #   for c in server.clients:
  #     if c != client:
  #       server.send_message(c, message)
  #       print("  image sent")

server = WebsocketServer(host='0.0.0.0', port=8383, loglevel=logging.INFO)
server.set_fn_new_client(new_client)
server.set_fn_client_left(delete_client)
server.set_fn_message_received(message_received)
server.run_forever()

