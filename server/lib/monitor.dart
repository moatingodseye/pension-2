import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'debuglogger.dart';

final monitor1 = createMiddleware(
  requestHandler: (Request request) {
    log.info('Public Request:${request.method}');
    return null; // Continue to next handler
  },
  responseHandler: (Response response) {
    // Run after response is generated
    log.info('Public Response:${response.statusCode}');
    return response.change(headers: {'X-Custom': 'value'});
  },
);   

final monitor2 = createMiddleware(
  requestHandler: (Request request) {
    log.info('Protected Request:${request.method}');
    return null; // Continue to next handler
  },
  responseHandler: (Response response) {
    // Run after response is generated
    log.info('Protected Response:${response.statusCode}');
    if (response.isEmpty) return response;

    final bodyStream = response.read().transform(utf8.decoder).join();
    final futureBody = bodyStream.then((body) {
      log.info('Protected:${body}');
      return body;
    });

    return response.change(
      body:Stream.fromFuture(futureBody).transform(utf8.encoder),
    );
  },
);   