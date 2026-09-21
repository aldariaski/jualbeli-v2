import 'package:flutter/material.dart';

import '../../../auth/data/auth_storage.dart';
import '../../../product/data/price_formatter.dart';
import '../../../payment/data/payment_service.dart';
import '../../data/order_model.dart';
import '../../data/order_service.dart';
import 'order_detail_page.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late Future<List<Order>> _future;
  int? _payingOrderId;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Order>> _load() async {
    final email = await AuthStorage.getCurrentUserEmail();

    if (email == null || email.isEmpty) {
      throw Exception('User email not found.');
    }

    return OrderService.instance.getOrders(email);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });

    await _future;
  }

  Future<void> _pay(Order order) async {
    setState(() => _payingOrderId = order.id);
    try {
      await PaymentService.instance.payOrder(order.id, order.totalAmount);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order #${order.id} is paid.')),
      );
      await _refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _payingOrderId = null);
    }
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '-';
    }

    final date = value.toLocal();

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
      ),
      body: FutureBuilder<List<Order>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Unable to load orders.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                children: const [
                  SizedBox(height: 220),
                  Center(
                    child: Text(
                      'You have no orders yet.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      'Order #${order.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${_formatDate(order.createdAt)}\n'
                        'Status: ${order.status}',
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatPrice(order.totalAmount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (order.status.toLowerCase() == 'pending')
                          SizedBox(
                            height: 32,
                            child: FilledButton(
                              onPressed: _payingOrderId == order.id ? null : () => _pay(order),
                              child: _payingOrderId == order.id
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Text('Pay'),
                            ),
                          )
                        else
                          const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailPage(
                            order: order,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}