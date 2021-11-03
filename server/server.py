import logging
from websocket_server import WebsocketServer
import json

servers = []
apps = []

def new_client(client, server):
	server.send_message_to_all("Hey all, a new client has joined us")

def message_received(client, server, message):
  request = json.loads(message)
  role = (request["role"])
  server.send_message(client, "OK " + role)

server = WebsocketServer(host='0.0.0.0', port=8383, loglevel=logging.INFO)
server.set_fn_new_client(new_client)
server.set_fn_message_received(message_received)
server.run_forever()

