import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../features/auth/data/auth_storage.dart';
import 'app_logo.dart';

class AppSearchBar extends StatefulWidget {
  const AppSearchBar({
    super.key,
    this.onChanged,
    this.onProductPageReturned,
  });

  final ValueChanged<String>? onChanged;
  final Future<void> Function()? onProductPageReturned;

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  Future<void> _openAddProduct() async {
    await context.push('/products/add');

    if (!mounted) return;
    await widget.onProductPageReturned?.call();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        final horizontalPadding = isMobile ? 12.0 : 20.0;

        return Container(
          width: double.infinity,
          color: Colors.green.shade50,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: isMobile ? 12 : 20,
          ),
          child: isMobile
              ? Column(
                  children: [
                    Row(
                      children: [
                        const AppLogo(size: 30),
                        const Spacer(),
                        _buildActions(compact: true),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSearchField(),
                  ],
                )
              : Row(
                  children: [
                    const AppLogo(size: 30),
                    const SizedBox(width: 16),
                    Expanded(child: _buildSearchField()),
                    const SizedBox(width: 8),
                    _buildActions(compact: false),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildSearchField() {
    return TextField(
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: 'Search products...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildActions({required bool compact}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Cart',
          onPressed: () => context.push('/cart'),
          icon: const Icon(Icons.shopping_cart_outlined),
        ),
        IconButton(
          tooltip: 'Orders',
          onPressed: () => context.push('/orders'),
          icon: const Icon(Icons.receipt_long_outlined),
        ),
        IconButton(
          tooltip: 'Add product',
          onPressed: _openAddProduct,
          icon: const Icon(Icons.add_box_outlined),
        ),
        if (!compact)
          FutureBuilder<String?>(
            future: AuthStorage.getCurrentUserName(),
            builder: (context, snapshot) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  snapshot.data ?? 'User (Logged Out)',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
        IconButton(
          tooltip: 'Logout',
          onPressed: () async {
            await AuthStorage.logout();

            if (!mounted) return;
            context.go(AppRouter.login);
          },
          icon: const Icon(Icons.logout),
        ),
      ],
    );
  }
}