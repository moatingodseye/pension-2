class ApiResponse {
  final bool ok;
  final String message;

  ApiResponse({
    required this.ok,
    required this.message,
  });

  // Factory constructor to create ApiResponse from a Map
  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      ok: json['success'] == true,
      message: json['message'] ?? json['error'] ?? 'An unknown error occurred',
    );
  }

  // Optionally, you can create a method to convert ApiResponse to JSON if needed
  Map<String, dynamic> toJson() {
    return {
      'ok': ok,
      'message': message,
    };
  }
}
