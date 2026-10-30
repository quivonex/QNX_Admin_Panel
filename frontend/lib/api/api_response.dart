  import '../models/qnx_admin/agreement_model.dart';
  import '../models/qnx_admin/approved_enquiry_model.dart';
  import '../models/qnx_admin/bank_details_request.dart';
  import '../models/qnx_admin/brand_model.dart';
  import '../models/qnx_admin/company_product_enquiry_model.dart';
  import '../models/qnx_admin/partner_company_model.dart';
  import '../models/qnx_admin/product_model.dart';
  import '../models/qnx_admin/unit_model.dart';
  import '../models/qnx_admin/role_model.dart';
  import '../models/qnx_admin/category_model.dart';
  import '../models/qnx_admin/user_enquiry_model.dart';
  import '../models/qnx_admin/offer_model.dart';
  import '../models/qnx_admin/enquiry_list_model.dart';
  import '../models/qnx_admin/company_pending_model.dart';
  import '../models/qnx_admin/company_model.dart';
  import '../models/qnx_admin/subcategory_model.dart';
  import '../models/qnx_admin/user_model.dart';
  import '../models/qnx_admin/franchise_model.dart';
  import '../models/qnx_admin/user_model.dart' as userModel;
  import '../models/qnx_admin/agreement_model.dart';
  import '../models/marketing_partner/update_bank_details_model.dart';
  import '../models/qnx_admin/agreement_model.dart';
  class ApiResponse<T> {
    final bool status;
    final String message;
    final T? data;
  
    ApiResponse({
      required this.status,
      required this.message,
      this.data,
    });
    factory ApiResponse.fromJson(
        Map<String, dynamic> json,
        T Function(Map<String, dynamic>) fromJson,
        ) {
      return ApiResponse<T>(
        status: json['status'] ?? false,
        message: json['message'] ?? '',
        data: json['data'] != null ? fromJson(json['data']) : null,
      );
    }
  }
  //-------------------------------Brand create --------------------------------------------------------------
  class BrandResponse {
    final String message;
    final Brand? brand;
    BrandResponse({
      required this.message,
      this.brand,
    });
    factory BrandResponse.fromJson(Map<String, dynamic> json) {
      return BrandResponse(
        message: json['message'] ?? '',
        brand: json['brand'] != null
            ? Brand.fromJson(json['brand'])
            : null,
      );
    }
  }
  //------------------------------------ Unit create------------------------------------------------------------------------
  class UnitResponse {
    final String message;
    final Unit? unit;
  
    UnitResponse({
      required this.message,
      this.unit,
    });
    factory UnitResponse.fromJson(Map<String, dynamic> json) {
      return UnitResponse(
        message: json['message'] ?? '',
        unit: json['data'] != null ? Unit.fromJson(json['data']) : null,
      );
    }
  }
  //-----------------------------------unit list ----------------------------------------------------------------------
  class UnitListResponse {
  
    final bool status;
    final String message;
    final int count;
    final List<Unit> units;
  
    UnitListResponse({
      required this.status,
      required this.message,
      required this.count,
      required this.units,
    });
  
    factory UnitListResponse.fromJson(Map<String, dynamic> json) {
      List<Unit> unitList = [];
  
      if (json['data'] != null) {
        unitList = (json['data'] as List)
            .map((e) => Unit.fromJson(e))
            .toList();
      }
      return UnitListResponse(
        status: json['status'] ?? false,
        message: json['message'] ?? '',
        count: json['count'] ?? 0,
        units: unitList,
      );
    }
  }
  //----------------------------------------- unit update -----------------------------------------------------------------------
  class UnitUpdateResponse {
    final String message;
    final Unit? unit;
    UnitUpdateResponse({
      required this.message,
      this.unit,
    });
    factory UnitUpdateResponse.fromJson(Map<String, dynamic> json) {
      return UnitUpdateResponse(
        message: json["message"] ?? "",
        unit: json["data"] != null
            ? Unit.fromJson(json["data"])
            : null,
      );
    }
  }
  //----------------------------------------- product create -------------------------------------------------------------------
  class ProductResponse {
    final String status;
    final Product product;
  
    ProductResponse({
      required this.status,
      required this.product,
    });
  
    factory ProductResponse.fromJson(Map<String, dynamic> json) {
      return ProductResponse(
        status: json['status'] ?? '',
        product: Product.fromJson(json['product']),
      );
    }
  }
  
  //---------------------------------------role create //-----------------------------------------------------------------------
  class RoleResponse {
  
    final String message;
    final Role? role;
  
    RoleResponse({
      required this.message,
      this.role,
    });
    factory RoleResponse.fromJson(Map<String, dynamic> json) {
      return RoleResponse(
        message: json['message'] ?? '',
        role: json['data'] != null ? Role.fromJson(json['data']) : null,
      );
    }
  }
  //--------------------------------------- roll list //------------------------------------------------------------------------
  class RoleListResponse {
    final String message;
    final List<Role> roles;
    RoleListResponse({
      required this.message,
      required this.roles,
    });
    factory RoleListResponse.fromJson(Map<String, dynamic> json) {
      List list = json['data'] ?? [];
      return RoleListResponse(
        message: json['message'] ?? '',
        roles: list.map((e) => Role.fromJson(e)).toList(),
      );
    }
  }
  //---------------------------------------login ------------------------------------------------------------------------------
  //---------------------------------------login ------------------------------------------------------------------------------
  // lib/models/login_model.dart (तुमच्या model मध्ये)
  
  // 📍 File: lib/models/login_model.dart

  // lib/api/api_response.dart

  class LoginResponse {
    final String message;
    final String accessToken;
    final String refreshToken;
    final LoginUser user;
    final bool fcmTokenSaved; // ✅ Add this field

    LoginResponse({
      required this.message,
      required this.accessToken,
      required this.refreshToken,
      required this.user,
      this.fcmTokenSaved = false, // ✅ Default false
    });

    factory LoginResponse.fromJson(Map<String, dynamic> json) {
      return LoginResponse(
        message: json['message'] ?? '',
        accessToken: json['access_token'] ?? '',
        refreshToken: json['refresh_token'] ?? '',
        user: LoginUser.fromJson(json['user'] ?? {}),
        fcmTokenSaved: json['fcm_token_saved'] ?? false, // ✅ Parse from response
      );
    }
  }

  class LoginUser {
    final int id;
    final String username;
    final String email;
    final String role;
    final String? referralCode; // ✅ Added this field
    final String? phoneNumber;  // Optional field

    LoginUser({
      required this.id,
      required this.username,
      required this.email,
      required this.role,
      this.referralCode,
      this.phoneNumber,
    });

    factory LoginUser.fromJson(Map<String, dynamic> json) {
      return LoginUser(
        id: json['id'] ?? 0,
        username: json['username'] ?? '',
        email: json['email'] ?? '',
        role: json['role'] ?? '',
        referralCode: json['referral_code'] ?? json['referralCode'], // ✅ Try both formats
        phoneNumber: json['phone_number'] ?? json['phoneNumber'],
      );
    }
  }
  //------------------------------- role--------------------------------------------------------------
  class UserRole {
    final int id;
    final String roleName;
    UserRole({
      required this.id,
      required this.roleName,
    });
    factory UserRole.fromJson(Map<String, dynamic> json) {
      return UserRole(
        id: json['id'],
        roleName: json['role_name'],
      );
    }
  }
  class Tokens {
    final String refresh;
    final String access;
  
    Tokens({
      required this.refresh,
      required this.access,
    });
  
    factory Tokens.fromJson(Map<String, dynamic> json) {
      return Tokens(
        refresh: json['refresh'],
        access: json['access'],
      );
    }
  }
  //---------------------------------------role update-------------------------------------------------------------------
  class RoleUpdateResponse {
  
    final String message;
  
    RoleUpdateResponse({
      required this.message,
    });
  
    factory RoleUpdateResponse.fromJson(Map<String,dynamic> json){
  
      return RoleUpdateResponse(
        message: json["message"] ?? "",
      );
  
    }
  
  }
  //---------------------------------------admin create------------------------------------------------------------------------------
  class AdminCreateResponse {
    final dynamic status; // 🔥 change
    final String message;
    final AdminUser user;
  
    AdminCreateResponse({
      required this.status,
      required this.message,
      required this.user,
    });
  
    factory AdminCreateResponse.fromJson(Map<String, dynamic> json) {
      return AdminCreateResponse(
        status: json['status'],
        message: json['message'] ?? '',
        user: AdminUser.fromJson(json['user'] ?? {}),
      );
    }
  }
  
  class AdminUser {
    final int userId;
    final String username;
    final String name;
    final String email;
    final String? phoneNumber; // 🔥 nullable
  
    AdminUser({
      required this.userId,
      required this.username,
      required this.name,
      required this.email,
      this.phoneNumber,
    });
  
    factory AdminUser.fromJson(Map<String, dynamic> json) {
      return AdminUser(
        userId: json['user_id'] ?? 0,
        username: json['username'] ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        phoneNumber: json['phone_number'], // null allowed
      );
    }
  }
  //---------------------------------------category create//----------------------------------------------------------------------
  class CategoryResponse {
    final bool status;
    final String message;
    final Category? data;
  
    CategoryResponse({
      required this.status,
      required this.message,
      this.data,
    });
    factory CategoryResponse.fromJson(Map<String, dynamic> json) {
      return CategoryResponse(
        status: json['status'] ?? false,
        message: json['message'] ?? '',
        data: json['data'] != null ? Category.fromJson(json['data']) : null,
      );
    }
  }
  //--------------------------------category all ---------------------------------------------------------------------------------
  /*class CategoryAllResponse {
  
    final bool status;
    final String message;
    final List<CategoryAllModel> data;
  
    CategoryAllResponse({
      required this.status,
      required this.message,
      required this.data,
    });
  
    factory CategoryAllResponse.fromJson(Map<String, dynamic> json) {
  
      List<CategoryAllModel> list = [];
  
      if (json['data'] != null) {
  
        list = (json['data'] as List)
            .map((e) => CategoryAllModel.fromJson(e))
            .toList();
  
      }
  
      return CategoryAllResponse(
        status: json['status'],
        message: json['message'],
        data: list,
      );
  
    }
  }*/
  
  class CategoryAllResponse {
  
    final bool status;
    final String message;
    final List<CategoryAllModel> data;
  
    CategoryAllResponse({
      required this.status,
      required this.message,
      required this.data,
    });
  
    factory CategoryAllResponse.fromJson(Map<String, dynamic> json) {
  
      List<CategoryAllModel> categoryList = [];
  
      if (json['data'] != null) {
  
        categoryList = (json['data'] as List)
            .map((e) => CategoryAllModel.fromJson(e))
            .toList();
  
      }
  
      return CategoryAllResponse(
        status: json['status'],
        message: json['message'],
        data: categoryList,
      );
    }
  }
  //--------------------------------------category list----------------------------------------------------------------------------
  class CategoryListResponse {
    final List<Category> categories;
    CategoryListResponse({required this.categories});
    factory CategoryListResponse.fromJson(Map<String, dynamic> json) {
      List list = json['data'] ?? [];
      return CategoryListResponse(
        categories: list.map((e) => Category.fromJson(e)).toList(),
      );
    }
  }
  //-----------------------------------category update------------------------------------------------------------
  class CategoryUpdateResponse {
  
    final bool status;
    final String message;
    final Category? data;
    CategoryUpdateResponse({
      required this.status,
      required this.message,
      this.data,
    });
    factory CategoryUpdateResponse.fromJson(Map<String, dynamic> json) {
      return CategoryUpdateResponse(
        status: json["status"],
        message: json["message"],
        data: json["data"] != null
            ? Category.fromJson(json["data"])
            : null,
      );
    }
  }
  //---------------------------------------category delete-------------------------------------------------------
  class CategoryDeleteResponse {
    final bool status;
    final String message;
    CategoryDeleteResponse({
      required this.status,
      required this.message,
    });
    factory CategoryDeleteResponse.fromJson(Map<String, dynamic> json) {
      return CategoryDeleteResponse(
        status: json["status"] ?? false,
        message: json["message"] ?? "",
      );
    }
  }
  //--------------------------------------send otp passwort forget--------------------------------------
  class SendOtpResponse {
    final String status;
    final String msg;
  
    SendOtpResponse({required this.status, required this.msg});
  
    factory SendOtpResponse.fromJson(Map<String, dynamic> json) {
      return SendOtpResponse(
        status: json['status'] ?? '',
        msg: json['msg'] ?? json['message'] ?? '',
      );
    }
  }
  //--------------------------------------verify otp password forget--------------------------------------
  class VerifyOtpResponse {
    final String status;
    final String msg;
    final int userId;
  
    VerifyOtpResponse({
      required this.status,
      required this.msg,
      required this.userId,
    });
  
    factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
      return VerifyOtpResponse(
        status: json['status'] ?? '',
        msg: json['msg'] ?? json['message'] ?? '',
        userId: json['user_id'] ?? 0,
      );
    }
  }
  //--------------------------------------reset password----------------------------------------------------------------------------
  class ResetPasswordResponse {
    final String status;
    final String msg;
  
    ResetPasswordResponse({required this.status, required this.msg});
  
    factory ResetPasswordResponse.fromJson(Map<String, dynamic> json) {
      return ResetPasswordResponse(
        status: json['status'] ?? '',
        msg: json['msg'] ?? json['message'] ?? '',
      );
    }
  }
  //-----------------------------------------user enquiry--------------------------------------------------------------
  class UserEnquiryResponse {
  
    final bool status;
    final String message;
    final List<UserEnquiry> enquiries;
    UserEnquiryResponse({
      required this.status,
      required this.message,
      required this.enquiries,
    });
    factory UserEnquiryResponse.fromJson(Map<String, dynamic> json) {
      List<UserEnquiry> list = [];
      if (json["data"] != null) {
  
        list = (json["data"] as List)
            .map((e) => UserEnquiry.fromJson(e))
            .toList();
      }
      return UserEnquiryResponse(
        status: json["status"],
        message: json["message"],
        enquiries: list,
      );
    }
  }
  //----------------------------------offer list-------------------------------------------------------------------------------
  class OfferListResponse {
    final String? message;
    final List<OfferModel> data;
  
    OfferListResponse({this.message, required this.data});
  
    factory OfferListResponse.fromJson(Map<String, dynamic> json) {
      return OfferListResponse(
        message: json['message'],
        data: (json['data'] as List)
            .map((e) => OfferModel.fromJson(e))
            .toList(),
      );
    }
  }
  //---------------------------------offer list update------------------------------------------------------------------------
  class OfferUpdateResponse {
    String? message;
    Map<String, dynamic>? data;
    OfferUpdateResponse({
      this.message,
      this.data,
    });
    factory OfferUpdateResponse.fromJson(Map<String, dynamic> json) {
      return OfferUpdateResponse(
        message: json["message"],
        data: json["data"],
      );
    }
  }
  //------------------------------------------single offer---------------------------------------------------------------------
  class SingleOfferResponse {
    String? message;
    SingleOfferModel? data;
    SingleOfferResponse({
      this.message,
      this.data,
    });
    factory SingleOfferResponse.fromJson(Map<String, dynamic> json) {
      return SingleOfferResponse(
        message: json["message"],
        data: json["data"] != null
            ? SingleOfferModel.fromJson(json["data"])
            : null,
      );
    }
  }
  //--------------------------------offer delete--------------------------------------------------------------------
  class OfferDeleteResponse {
  
    String? message;
    OfferDeleteResponse({this.message});
    factory OfferDeleteResponse.fromJson(Map<String,dynamic> json){
      return OfferDeleteResponse(
        message: json["message"],
      );
    }
  }
  //-------------------------------------------enquiry list------------------------------------------------------------------
  class EnquiryListResponse {
    bool? status;
    String? message;
    List<EnquiryListModel>? data;
    EnquiryListResponse({this.status, this.message, this.data});
    factory EnquiryListResponse.fromJson(Map<String, dynamic> json) {
      return EnquiryListResponse(
        status: json['status'],
        message: json['message'],
        data: (json['data'] as List)
            .map((e) => EnquiryListModel.fromJson(e))
            .toList(),
      );
    }
  }
  
  
  
  //-------------------------------------company pending-----------------------------------------------------------------------
  class CompanyPendingResponse {
  
    bool? status;
    String? message;
    List<CompanyPendingModel>? data;
  
    CompanyPendingResponse({
      this.status,
      this.message,
      this.data,
    });
  
    factory CompanyPendingResponse.fromJson(Map<String, dynamic> json) {
  
      return CompanyPendingResponse(
  
        status: json['status'],
        message: json['message'],
  
        data: (json['data'] as List)
            .map((e) => CompanyPendingModel.fromJson(e))
            .toList(),
      );
    }
  }
  
  
  class CompanyAllResponse {
  
    final bool status;
    final String message;
    final List<CompanyAllModel> data;
  
    CompanyAllResponse({
      required this.status,
      required this.message,
      required this.data,
    });
  
    factory CompanyAllResponse.fromJson(Map<String, dynamic> json) {
  
      List<CompanyAllModel> list = [];
  
      if (json['data'] != null) {
        list = (json['data'] as List)
            .map((e) => CompanyAllModel.fromJson(e))
            .toList();
      }
  
      return CompanyAllResponse(
        status: json['status'],
        message: json['message'],
        data: list,
      );
    }
  }
  //---------------------------------------company soft delete-------------------------------------------------------------------
  class CompanySoftDeleteResponse {
  
    final String message;
  
    CompanySoftDeleteResponse({
      required this.message,
    });
  
    factory CompanySoftDeleteResponse.fromJson(Map<String, dynamic> json) {
  
      return CompanySoftDeleteResponse(
        message: json["message"] ?? "",
      );
  
    }
  
  }
  //--------------------------------------company restore-----------------------------------------------------------------------
  class CompanyRestoreResponse {
  
    final String message;
  
    CompanyRestoreResponse({
      required this.message,
    });
  
    factory CompanyRestoreResponse.fromJson(Map<String, dynamic> json) {
  
      return CompanyRestoreResponse(
        message: json["message"] ?? "",
      );
  
    }
  
  }
  //-------------------------------------sub category---------------------------------------------------------------------------
  
  class SubCategoryResponse {
  
    final bool status;
    final String message;
    final List<SubCategoryModel> data;
  
    SubCategoryResponse({
      required this.status,
      required this.message,
      required this.data,
    });
  
    factory SubCategoryResponse.fromJson(Map<String, dynamic> json) {
  
      List list = json["data"] ?? [];
  
      return SubCategoryResponse(
  
        status: json["status"],
        message: json["message"],
        data: list.map((e) => SubCategoryModel.fromJson(e)).toList(),
  
      );
    }
  }
  //-------------------------------------------pending product----------------------------------------------
  
  
  class PendingProductResponse {
  
    final bool status;
    final String message;
    final int count;
    final List<PendingProductModel> data;
  
    PendingProductResponse({
      required this.status,
      required this.message,
      required this.count,
      required this.data,
    });
  
    factory PendingProductResponse.fromJson(Map<String, dynamic> json) {
  
      List list = json["data"] ?? [];
  
      return PendingProductResponse(
        status: json["status"] ?? false,
        message: json["message"] ?? "",
        count: json["count"] ?? 0,
        data: list.map((e) => PendingProductModel.fromJson(e)).toList(),
      );
    }
  }
  //--------------------------------product approve-------------------------------------------------
  class ProductApproveResponse {
  
    final bool status;
    final String message;
  
    ProductApproveResponse({
      required this.status,
      required this.message,
    });
  
    factory ProductApproveResponse.fromJson(Map<String, dynamic> json) {
  
      return ProductApproveResponse(
        status: json["status"] ?? false,
        message: json["message"] ?? "",
      );
  
    }
  
  }
  //-----------------------------------------reject product------------------------------------------------------------------------
  class RejectProductResponse {
  
    final bool status;
    final String message;
  
    RejectProductResponse({
      required this.status,
      required this.message,
    });
  
    factory RejectProductResponse.fromJson(Map<String, dynamic> json) {
  
      return RejectProductResponse(
  
        status: json["status"] ?? false,
        message: json["message"] ?? "",
  
      );
  
    }
  
  }
  
  //------------------------------role detail -------------------------------------------------------------------------------------
  class RoleDetailResponse {
  
    final String message;
    final RoleDetailModel? role;
  
    RoleDetailResponse({
      required this.message,
      this.role,
    });
  
    factory RoleDetailResponse.fromJson(Map<String, dynamic> json) {
  
      return RoleDetailResponse(
        message: json['message'] ?? "",
        role: json['data'] != null
            ? RoleDetailModel.fromJson(json['data'])
            : null,
      );
  
    }
  
  }
  
  //-------------------------------------------------------dashboard cards response-------------------------------------------------
  class DashboardResponse {
    final CompanyCountModel company;
    final ProductCountModel product;
  
    DashboardResponse({
      required this.company,
      required this.product,
    });
  }
  
  //------------------------------------agriment re---------------------------------------------------------------------

  

  
  //--------------------registration otp-----------------------------------------------------------------------------
  class RegistrationSendOtpResponse {
    final String message;
    RegistrationSendOtpResponse({required this.message});
    factory RegistrationSendOtpResponse.fromJson(Map<String, dynamic> json) {
      return RegistrationSendOtpResponse(
        message: json['message'] ?? '',
      );
    }
  }
  //-----------------------verify registration otp-------------------------------------------------------------------
  class RegistrationVerifyOtpResponse {
    final String message;
    RegistrationVerifyOtpResponse({required this.message});
    factory RegistrationVerifyOtpResponse.fromJson(Map<String, dynamic> json) {
      return RegistrationVerifyOtpResponse(
        message: json['message'] ?? '',
      );
    }
  }
  
  //----------------------admin register create------------------------------------------------------
  class RegisterResponse {
    final String message;
    RegisterResponse({required this.message});
    factory RegisterResponse.fromJson(Map<String, dynamic> json) {
      return RegisterResponse(
        message: json['message'] ?? '',
      );
    }
  }
  //------------------------------all user list----------------------------------------------------
  class UserListResponse {
    final String status;
    final List<userModel.User> data; // ✅ using prefixed User
  
    UserListResponse({required this.status, required this.data});
  
    factory UserListResponse.fromJson(Map<String, dynamic> json) {
      final List<dynamic> list = json['data'] ?? [];
      return UserListResponse(
        status: json['status'] ?? '',
        data: list.map((e) => userModel.User.fromJson(e)).toList(),
      );
    }
  }
  
  
  
  //----------------agrimrnt company list----------------------------------------------------
  class AgreementCompanyResponse {
    final bool status;
    final String message;
    final List<AgreementCompanyModel> data;
  
    AgreementCompanyResponse({
      required this.status,
      required this.message,
      required this.data,
    });
  
    factory AgreementCompanyResponse.fromJson(Map<String, dynamic> json) {
      final List list = json['data'] ?? [];
      return AgreementCompanyResponse(
        status: json['status'] ?? false,
        message: json['message'] ?? '',
        data: list.map((e) => AgreementCompanyModel.fromJson(e)).toList(),
      );
    }
  }
  
  //-----------------------------agreement product -------------------------------------------------------------
  class AgreementProductResponse {
    final String status;
    final List<AgreementProductModel> data;
  
    AgreementProductResponse({
      required this.status,
      required this.data,
    });
  
    factory AgreementProductResponse.fromJson(Map<String, dynamic> json) {
      final List list = json['data'] ?? [];
      return AgreementProductResponse(
        status: json['status'] ?? '',
        data: list.map((e) => AgreementProductModel.fromJson(e)).toList(),
      );
    }
  }
  
  //-----------------------company_product_enquiry_response-------------------------------------------------------------
  
  class PendingEnquiryResponse {
    final bool status;
    final String message;
    final int count;
    final List<PendingEnquiry> data;
  
    PendingEnquiryResponse({
      required this.status,
      required this.message,
      required this.count,
      required this.data,
    });
  
    factory PendingEnquiryResponse.fromJson(Map<String, dynamic> json) {
      final List<dynamic> list = json['data'] ?? [];
      return PendingEnquiryResponse(
        status: json['status'] ?? false,
        message: json['message'] ?? '',
        count: json['count'] ?? 0,
        data: list.map((e) => PendingEnquiry.fromJson(e)).toList(),
      );
    }
  }
  
  
  //-----------------------------------send button response -----------------------------------------------------
  class SendEnquiryResponse {
    final bool status;
    final String message;
  
    SendEnquiryResponse({required this.status, required this.message});
  
    factory SendEnquiryResponse.fromJson(Map<String, dynamic> json) {
      return SendEnquiryResponse(
        status: json['status'] ?? false,
        message: json['message'] ?? '',
      );
    }
  }
  //------------------------------partner_companies_response------------------------------------------------
  
  
  
  class PartnerCompaniesResponse {
    final bool status;
    final int partnerId;
    final String partnerName;
    final String partnerReferralCode;
    final int totalCompanies;
    final List<PartnerCompany> data;
  
    PartnerCompaniesResponse({
      required this.status,
      required this.partnerId,
      required this.partnerName,
      required this.partnerReferralCode,
      required this.totalCompanies,
      required this.data,
    });
  
    factory PartnerCompaniesResponse.fromJson(Map<String, dynamic> json) {
      final List list = json['data'] ?? [];
      return PartnerCompaniesResponse(
        status: json['status'] ?? false,
        partnerId: json['partner_id'] ?? 0,
        partnerName: json['partner_name'] ?? '',
        partnerReferralCode: json['partner_referral_code'] ?? '',
        totalCompanies: json['total_companies'] ?? 0,
        data: list.map((e) => PartnerCompany.fromJson(e)).toList(),
      );
    }
  }
  
  //-------------------------------------bank_details_response--------------------------------------------------
  
  class BankDetailsResponse {
    final bool status;
    final String message;
    final BankDetailsData? data;
  
    BankDetailsResponse({
      required this.status,
      required this.message,
      this.data,
    });
  
    factory BankDetailsResponse.fromJson(Map<String, dynamic> json) {
      return BankDetailsResponse(
        status: json['status'] ?? false,
        message: json['message'] ?? '',
        data: json['data'] != null ? BankDetailsData.fromJson(json['data']) : null,
      );
    }
  }

  class BankDetailsData {
    final int id;
    final String accountHolderName;
    final String bankName;
    final String branchName;
    final String accountNumber;
    final String ifscCode;
    final String accountType;
    final String? upiId;
    final String createdAt;
    final int marketingPartner;

    BankDetailsData({
      required this.id,
      required this.accountHolderName,
      required this.bankName,
      required this.branchName,
      required this.accountNumber,
      required this.ifscCode,
      required this.accountType,
      this.upiId,
      required this.createdAt,
      required this.marketingPartner,
    });

    factory BankDetailsData.fromJson(Map<String, dynamic> json) {
      return BankDetailsData(
        id: json['id'] ?? 0,
        accountHolderName: json['account_holder_name'] ?? '',
        bankName: json['bank_name'] ?? '',
        branchName: json['branch_name'] ?? '',
        accountNumber: json['account_number'] ?? '',
        ifscCode: json['ifsc_code'] ?? '',
        accountType: json['account_type'] ?? '',
        upiId: json['upi_id'],
        createdAt: json['created_at'] ?? '',
        marketingPartner: json['marketing_partner'] ?? 0,
      );
    }

    Map<String, dynamic> toJson() {
      return {
        'id': id,
        'account_holder_name': accountHolderName,
        'bank_name': bankName,
        'branch_name': branchName,
        'account_number': accountNumber,
        'ifsc_code': ifscCode,
        'account_type': accountType,
        'upi_id': upiId,
        'created_at': createdAt,
        'marketing_partner': marketingPartner,
      };
    }
  }

  class RetrieveBankDetailsResponse {
    final bool status;
    final String message;
    final BankDetailsData? data;

    RetrieveBankDetailsResponse({
      required this.status,
      required this.message,
      this.data,
    });

    factory RetrieveBankDetailsResponse.fromJson(Map<String, dynamic> json) {
      return RetrieveBankDetailsResponse(
        status: json['status'] ?? false,
        message: json['message'] ?? '',
        data: json['data'] != null
            ? BankDetailsData.fromJson(json['data'])
            : null,
      );
    }
  }
  
  //-------------------------------------bank_detail_response------------------------------------------
  
  
  class BankDetailResponse {
    final bool status;
    final String message;
    final List<BankDetail> data;
  
    BankDetailResponse({
      required this.status,
      required this.message,
      required this.data,
    });
  
    factory BankDetailResponse.fromJson(Map<String, dynamic> json) {
      final List list = json['data'] is List ? json['data'] : [json['data']];
      return BankDetailResponse(
        status: json['status'] ?? false,
        message: json['message'] ?? '',
        data: list.map((e) => BankDetail.fromJson(e)).toList(),
      );
    }
  }
  //-------------------------class ApprovedEnquiryResponse ----------------------------------------------------
  class ApprovedEnquiryResponse {
    final bool status;
    final List<ApprovedEnquiry> data;
  
    ApprovedEnquiryResponse({
      required this.status,
      required this.data,
    });
  
    factory ApprovedEnquiryResponse.fromJson(Map<String, dynamic> json) {
      final List list = json['data'] ?? [];
      return ApprovedEnquiryResponse(
        status: json['status'] ?? false,
        data: list.map((e) => ApprovedEnquiry.fromJson(e)).toList(),
      );
    }
  }
  
  //-------------------------------------franchise_response----------------------------------------
  
  // lib/models/franchise_response.dart
  
  
  class FranchiseListResponse {
    final String status;
    final String message;
    final int total;
    final List<Franchise> data;
  
    FranchiseListResponse({
      required this.status,
      required this.message,
      required this.total,
      required this.data,
    });
  
    factory FranchiseListResponse.fromJson(Map<String, dynamic> json) {
      List<Franchise> franchiseList = [];
  
      if (json['data'] != null && json['data'] is List) {
        franchiseList = (json['data'] as List)
            .map((e) => Franchise.fromJson(e))
            .toList();
      }
  
      return FranchiseListResponse(
        status: json['status'] ?? '',
        message: json['message'] ?? '',
        total: json['total'] ?? 0,
        data: franchiseList,
      );
    }
  
    Map<String, dynamic> toJson() {
      return {
        'status': status,
        'message': message,
        'total': total,
        'data': data.map((e) => e.toJson()).toList(),
      };
    }
  }
  
  //-----------------------approved_marketing_partners-----------------------------------------------------
  
  // Approved Marketing Partner Count Response
  class ApprovedMarketingPartnerCountResponse {
    final bool status;
    final String message;
    final int count;
  
    ApprovedMarketingPartnerCountResponse({
      required this.status,
      required this.message,
      required this.count,
    });
  
    factory ApprovedMarketingPartnerCountResponse.fromJson(Map<String, dynamic> json) {
      return ApprovedMarketingPartnerCountResponse(
        status: json['status'] ?? false,
        message: json['message'] ?? '',
        count: json['count'] ?? 0,
      );
    }
  }
  
  // Approved Marketing Partner List Response
  class ApprovedMarketingPartnerListResponse {
    final bool status;
    final String message;
    final int count;
    final List<ApprovedMarketingPartner> data;
  
    ApprovedMarketingPartnerListResponse({
      required this.status,
      required this.message,
      required this.count,
      required this.data,
    });
  
    factory ApprovedMarketingPartnerListResponse.fromJson(Map<String, dynamic> json) {
      List<ApprovedMarketingPartner> partnerList = [];
      if (json['data'] != null && json['data'] is List) {
        partnerList = (json['data'] as List)
            .map((e) => ApprovedMarketingPartner.fromJson(e))
            .toList();
      }
      return ApprovedMarketingPartnerListResponse(
        status: json['status'] ?? false,
        message: json['message'] ?? '',
        count: json['count'] ?? 0,
        data: partnerList,
      );
    }
  }
  
  // Approved Marketing Partner Model
  class ApprovedMarketingPartner {
    final int id;
    final String referralCode;
    final String referralLink;
    final String? referredByName;
    final String? referredByReferralCode;
    final String applicationType;
    final bool otpVerified;
    final String fullName;
    final String email;
    final String mobile;
    final String? profileImage;
    final String state;
    final String district;
    final String taluka;
    final String village;
    final String pincode;
    final String workingArea;
    final String profession;
    final String experience;
    final List<String> promotionPlatforms;
    final int teamSize;
    final String status;
    final String createdAt;
    final int? user;
    final int? referredBy;
  
    ApprovedMarketingPartner({
      required this.id,
      required this.referralCode,
      required this.referralLink,
      this.referredByName,
      this.referredByReferralCode,
      required this.applicationType,
      required this.otpVerified,
      required this.fullName,
      required this.email,
      required this.mobile,
      this.profileImage,
      required this.state,
      required this.district,
      required this.taluka,
      required this.village,
      required this.pincode,
      required this.workingArea,
      required this.profession,
      required this.experience,
      required this.promotionPlatforms,
      required this.teamSize,
      required this.status,
      required this.createdAt,
      this.user,
      this.referredBy,
    });
  
    factory ApprovedMarketingPartner.fromJson(Map<String, dynamic> json) {
      List<String> platforms = [];
      if (json['promotion_platforms'] != null && json['promotion_platforms'] is List) {
        platforms = (json['promotion_platforms'] as List)
            .map((e) => e.toString())
            .toList();
      }
  
      return ApprovedMarketingPartner(
        id: json['id'] ?? 0,
        referralCode: json['referral_code'] ?? '',
        referralLink: json['referral_link'] ?? '',
        referredByName: json['referred_by_name'],
        referredByReferralCode: json['referred_by_referral_code'],
        applicationType: json['application_type'] ?? '',
        otpVerified: json['otp_verified'] ?? false,
        fullName: json['full_name'] ?? '',
        email: json['email'] ?? '',
        mobile: json['mobile'] ?? '',
        profileImage: json['profile_image'],
        state: json['state'] ?? '',
        district: json['district'] ?? '',
        taluka: json['taluka'] ?? '',
        village: json['village'] ?? '',
        pincode: json['pincode'] ?? '',
        workingArea: json['working_area'] ?? '',
        profession: json['profession'] ?? '',
        experience: json['experience'] ?? '',
        promotionPlatforms: platforms,
        teamSize: json['team_size'] ?? 0,
        status: json['status'] ?? '',
        createdAt: json['created_at'] ?? '',
        user: json['user'],
        referredBy: json['referred_by'],
      );
    }
  }



  // ✅ Agreement Percentage Update Response
  class AgreementPercentageUpdateResponse {
    final bool status;
    final String message;
    final AgreementPercentageData? data;

    AgreementPercentageUpdateResponse({
      required this.status,
      required this.message,
      this.data,
    });

    factory AgreementPercentageUpdateResponse.fromJson(Map<String, dynamic> json) {
      return AgreementPercentageUpdateResponse(
        status: json['status'] ?? false,
        message: json['message'] ?? '',
        data: json['data'] != null
            ? AgreementPercentageData.fromJson(json['data'])
            : null,
      );
    }
  }

  class AgreementPercentageData {
    final int agreementId;
    final double profitSharePercentage;
    final double sellingCommissionPercentage;

    AgreementPercentageData({
      required this.agreementId,
      required this.profitSharePercentage,
      required this.sellingCommissionPercentage,
    });

    factory AgreementPercentageData.fromJson(Map<String, dynamic> json) {
      return AgreementPercentageData(
        agreementId: json['agreement_id'] ?? 0,
        profitSharePercentage: (json['profit_share_percentage'] ?? 0).toDouble(),
        sellingCommissionPercentage: (json['selling_commission_percentage'] ?? 0).toDouble(),
      );
    }
  }


  //----------------------------update_bank_details_response---------------------------------------



  /// Response model for updating bank details
  class UpdateBankDetailsResponse {
    final bool status;
    final String message;
    final BankDetailsData? data;

    UpdateBankDetailsResponse({
      required this.status,
      required this.message,
      this.data,
    });

    factory UpdateBankDetailsResponse.fromJson(Map<String, dynamic> json) {
      return UpdateBankDetailsResponse(
        status: json['status'] ?? false,
        message: json['message'] ?? '',
        data: json['data'] != null
            ? BankDetailsData.fromJson(json['data'])
            : null,
      );
    }
  }