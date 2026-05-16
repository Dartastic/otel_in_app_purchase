// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_in_app_purchase_suppression.dart';

const _tracerName = 'dartastic_otel_libs_in_app_purchase';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class InAppPurchaseResult {
  const InAppPurchaseResult({
    this.store,
    this.productId,
    this.productType,
    this.purchaseId,
    this.transactionId,
    this.originalTransactionId,
    this.purchaseStatus,
    this.priceMinor,
    this.currencyCode,
    this.offerType,
    this.introductoryOffer,
    this.acknowledged,
    this.serverVerified,
    this.serverErrorCode,
    this.errorCode,
    this.errorMessage,
    this.statusCode,
  });

  /// `app_store` (iOS/macOS StoreKit) / `play_store` (Android Play
  /// Billing).
  final String? store;

  final String? productId;

  /// `consumable` / `non_consumable` / `subscription` /
  /// `non_renewing_subscription`.
  final String? productType;

  final String? purchaseId;

  /// Per-platform: App Store transaction id, Play purchaseToken/orderId.
  final String? transactionId;

  /// For renewals, the original transaction's id.
  final String? originalTransactionId;

  /// `pending` / `purchased` / `error` / `restored` / `canceled`.
  final String? purchaseStatus;

  /// Price in minor units (cents/yen/etc.).
  final int? priceMinor;

  final String? currencyCode;

  /// `INTRO_OFFER` / `PROMO_OFFER` / `WIN_BACK_OFFER` (subscriptions).
  final String? offerType;

  /// `true` when an introductory offer was applied.
  final bool? introductoryOffer;

  /// For Play Billing: `true` after `acknowledgePurchase` succeeded.
  /// Required within 3 days or Play refunds the purchase.
  final bool? acknowledged;

  /// Result of your own server-side receipt verification.
  final bool? serverVerified;

  /// Server-side verification error code (your backend's contract).
  final String? serverErrorCode;

  /// Platform-side error code. Apple: `SKError` numeric codes
  /// (0=unknown, 2=paymentCancelled, 3=paymentInvalid, 4=paymentNotAllowed,
  /// 5=storeProductNotAvailable, 6=cloudServicePermissionDenied,
  /// 7=cloudServiceNetworkConnectionFailed, 8=cloudServiceRevoked,
  /// 9=privacyAcknowledgementRequired, 10=unauthorizedRequestData,
  /// 11=invalidOfferIdentifier, 12=invalidSignature,
  /// 13=missingOfferParams, 14=invalidOfferPrice).
  /// Play: `BillingResponseCode` numeric codes
  /// (-2=feature_not_supported, -1=service_disconnected, 0=ok,
  /// 1=user_canceled, 2=service_unavailable, 3=billing_unavailable,
  /// 4=item_unavailable, 5=developer_error, 6=error,
  /// 7=item_already_owned, 8=item_not_owned, 12=network_error).
  final int? errorCode;

  final String? errorMessage;

  final int? statusCode;
}

class InAppPurchaseCallResult<T> {
  const InAppPurchaseCallResult({required this.value, this.result});
  final T value;
  final InAppPurchaseResult? result;
}

/// Wraps an in-app purchase flow call in a CLIENT span. [operation]
/// is one of `products.query`, `purchase.buyConsumable`,
/// `purchase.buyNonConsumable`, `purchase.acknowledge`,
/// `purchase.finish`, `purchase.restore`, `purchase.refund_request`,
/// `subscription.upgrade`, `subscription.downgrade`,
/// `subscription.cancel`, `receipt.verify`, `country_code.get`.
Future<T> tracedInAppPurchase<T>({
  required String operation,
  required Future<InAppPurchaseCallResult<T>> Function() invoke,
}) async {
  if (inAppPurchaseInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'in_app_purchase',
    'rpc.method': operation,
    'in_app_purchase.operation': operation,
  };

  final span = _tracer().startSpan(
    'in_app_purchase $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.store != null) {
        extras.add(OTel.attributeString(
          'in_app_purchase.store',
          r.result!.store!,
        ));
      }
      if (r.result!.productId != null) {
        extras.add(OTel.attributeString(
          'in_app_purchase.product.id',
          r.result!.productId!,
        ));
      }
      if (r.result!.productType != null) {
        extras.add(OTel.attributeString(
          'in_app_purchase.product.type',
          r.result!.productType!,
        ));
      }
      if (r.result!.purchaseId != null) {
        extras.add(OTel.attributeString(
          'in_app_purchase.purchase.id',
          r.result!.purchaseId!,
        ));
      }
      if (r.result!.transactionId != null) {
        extras.add(OTel.attributeString(
          'in_app_purchase.transaction.id',
          r.result!.transactionId!,
        ));
      }
      if (r.result!.originalTransactionId != null) {
        extras.add(OTel.attributeString(
          'in_app_purchase.transaction.original_id',
          r.result!.originalTransactionId!,
        ));
      }
      if (r.result!.purchaseStatus != null) {
        extras.add(OTel.attributeString(
          'in_app_purchase.purchase.status',
          r.result!.purchaseStatus!,
        ));
        if (r.result!.purchaseStatus == 'error') {
          span.setStatus(SpanStatusCode.Error, 'IAP purchase error');
        }
      }
      if (r.result!.priceMinor != null) {
        extras.add(OTel.attributeInt(
          'in_app_purchase.price.minor',
          r.result!.priceMinor!,
        ));
      }
      if (r.result!.currencyCode != null) {
        extras.add(OTel.attributeString(
          'in_app_purchase.currency.code',
          r.result!.currencyCode!,
        ));
      }
      if (r.result!.offerType != null) {
        extras.add(OTel.attributeString(
          'in_app_purchase.offer.type',
          r.result!.offerType!,
        ));
      }
      if (r.result!.introductoryOffer != null) {
        extras.add(OTel.attributeBool(
          'in_app_purchase.offer.introductory',
          r.result!.introductoryOffer!,
        ));
      }
      if (r.result!.acknowledged != null) {
        extras.add(OTel.attributeBool(
          'in_app_purchase.acknowledged',
          r.result!.acknowledged!,
        ));
      }
      if (r.result!.serverVerified != null) {
        extras.add(OTel.attributeBool(
          'in_app_purchase.server.verified',
          r.result!.serverVerified!,
        ));
        if (r.result!.serverVerified == false) {
          span.setStatus(
            SpanStatusCode.Error,
            'IAP server verification failed',
          );
        }
      }
      if (r.result!.serverErrorCode != null) {
        extras.add(OTel.attributeString(
          'in_app_purchase.server.error_code',
          r.result!.serverErrorCode!,
        ));
      }
      if (r.result!.errorCode != null) {
        extras.add(OTel.attributeInt(
          'in_app_purchase.error.code',
          r.result!.errorCode!,
        ));
      }
      if (r.result!.errorMessage != null) {
        extras.add(OTel.attributeString(
          'in_app_purchase.error.message',
          r.result!.errorMessage!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'IAP HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
