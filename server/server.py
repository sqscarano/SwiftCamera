import logging
import json
import asyncio
import websockets

clients = set()

async def send_to_others(websocket, message):
  for client in clients:
    if client != websocket:
      await client.send(message)

async def process_message(websocket, message):
  request = json.loads(message)
  
  if "image" in request:
    print("[websocket] image")
    await send_to_others(websocket, message)

  if "text" in request:
    print("[websocket] text")
    await send_to_others(websocket, message)

async def server(websocket, path):
  try:
    clients.add(websocket)
    print("[websocket] new_client")

    async for message in websocket:
        await process_message(websocket, message)

  except (asyncio.exceptions.IncompleteReadError, websockets.exceptions.ConnectionClosed):
    print("[websocket] connection_closed")
    pass

  finally:
    print("[websocket] end_client")
    clients.remove(websocket)


async def main():
    async with websockets.serve(server, "0.0.0.0", 8383):
        print("OK")
        await asyncio.Future()  # run forever

asyncio.run(main())
