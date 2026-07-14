class CategoryModel {
  int? id;
  String? name;
  String? imageFullUrl;
  String? slug;

  /// Subcategories, as returned inline by `/categories`. Carrying them here means a
  /// subcategory id on an item can be resolved to a name without a second request —
  /// see `CategoryController.subCategoryNameOf`.
  List<CategoryModel>? childes;

  CategoryModel({this.id, this.name, this.imageFullUrl, this.slug, this.childes});

  CategoryModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    imageFullUrl = json['image_full_url'];
    slug = json['slug'];
    if (json['childes'] != null) {
      childes = [];
      json['childes'].forEach((v) => childes!.add(CategoryModel.fromJson(v)));
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['image_full_url'] = imageFullUrl;
    data['slug'] = slug;
    if (childes != null) {
      data['childes'] = childes!.map((CategoryModel v) => v.toJson()).toList();
    }
    return data;
  }
}
