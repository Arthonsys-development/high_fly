class ApiResult<T> {
  final T? data;
  final ErrorResponse? error;

  ApiResult.success(this.data) : error = null;
  ApiResult.failure(this.error) : data = null;

  bool get isSuccess => data != null;
}

class ApiError {
  final String field;
  final List<String> message;

  ApiError({
    required this.field,
    required this.message,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      field: json['field'] ?? '',
      message: List<String>.from(json['message'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'field': field,
      'message': message,
    };
  }
}

class ErrorResponse {
  final List<ApiError> errors;

  ErrorResponse({required this.errors});

  factory ErrorResponse.fromJson(Map<String, dynamic> json) {
    return ErrorResponse(
      errors: (json['errors'] as List<dynamic>?)
          ?.map((e) => ApiError.fromJson(e))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'errors': errors.map((e) => e.toJson()).toList(),
    };
  }
}