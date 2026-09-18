import 'package:flutter/material.dart';

import '../widgets/product_card.dart';
import '../../../product/data/product_model.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({
    super.key,
    required this.displayedProducts,
    this.onProductUpdated,
  });

  final List<Product> displayedProducts;
  final Future<void> Function(Product product)? onProductUpdated;

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late List<Product> _products;

  @override
  void initState() {
    super.initState();

    _products = widget.displayedProducts;
  }

  @override
  void didUpdateWidget(covariant ProductsPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.displayedProducts != widget.displayedProducts) {
      _products = widget.displayedProducts;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Text('No products found in this category.'),
      );
    }

    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _products.length,
        separatorBuilder: (context, index) {
          return const SizedBox(width: 16);
        },
        itemBuilder: (context, index) {
          return ProductCard(
            product: _products[index],
            onProductUpdated: widget.onProductUpdated,
          );
        },
      ),
    );
  }
}
