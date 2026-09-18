import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/data/auth_storage.dart';
import '../../../auth/data/auth_service.dart';
import '../../../product/data/product_api_service.dart';
import '../../../product/data/product_model.dart';
import '../../../home/presentation/widgets/product_card.dart';
import '../../../../app/router.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<List<Product>> _productsFuture;
  final _productService = ProductApiService();

  @override
  void initState() {
    super.initState();
    _productsFuture = _loadMyProducts();
  }

  Future<List<Product>> _loadMyProducts() async {
    final email = await AuthStorage.getCurrentUserEmail();
    final products = await _productService.getProducts();
    if (email == null) return [];
    return products
        .where(
          (product) => product.sellerEmail.toLowerCase() == email.toLowerCase(),
        )
        .toList();
  }

  Future<void> _refreshProducts() async {
    setState(() {
      _productsFuture = _loadMyProducts();
    });
    await _productsFuture;
  }

  Future<void> _changePassword() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change password'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _passwordField(currentController, 'Current password'),
                const SizedBox(height: 12),
                _passwordField(newController, 'New password'),
                const SizedBox(height: 12),
                _passwordField(
                  confirmController,
                  'Confirm new password',
                  validator: (value) => value != newController.text
                      ? 'Passwords do not match.'
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await AuthService().changePassword(
                  currentPassword: currentController.text,
                  newPassword: newController.text,
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext, true);
              } catch (error) {
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      error.toString().replaceFirst('Exception: ', ''),
                    ),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    currentController.dispose();
    newController.dispose();
    confirmController.dispose();

    if (submitted == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully.')),
      );
    }
  }

  Widget _passwordField(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      validator:
          validator ??
          (value) {
            if (value == null || value.isEmpty) return 'Required.';
            if (label != 'Current password' && value.length < 6) {
              return 'Use at least 6 characters.';
            }
            return null;
          },
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: RefreshIndicator(
        onRefresh: _refreshProducts,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            FutureBuilder<List<String?>>(
              future: Future.wait([
                AuthStorage.getCurrentUserName(),
                AuthStorage.getCurrentUserEmail(),
              ]),
              builder: (context, snapshot) {
                final name = snapshot.data?[0] ?? 'User';
                final email = snapshot.data?[1] ?? '';
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(name),
                    subtitle: Text(email),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _changePassword,
              icon: const Icon(Icons.lock_reset),
              label: const Text('Change password'),
            ),
            const SizedBox(height: 24),
            Text(
              'My Products',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Product>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final products = snapshot.data ?? [];
                if (products.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text('You have no products for sale.'),
                    ),
                  );
                }
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisExtent: 240,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) => ProductCard(
                    product: products[index],
                    onProductUpdated: (_) => _refreshProducts(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () async {
                await AuthStorage.logout();
                if (!context.mounted) return;
                context.go(AppRouter.login);
              },
              icon: const Icon(Icons.logout),
              label: const Text('Log out'),
            ),
          ],
        ),
      ),
    );
  }
}
