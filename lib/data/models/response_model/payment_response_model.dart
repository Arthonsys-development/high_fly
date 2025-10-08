class CreateOrderResponse {
  final int? semester;
  final String? message;
  final bool? success;

  const CreateOrderResponse({
    this.semester,
    this.message,
    this.success,
  });

  factory CreateOrderResponse.fromJson(Map<String, dynamic> json) {
    return CreateOrderResponse(
      semester: json['semester'] as int?,
      message: json['message'] as String?,
      success: json['success'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'semester': semester,
      'message': message,
      'success': success,
    };
  }
}


class CreateSubscriptionResponse {
  final String? message;

  const CreateSubscriptionResponse({
    this.message,
  });

  factory CreateSubscriptionResponse.fromJson(Map<String, dynamic> json) {
    return CreateSubscriptionResponse(
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
    };
  }
}


class CouponCodeResponse {
  final String? code;
  final double? originalAmount;
  final double? discountedAmount;
  final double? discountAmount;
  final String? discountType;
  final double? couponAmount;
  final String? message;
  final bool? success;

  const CouponCodeResponse({
    this.code,
    this.originalAmount,
    this.discountedAmount,
    this.discountAmount,
    this.discountType,
    this.couponAmount,
    this.message,
    this.success,
  });

  factory CouponCodeResponse.fromJson(Map<String, dynamic> json) {
    return CouponCodeResponse(
      code: json['code'] as String?,
      originalAmount: (json['original_amount'] as num?)?.toDouble(), // Handle both int and double
      discountedAmount: (json['discounted_amount'] as num?)?.toDouble(),
      discountAmount: (json['discount_amount'] as num?)?.toDouble(),
      discountType: json['discount_type'] as String?,
      couponAmount: (json['coupon_amount'] as num?)?.toDouble(), // Handle both int and double
      message: json['message'] as String?,
      success: json['success'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'original_amount': originalAmount,
      'discounted_amount': discountedAmount,
      'discount_amount': discountAmount,
      'discount_type': discountType,
      'coupon_amount': couponAmount,
      'message': message,
      'success': success,
    };
  }
}



// MARK: - PaymentMethods
class PaymentMethods {
  final String? object;
  final dynamic count;
  final List<Datum>? data;
  final bool? hasMore;
  final String? url;

  PaymentMethods({
    this.object,
    this.count,
    this.data,
    this.hasMore,
    this.url,
  });

  factory PaymentMethods.fromJson(Map<String, dynamic> json) {
    return PaymentMethods(
      object: json['object'],
      count: json['count'],
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => Datum.fromJson(e))
          .toList(),
      hasMore: json['has_more'],
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'object': object,
      'count': count,
      'data': data?.map((e) => e.toJson()).toList(),
      'has_more': hasMore,
      'url': url,
    };
  }
}

// MARK: - Datum
class Datum {
  final String? id;
  final String? object;
  final BillingDetails? billingDetails;
  final CardData? card;
  final int? created;
  final String? customer;
  final bool? livemode;
  final Metadata? metadata;
  final String? type;

  Datum({
    this.id,
    this.object,
    this.billingDetails,
    this.card,
    this.created,
    this.customer,
    this.livemode,
    this.metadata,
    this.type,
  });

  factory Datum.fromJson(Map<String, dynamic> json) {
    return Datum(
      id: json['id'],
      object: json['object'],
      billingDetails: json['billing_details'] != null
          ? BillingDetails.fromJson(json['billing_details'])
          : null,
      card: json['card'] != null ? CardData.fromJson(json['card']) : null,
      created: json['created'],
      customer: json['customer'],
      livemode: json['livemode'],
      metadata: Metadata.fromJson(json['metadata'] ?? {}),
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'object': object,
      'billing_details': billingDetails?.toJson(),
      'card': card?.toJson(),
      'created': created,
      'customer': customer,
      'livemode': livemode,
      'metadata': metadata?.toJson(),
      'type': type,
    };
  }
}

// MARK: - BillingDetails
class BillingDetails {
  final Address? address;
  final String? email;
  final String? name;
  final String? phone;

  BillingDetails({this.address, this.email, this.name, this.phone});

  factory BillingDetails.fromJson(Map<String, dynamic> json) {
    return BillingDetails(
      address: json['address'] != null ? Address.fromJson(json['address']) : null,
      email: json['email'],
      name: json['name'],
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address?.toJson(),
      'email': email,
      'name': name,
      'phone': phone,
    };
  }
}

// MARK: - Address
class Address {
  final String? city;
  final String? country;
  final String? line1;
  final String? line2;
  final String? postalCode;
  final String? state;

  Address({
    this.city,
    this.country,
    this.line1,
    this.line2,
    this.postalCode,
    this.state,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      city: json['city'],
      country: json['country'],
      line1: json['line1'],
      line2: json['line2'],
      postalCode: json['postal_code'],
      state: json['state'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'country': country,
      'line1': line1,
      'line2': line2,
      'postal_code': postalCode,
      'state': state,
    };
  }
}

// MARK: - Card
class CardData {
  final String? brand;
  final Checks? checks;
  final String? country;
  final int? expMonth;
  final int? expYear;
  final String? fingerprint;
  final String? funding;
  final dynamic generatedFrom;
  final String? last4;
  final Networks? networks;
  final ThreeDSecureUsage? threeDSecureUsage;
  final dynamic wallet;

  CardData({
    this.brand,
    this.checks,
    this.country,
    this.expMonth,
    this.expYear,
    this.fingerprint,
    this.funding,
    this.generatedFrom,
    this.last4,
    this.networks,
    this.threeDSecureUsage,
    this.wallet,
  });

  factory CardData.fromJson(Map<String, dynamic> json) {
    return CardData(
      brand: json['brand'],
      checks: json['checks'] != null ? Checks.fromJson(json['checks']) : null,
      country: json['country'],
      expMonth: json['exp_month'],
      expYear: json['exp_year'],
      fingerprint: json['fingerprint'],
      funding: json['funding'],
      generatedFrom: json['generated_from'],
      last4: json['last4'],
      networks:
      json['networks'] != null ? Networks.fromJson(json['networks']) : null,
      threeDSecureUsage: json['three_d_secure_usage'] != null
          ? ThreeDSecureUsage.fromJson(json['three_d_secure_usage'])
          : null,
      wallet: json['wallet'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'brand': brand,
      'checks': checks?.toJson(),
      'country': country,
      'exp_month': expMonth,
      'exp_year': expYear,
      'fingerprint': fingerprint,
      'funding': funding,
      'generated_from': generatedFrom,
      'last4': last4,
      'networks': networks?.toJson(),
      'three_d_secure_usage': threeDSecureUsage?.toJson(),
      'wallet': wallet,
    };
  }
}

// MARK: - Checks
class Checks {
  final String? addressLine1Check;
  final String? addressPostalCodeCheck;
  final String? cvcCheck;

  Checks({
    this.addressLine1Check,
    this.addressPostalCodeCheck,
    this.cvcCheck,
  });

  factory Checks.fromJson(Map<String, dynamic> json) {
    return Checks(
      addressLine1Check: json['address_line1_check'],
      addressPostalCodeCheck: json['address_postal_code_check'],
      cvcCheck: json['cvc_check'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address_line1_check': addressLine1Check,
      'address_postal_code_check': addressPostalCodeCheck,
      'cvc_check': cvcCheck,
    };
  }
}

// MARK: - Networks
class Networks {
  final List<String>? available;
  final dynamic preferred;

  Networks({this.available, this.preferred});

  factory Networks.fromJson(Map<String, dynamic> json) {
    return Networks(
      available: (json['available'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      preferred: json['preferred'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'available': available,
      'preferred': preferred,
    };
  }
}

// MARK: - ThreeDSecureUsage
class ThreeDSecureUsage {
  final bool? supported;

  ThreeDSecureUsage({this.supported});

  factory ThreeDSecureUsage.fromJson(Map<String, dynamic> json) {
    return ThreeDSecureUsage(
      supported: json['supported'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'supported': supported,
    };
  }
}

// MARK: - Metadata
class Metadata {
  Metadata();

  factory Metadata.fromJson(Map<String, dynamic> json) {
    return Metadata();
  }

  Map<String, dynamic> toJson() {
    return {};
  }
}

class DeleteCardResponse {
  final String? message;
  final bool? success;

  DeleteCardResponse({
    this.message,
    this.success,
  });

  factory DeleteCardResponse.fromJson(Map<String, dynamic> json) {
    return DeleteCardResponse(
      message: json['message'] as String?,
      success: json['success'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'success': success,
    };
  }
}

class CreatePaymentResponse {
  final String? id;
  final String? object;
  final int? amount;
  final String? currency;
  final String? status;
  final String? clientSecret;
  final String? paymentMethodId;
  final String? customerId;
  final String? description;
  final Map<String, dynamic>? metadata;
  final int? created;
  final bool? livemode;
  final String? message;
  final bool? success;

  CreatePaymentResponse({
    this.id,
    this.object,
    this.amount,
    this.currency,
    this.status,
    this.clientSecret,
    this.paymentMethodId,
    this.customerId,
    this.description,
    this.metadata,
    this.created,
    this.livemode,
    this.message,
    this.success,
  });

  factory CreatePaymentResponse.fromJson(Map<String, dynamic> json) {
    return CreatePaymentResponse(
      id: json['id'] as String?,
      object: json['object'] as String?,
      amount: json['amount'] as int?,
      currency: json['currency'] as String?,
      status: json['status'] as String?,
      clientSecret: json['client_secret'] as String?,
      paymentMethodId: json['payment_method'] as String?,
      customerId: json['customer'] as String?,
      description: json['description'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      created: json['created'] as int?,
      livemode: json['livemode'] as bool?,
      message: json['message'] as String?,
      success: json['success'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'object': object,
      'amount': amount,
      'currency': currency,
      'status': status,
      'client_secret': clientSecret,
      'payment_method': paymentMethodId,
      'customer': customerId,
      'description': description,
      'metadata': metadata,
      'created': created,
      'livemode': livemode,
      'message': message,
      'success': success,
    };
  }
}

class CreatePaymentIntentResponse {
  final String? id;
  final String? object;
  final int? amount;
  final String? currency;
  final String? status;
  final String? clientSecret;
  final String? paymentMethodId;
  final String? customerId;
  final String? description;
  final Map<String, dynamic>? metadata;
  final int? created;
  final bool? livemode;
  final String? message;
  final bool? success;

  CreatePaymentIntentResponse({
    this.id,
    this.object,
    this.amount,
    this.currency,
    this.status,
    this.clientSecret,
    this.paymentMethodId,
    this.customerId,
    this.description,
    this.metadata,
    this.created,
    this.livemode,
    this.message,
    this.success,
  });

  factory CreatePaymentIntentResponse.fromJson(Map<String, dynamic> json) {
    return CreatePaymentIntentResponse(
      id: json['id'] as String?,
      object: json['object'] as String?,
      amount: json['amount'] as int?,
      currency: json['currency'] as String?,
      status: json['status'] as String?,
      clientSecret: json['client_secret'] as String?,
      paymentMethodId: json['payment_method'] as String?,
      customerId: json['customer'] as String?,
      description: json['description'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      created: json['created'] as int?,
      livemode: json['livemode'] as bool?,
      message: json['message'] as String?,
      success: json['success'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'object': object,
      'amount': amount,
      'currency': currency,
      'status': status,
      'client_secret': clientSecret,
      'payment_method': paymentMethodId,
      'customer': customerId,
      'description': description,
      'metadata': metadata,
      'created': created,
      'livemode': livemode,
      'message': message,
      'success': success,
    };
  }
}


