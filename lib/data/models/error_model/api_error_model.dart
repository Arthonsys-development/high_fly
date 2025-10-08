// class ApiErrorResponse {
//   final List<ApiError> errors;
//
//   ApiErrorResponse({required this.errors});
//
//   factory ApiErrorResponse.fromJson(Map<String, dynamic> json) {
//     return ApiErrorResponse(
//       errors: (json['errors'] as List<dynamic>)
//           .map((e) => ApiError.fromJson(e as Map<String, dynamic>))
//           .toList(),
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'errors': errors.map((e) => e.toJson()).toList(),
//     };
//   }
// }
//
// class ApiError {
//   final String field;
//   final List<String> message;
//
//   ApiError({required this.field, required this.message});
//
//   factory ApiError.fromJson(Map<String, dynamic> json) {
//     return ApiError(
//       field: json['field'] as String,
//       message: List<String>.from(json['message']),
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'field': field,
//       'message': message,
//     };
//   }
// }
