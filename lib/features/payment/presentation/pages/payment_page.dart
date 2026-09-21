import 'package:flutter/material.dart';

import '../../../auth/data/auth_storage.dart';
import '../../../orders/data/order_model.dart';
import '../../../orders/data/order_service.dart';
import '../../../product/data/price_formatter.dart';
import '../../data/payment_service.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _service = PaymentService.instance;
  double _balance = 0;
  List<Order> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final currentEmail = await AuthStorage.getCurrentUserEmail();
      if (currentEmail == null || currentEmail.trim().isEmpty) {
        throw Exception('User email not found.');
      }

      final balance = await _service.getBalance();
      final orders = await OrderService.instance.getOrders('');
      final normalizedEmail = currentEmail.trim().toLowerCase();
      if (!mounted) return;
      setState(() {
        _balance = balance;
        _orders = orders.where((order) {
          return order.status.toLowerCase() == 'pending' &&
              order.email.trim().toLowerCase() == normalizedEmail;
        }).toList();
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _topUp() async {
    final amount = await showDialog<double>(
      context: context,
      builder: (_) => const _TopUpDialog(),
    );
    if (amount == null) return;

    try {
      final balance = await _service.topUp(amount);
      if (!mounted) return;
      setState(() => _balance = balance);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wallet topped up.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _pay(Order order) async {
    try {
      await _service.payOrder(order.id, order.totalAmount);
      if (!mounted) return;
      await _load();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order #${order.id} is paid.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(children: const [SizedBox(height: 280), Center(child: CircularProgressIndicator())])
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Wallet balance', style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(formatPrice(_balance), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _topUp, icon: const Icon(Icons.add), label: const Text('Top up'))),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Orders awaiting payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_error != null) Text(_error!),
                  if (_error == null && _orders.isEmpty) const Padding(padding: EdgeInsets.only(top: 24), child: Text('No orders need payment.')),
                  ..._orders.map((order) => Card(
                        child: ListTile(
                          title: Text('Order #${order.id}'),
                          subtitle: Text('Payment pending'),
                          trailing: FilledButton(onPressed: () => _pay(order), child: Text(formatPrice(order.totalAmount))),
                        ),
                      )),
                ],
              ),
      ),
    );
  }
}

class _TopUpDialog extends StatefulWidget {
  const _TopUpDialog();

  @override
  State<_TopUpDialog> createState() => _TopUpDialogState();
}

class _TopUpDialogState extends State<_TopUpDialog> {
  String _value = '';

  void _add(String digit) {
    if (_value.length >= 9) return;
    setState(() => _value += digit);
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_value) ?? 0;
    return AlertDialog(
      title: const Text('Top up wallet'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(formatPrice(amount), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        for (final row in const [['1', '2', '3'], ['4', '5', '6'], ['7', '8', '9'], ['C', '0', 'back']])
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: row.map((key) => IconButton(
                onPressed: () {
                  if (key == 'C') return setState(() => _value = '');
                  if (key == 'back') return setState(() { if (_value.isNotEmpty) _value = _value.substring(0, _value.length - 1); });
                  _add(key);
                },
                icon: key == 'back'
                  ? const Icon(Icons.backspace_outlined)
                  : key == 'C'
                    ? const Icon(Icons.clear)
                    : Text(key, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                tooltip: key == 'back' ? 'Delete' : key,
              )).toList()),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: amount > 0 ? () => Navigator.pop(context, amount) : null, child: const Text('Add funds')),
      ],
    );
  }
}
