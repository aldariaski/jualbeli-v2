import 'package:flutter/material.dart';

import '../../../auth/data/auth_storage.dart';
import '../../data/product_api_service.dart';
import '../../data/product_model.dart';

class PostProductPage extends StatefulWidget {
  const PostProductPage({super.key, this.product});

  final Product? product;

  @override
  State<PostProductPage> createState() => _PostProductPageState();
}

class _PostProductPageState extends State<PostProductPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageController = TextEditingController();

  String _category = Product.shopCategories
      .where((category) => category != 'All')
      .first;

  bool _posting = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();

    final product = widget.product;
    if (product != null) {
      _nameController.text = product.name;
      _priceController.text = product.price.toString();
      _imageController.text = product.image ?? '';
      if (Product.shopCategories.contains(product.category) &&
          product.category != 'All') {
        _category = product.category;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _postProduct() async {
    if (_posting) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = await AuthStorage.getCurrentUserEmail();
    final sellerName = await AuthStorage.getCurrentUserName();

    if (email == null || email.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User email not found.')));

      return;
    }

    if (sellerName == null || sellerName.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User name not found.')));

      return;
    }

    setState(() {
      _posting = true;
    });

    try {
      final api = ProductApiService();
      final image = _imageController.text.trim().isEmpty
          ? null
          : _imageController.text.trim();

      final Product savedProduct;

      if (_isEditing) {
        savedProduct = await api.updateProduct(
          id: widget.product!.id,
          name: _nameController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          image: image,
          category: _category,
        );
      } else {
        savedProduct = await api.createProduct(
          name: _nameController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          image: image,
          category: _category,
          sellerEmail: email,
          sellerName: sellerName.toString(),
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Product updated successfully.'
                : 'Product added successfully.',
          ),
        ),
      );

      Navigator.pop(context, savedProduct);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to ${_isEditing ? 'update' : 'add'} product: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _posting = false;
        });
      }
    }
  }

  InputDecoration _decoration({
    required String label,
    String? hint,
    Widget? prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefix,
      suffixIcon: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildImagePreview() {
    final imageUrl = _imageController.text.trim();

    if (imageUrl.isEmpty) {
      return Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              'Product image preview',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        height: 180,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                const Text('Unable to load image'),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Product' : 'Add Product')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              _buildImagePreview(),

              const SizedBox(height: 24),

              Text(
                'Product Information',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: _decoration(
                  label: 'Product name',
                  hint: 'Enter product name',
                  prefix: const Icon(Icons.inventory_2_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a product name.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                decoration: _decoration(
                  label: 'Price',
                  hint: '5900000',
                  prefix: const Icon(Icons.payments_outlined),
                ),
                validator: (value) {
                  final price = double.tryParse(value?.trim() ?? '');

                  if (price == null || price <= 0) {
                    return 'Please enter a valid price.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: _decoration(
                  label: 'Category',
                  prefix: const Icon(Icons.category_outlined),
                ),
                items: Product.shopCategories
                    .where((category) => category != 'All')
                    .map(
                      (category) => DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: _posting
                    ? null
                    : (value) {
                        if (value == null) return;

                        setState(() {
                          _category = value;
                        });
                      },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _imageController,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                onChanged: (_) {
                  setState(() {});
                },
                decoration: _decoration(
                  label: 'Image URL',
                  hint: 'https://example.com/product.jpg',
                  prefix: const Icon(Icons.link_outlined),
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _posting ? null : _postProduct,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _posting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _isEditing ? 'Save Changes' : 'Add Product',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
