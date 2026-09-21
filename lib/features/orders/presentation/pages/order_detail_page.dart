import 'package:flutter/material.dart';

import '../../../auth/data/auth_storage.dart';
import '../../../product/data/price_formatter.dart';
import '../../../payment/data/payment_service.dart';
import '../../data/order_model.dart';
import '../../data/order_service.dart';

class OrderDetailPage extends StatefulWidget {
  final Order order;

  const OrderDetailPage({
    super.key,
    required this.order,
  });

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late Future<Map<String, dynamic>> _future;
  bool _paying = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final email = await AuthStorage.getCurrentUserEmail();

    if (email == null || email.isEmpty) {
      throw Exception('User email not found.');
    }

    return OrderService.instance.getOrder(
      email,
      widget.order.id,
    );
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

  Future<void> _pay(double amount) async {
    setState(() => _paying = true);
    try {
      await PaymentService.instance.payOrder(widget.order.id, amount);
      if (!mounted) return;
      setState(() => _future = _load());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order #${widget.order.id} is paid.')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.order.id}'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
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
                      'Unable to load order.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _future = _load();
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data;

          if (data == null) {
            return const Center(
              child: Text('Order not found.'),
            );
          }

          final itemsData = data['items'];

          final items = itemsData is List
              ? itemsData
                  .map(
                    (item) => OrderItem.fromJson(
                      Map<String, dynamic>.from(item),
                    ),
                  )
                  .toList()
              : <OrderItem>[];

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _future = _load();
              });

              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildOrderHeader(),
                const SizedBox(height: 20),

                const Text(
                  'Items',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                if (items.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No items found for this order.'),
                    ),
                  )
                else
                  ...items.map(_buildItem),

                const SizedBox(height: 20),

                _buildTotal(data),
                if ((data['status']?.toString() ?? widget.order.status).toLowerCase() == 'pending')
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _paying ? null : () => _pay(_totalFrom(data)),
                        icon: _paying
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.payment),
                        label: const Text('Pay order'),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order #${widget.order.id}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(widget.order.createdAt),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Status: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(widget.order.status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(OrderItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(item),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Quantity: ${item.quantity}',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Price: ${formatPrice(item.price)}',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Subtotal: ${formatPrice(item.subtotal)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
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

  Widget _buildImage(OrderItem item) {
    if (item.image == null || item.image!.trim().isEmpty) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.image_not_supported,
          color: Colors.grey,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        item.image!,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 80,
            height: 80,
            color: Colors.grey.shade200,
            child: const Icon(
              Icons.broken_image,
              color: Colors.grey,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTotal(Map<String, dynamic> data) {
    final total = _totalFrom(data);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              formatPrice(total),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _totalFrom(Map<String, dynamic> data) {
    return data['totalAmount'] is num
        ? (data['totalAmount'] as num).toDouble()
        : double.tryParse(
              data['totalAmount']?.toString() ?? '',
            ) ??
            widget.order.totalAmount;

  }
}