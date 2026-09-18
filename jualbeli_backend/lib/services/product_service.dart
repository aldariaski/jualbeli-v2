import '../models/product.dart';
import '../repositories/product_repository.dart';

class ProductService {
  final ProductRepository _productRepository;

  ProductService({ProductRepository? productRepository})
    : _productRepository = productRepository ?? ProductRepository();

  Future<List<Product>> getProducts() {
    return _productRepository.getAll();
  }

  Future<Product> getProduct(int id) async {
    final product = await _productRepository.findById(id);

    if (product == null) {
      throw Exception('Product not found.');
    }

    return product;
  }

  Future<Product> updateProduct({
    required int id,
    required String ownerEmail,
    required String name,
    required double price,
    String? image,
    required String category,
  }) async {
    final product = await _productRepository.updateProduct(
      id: id,
      ownerEmail: ownerEmail,
      name: name,
      price: price,
      image: image,
      category: category,
    );

    if (product == null) {
      throw Exception('Product not found or you are not the owner.');
    }

    return product;
  }

  Future<Product> createProduct({
    required String name,
    required double price,
    String? image,
    required String category,
    required String sellerEmail,
    required String sellerName,
  }) {
    return _productRepository.createProduct(
      name: name,
      price: price,
      image: image,
      category: category,
      sellerEmail: sellerEmail,
      sellerName: sellerName,
    );
  }
}
