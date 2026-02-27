class AppError implements Exception {
  final String message;
  final int? statusCode;

  const AppError(this.message, {this.statusCode});

  @override
  String toString() => message;
}
