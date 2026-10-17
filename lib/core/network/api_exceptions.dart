import 'dart:core';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class NetworkException extends ApiException {
  const NetworkException([String message = 'Sin conexión a internet. Revisa tu conectividad.'])
      : super(message, 0);
}

class TimeoutApiException extends ApiException {
  const TimeoutApiException([String message = 'El tiempo de espera de la solicitud ha expirado.'])
      : super(message, 408);
}

class ValidationException extends ApiException {
  final Map<String, List<String>> errors;

  ValidationException(super.message, this.errors, [super.statusCode = 422]);
}

class RateLimitException extends ApiException {
  const RateLimitException([String message = 'Demasiadas solicitudes. Inténtalo más tarde.'])
      : super(message, 429);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([String message = 'Acceso no autorizado.'])
      : super(message, 401);
}

class NotFoundException extends ApiException {
  const NotFoundException([String message = 'Recurso no encontrado.'])
      : super(message, 404);
}

class ServerException extends ApiException {
  const ServerException([String message = 'Error interno en el servidor remoto.'])
      : super(message, 500);
}
