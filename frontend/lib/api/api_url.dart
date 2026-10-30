class ApiUrls {
  //static const String baseUrl = "http://192.168.0.183:16000";
  // static cost String baseUrl = 'http://192.168.31.98:16000';
  // static const String baseUrl = "http://192.168.0.213:16000";
  // static const String baseUrl = "http://192.168.0.196:16000";
  // static const String baseUrl = "http://172.19.117.48:16000";
  // static const String baseUrl = "http://192.168.31.173:16000";
   static const String baseUrl = "http://192.168.31.252:16000";
   // static const String baseUrl = "http://169.254.9.67:16000";
   // static const String baseUrl = "https://test.qnxmartb2b.com";
   // static const String baseUrl = "https://api.qnxmartb2b.com";
  // static const String baseUrl = "https://crummy-gestation-unrigged.ngrok-free.dev";

  // -------------------------------Company create------------------------------
  static const String companyCreate = "$baseUrl/company/company/create/";
  // -------------------------------Brand create--------------------------------
  static const String brandCreate = "$baseUrl/product/api/brands/create/";
  // -------------------------------Unit create---------------------------------
  static const String unitCreate = "$baseUrl/product/unit/create/";
  // -------------------------------Unit list-----------------------------------
  static const String unitList = "$baseUrl/product/unit/all/";
  // -------------------------------Unit update---------------------------------
  static const String updateUnit = "$baseUrl/product/unit/update/";
  // -------------------------------product create------------------------------
  static const String productCreate = "$baseUrl/product/api/products/create/";
  // -------------------------------product list--------------------------------
  static const String productList = "$baseUrl/product/api/products/list/";
  // -------------------------------Admin Login---------------------------------
  // static const String adminLogin = "$baseUrl/admin_profile/admin/login/";//accounts/login
  static const String adminLogin = "$baseUrl/accounts/login/";
  // -------------------------------admin create--------------------------------
  static const String adminCreate = "$baseUrl/admin_profile/admin/create/";
  // -------------------------------Role create---------------------------------
  static const String roleCreate = "$baseUrl/admin_profile/roles/create/";
  // -------------------------------Role list-----------------------------------
  static const String roleList   = "$baseUrl/admin_profile/roles/list/";
  // -------------------------------role detail---------------------------------
  static const String roleDetail = "$baseUrl/admin_profile/roles/detail/";
  // -------------------------------role update---------------------------------
  static const String roleUpdate = "$baseUrl/admin_profile/roles/update/";
  // -------------------------------role delete---------------------------------
  static const String roleDelete = "$baseUrl/admin_profile/roles/soft_delete/";

  // -------------------------------Category create-----------------------------
  static const String categoryCreate = "$baseUrl/product/category/create/";
  // -------------------------------category list-------------------------------
  static const String categoryList = "$baseUrl/product/category/all/";
  // -------------------------------category update-----------------------------
  static const String update = "$baseUrl/product/category/update/";
  // -------------------------------category delete-----------------------------
  static const String delete = "$baseUrl/product/category/delete/";

  // -------------------------------send otp change password--------------------
  static const String sendOtp = "$baseUrl/accounts/forgot-password/send-otp/";
  // -------------------------------Verify OTP change password------------------
  static const String verifyOtp ="$baseUrl/accounts/forgot-password/verify-otp/";
  // --------------------------- RESET PASSWORD change password ----------------
  static const String resetPassword ="$baseUrl/accounts/forgot-password/reset/";

  //------------------------------user enquiry----------------------------------
  static const String userEnquiryList = "$baseUrl/enquiry/uenquiry_list/";
  //-------------------------enquiry--------------------------------------------
  static const String enquiryList = "$baseUrl/enquiry/enquiry_list/";
  // New endpoint for latest enquiries (POST)
  static const String latestEnquiries = "$baseUrl/enquiry/latest-enquiries/";
  // ------------------------------- Agreement List ----------------------------
   static const String companyAgreementList = "$baseUrl/agreement/company-agreement/list/";
  //-------------------------------offer list-----------------------------------
  static const String offerList = "$baseUrl/offer/offers/listall/";
  //-------------------------------offer list update----------------------------
  static const String offerUpdate = "$baseUrl/offer/offers/update/";
  //--------------------------single offer retrive------------------------------
  static const String singleOffer = "$baseUrl/offer/offers/single_retrieve/";
  //--------------------------single offer delete-----------------------------
  static const String deleteOffer = "$baseUrl/offer/offers/delete/";

  //-------------------------company pending -----------------------------------
  static const String pendingCompanies  = "$baseUrl/company/company/pending/";
  //-----------------------company all  ----------------------------------------
  static const String companyAll = "$baseUrl/company/company/all/";

  static const String companySingleRetrieve = "$baseUrl/company/company/single-retrieve/";

  //-----------------------------company softdelete-----------------------------
  static const String companySoftDelete ="$baseUrl/company/company/soft-delete/";
  //---------------------------------company restore----------------------------
  static const String companyRestore = "$baseUrl/company/company/restore/";
  // latest Company endpoints
  static const String latestCompanies = "$baseUrl/company/latest-companies/";

  //-------------------------category all  -------------------------------------
  static const String categoryAll = "$baseUrl/product/category/all/";
  //-----------------------subcategory -----------------------------------------
  static const String subCategoryAll = "$baseUrl/product/subcategories/all/";


  //---------------------------------pending products---------------------------
  static const String pendingProducts = "$baseUrl/product/pending-products/";
  //-----------------------------------product approve--------------------------
  static const String productApprove = "$baseUrl/product/product/approve/";
  //-----------------------------product approved list -------------------------
  static const String approvedProductList = "$baseUrl/product/product/approved-list/";
  //-----------------------------product reject  -------------------------------
  static const String rejectProduct = "$baseUrl/product/product/reject/";
  // latest Product endpoints
  static const String latestProducts = "$baseUrl/product/latest-products/";

  static const String Productcard = "$baseUrl/product/approved-product-count/";

  static const String companytcard = "$baseUrl/company/company/";

  static const String enquirycard = "$baseUrl/enquiry/enquiry-count/";

   static const String createAgreement = "$baseUrl/agreement/company-agreement/create/";


  //----------------------------------------------------------------------------
  static const String registersendOtp = "$baseUrl/accounts/send-otp/";
  static const String registerverifyOtp = "$baseUrl/accounts/verify-otp/";
  static const String register = "$baseUrl/accounts/register/";
  static const String userList = "$baseUrl/accounts/users/";

/*static const String companyList = "$baseUrl/company/company/list/";*/

  static const String agreementCompanyAll = "$baseUrl/company/company/all/";

  static const String companyWiseProducts = "$baseUrl/company/product/company-wise/";

// ----------------------------- Product Update Requests ----------------------------
  static const String updateRequestList = "$baseUrl/product/product/update-request-list/";
  static const String approveUpdateRequest = "$baseUrl/product/product/approve-update/";
  static const String rejectUpdateRequest = "$baseUrl/product/product/reject-update/";

  static const String brandList = "$baseUrl/product/api/brands/list/";

/*  static const String completeRegistration = "$baseUrl/enquiry/partner/complete-registration/";*/
  static const String marketingHeadsList = "$baseUrl/enquiry/marketing-heads/list/";
  static const String rejectPartner = "$baseUrl/enquiry/partner/reject/";
  // Marketing Partner Endpoints
  static const String marketingPartnersList = "$baseUrl/enquiry/marketing-partners/list/";
  static const String completeRegistrationPartner = "$baseUrl/enquiry/partner/complete-registration/";

  static const String referredPartners = "$baseUrl/enquiry/referred-partners/";
  static const String pendingEnquiries = "$baseUrl/enquiry/company-product-enquiries/";

  static const String sendEnquiryToCompany = "$baseUrl/enquiry/enquiry/send-to-company/";
  static const String approvedEnquiries = "$baseUrl/enquiry/enquiry/approved-list/";

  static const String partnerCompanies = "$baseUrl/enquiry/partner-companies/";

  static const String createBankDetails = "$baseUrl/enquiry/bank-details/create/";

  static const String retrieveBankDetails = "$baseUrl/enquiry/retrieve-bank-details/";
  // -------------------------------Franchise endpoints------------------------------
  static const String franchiseList = "$baseUrl/franchicies/franchise/public-list/";
  // Agreement Approve/Reject URLs
  static const String companyAgreementApprove = "$baseUrl/agreement/company-agreement/approve/reject/";
  static const String companyAgreementReject = "$baseUrl/agreement/company-agreement/approve/reject/";

  // ✅ Agreement Percentage Update URL
  static const String updateAgreementPercentage =
      "$baseUrl/agreement/agreement/update-percentage/";
// Marketing Partners Approved
  static const String approvedMarketingPartnersCount = "$baseUrl/enquiry/approved-marketing-partners/count/";
  static const String approvedMarketingPartnersList = "$baseUrl/enquiry/approved-marketing-partners/list/";

  static const String paidCompaniesCount = "$baseUrl/company/paid-companies/count/";

// Unpaid Companies Pending Amount
  static const String unpaidCompaniesPendingAmount = "$baseUrl/company/unpaid-companies/pending-amount/";

  static const String marketingPartnerCommissionList = "$baseUrl/payment/marketing-partner/commission/partners/";

  // ✅ Marketing Partner Wallet
  static const String marketingPartnerWallet = "$baseUrl/payment/marketing-partner/wallet/";

  // ✅ Payment Request URLs
  static const String pendingWithdrawRequests = "$baseUrl/payment/marketing-partner/wallet/withdraw/pending-requests/";

  static const String generatePaymentQR = "$baseUrl/payment/marketing-partner/generate-payment-qr/";

  static const String withdrawAmount = "$baseUrl/payment/marketing-partner/wallet/withdraw/amount/";
  // -------------------------------Amount Update------------------------------
  static const String amountUpdate = "$baseUrl/payment/amount_update/";

  // -------------------------------Loan Enquiry--------------------------------
  static const String loanEnquiryList = "$baseUrl/loan/loan-enquiry/list/";

  //--------------------------- Banner Image endpoints----------------------------------------------------
  static const String uploadImage = "$baseUrl/admin_profile/upload_image/";
  static const String updateImage = "$baseUrl/admin_profile/upload_image_update/";
  static const String deleteImage = "$baseUrl/admin_profile/upload_image_delete/";
  static const String imageList = "$baseUrl/admin_profile/upload_image_list/";


  // -------------------------------Packing Video--------------------------------
  static const String retrievePackingVideo = "$baseUrl/shipping/packing-video/retrieve/";

  // ==================== CUSTOMER SUBSCRIPTION PLAN ====================
  static const String customerSubscriptionPlanCreate = "$baseUrl/payment/customer-subscription-plans/create/";
  static const String customerSubscriptionPlanList = "$baseUrl/payment/customer-subscription-plans/";

  //=============================================================================================================
  //-------------------------------------------------marketing head------------------------------------------
  //===============================================================================================================
  static const String myMarketingProfile = "$baseUrl/enquiry/my-marketing-profile/";
  static const String myReferredPartners = '$baseUrl/enquiry/my-referred-partners/';
  static const String marketingHeadCompanies = "$baseUrl/enquiry/marketing-head-companies/";
  static const String createPartnerHeadAgreement = "$baseUrl/agreement/create-partner-head-agreement/";
  //=============================================================================================================
  //-------------------------------------------------marketing partner------------------------------------------
  //=========================================================================================================
  static const String myMarketingCompanies = "$baseUrl/enquiry/my-marketing-companies/";
// ------------------ Marketing Partner Agreement ------------------
  // ==================== MARKETING PARTNER AGREEMENT ====================
  static const String marketingPartnerAgreementList = "$baseUrl/agreement/marketing-partner-agreement/list/";
  static const String marketingPartnerAgreementCreate = "$baseUrl/agreement/marketing-partner-agreement/create/";
  static const String marketingPartnerAgreementApprove = "$baseUrl/agreement/marketing-partner-agreement/approve/reject/";
  static const String marketingPartnerAgreementReject = "$baseUrl/agreement/marketing-partner-agreement/approve/reject/";
// ✅ Keep old for backward compatibility
  static const String marketingPartnerAgreement = "$baseUrl/agreement/marketing-partner-agreement/";
  static const String commissionUrl = "$baseUrl/payment/marketing-partner/commission/";
  static const String productReferral = "$baseUrl/product/api/product/referral/";
  static const String walletWithdrawUrl = "$baseUrl/payment/marketing-partner/wallet/withdraw/";
  static const String walletUrl = "$baseUrl/payment/marketing-partner/wallet/";
  static const String approvedProperties = "$baseUrl/real_estate/properties/approved/";

  static const String pendingCommissionUrl = "$baseUrl/payment/marketing-partner/commission/pending/";
  static const String generateFranchiseReferral = "$baseUrl/franchicies/generate_referral_link/";

  static const String updateBankDetails = "$baseUrl/enquiry/bank-details/update/";
  static const String myMarketingPartnerAgreements = "$baseUrl/agreement/marketing-partner-agreement/my/";




// ----------------------------------REAL ESTATE PROPERTY REFERRAL URLS-----------------------------------------

  static const String propertyReferralGenerate = "$baseUrl/real_estate/property_referral-link/";

//=================================================================================================================
  //------------------------------ Google Places API--------------------------------------------------------------
  //==============================================================================================================
// -------------------------------Google Places API--------------------------------––------------------
  static const String nearbyPlacesApi = "$baseUrl/admin_profile/places/nearby/";
  static const String nearbySearchUrl = "https://maps.googleapis.com/maps/api/place/nearbysearch/json";
  static const String textSearchUrl = "https://maps.googleapis.com/maps/api/place/textsearch/json";
  static const String placeDetailsUrl = "https://maps.googleapis.com/maps/api/place/details/json";
  // ✅ Reverse Geocoding API (Get location name from coordinates)
  static const String reverseGeocodeApi = "$baseUrl/admin_profile/places/reverse-geocode/";
  static const String googleGeocodeUrl = "https://maps.googleapis.com/maps/api/geocode/json";


  //==================================================================================================================
  //----------------------------------RealEstate URLS---------------------------------------------------------
 // =================================================================================================================
  static const String amenityCreate = "$baseUrl/real_estate/amenity/create/";
  static const String amenityList = "$baseUrl/real_estate/amenities/list/";
  // ---------------------------------Property endpoints------------------------
// -------------------------------Property List---------------------------------
  static const String propertyList = "$baseUrl/real_estate/properties/list/";
// -------------------------------Property Approve---------------------------------
  static const String propertyApprove = "$baseUrl/real_estate/properties/approve/";

  // -------------------------------Channel Partners---------------------------------
  static const String channelPartnerList = "$baseUrl/real_estate/channel-partner/list/";

  // -------------------------------Property Enquiry Assign---------------------------------
  static const String propertyEnquiryAssign = "$baseUrl/real_estate/property-enquiry/assign/";
// -------------------------------Property Enquiries----------------------------
  static const String propertyEnquiries = "$baseUrl/real_estate/enquiries/";
  // -------------------------------Builder Create------------------------------
  static const String builderCreate = "$baseUrl/real_estate/builder/create/";

  // -------------------------------Builders List-------------------------------
  static const String buildersList = "$baseUrl/real_estate/builders/";

  // -------------------------------Property Create-----------------------------
  static const String propertyCreate = "$baseUrl/real_estate/property/create/";


//=================================================================================================================
  // ===================== SHIPROCKET ENDPOINTS ================================
 //==================================================================================================================
  static const String shipOrders = "$baseUrl/shipping/ship-orders/";
  static const String shiprocketCreateOrder = "$baseUrl/shipping/shiprocket-create-order/";

  static const String shipmentList = "$baseUrl/shipping/shipments/list/";
  static const String assignAWB = "$baseUrl/shipping/assign-awb/";
  // ===================== SHIPROCKET COURIER RATES =====================
  static const String orderCourierRates = "$baseUrl/shipping/order-courier-rates/";

  // -------------------------------PDF Property Extract------------------------
 static const String pdfExtractProperty = "$baseUrl/AI/extract-property/";

  // -------------------------------Channel Partner Enquiries------------------------------
  static const String channelPartnerEnquiries = "$baseUrl/real_estate/channel-partner/enquiries/";


  // ==================== REAL ESTATE - MY PROPERTIES ====================
  static const String myProperties = "$baseUrl/real_estate/my/properties/";
  static const String propertyUpdate = "$baseUrl/real_estate/property-update/";
  
  
  // Schedule Meeting endpoint
  static const String scheduleMeeting = "$baseUrl/real_estate/property-enquiry/schedule-meeting/";

  // ==================== PROPERTY SUBSCRIPTION PLAN ====================
  static const String propertySubscriptionCreate = "$baseUrl/payment/property-subscription-plan/create/";
  static const String propertySubscriptionList = "$baseUrl/payment/property-subscription-plan/list/";
  static const String propertySubscriptionUpdate = "$baseUrl/payment/property-subscription-plan/update/";

  static const String enquiryWiseMarketingPartners = "$baseUrl/real_estate/my/enquiries/marketing-partners/";

  // ==================== OLX CATEGORY ENDPOINTS ====================
  static const String olxBaseUrl = "$baseUrl/olx";
  static const String olxCategoryList = "$olxBaseUrl/categories/";
  static const String olxCategoryCreate = "$olxBaseUrl/categories/create/";

  // ==================== OLX SUB-CATEGORY ====================
  static const String olxSubcategoryList = "$olxBaseUrl/subcategories/";
  static const String olxSubcategoryCreate = "$olxBaseUrl/subcategories/create/";

  // ==================== OLX PLANS ====================
  static const String olxPlanList = "$olxBaseUrl/plans/";
  static const String olxPlanCreate = "$olxBaseUrl/plans/create/";

  // ==================== OLX PRICING ====================
  static const String olxPricingCreate = "$olxBaseUrl/pricing/create/";
  static const String olxPricingListByPlan = "$olxBaseUrl/pricing/plans/";

  // ==================== OLX ATTRIBUTES ====================
  static const String olxAttributeCreate = "$olxBaseUrl/attributes/create/";
  static const String olxAttributeList = "$olxBaseUrl/attributes/";

  // ==================== OLX SETTINGS ====================
  static const String olxSettingsCreate = "$olxBaseUrl/settings/create/";
  static const String olxSettingsUpdate = "$olxBaseUrl/settings/update/";
  static const String olxSettingsList = "$olxBaseUrl/settings/";


  // ==================== OLX COMMUNICATION PLANS ====================
  static const String olxCommunicationPlanCreate = "$olxBaseUrl/bazaar-communication-plans/create/";
  static const String olxCommunicationPlanList = "$olxBaseUrl/bazaar-communication-plans/list/";
  static const String olxCommunicationPlanUpdate = "$olxBaseUrl/bazaar-communication-plans/update/";



  // ==================== OLX COMMUNICATION SETTINGS ====================
  static const String olxCommunicationSettingsDetail = "$olxBaseUrl/bazaar-communication-settings/detail/";
  static const String olxCommunicationSettingsUpdate = "$olxBaseUrl/bazaar-communication-settings/update/";




  // ==================== AI ADMIN ENDPOINTS ====================
  static const String aiAdminDashboard = "$baseUrl/AI/admin/dashboard/";
  static const String aiAdminSettings = "$baseUrl/AI/admin/settings/";
  static const String aiAdminConversations = "$baseUrl/AI/admin/conversations/";
  static const String aiAdminMessages = "$baseUrl/AI/admin/messages/";
  static const String aiAdminAnalytics = "$baseUrl/AI/admin/analytics/";
  static const String aiAdminUsage = "$baseUrl/AI/admin/usage/";



  // ==================== SUBSCRIPTION PLANS google (ADMIN) ====================
  static const String subscriptionPlanCreate = "$baseUrl/admin_profile/subscription-plans/create/";
  static const String subscriptionPlanList = "$baseUrl/admin_profile/subscription-plans/list/";

  // ==================== SHIPROCKET RETURN ORDERS ====================
  static const String returnOrdersList = "$baseUrl/shipping/return-orders/";
  static const String createReturnShipment = "$baseUrl/shipping/return-order/create-shipment/";

  // ✅ NEW: Return Shipments (List + AWB Assign)
  static const String returnShipmentList = "$baseUrl/shipping/return-order/shiprocket-list/";
  static const String assignReturnAWB = "$baseUrl/shipping/return-order/assign-awb/";

  // ==================== SHIPROCKET ENDPOINTS ====================
  static const String prepaidCancelledOrders =
      "$baseUrl/shipping/prepaid-cancelled-orders/";

  // ==================== PACKING MATERIAL ENQUIRY ====================
  static const String packingMaterialEnquiryList = "$baseUrl/shipping/packing-material-enquiry/list/";


  // ==================== PRODUCT BOOSTING PLANS ====================
  static const String boostingPlanCreate = "$baseUrl/product/boosting/plans/create/";
  static const String boostingPlanList = "$baseUrl/product/product-boosting-plans/";

}