import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_search_bar.dart';

import '../../../product/data/product_api_service.dart';
import '../../../product/data/product_model.dart';

import '../widgets/categories.dart';
import '../widgets/products_page.dart';
import '../widgets/section_title.dart';

import '../../../../app/router.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomeActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HomeActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 23,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomePageState extends State<HomePage> {
  final ProductApiService _productApiService = ProductApiService();

  String selectedCategory = 'All';
  String searchQuery = '';

  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();

    _productsFuture = _productApiService.getProducts();
  }

  List<Product> filterProducts(List<Product> products) {
    return products
        .where(
          (product) =>
              (selectedCategory == 'All' ||
                  product.category == selectedCategory) &&
              product.matchesSearch(searchQuery),
        )
        .toList();
  }

  void _searchProducts(String query) {
    setState(() {
      searchQuery = query;
    });
  }

  Future<void> _refreshProducts() async {
    setState(() {
      _productsFuture = _productApiService.getProducts();
    });

    await _productsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            AppSearchBar(
              onChanged: _searchProducts,
              onProductPageReturned: _refreshProducts,
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  const Text(
                    'Welcome!',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  const Text('Find the best products for you.'),

                  const SizedBox(height: 32),

                  const SectionTitle(title: 'Categories'),

                  const SizedBox(height: 12),

                  Categories(
                    selectedCategory: selectedCategory,
                    onCategorySelected: (category) {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                  ),

                  const SizedBox(height: 32),

                  SectionTitle(
                    title: selectedCategory == 'All'
                        ? 'Featured Products'
                        : selectedCategory,
                  ),

                  const SizedBox(height: 12),

                  FutureBuilder<List<Product>>(
                    future: _productsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 240,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (snapshot.hasError) {
                        return SizedBox(
                          height: 240,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Unable to load products.'),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _refreshProducts,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final products = snapshot.data ?? [];

                      final displayedProducts = filterProducts(products);

                      return ProductsPage(displayedProducts: displayedProducts);
                    },
                  ),

                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.shade100),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _HomeActionButton(
                            icon: Icons.shopping_cart_outlined,
                            label: 'Cart',
                            onTap: () {
                              context.push('/cart');
                            },
                          ),
                        ),
                        Expanded(
                          child: _HomeActionButton(
                            icon: Icons.receipt_long_outlined,
                            label: 'Orders',
                            onTap: () {
                              context.push('/orders');
                            },
                          ),
                        ),
                        Expanded(
                          child: _HomeActionButton(
                            icon: Icons.add_box_outlined,
                            label: 'Add Product',
                            onTap: () async {
                              final result = await context.push(
                                '/products/add',
                              );

                              if (result == true) {
                                await _refreshProducts();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
