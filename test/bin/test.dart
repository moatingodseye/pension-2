import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

// import 'dart:io';
// import 'package:shelf/shelf.dart';
// import 'package:shelf/shelf_io.dart' as io;
// import 'package:shelf_router/shelf_router.dart';

// Create router
final router = Router()
  ..get('/', (Request req) => Response.ok('Hello World'))
  ..post('/test', (Request req) => Response.ok('Test route'))
  ..post('/data', (Request req) async {
    var body = await req.readAsString();
    return Response.ok('Received: $body');
  });

// CORS middleware
Middleware corsMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response(200, headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type',
        });
      }
      
      var response = await innerHandler(request);
      return response.change(headers: {
        'Access-Control-Allow-Origin': '*',
      });
    };
  };
}

void main() async {
  var handler = const Pipeline()
    .addMiddleware(logRequests())
    .addMiddleware(corsMiddleware())
    .addHandler(router);

  var server = await io.serve(handler, InternetAddress.anyIPv4, 8080);
  print('Server running on http://${server.address}:${server.port}');
}   

// Response _echoRequest(Request request) => Response.ok('Request for "${request.url}"');

// void main() async {
//   var handler =
//       const Pipeline().addMiddleware(logRequests()).addHandler(_echoRequest);

//   var server = await io.serve(handler, InternetAddress.anyIPv4, 8080);

//   // Enable content compression
//   server.autoCompress = true;

//   print('Serving at http://${server.address.host}:${server.port}');

//   final app = Router();

//   app.get('/hello', (Request request) {
//     return Response.ok('hello-world');
//   });

//   app.get('/user/<user>', (Request request, String user) {
//     return Response.ok('hello $user');
//   });

//   final server2 = await io.serve(app.call, InternetAddress.anyIPv4, 8081);
//   print('Server listening on port ${server2.port}');
// }
