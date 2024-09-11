import 'dart:ffi';

class StoreApi{
  int? id;
  String? title;
  double? price;
  String? category;
  String? description;
  String? imageUrl;


  StoreApi({
    this.id,
    this.title,
    this.price,
    this.category,
    this.description,
    this.imageUrl});


  StoreApi.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    price = (json['price'] is int) ? (json['price'] as int).toDouble() : json['price'] as double?;
    category = json['category'];
    description = json['description'];
    imageUrl = json['image'];
  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['price'] = price;
    data['category'] = category;
    data['description'] = description;
    data['image'] = imageUrl;
    return data;
  }

}