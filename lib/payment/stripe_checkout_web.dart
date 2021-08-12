@JS()
library stripe;

import 'package:flutter/material.dart';
import '../constants.dart';
import 'package:js/js.dart';

void redirectToCheckout(BuildContext _, int quanti) async {
  final stripe = Stripe(apiKey);
  stripe.redirectToCheckout(CheckoutOptions(
    lineItems: [
      LineItem(price: nikesPriceId, quantity: quanti),
    ],
    mode: 'payment',
    successUrl: 'https://habitbuilder-6f9ca.web.app/#/tracker',
    cancelUrl: 'https://habitbuilder-6f9ca.web.app/',
  ));
}

@JS()
class Stripe {
  external Stripe(String key);

  external redirectToCheckout(CheckoutOptions options);
}

@JS()
@anonymous
class CheckoutOptions {
  external List<LineItem> get lineItems;

  external String get mode;

  external String get successUrl;

  external String get cancelUrl;

  external factory CheckoutOptions({
    List<LineItem> lineItems,
    String mode,
    String successUrl,
    String cancelUrl,
    String sessionId,
  });
}

@JS()
@anonymous
class LineItem {
  external String get price;

  external int get quantity;

  external factory LineItem({String price, int quantity});
}
