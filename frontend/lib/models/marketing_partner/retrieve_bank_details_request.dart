class RetrieveBankDetailsRequest {
  final int marketingPartner;

  RetrieveBankDetailsRequest({required this.marketingPartner});

  Map<String, dynamic> toJson() {
    return {
      "marketing_partner": marketingPartner,
    };
  }
}