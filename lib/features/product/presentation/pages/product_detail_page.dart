import 'package:flutter/material.dart';

import '../../data/product_model.dart';
import '../../data/price_formatter.dart';
import '../../../cart/data/cart_service.dart';
import '../../../auth/data/auth_storage.dart';
import 'post_product_page.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  final Future<void> Function(Product product)? onProductUpdated;

  const ProductDetailPage({
    super.key,
    required this.product,
    this.onProductUpdated,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late Product product;

  @override
  void initState() {
    super.initState();
    product = widget.product;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          FutureBuilder<String?>(
            future: AuthStorage.getCurrentUserEmail(),
            builder: (context, snapshot) {
              if (snapshot.data?.toLowerCase() !=
                  product.sellerEmail.toLowerCase()) {
                return const SizedBox.shrink();
              }

              return IconButton(
                tooltip: 'Edit product',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  final updatedProduct = await Navigator.push<Product>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PostProductPage(product: product),
                    ),
                  );

                  if (updatedProduct != null && mounted) {
                    setState(() {
                      product = updatedProduct;
                    });
                    await widget.onProductUpdated?.call(updatedProduct);
                  }
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: product.image != null && product.image!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        product.image!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.image_not_supported,
                            size: 80,
                          );
                        },
                      ),
                    )
                  : const Icon(Icons.image, size: 80),
            ),

            const SizedBox(height: 24),

            // Category
            Text(
              product.category,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),

            const SizedBox(height: 8),

            // Name
            Text(
              product.name,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            // Price
            Text(
              formatPrice(product.price),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 32),

            const Text(
              'Seller',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.sellerName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Add to cart
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    final email = await AuthStorage.getCurrentUserEmail();

                    if (email == null || email.isEmpty) {
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please login before adding to cart.'),
                        ),
                      );

                      return;
                    }

                    if (email.trim().toLowerCase() ==
                        product.sellerEmail.trim().toLowerCase()) {
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('You cannot buy your own product.'),
                        ),
                      );
                      return;
                    }

                    await CartService.instance.addProduct(email, product);

                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Product added to cart.')),
                    );
                  } catch (e) {
                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add product: $e')),
                    );
                  }
                },
                child: const Text(
                  'Add to Cart',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
