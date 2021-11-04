const ws = new WebSocket('ws://localhost:8383');

ws.addEventListener('message', function (event) {
  console.log('[websocket] message received');
  const request = JSON.parse(event.data)
  const imgBase64 = request.image
  const scale = request.scale
  const src = 'data:image/png;base64,' + imgBase64;

  const width = 400.0 * scale;
  var image = new Image(width);
  image.src = src;
  image.id = 'asdf';

  let frameDocument = document.getElementById("sqs-site-frame").contentWindow.document;
  let parent = frameDocument.getElementsByClassName("sqs-row")[0].getElementsByClassName("sqs-col")[0];  
  parent.appendChild(image);  

  console.log('[websocket] image created');
})

