// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_in_app_purchase/otel_in_app_purchase.dart';

/// Traces in-app purchase flow calls with OpenTelemetry.
///
/// `otel_in_app_purchase` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each in-app purchase flow call in
/// [tracedInAppPurchase]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'in-app-purchase-example');

  // Wraps an in-app purchase flow call in a CLIENT span.
  final inAppPurchaseId = await tracedInAppPurchase<String>(
    operation: 'products.query',
    invoke: () async {
      // Make the in-app purchase flow call here, then report what it returned.
      const id = 'in_app_purchase_8f3a2c';
      return const InAppPurchaseCallResult(
          value: id,
          result: InAppPurchaseResult(
              store: 'app_store',
              productId: 'product_8f3a2c',
              productType: 'consumable',
              purchaseId: 'purchase_8f3a2c',
              transactionId: 'transaction_8f3a2c',
              originalTransactionId: 'originaltransaction_8f3a2c',
              purchaseStatus: 'pending',
              priceMinor: 1,
              currencyCode: 'usd',
              offerType: 'INTRO_OFFER',
              introductoryOffer: true,
              acknowledged: true,
              serverVerified: true,
              serverErrorCode: 'example',
              errorCode: 1,
              errorMessage: 'example',
              statusCode: 200));
    },
  );
  OTelLog.info('tracedInAppPurchase products.query returned $inAppPurchaseId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutInAppPurchaseInstrumentationAsync.
  await runWithoutInAppPurchaseInstrumentationAsync(
    () => tracedInAppPurchase<String>(
      operation: 'products.query',
      invoke: () async {
        const id = 'in_app_purchase_8f3a2c';
        return const InAppPurchaseCallResult(
            value: id,
            result: InAppPurchaseResult(
                store: 'app_store',
                productId: 'product_8f3a2c',
                productType: 'consumable',
                purchaseId: 'purchase_8f3a2c',
                transactionId: 'transaction_8f3a2c',
                originalTransactionId: 'originaltransaction_8f3a2c',
                purchaseStatus: 'pending',
                priceMinor: 1,
                currencyCode: 'usd',
                offerType: 'INTRO_OFFER',
                introductoryOffer: true,
                acknowledged: true,
                serverVerified: true,
                serverErrorCode: 'example',
                errorCode: 1,
                errorMessage: 'example',
                statusCode: 200));
      },
    ),
  );

  await OTel.shutdown();
}
