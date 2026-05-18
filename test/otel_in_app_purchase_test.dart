// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_in_app_purchase/otel_in_app_purchase.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_in_app_purchase-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('purchase.buyNonConsumable records store + product + price', () async {
    await tracedInAppPurchase<String>(
      operation: 'purchase.buyNonConsumable',
      invoke: () async => const InAppPurchaseCallResult(
        value: 'ok',
        result: InAppPurchaseResult(
          store: 'app_store',
          productId: 'pro_lifetime',
          productType: 'non_consumable',
          purchaseStatus: 'purchased',
          priceMinor: 4999,
          currencyCode: 'USD',
          introductoryOffer: false,
          serverVerified: true,
        ),
      ),
    );
    final a = attrsOf(
      spans.findSpanByName('in_app_purchase purchase.buyNonConsumable')!,
    );
    expect(a['in_app_purchase.store'], 'app_store');
    expect(a['in_app_purchase.product.type'], 'non_consumable');
    expect(a['in_app_purchase.price.minor'], 4999);
    expect(a['in_app_purchase.server.verified'], true);
  });

  test('server.verified=false sets span error', () async {
    await tracedInAppPurchase<String>(
      operation: 'receipt.verify',
      invoke: () async => const InAppPurchaseCallResult(
        value: 'ok',
        result: InAppPurchaseResult(
          purchaseStatus: 'purchased',
          serverVerified: false,
          serverErrorCode: 'TAMPERED_RECEIPT',
        ),
      ),
    );
    expect(
      spans.findSpanByName('in_app_purchase receipt.verify')!.status,
      SpanStatusCode.Error,
    );
  });

  test('paymentCancelled does NOT set span error', () async {
    await tracedInAppPurchase<String>(
      operation: 'purchase.buyConsumable',
      invoke: () async => const InAppPurchaseCallResult(
        value: 'ok',
        result: InAppPurchaseResult(
          store: 'app_store',
          purchaseStatus: 'canceled',
          errorCode: 2,
          errorMessage: 'paymentCancelled',
        ),
      ),
    );
    expect(
      spans.findSpanByName('in_app_purchase purchase.buyConsumable')!.status,
      isNot(SpanStatusCode.Error),
    );
  });

  test('Play Billing acknowledged + subscription offer', () async {
    await tracedInAppPurchase<String>(
      operation: 'purchase.acknowledge',
      invoke: () async => const InAppPurchaseCallResult(
        value: 'ok',
        result: InAppPurchaseResult(
          store: 'play_store',
          productId: 'pro_monthly',
          productType: 'subscription',
          offerType: 'INTRO_OFFER',
          introductoryOffer: true,
          acknowledged: true,
        ),
      ),
    );
    final a = attrsOf(
      spans.findSpanByName('in_app_purchase purchase.acknowledge')!,
    );
    expect(a['in_app_purchase.acknowledged'], true);
    expect(a['in_app_purchase.offer.type'], 'INTRO_OFFER');
  });

  test('suppression skips spans', () async {
    await runWithoutInAppPurchaseInstrumentationAsync(() async {
      await tracedInAppPurchase<String>(
        operation: 'products.query',
        invoke: () async => const InAppPurchaseCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('in_app_purchase '), isEmpty);
  });
}
