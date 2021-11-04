const ws = new WebSocket('ws://localhost:8383');

function handle_image(request) {
  const imgBase64 = request.image
  const scale = request.scale
  const src = 'data:image/png;base64,' + imgBase64;

  const width = 600.0 * scale;
  var image = new Image(width);
  image.src = src;
  image.id = 'asdf';

  let frameDocument = document.getElementById("sqs-site-frame").contentWindow.document;
  let parent = frameDocument.getElementsByClassName("sqs-row")[1].getElementsByClassName("sqs-col")[0];  
  parent.appendChild(image);  

  console.log('[websocket] image created');
}

function handle_text(request) {
  const textNode = document.createTextNode(request.text);

  let frameDocument = document.getElementById("sqs-site-frame").contentWindow.document;
  let parent = frameDocument.getElementsByClassName("sqs-row")[1].getElementsByClassName("sqs-col")[0];  
  parent.appendChild(textNode);  

  console.log('[websocket] text created');
}

ws.addEventListener('message', function (event) {
  console.log('[websocket] message received');
  const request = JSON.parse(event.data)

  if (request.image) { handle_image(request) }
  if (request.text) { handle_text(request) }
})

