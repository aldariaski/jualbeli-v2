import 'package:flutter/material.dart';

import '../../../payment/presentation/pages/payment_page.dart';

class OrderSuccessPage extends StatelessWidget {
  const OrderSuccessPage({
    super.key,
    required this.orderId,
  });

  final int orderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Order Complete',
        ),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 90,
              ),

              const SizedBox(
                height: 24,
              ),

              const Text(
                'Order placed successfully!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              Text(
                'Order #$orderId',
                style: const TextStyle(
                  fontSize: 18,
                ),
              ),

              const SizedBox(
                height: 32,
              ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const PaymentPage()),
                    );
                  },
                  child: const Text(
                    'Pay Now',
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