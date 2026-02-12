import 'package:flutter_test/flutter_test.dart';
import 'package:client/services/apiResponse.dart';
import 'package:client/services/apiException.dart';

void main() {
  group('ApiResponse', () {
    test('fromJson creates success response', () {
      final json = {
        'success': true,
        'message': 'Operation completed',
      };
      final response = ApiResponse.fromJson(json);
      expect(response.ok, true);
      expect(response.message, 'Operation completed');
    });

    test('fromJson creates failure response', () {
      final json = {
        'success': false,
        'message': 'Error occurred',
      };
      final response = ApiResponse.fromJson(json);
      expect(response.ok, false);
      expect(response.message, 'Error occurred');
    });

    test('handles missing message with error field', () {
      final json = {
        'success': false,
        'error': 'Some error',
      };
      final response = ApiResponse.fromJson(json);
      expect(response.ok, false);
      expect(response.message, 'Some error');
    });

    test('handles missing message with default', () {
      final json = {
        'success': true,
      };
      final response = ApiResponse.fromJson(json);
      expect(response.ok, true);
      expect(response.message, 'An unknown error occurred');
    });

    test('toJson serializes correctly', () {
      final response = ApiResponse(ok: true, message: 'Success');
      final json = response.toJson();
      expect(json['ok'], true);
      expect(json['message'], 'Success');
    });
  });

  group('apiException', () {
    test('creates exception with body', () {
      final exception = apiException('Test error message');
      expect(exception.body, 'Test error message');
    });

    test('is an Exception', () {
      final exception = apiException('Error');
      expect(exception, isA<Exception>());
    });
  });
}
