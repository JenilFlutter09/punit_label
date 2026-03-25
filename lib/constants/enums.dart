import 'dart:convert';

enum Request { get, post, put, patch, delete, awsUpload }
enum UserRoles { production,dispatch,both }
enum InwardState { idle, running, paused }
// enum LabelFormat { Small, Medium, Large,ExtraLarge }
enum LabelFormat { Small, Medium, Large, ExtraLarge, WholesalePack, Dryfruit }
enum TareState{ on , off , barcode}
enum LabelState{ Label, Receipt}

enum WeightStatus {
  inRange,     // 0
  outOfRange,  // 1
}
