class CardModel {
  final String number;
  final String expMonth;
  final String expYear;
  final String cvc;
  final bool saveForLater;

  CardModel({
    required this.number,
    required this.expMonth,
    required this.expYear,
    required this.cvc,
    required this.saveForLater,
  });

  Map<String, dynamic> toJson() {
    return {
      "number": number,
      "exp_month": expMonth,
      "exp_year": expYear,
      "cvc": cvc,
      "save_for_later": saveForLater,
    };
  }
}

class CreateOrderRequest {
  final String semester; // Changed to String to match API format
  final String? stripeToken; // Optional for saved cards
  final CardModel? card; // Optional when using saved card
  final String? couponCode;

  CreateOrderRequest({
    required this.semester,
    this.stripeToken,
    this.card,
    this.couponCode,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      "semester": semester,
      "coupon_code": couponCode ?? "null", // Always include coupon_code, use "null" if empty
    };
    
    // Only include card details if provided (for new cards)
    if (card != null) {
      data["card"] = card!.toJson();
    }
    
    // Only include stripe_token for saved cards (when no card details provided)
    if (stripeToken != null && card == null) {
      data["stripe_token"] = stripeToken;
    }
    return data;
  }
}


class CreateSubscriptionRequest {
  final CardModel? card; // Optional when using saved card

  CreateSubscriptionRequest({
    this.card,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      "card": card
    };
    return data;
  }
}


class CouponCodeRequest {
  final int semester;
  final String code;
  final double? originalAmount;

  CouponCodeRequest({
    required this.semester,
    required this.code,
    this.originalAmount,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      "semester": semester,
      "code": code,
    };
    
    if (originalAmount != null) {
      data["original_amount"] = originalAmount;
    }
    
    return data;
  }
}

class DeleteCardRequest {
  final String cardId;

  DeleteCardRequest({
    required this.cardId,
  });

  Map<String, dynamic> toJson() {
    return {
      "card_id": cardId,
    };
  }
}

class CreatePaymentRequest {
  final String amount;
  final String currency;
  final String? paymentMethodId;
  final CardModel? card;
  final String? customerId;
  final bool? savePaymentMethod;
  final Map<String, dynamic>? metadata;

  CreatePaymentRequest({
    required this.amount,
    required this.currency,
    this.paymentMethodId,
    this.card,
    this.customerId,
    this.savePaymentMethod,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      "amount": amount,
      "currency": currency,
    };
    
    if (paymentMethodId != null) {
      data["payment_method"] = paymentMethodId;
    }
    
    if (customerId != null) {
      data["customer"] = customerId;
    }
    
    if (savePaymentMethod != null) {
      data["setup_future_usage"] = savePaymentMethod! ? "off_session" : null;
    }
    
    if (metadata != null) {
      data["metadata"] = metadata;
    }
    
    if (card != null) {
      data["card"] = {
        "number": card!.number,
        "exp_month": card!.expMonth,
        "exp_year": card!.expYear,
        "cvc": card!.cvc,
      };
    }
    
    return data;
  }
}

class CreatePaymentIntentRequest {
  final String amount;
  final String currency;
  final String? customerId;
  final String? paymentMethodId;
  final bool? confirmPayment;
  final Map<String, dynamic>? metadata;

  CreatePaymentIntentRequest({
    required this.amount,
    required this.currency,
    this.customerId,
    this.paymentMethodId,
    this.confirmPayment,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      "amount": amount,
      "currency": currency,
    };
    
    if (customerId != null) {
      data["customer"] = customerId;
    }
    
    if (paymentMethodId != null) {
      data["payment_method"] = paymentMethodId;
    }
    
    if (confirmPayment != null) {
      data["confirm"] = confirmPayment;
    }
    
    if (metadata != null) {
      data["metadata"] = metadata;
    }
    
    return data;
  }
}