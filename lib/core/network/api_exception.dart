/// Extends FormatException so existing form error presenters can display it.
class ApiException extends FormatException {
  final int? statusCode;

  const ApiException(super.message, {this.statusCode});

  bool get isUnauthorized => statusCode == 401;
}
