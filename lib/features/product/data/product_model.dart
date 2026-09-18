class Product {
  final int id;
  final String name;
  final double price;
  final String? image;
  final String category;
  final String sellerName;
  final String sellerEmail;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.image,
    required this.category,
    required this.sellerName,
    required this.sellerEmail,
  });

  bool matchesSearch(String query) {
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) return true;

    return name.toLowerCase().contains(normalizedQuery) ||
        category.toLowerCase().contains(normalizedQuery) ||
        sellerName.toLowerCase().contains(normalizedQuery);
  }
  

  static const shopCategories = [
    'All',
    'Electronics',
    'Fashion',
    'Shoes',
    'Beauty',
    'Health',
    'Home & Living',
    'Furniture',
    'Sports',
    'Toys',
    'Books',
    'Food & Beverages',
    'Automotive',
    'Accessories',
    'Pet Supplies',
    'Baby & Kids',
    'Groceries',
    'Office & Stationery',
    'Tools & Hardware',
    'Other',
  ];

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      image: json['image'] as String?,
      category: json['category'] as String,
      sellerName: json['sellerName'] as String,
      sellerEmail: json['sellerEmail'] as String,
    );
  }
}