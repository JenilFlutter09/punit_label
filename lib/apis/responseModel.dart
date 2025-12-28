class ResponseModel {
  ResponseModel({required this.data, required this.hasError, this.errorCode});
  final String data;
  final bool hasError;
  final int? errorCode;

  @override
  String toString() =>
      'ResponseModel(data: $data, hasError: $hasError, errorCode: $errorCode)';
}
class NewResponseModel {
  NewResponseModel({required this.data, required this.hasError, required this.statusCode});
  final String data;
  final bool hasError;
  final int statusCode;

  @override
  String toString() =>
      'NewResponseModel(data: $data, hasError: $hasError, errorCode: $statusCode)';
}
