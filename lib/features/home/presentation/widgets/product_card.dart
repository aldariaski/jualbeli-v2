import 'package:flutter/material.dart';

import '../../../product/data/product_model.dart';
import '../../../product/data/price_formatter.dart';
import '../../../product/presentation/pages/product_detail_page.dart';

class ProductCard extends StatefulWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onProductUpdated,
  });

  final Product product;
  final VoidCallback? onTap;
  final Future<void> Function(Product product)? onProductUpdated;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          widget.onTap ??
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailPage(
                  product: widget.product,
                  onProductUpdated: widget.onProductUpdated,
                ),
              ),
            );
          },
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child:
                    widget.product.image != null &&
                        widget.product.image!.isNotEmpty
                    ? Image.network(
                        widget.product.image!,
                        width: double.infinity,
                        height: 150,
                        fit: BoxFit.cover,
                      )
                    : const SizedBox(
                        width: double.infinity,
                        height: 150,
                        child: Icon(Icons.image, size: 60),
                      ),
              ),

              const SizedBox(height: 12),

              Text(
                widget.product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                formatPrice(widget.product.price),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
