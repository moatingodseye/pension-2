import 'package:shelf/shelf.dart';

Middleware apiKeyMiddleware(String validApiKey) {
  return (Handler handler) {
    return (Request request) async {
      final header = request.headers['Authorization'];

      if (header == null || !header.startsWith('Bearer ')) {
        return Response.forbidden('Invalid API key');
      }

      // Remove the 'Bearer ' prefix
      final apiKey = header.substring('Bearer '.length);

      if (apiKey != validApiKey) {
        return Response.forbidden('Invalid API key');
      }

      // If the API key is valid, continue with the request
      return await handler(request);
    };
  };
}
