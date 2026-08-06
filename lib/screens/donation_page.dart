import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../services/donation_service.dart';

class DonationPage extends StatefulWidget {
  final DonationService donationService;

  DonationPage({super.key, DonationService? donationService})
    : donationService = donationService ?? DonationService();

  @override
  State<DonationPage> createState() => _DonationPageState();
}

class _DonationPageState extends State<DonationPage> {
  late final StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;
  var _isLoading = true;
  var _isPurchasing = false;
  var _storeAvailable = false;
  List<ProductDetails> _products = const [];
  String? _message;

  @override
  void initState() {
    super.initState();
    _purchaseSubscription = widget.donationService.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isPurchasing = false;
          _message = 'The purchase update could not be processed.';
        });
      },
    );
    unawaited(_loadDonationProducts());
  }

  @override
  void dispose() {
    _purchaseSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadDonationProducts() async {
    final storeAvailable = await widget.donationService.isAvailable();
    if (!mounted) {
      return;
    }

    if (!storeAvailable) {
      setState(() {
        _isLoading = false;
        _storeAvailable = false;
        _message = 'Purchases are not available on this device.';
      });
      return;
    }

    final response = await widget.donationService.queryDonationProducts();
    final products = response.productDetails.toList()
      ..sort((first, second) => first.rawPrice.compareTo(second.rawPrice));

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _storeAvailable = true;
      _products = products;
      if (response.error != null) {
        _message = response.error!.message;
      } else if (products.isEmpty) {
        _message =
            'No donation products are available yet. Create donation_small, donation_medium, and donation_large in Play Console.';
      } else {
        _message = null;
      }
    });
  }

  Future<void> _buyDonation(ProductDetails productDetails) async {
    setState(() {
      _isPurchasing = true;
      _message = null;
    });

    final started = await widget.donationService.buyDonation(productDetails);
    if (!mounted) {
      return;
    }

    if (!started) {
      setState(() {
        _isPurchasing = false;
        _message = 'The purchase could not be started.';
      });
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        if (mounted) {
          setState(() {
            _isPurchasing = true;
            _message = 'Waiting for the store to finish the purchase.';
          });
        }
        continue;
      }

      if (purchase.pendingCompletePurchase) {
        await widget.donationService.completePurchase(purchase);
      }

      if (!mounted) {
        continue;
      }

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        setState(() {
          _isPurchasing = false;
          _message = 'Thank you for supporting Kartler.';
        });
      } else if (purchase.status == PurchaseStatus.error) {
        setState(() {
          _isPurchasing = false;
          _message = purchase.error?.message ?? 'The purchase failed.';
        });
      } else if (purchase.status == PurchaseStatus.canceled) {
        setState(() {
          _isPurchasing = false;
          _message = 'The purchase was canceled.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support Kartler')),
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Send a donation',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Donations are handled by the store billing system. They do not unlock app features.',
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (!_storeAvailable || _products.isEmpty)
              _DonationMessage(message: _message)
            else ...[
              for (final product in _products)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FilledButton.icon(
                    onPressed: _isPurchasing
                        ? null
                        : () => _buyDonation(product),
                    icon: const Icon(Icons.favorite_outline),
                    label: Text('Donate ${product.price}'),
                  ),
                ),
              if (_isPurchasing) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
              ],
              if (_message != null) ...[
                const SizedBox(height: 16),
                _DonationMessage(message: _message),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _DonationMessage extends StatelessWidget {
  final String? message;

  const _DonationMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Text(message ?? 'Donation products are not available.');
  }
}
