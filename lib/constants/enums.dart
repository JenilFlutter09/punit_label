import 'dart:convert';

enum Request { get, post, put, patch, delete, awsUpload }
enum UserRoles { production,dispatch,both }
enum InwardState { idle, running, paused }
// enum LabelFormat { Small, Medium, Large,ExtraLarge }
//enum LabelFormat { Small, Medium, Large, ExtraLarge, WholesalePack }
//enum LabelFormat { Small, Medium, Large, ExtraLarge, WholesalePack ,neoLabel, SmallSeven}
//enum LabelFormat { Small, Medium, Large, ExtraLarge, WholesalePack , SmallSeven}
//enum LabelFormat { Small, Medium, Large, ExtraLarge, WholesalePack ,MajedarTea}
//enum LabelFormat { Small,Medium, Large, ExtraLarge, WholesalePack ,MajedarTea, SmallSeven}
enum LabelFormat { Small,Medium, Large, ExtraLarge, WholesalePack ,MajedarTea, SmallSeven, DryFruit}
//enum LabelFormat { Small, Medium, Large,ExtraLarge ,MajedarTea}
enum TareState{ on , off , barcode}
enum LabelState{ Label, Receipt}

enum WeightStatus {
  inRange,     // 0
  outOfRange,  // 1
}
