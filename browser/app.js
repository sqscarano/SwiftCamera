const ws = new WebSocket('ws://localhost:8383');

ws.addEventListener('message', function (event) {
  console.log('message from server: ', event.data); }

