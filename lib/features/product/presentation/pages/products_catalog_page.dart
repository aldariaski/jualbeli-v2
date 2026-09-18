import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/categories.dart';
import '../../../home/presentation/widgets/product_card.dart';
import '../../data/product_api_service.dart';
import '../../data/product_model.dart';

class ProductsCatalogPage extends StatefulWidget {
  const ProductsCatalogPage({super.key, this.onProductUpdated});

  final Future<void> Function(Product product)? onProductUpdated;

  @override
  State<ProductsCatalogPage> createState() => _ProductsCatalogPageState();
}

class _ProductsCatalogPageState extends State<ProductsCatalogPage> {
  final _service = ProductApiService();
  late Future<List<Product>> _productsFuture;
  String _category = 'All';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _productsFuture = _service.getProducts();
  }

  Future<void> _refresh() async {
    setState(() {
      _productsFuture = _service.getProducts();
    });
    await _productsFuture;
  }

  List<Product> _filter(List<Product> products) {
    return products.where((product) {
      final categoryMatches =
          _category == 'All' || product.category == _category;
      return categoryMatches && product.matchesSearch(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Products')),
      body: SafeArea(
        child: FutureBuilder<List<Product>>(
          future: _productsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: ElevatedButton(
                  onPressed: _refresh,
                  child: const Text('Retry loading products'),
                ),
              );
            }

            final products = _filter(snapshot.data ?? []);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: TextField(
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Categories(
                    selectedCategory: _category,
                    onCategorySelected: (value) =>
                        setState(() => _category = value),
                  ),
                ),
                Expanded(
                  child: products.isEmpty
                      ? const Center(child: Text('No products found.'))
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 220,
                                mainAxisExtent: 240,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          itemCount: products.length,
                          itemBuilder: (context, index) => ProductCard(
                            product: products[index],
                            onProductUpdated: (product) async {
                              await _refresh();
                              await widget.onProductUpdated?.call(product);
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
