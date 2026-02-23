import 'dart:convert';

enum Request { get, post, put, patch, delete, awsUpload }
enum UserRoles { production,dispatch,both }
enum InwardState { idle, running, paused }
enum LabelFormat { Small, Medium, Large,ExtraLarge }
enum TareState{ on , off , barcode}
enum LabelState{ Label, Receipt}
enum DeviceState {
  on,        // "IN_LIMIT" or "0"
  off,     // "OUT_OF_LIMIT" or "1"
}
enum WeightStatus {
  inRange,     // 0
  outOfRange,  // 1
}
String buildPayload(WeightStatus status) {
  return jsonEncode({
    "status": status == WeightStatus.inRange ? "0" : "1"
  });
}