enum ApiErrorType {
  none,
  connection,   // Sunucuya ulaşılamıyor / Network timeout / Wi-Fi kapalı
  unauthorized, // 401 Oturum Doldu / 403 Erişim Yetkisi Yok
  server,       // 5xx Sunucu Hatası
  badRequest,   // 400 Geçersiz İstek / Hatalı Bilgi
  unknown,      // Bilinmeyen Hata
}

class ApiResponse<T> {
  final bool isSuccess;
  final T? data;
  final String errorMessage;
  final ApiErrorType errorType;
  final int? statusCode;

  const ApiResponse({
    required this.isSuccess,
    this.data,
    this.errorMessage = '',
    this.errorType = ApiErrorType.none,
    this.statusCode,
  });

  factory ApiResponse.success(T data) {
    return ApiResponse(isSuccess: true, data: data);
  }

  factory ApiResponse.error(String message, ApiErrorType type, {int? statusCode}) {
    return ApiResponse(
      isSuccess: false,
      errorMessage: message,
      errorType: type,
      statusCode: statusCode,
    );
  }
}
