import 'package:in_app_purchase/in_app_purchase.dart';

class DonationProductIds {
  DonationProductIds._();

  static const small = 'donation_small';
  static const medium = 'donation_medium';
  static const large = 'donation_large';

  static const all = <String>{small, medium, large};
}

class DonationService {
  DonationService({InAppPurchase? inAppPurchase})
    : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance;

  final InAppPurchase _inAppPurchase;

  Stream<List<PurchaseDetails>> get purchaseStream =>
      _inAppPurchase.purchaseStream;

  Future<bool> isAvailable() {
    return _inAppPurchase.isAvailable();
  }

  Future<ProductDetailsResponse> queryDonationProducts() {
    return _inAppPurchase.queryProductDetails(DonationProductIds.all);
  }

  Future<bool> buyDonation(ProductDetails productDetails) {
    final purchaseParam = PurchaseParam(productDetails: productDetails);
    return _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
  }

  Future<void> completePurchase(PurchaseDetails purchaseDetails) {
    return _inAppPurchase.completePurchase(purchaseDetails);
  }
}
