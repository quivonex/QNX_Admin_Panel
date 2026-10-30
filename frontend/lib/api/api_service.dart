import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_url.dart';
import '../models/qnx_admin/packing_material_enquiry_model.dart';

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../api/api_response.dart';
import '../models/channel_partner/channel_partner_enquiry_model.dart';
import '../models/marketing_partner/marketing_agreement_model.dart';
import '../models/qnx_admin/bank_details_request.dart';
import '../models/qnx_admin/complete_enquiry_count_model.dart';
import '../models/qnx_admin/google_subscription_plan_model.dart';
import '../models/qnx_admin/packing_video_model.dart';
import '../models/qnx_admin/paid_unpaid_enquiry_model.dart';
//import '../screens/marketing_partner/marketing_agreement_model.dart';
import 'api_url.dart';
import 'dart:typed_data';
import '../models/qnx_admin/company_model.dart';
import '../models/qnx_admin/brand_model.dart';
import '../models/qnx_admin/unit_model.dart';
import '../models/qnx_admin/product_model.dart';
import '../models/qnx_admin/login_model.dart';
import '../models/qnx_admin/role_model.dart';
import '../models/qnx_admin/admin_create_model.dart';
import '../models/qnx_admin/category_model.dart';
import '../models/qnx_admin/user_enquiry_model.dart';
import '../models/qnx_admin/offer_model.dart';
import '../../models/qnx_admin/paid_company_model.dart';
import '../models/qnx_admin/enquiry_list_model.dart';
import '../models/qnx_admin/company_pending_model.dart';
import '../models/qnx_admin/agreement_model.dart'
    hide AgreementProductResponse, AgreementCompanyResponse;import '../models/qnx_admin/user_model.dart';
import 'package:flutter/foundation.dart' hide Category; // ADD THIS
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/qnx_admin/offer_model.dart';   // फक्त हेच ठेवा
import '../models/qnx_admin/update_request_model.dart';
import '../models/qnx_admin/update_request_model.dart';
import '../models/qnx_admin/amount_update_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api/api_url.dart';
import '../models/qnx_admin/marketing_head_model.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api/api_url.dart';
import '../models/qnx_admin/marketing_partner_model.dart';
import '../models/qnx_admin/marketing_head_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api/api_url.dart';
import '../models/qnx_admin/referral_partner_model.dart';
import '../models/qnx_admin/approved_enquiry_model.dart' hide ApprovedEnquiryResponse;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/qnx_admin/pending_withdraw_model.dart';
import '../models/qnx_admin/payment_qr_model.dart';
import '../models/qnx_admin/payment_withdraw_model.dart';
import '../models/qnx_admin/payment_qr_model.dart';        // ✅ हे import add करा
import '../models/qnx_admin/pending_withdraw_model.dart';
import '../models/qnx_admin/banner_model.dart';
import '../models/qnx_admin/loan_enquiry_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // ✅ Add this import
import '../models/marketing_head/marketing_profile_model.dart';
import 'marketing_service.dart' show MarketingProfileService;
import '../models/qnx_admin/customer_subscription_plan_model.dart';
import '../models/qnx_admin/boosting_plan_model.dart';


//-------------------------------company create------------------------------------------------------------------------------------
class CompanyService {
  final http.Client _client;

  CompanyService({http.Client? client}) : _client = client ?? http.Client();
  Future<ApiResponse<Company>> createCompany({
    required Company company,
    File? logoImage,
    Uint8List? webImage,
    String? webImageName,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiUrls.companyCreate),
      );
      // Convert company to JSON and add each field properly
      company.toJson().forEach((key, value) {
        if (value == null) return;
        // ✅ If List or Map → send as proper JSON string
        if (value is List || value is Map) {
          request.fields[key] = jsonEncode(value);
        }
        // ✅ Normal fields
        else {
          request.fields[key] = value.toString();
        }
      });
      // ✅ Add logo if provided
      if (kIsWeb && webImage != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'logo',
            webImage,
            filename: webImageName ?? 'logo.png',
          ),
        );
      } else if (!kIsWeb && logoImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'logo',
            logoImage.path,
          ),
        );
      }
      // Debug (optional but useful)
      print("FIELDS: ${request.fields}");
      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      var jsonResponse = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse<Company>.fromJson(
          jsonResponse,
              (data) => Company.fromJson(data),
        );
      } else {
        return ApiResponse<Company>(
          status: false,
          message: jsonResponse.toString(),
        );
      }
    } catch (e) {
      return ApiResponse<Company>(
        status: false,
        message: 'Error: ${e.toString()}',
      );
    }
  }
}
//------------------------------- Brand--------------------------------------------------------------------------------------------
class BrandService {
  Future<BrandResponse> createBrand(Brand brand) async {
    final url = Uri.parse(ApiUrls.brandCreate);
    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(brand.toJson()),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return BrandResponse.fromJson(data);
      } else {
        return BrandResponse(message: "Failed to create brand");
      }
    } catch (e) {
      return BrandResponse(message: "Error: $e");
    }
  }
}
//------------------------------- Unit create--------------------------------------------------------------------------------------
class UnitService {
  Future<UnitResponse> createUnit(Unit unit) async {
    final url = Uri.parse(ApiUrls.unitCreate);
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(unit.toJson()),
      );
      final jsonResponse = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return UnitResponse.fromJson(jsonResponse);
      } else {
        return UnitResponse(message: jsonResponse['message'] ?? "Failed to create unit");
      }
    } catch (e) {
      return UnitResponse(message: "Error: $e");
    }
  }
  // -------------------------------UNIT LIST (POST METHOD)------------------------------------------------------------------------
  Future<List<Unit>> getUnits() async {
    final response = await http.post(
      Uri.parse(ApiUrls.unitList),
      headers: {
        "Content-Type": "application/json"
      },
    );
    //print("Status: ${response.statusCode}");
    // print("Body: ${response.body}");
    final data = jsonDecode(response.body);
    UnitListResponse unitResponse =
    UnitListResponse.fromJson(data);
    return unitResponse.units;
  }
}
// -------------------------------unit update--------------------------------------------------------------------------------------
class UnitUpdateService {
  Future<UnitUpdateResponse> updateUnit(UnitUpdateModel model) async {
    final response = await http.post(
      Uri.parse(ApiUrls.updateUnit),
      headers: {
        "Content-Type": "application/json"
      },
      body: jsonEncode(model.toJson()),
    );
    if (response.statusCode == 200) {
      return UnitUpdateResponse.fromJson(jsonDecode(response.body));
    }
    return UnitUpdateResponse(
      message: "Unit update failed",
    );
  }
}
//-------------------------------product create------------------------------------------------------------------------------------
class ProductService {
  final http.Client _client;
  static const int timeoutSeconds = 60;
  ProductService({http.Client? client}) : _client = client ?? http.Client();
  void dispose() {
    _client.close();
  }
  Future<ProductResponse?> createProduct({
    // Required fields
    required int category,
    required int brand,
    required String name,
    required String slug,
    required String description,
    required String price,
    // Optional fields
    String? discountPrice,
    int? unit,
    int? stockQuantity,
    String? productCode,
    String? sku,
    String? voltage,
    String? power,
    String? weight,
    String? dimensions,

    // Files
    File? thumbnailImage,
    Uint8List? webThumbnail,
    String? webThumbnailName,
    List<File>? productImages,
    List<Uint8List>? webImages,
    List<String>? webImageNames,
  }) async {
    try {
      var request = http.MultipartRequest(
          'POST',
          Uri.parse(ApiUrls.productCreate)
      )..headers.addAll({
        'Accept': 'application/json',
      });
      // Add all fields to request
      Map<String, dynamic> productData = {
        'category': category,
        'brand': brand,
        'name': name,
        'slug': slug,
        'description': description,
        'price': price,
      };
      // Add optional fields only if they have values
      if (discountPrice != null && discountPrice.isNotEmpty) {
        productData['discount_price'] = discountPrice;
      }
      if (unit != null) {
        productData['unit'] = unit;
      }
      if (stockQuantity != null) {
        productData['stock_quantity'] = stockQuantity;
      }
      if (productCode != null && productCode.isNotEmpty) {
        productData['product_code'] = productCode;
      }
      if (sku != null && sku.isNotEmpty) {
        productData['sku'] = sku;
      }
      if (voltage != null && voltage.isNotEmpty) {
        productData['voltage'] = voltage;
      }
      if (power != null && power.isNotEmpty) {
        productData['power'] = power;
      }
      if (weight != null && weight.isNotEmpty) {
        productData['weight'] = weight;
      }
      if (dimensions != null && dimensions.isNotEmpty) {
        productData['dimensions'] = dimensions;
      }

      // Add all fields to request
      productData.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      print('📦 Request Fields: ${request.fields}');

      // Add thumbnail if provided
      if (kIsWeb && webThumbnail != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'thumbnail_s3_key',
            webThumbnail,
            filename: webThumbnailName ?? 'thumbnail.png',
            contentType: MediaType('image', _getImageExtension(webThumbnailName)),
          ),
        );
      } else if (!kIsWeb && thumbnailImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'thumbnail_s3_key',
            thumbnailImage.path,
            contentType: MediaType('image', _getFileExtension(thumbnailImage.path)),
          ),
        );
      }
      // Add multiple product images
      if (kIsWeb && webImages != null) {
        for (int i = 0; i < webImages.length; i++) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'images', // Same field name for multiple files
              webImages[i],
              filename: webImageNames?[i] ?? 'product_image_$i.png',
              contentType: MediaType('image', _getImageExtension(webImageNames?[i])),
            ),
          );
        }
      } else if (!kIsWeb && productImages != null) {
        for (File image in productImages) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'images',
              image.path,
              contentType: MediaType('image', _getFileExtension(image.path)),
            ),
          );
        }
      }
      print('📎 Total Files: ${request.files.length}');
      // Send request
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: timeoutSeconds),
        onTimeout: () => throw Exception('Request timeout after $timeoutSeconds seconds'),
      );
      var response = await http.Response.fromStream(streamedResponse);
      // print('📥 Response Status: ${response.statusCode}');
      //print('📥 Response Body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        return ProductResponse.fromJson(jsonResponse);
      } else {
        print('Error Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception: $e');
      return null;
    }
  }
  String _getFileExtension(String path) {
    return path.split('.').last.toLowerCase();
  }
  String _getImageExtension(String? filename) {
    if (filename == null) return 'png';
    return filename.split('.').last.toLowerCase();
  }
  Future<List<Product>> getProducts() async {
    final response = await http.post(
      Uri.parse(ApiUrls.productList),
      headers: {
        "Content-Type": "application/json"
      },
      body: jsonEncode({
        "page": 1,
        "limit": 20
      }),
    );
    // print("Status: ${response.statusCode}");
    // print("Body: ${response.body}");
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List list = data['products'];   // ✅ FIX
      return list.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load products");
    }
  }
}
//-------------------------------Roll create---------------------------------------------------------------------------------------
class RoleService {
  Future<RoleResponse> createRole(Role role) async {
    final url = Uri.parse(ApiUrls.roleCreate);
    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json"
        },
        body: jsonEncode(role.toJson()),
      );
      final jsonResponse = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return RoleResponse.fromJson(jsonResponse);
      } else {
        return RoleResponse(
          message: jsonResponse['message'] ?? "Failed to create role",
        );
      }
    } catch (e) {
      return RoleResponse(
        message: "Error: $e",
      );
    }
  }
//------------------------------- Role list table---------------------------------------------------------------------------------
  Future<List<Role>> getRoles() async {
    try {
      print("🌐 Calling API: ${ApiUrls.roleList}");

      final response = await http.post(
        Uri.parse(ApiUrls.roleList),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({}),
      );

      print("📡 Response Status: ${response.statusCode}");
      print("📦 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // API response structure बघा
        print("🔑 Response Keys: ${jsonResponse.keys}");

        List<Role> roles = [];

        // Different possible structures handle करा
        if (jsonResponse.containsKey('data') && jsonResponse['data'] is List) {
          roles = (jsonResponse['data'] as List)
              .map((e) => Role.fromJson(e))
              .toList();
        }
        else if (jsonResponse.containsKey('roles') && jsonResponse['roles'] is List) {
          roles = (jsonResponse['roles'] as List)
              .map((e) => Role.fromJson(e))
              .toList();
        }
        else if (jsonResponse.containsKey('results') && jsonResponse['results'] is List) {
          roles = (jsonResponse['results'] as List)
              .map((e) => Role.fromJson(e))
              .toList();
        }

        print("✅ Loaded ${roles.length} roles");
        return roles;
      } else {
        print("❌ Failed to load roles: ${response.statusCode}");
        return []; // Empty list return करा, exception नाही
      }
    } catch (e) {
      print("❌ Exception in getRoles: $e");
      return []; // Exception झाल्यावर empty list
    }
  }
//------------------------------- role list dropdown-------------------------------------------------------------------------------
  Future<List<Role>> fetchRoles() async {
    final response = await http.post(
      Uri.parse(ApiUrls.roleList),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({}), // Empty JSON body
    );
    // print("Status: ${response.statusCode}");
    //print("Body: ${response.body}");
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List list = data['data'] ?? [];
      return list.map((e) => Role.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load roles, status: ${response.statusCode}");
    }
  }
}

//------------------------------------role update---------------------------------------------------------------
class RoleUpdateService {

  Future<RoleUpdateResponse> updateRole(RoleUpdateModel model) async {

    final response = await http.post(

      Uri.parse(ApiUrls.roleUpdate),

      headers: {
        "Content-Type": "application/json",
      },

      body: jsonEncode(model.toJson()),

    );

    if(response.statusCode == 200){

      final data = jsonDecode(response.body);

      return RoleUpdateResponse.fromJson(data);

    }else{

      throw Exception("Failed to update role");

    }

  }

}
//---------------------------------role delete--------------------------------------------------------------------
class RoleDeleteService {

  Future<String> deleteRole(RoleDeleteModel model) async {

    final response = await http.post(

      Uri.parse(ApiUrls.roleDelete),

      headers: {
        "Content-Type": "application/json",
      },

      body: jsonEncode(model.toJson()),

    );

    if(response.statusCode == 200){

      final data = jsonDecode(response.body);

      return data["message"];

    }else{

      throw Exception("Delete failed");

    }

  }

}

//-------------------------------login form ---------------------------------------------------------------------------------------

class LoginService {
  Future<LoginResponse> login(LoginModel model) async {
    final response = await http.post(
      Uri.parse(ApiUrls.adminLogin),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(model.toJson()),
    );

    print("📤 Login Request: ${model.toJson()}");
    print("📥 STATUS CODE: ${response.statusCode}");
    print("📦 RESPONSE: ${response.body}");

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return LoginResponse.fromJson(jsonData);
    } else {
      throw Exception("Login Failed: ${response.body}");
    }
  }
}
//------------------------------- Admin create-------------------------------------------------------------------------------------
/*class AdminService {
  Future<AdminCreateResponse> createAdmin(
      AdminCreateModel model) async {
    final response = await http.post(
      Uri.parse(ApiUrls.adminCreate),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(model.toJson()),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonData = jsonDecode(response.body);
      return AdminCreateResponse.fromJson(jsonData);
    } else {
      throw Exception("Admin creation failed");
    }
  }
}*/
//------------------------------- Category create----------------------------------------------------------------------------------
class CategoryService {
  /// Create Category
  Future<CategoryResponse> createCategory(Category category) async {
    try {
      final response = await http.post(
        Uri.parse(ApiUrls.categoryCreate),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(category.toJson()),
      );
      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return CategoryResponse.fromJson(jsonResponse);
      } else {
        return CategoryResponse(
          status: false,
          message: jsonResponse['message'] ?? "Failed to create category",
        );
      }
    } catch (e) {
      return CategoryResponse(status: false, message: "Error: $e");
    }
  }


  /// ------------------------------- Category List (POST method)------------------------------------------------------------------
  Future<List<Category>> getCategories() async {
    try {
      final response = await http.post(
        Uri.parse(ApiUrls.categoryList),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({}),  // API expects POST
      );
      final jsonResponse = jsonDecode(response.body);
      if (response.statusCode == 200) {
        CategoryListResponse listResponse =
        CategoryListResponse.fromJson(jsonResponse);
        return listResponse.categories;
      } else {
        throw Exception("Failed to load categories");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }
}
//------------------------------------category all------------------------------------------------------------------------------
/*
class CategoryAllService {

  Future<CategoryAllResponse> getAllCategories() async {

    final response = await http.post(
      Uri.parse(ApiUrls.categoryAll),
    );

    final data = jsonDecode(response.body);

    return CategoryAllResponse.fromJson(data);

  }

}*/

class CategoryAllService {

  Future<List<CategoryAllModel>> getCategories() async {

    final response = await http.post(
      Uri.parse(ApiUrls.categoryAll),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({}),
    );

    if (response.statusCode == 200) {

      final jsonData = jsonDecode(response.body);

      CategoryAllResponse apiResponse =
      CategoryAllResponse.fromJson(jsonData);

      return apiResponse.data;

    } else {

      throw Exception("Failed to load categories");

    }
  }
}
//----------------------------------------category Update----------------------------------------------------------------------
class CategoryUpdateService {

  Future<CategoryUpdateResponse> updateCategory(
      CategoryUpdateModel model) async {
    final response = await http.post(
      Uri.parse(ApiUrls.update),
      headers: {
        "Content-Type": "application/json"
      },
      body: jsonEncode(model.toJson()),
    );
    if (response.statusCode == 200) {
      return CategoryUpdateResponse.fromJson(
        jsonDecode(response.body),
      );
    }
    return CategoryUpdateResponse(
      status: false,
      message: "Category update failed",
    );
  }
}
//------------------------------------category delete service----------------------------------------------------------
class CategoryDeleteService {

  Future<CategoryDeleteResponse> deleteCategory(
      CategoryDeleteModel model) async {
    final response = await http.post(
      Uri.parse(ApiUrls.delete),
      headers: {
        "Content-Type": "application/json"
      },
      body: jsonEncode(model.toJson()),
    );
    if (response.statusCode == 200) {
      return CategoryDeleteResponse.fromJson(
        jsonDecode(response.body),
      );
    }
    return CategoryDeleteResponse(
      status: false,
      message: "Delete failed",
    );
  }
}
// ------------------------------- send otp change password-------------------------------------------------------------------------
class SendOtpService {
  Future<SendOtpResponse> sendOtp(
      SendOtpModel model) async {
    final response = await http.post(
      Uri.parse(ApiUrls.sendOtp),
      headers: {
        "Content-Type": "application/json"
      },
      body: jsonEncode(model.toJson()),
    );
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return SendOtpResponse.fromJson(jsonData);
    } else {
      throw Exception("Failed to send OTP");
    }
  }
}
//------------------------------- verify otp change password------------------------------------------------------------------------
class VerifyOtpService {
  Future<VerifyOtpResponse> verifyOtp(VerifyOtpModel model) async {
    final response = await http.post(
      Uri.parse(ApiUrls.verifyOtp),
      headers: {
        "Content-Type": "application/json"
      },
      body: jsonEncode(model.toJson()),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return VerifyOtpResponse.fromJson(data);
    } else {
      throw Exception("OTP Verification Failed");
    }
  }
}
//-------------------------------Reset password-------------------------------------------------------------------------------------
class ResetPasswordService {
  Future<ResetPasswordResponse> resetPassword(
      ResetPasswordModel model) async {
    final response = await http.post(
      Uri.parse(ApiUrls.resetPassword),
      headers: {
        "Content-Type": "application/json"
      },
      body: jsonEncode(model.toJson()),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ResetPasswordResponse.fromJson(data);
    } else {
      throw Exception("Password Reset Failed");
    }
  }
}
//---------------------------------------------user enquiry-----------------------------------------------------------------
class UserEnquiryService {
  Future<List<UserEnquiry>> getEnquiries() async {
    final response = await http.post(
      Uri.parse(ApiUrls.userEnquiryList ),
      headers: {"Content-Type": "application/json"},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List list = data["data"];
      return list.map((e) => UserEnquiry.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load enquiries");
    }
  }
}
//--------------------------------------------offer list ------------------------------------------------------------------------
class OfferService {
  Future<OfferListResponse> getOffers() async {
    final response = await http.post(
      Uri.parse(ApiUrls.offerList),
      headers: {"Content-Type": "application/json"},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return OfferListResponse.fromJson(data);
    } else {
      throw Exception("Failed to load offers");
    }
  }
}
//-------------------------------------offer update ----------------------------------------------------------------------------
class OfferUpdateService {
  Future<OfferUpdateResponse> updateOffer(
      OfferUpdateModel model) async {
    final response = await http.post(
      Uri.parse(ApiUrls.offerUpdate),
      headers: {
        "Content-Type": "application/json"
      },
      body: jsonEncode(model.toJson()),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return OfferUpdateResponse.fromJson(data);
    } else {
      throw Exception("Offer update failed");
    }
  }
}
//----------------------------single offer ------------------------------------------------------------------
class SingleOfferService {
  Future<SingleOfferResponse> getSingleOffer(int id) async {
    final response = await http.post(
      Uri.parse(ApiUrls.singleOffer),
      headers: {
        "Content-Type": "application/json"
      },
      body: jsonEncode({
        "id": id
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return SingleOfferResponse.fromJson(data);
    } else {
      throw Exception("Failed to fetch offer");
    }
  }
}
//------------------------------------------offer delete ---------------------------------------------------------------
class OfferDeleteService {
  Future<OfferDeleteResponse> deleteOffer(int id) async {
    final response = await http.post(
      Uri.parse(ApiUrls.deleteOffer),
      headers: {
        "Content-Type": "application/json"
      },
      body: jsonEncode({
        "id": id
      }),
    );
    if(response.statusCode == 200){
      final data = jsonDecode(response.body);
      return OfferDeleteResponse.fromJson(data);
    }else{
      throw Exception("Delete Failed");
    }
  }
}
//--------------------------------------------enquiry list--------------------------------------------------------------------
class EnquiryListService {
  static Future<List<EnquiryListModel>> fetchEnquiries() async {
    final response = await http.post(
      Uri.parse(ApiUrls.enquiryList),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      EnquiryListResponse enquiryResponse =
      EnquiryListResponse.fromJson(data);
      return enquiryResponse.data ?? [];
    } else {
      throw Exception("Failed to load enquiries");
    }
  }

  static Future<SendEnquiryResponse> sendEnquiryToCompany(int enquiryId) async {
    final response = await http.post(
      Uri.parse(ApiUrls.sendEnquiryToCompany),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id": enquiryId}),
    );
    if (response.statusCode == 200) {
      return SendEnquiryResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to send enquiry to company");
    }
  }
}
//-------------------------------------latest enquiries------------------------------------------------------------
class LatestEnquiryService {
  Future<LatestEnquiryResponse> fetchLatestEnquiries() async {
    try {
      final response = await http.post(
        Uri.parse(ApiUrls.latestEnquiries),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return LatestEnquiryResponse.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to load latest enquiries: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching latest enquiries: $e');
    }
  }
}
//----------------------------------company pending---------------------------------------------------------------------------
class CompanyPendingService {

  static Future<List<CompanyPendingModel>> fetchPendingCompanies() async {

    final response = await http.post(
      Uri.parse(ApiUrls.pendingCompanies),

      headers: {
        "Content-Type": "application/json",
      },

      body: jsonEncode({}),
    );

    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);

      CompanyPendingResponse pendingResponse =
      CompanyPendingResponse.fromJson(data);

      return pendingResponse.data ?? [];

    } else {

      throw Exception("Failed to load pending companies");
    }
  }
}
//----------------------------------company all---------------------------------------------------------------------------
class CompanyAllService {

  Future<CompanyAllResponse> getCompanies() async {

    final response = await http.post(
      Uri.parse(ApiUrls.companyAll),
    );

    final data = jsonDecode(response.body);

    return CompanyAllResponse.fromJson(data);
  }


  // In CompanyAllService class
  Future<CompanySingleRetrieveResponse> getCompanyDetails(int companyId) async {
    final response = await http.post(
      Uri.parse(ApiUrls.companySingleRetrieve),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'company_id': companyId}),
    );
    if (response.statusCode == 200) {
      return CompanySingleRetrieveResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load company details');
    }
  }
}
//---------------------------------------latest companty---------------------------------------------------------
class LatestCompanyService {
  Future<LatestCompanyResponse> fetchLatestCompanies() async {
    try {
      final response = await http.post(
        Uri.parse(ApiUrls.latestCompanies),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return LatestCompanyResponse.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to load latest companies: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching latest companies: $e');
    }
  }
}
//-------------------------------------company softdelete-----------------------------------------------------------------------
class CompanySoftDeleteService {

  Future<CompanySoftDeleteResponse> deleteCompany(
      CompanySoftDeleteModel model) async {

    final response = await http.post(

      Uri.parse(ApiUrls.companySoftDelete),

      headers: {
        "Content-Type": "application/json"
      },

      body: jsonEncode(model.toJson()),

    );

    final jsonData = jsonDecode(response.body);

    return CompanySoftDeleteResponse.fromJson(jsonData);

  }
}
//---------------------------------------company restore-------------------------------------------------------------------
class CompanyRestoreService {

  Future<CompanyRestoreResponse> restoreCompany(
      CompanyRestoreModel model) async {

    final response = await http.post(

      Uri.parse(ApiUrls.companyRestore),

      headers: {
        "Content-Type": "application/json"
      },

      body: jsonEncode(model.toJson()),

    );

    final jsonData = jsonDecode(response.body);

    return CompanyRestoreResponse.fromJson(jsonData);

  }
}
//---------------------------------------sub category-------------------------------------------------------------------------

class SubCategoryService {

  Future<SubCategoryResponse> getSubCategories() async {

    final response = await http.post(
      Uri.parse(ApiUrls.subCategoryAll),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({}),
    );

    if (response.statusCode == 200) {

      final jsonData = jsonDecode(response.body);

      return SubCategoryResponse.fromJson(jsonData);

    } else {

      throw Exception("Failed to load subcategories");

    }
  }
}
//---------------------------------------------------pending product----------------------------------------------------------------
class PendingProductService {

  Future<PendingProductResponse> getPendingProducts() async {

    final response = await http.post(
      Uri.parse(ApiUrls.pendingProducts),
      headers: {
        "Content-Type": "application/json"
      },
      body: jsonEncode({}),
    );

    final jsonData = jsonDecode(response.body);

    return PendingProductResponse.fromJson(jsonData);
  }
}
//-------------------------------------product approve-------------------------------------------------------------------
class ProductApproveService {

  Future<ProductApproveResponse> approveProduct(
      ProductApproveModel model) async {

    final response = await http.post(
      Uri.parse(ApiUrls.productApprove),
      headers: {
        "Content-Type": "application/json"
      },
      body: jsonEncode(model.toJson()),
    );
    final jsonData = jsonDecode(response.body);
    return ProductApproveResponse.fromJson(jsonData);
  }
}
//---------------------------------------------latest products---------------------------------------------------------------
class LatestProductService {
  Future<LatestProductResponse> fetchLatestProducts() async {
    try {
      final response = await http.post(
        Uri.parse(ApiUrls.latestProducts),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return LatestProductResponse.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to load latest products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching latest products: $e');
    }
  }
}

//----------------------------------product approved list---------------------------------------------------
class ProductApprovedService {
  Future<ApiResponse<List<ApprovedProductModel>>> getApprovedProducts() async {
    try {
      final response = await http.post(
        Uri.parse(ApiUrls.approvedProductList),
        headers: {
          // Add if your API requires token
          // 'Authorization': 'Bearer ${yourToken}',
          'Content-Type': 'application/json',
        },
      );

      print("✅ API Status Code: ${response.statusCode}");
      print("📦 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print("📊 Parsed JSON: $jsonData");

        // Check if status is true
        if (jsonData['status'] != true) {
          return ApiResponse(
            status: false,
            message: jsonData['message'] ?? 'API returned false status',
            data: [],
          );
        }

        // Ensure data is a list
        if (jsonData['data'] == null || jsonData['data'] is! List) {
          return ApiResponse(
            status: false,
            message: 'Invalid data format: expected list',
            data: [],
          );
        }

        List list = jsonData['data'];
        List<ApprovedProductModel> products = [];

        for (var item in list) {
          try {
            products.add(ApprovedProductModel.fromJson(item));
          } catch (e, stack) {
            print("❌ Error parsing product: $e");
            print(stack);
            // Continue with next product
          }
        }

        return ApiResponse(
          status: true,
          message: jsonData['message'] ?? 'Success',
          data: products,
        );
      } else {
        throw Exception("HTTP ${response.statusCode}");
      }
    } catch (e, stack) {
      print("🔥 Service Error: $e");
      print(stack);
      throw Exception("Failed to load approved products: $e");
    }
  }
}
//-----------------------------------------reject product---------------------------------------------------------------------------
class RejectProductService {

  Future<RejectProductResponse> rejectProduct(
      RejectProductModel model) async {
    final response = await http.post(
      Uri.parse(ApiUrls.rejectProduct),
      headers: {
        "Content-Type": "application/json"
      },
      body: jsonEncode(model.toJson()),
    );
    final jsonData = jsonDecode(response.body);
    return RejectProductResponse.fromJson(jsonData);
  }
}
//-------------------------------------role detail---------------------------------------------------------------------------
class RoleDetailService {
  Future<RoleDetailResponse> getRoleDetail(int id) async {
    final response = await http.post(
      Uri.parse(ApiUrls.roleDetail),
      headers: {
        "Content-Type": "application/json"
      },
      body: jsonEncode({
        "id": id
      }),
    );
    final data = jsonDecode(response.body);
    return RoleDetailResponse.fromJson(data);
  }
}

//-----------------------------------dashboard cards service--------------------------------------------------------------------
class DashboardService {

  // ✅ COMPANY COUNT API
  Future<CompanyCountModel> getCompanyCount() async {
    final response = await http.post(
      Uri.parse(ApiUrls.companytcard),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return CompanyCountModel.fromJson(data);
    } else {
      throw Exception("Failed to load company count");
    }
  }

  // ✅ PRODUCT COUNT API
  Future<ProductCountModel> getProductCount() async {
    final response = await http.post(
      Uri.parse(ApiUrls.Productcard),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ProductCountModel.fromJson(data);
    } else {
      throw Exception("Failed to load product count");
    }
  }

  // ✅ ENQUIRY COUNT API
  Future<EnquiryCountModel> getEnquiryCount() async {
    final response = await http.post(
      Uri.parse(ApiUrls.enquirycard),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return EnquiryCountModel.fromJson(data);
    } else {
      throw Exception("Failed to load enquiry count");
    }
  }
}




// ============================================================
// ✅ DEBUG FUNCTION - Class च्या बाहेर
// ============================================================
Future<void> debugSharedPreferences() async {
  final prefs = await SharedPreferences.getInstance();
  print("=== DEBUG: SharedPreferences ===");
  print("All keys: ${prefs.getKeys()}");

  final userId = prefs.getString('user_id');
  final token = prefs.getString('access_token');
  final username = prefs.getString('username');
  final role = prefs.getString('user_role');

  print("user_id: '$userId'");
  print("access_token: '${token?.substring(0, token.length > 20 ? 20 : token.length)}...'");
  print("username: '$username'");
  print("role: '$role'");
  print("================================");
}

// ============================================================
// ✅ AGREEMENT SERVICE
// ============================================================
// ============================================================
// ✅ AGREEMENT SERVICE
// ============================================================
class AgreementService {

  // ✅ CREATE COMPANY AGREEMENT
  static Future<AgreementResponse?> createAgreement(AgreementModel model) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiUrls.createAgreement),
    );

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    // Text fields
    request.fields['agreement_number'] = model.agreementNumber ?? '';
    request.fields['company'] = model.companyId.toString();
    request.fields['agreement_role'] = model.agreementRole;
    request.fields['apply_on_all_products'] = model.applyOnAllProducts.toString();
    request.fields['agreement_start_date'] = model.agreementStartDate;
    request.fields['agreement_end_date'] = model.agreementEndDate;
    request.fields['company_owner_name'] = model.companyOwnerName;
    request.fields['company_address'] = model.companyAddress;

    if (model.sellerAdharNumber != null && model.sellerAdharNumber!.isNotEmpty) {
      request.fields['seller_adhar_number'] = model.sellerAdharNumber!;
    }
    if (model.ownerAdharNumber != null && model.ownerAdharNumber!.isNotEmpty) {
      request.fields['owner_adhar_number'] = model.ownerAdharNumber!;
    }
    if (model.sellerPanNumber != null && model.sellerPanNumber!.isNotEmpty) {
      request.fields['seller_pan_number'] = model.sellerPanNumber!;
    }
    if (model.ownerPanNumber != null && model.ownerPanNumber!.isNotEmpty) {
      request.fields['owner_pan_number'] = model.ownerPanNumber!;
    }
    if (model.additionalPoints.isNotEmpty) {
      request.fields['additional_points'] = model.additionalPoints;
    }
    if (model.qnxMartRepresentative.isNotEmpty) {
      request.fields['qnx_mart_representative'] = model.qnxMartRepresentative;
    }
    if (model.remarks != null && model.remarks!.isNotEmpty) {
      request.fields['remarks'] = model.remarks!;
    }
    if (model.profitSharePercentage.isNotEmpty) {
      request.fields['profit_share_percentage'] = model.profitSharePercentage;
    }
    if (model.sellingCommissionPercentage.isNotEmpty) {
      request.fields['selling_commission_percentage'] = model.sellingCommissionPercentage;
    }
    if (model.agreementProducts.isNotEmpty) {
      request.fields['agreement_products'] = jsonEncode(model.agreementProducts);
    }

    // Files
    if (model.qnxMartSign != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'qnx_mart_sign_s3_key',
        model.qnxMartSign!,
        filename: 'qnx_mart_sign.png',
        contentType: MediaType('image', 'png'),
      ));
    }
    if (model.companySign != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'company_sign_s3_key',
        model.companySign!,
        filename: 'company_sign.png',
        contentType: MediaType('image', 'png'),
      ));
    }
    if (model.qnxMartPicture != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'qnx_mart_picture_s3_key',
        model.qnxMartPicture!,
        filename: 'qnx_mart_picture.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));
    }
    if (model.companyPicture != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'company_picture_s3_key',
        model.companyPicture!,
        filename: 'company_picture.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));
    }
    if (model.uploadedAgreementPdf != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'uploaded_agreement_pdf_s3_key',
        model.uploadedAgreementPdf!,
        filename: 'agreement.pdf',
        contentType: MediaType('application', 'pdf'),
      ));
    }

    print('========================================');
    print('📤 Create Company Agreement: ${ApiUrls.createAgreement}');
    print('📤 Fields: ${request.fields.length}');
    print('📤 Files: ${request.files.length}');
    print('========================================');

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    print("📥 Status: ${response.statusCode}");
    print("📦 Response: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return AgreementResponse.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  // ✅ FETCH COMPANY AGREEMENTS
  static Future<AgreementListResponse> fetchCompanyAgreements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      final response = await http.post(
        Uri.parse(ApiUrls.companyAgreementList),
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({}),
      );

      print("📤 Company Agreement List URL: ${ApiUrls.companyAgreementList}");
      print("📥 Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['data'] == null) jsonData['data'] = [];
        return AgreementListResponse.fromJson(jsonData);
      }
      return AgreementListResponse(
        status: 'error',
        message: 'Failed: ${response.statusCode}',
        total: 0,
        data: [],
      );
    } catch (e) {
      return AgreementListResponse(
        status: 'error',
        message: 'Error: $e',
        total: 0,
        data: [],
      );
    }
  }

  // ✅ APPROVE COMPANY AGREEMENT
  static Future<CompanyAgreementApproveResponse?> approveCompanyAgreement({
    required int agreementId,
    String? remarks,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      final requestBody = {
        'agreement_id': agreementId,
        'status': 'approved',
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
      };

      final response = await http.post(
        Uri.parse(ApiUrls.companyAgreementApprove),
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('📤 Approve Company: ${response.statusCode}');
      print('📦 ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return CompanyAgreementApproveResponse.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ✅ REJECT COMPANY AGREEMENT
  static Future<CompanyAgreementRejectResponse?> rejectCompanyAgreement({
    required int agreementId,
    required String rejectionReason,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      final requestBody = {
        'agreement_id': agreementId,
        'status': 'rejected',
        'rejection_reason': rejectionReason,
      };

      final response = await http.post(
        Uri.parse(ApiUrls.companyAgreementReject),
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('📤 Reject Company: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return CompanyAgreementRejectResponse.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ✅ UPDATE AGREEMENT PERCENTAGE
  static Future<AgreementPercentageUpdateResponse> updateAgreementPercentage({
    required int agreementId,
    required double profitSharePercentage,
    double? sellingCommissionPercentage,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      Map<String, dynamic> requestBody = {
        'agreement_id': agreementId,
        'profit_share_percentage': profitSharePercentage,
      };
      if (sellingCommissionPercentage != null) {
        requestBody['selling_commission_percentage'] = sellingCommissionPercentage;
      }

      final response = await http.post(
        Uri.parse(ApiUrls.updateAgreementPercentage),
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        return AgreementPercentageUpdateResponse.fromJson(jsonDecode(response.body));
      }
      throw Exception('Failed to update percentage: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // ============================================================
  // ✅ MARKETING PARTNER AGREEMENT METHODS
  // ============================================================

  // ✅ 1. FETCH LIST
  static Future<MarketingPartnerAgreementListResponse>
  fetchMarketingPartnerAgreements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      final response = await http.post(
        Uri.parse(ApiUrls.marketingPartnerAgreementList),
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({}),
      );

      print('📤 MP Agreement List: ${ApiUrls.marketingPartnerAgreementList}');
      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200) {
        return MarketingPartnerAgreementListResponse.fromJson(
            jsonDecode(response.body));
      }
      return MarketingPartnerAgreementListResponse(
        success: false,
        message: 'Failed: ${response.statusCode}',
        count: 0,
        data: [],
      );
    } catch (e) {
      return MarketingPartnerAgreementListResponse(
        success: false,
        message: 'Error: $e',
        count: 0,
        data: [],
      );
    }
  }

  // ============================================================
// ✅ MY MARKETING PARTNER AGREEMENTS (Marketing Partner साठी)
// ============================================================
  static Future<MarketingPartnerAgreementListResponse>
  fetchMyMarketingPartnerAgreements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      print('📤 Fetching My Marketing Partner Agreements');
      print('URL: ${ApiUrls.myMarketingPartnerAgreements}');
      print('Token: ${token.isNotEmpty ? "✅ Present" : "❌ Missing"}');

      final response = await http.post(
        Uri.parse(ApiUrls.myMarketingPartnerAgreements),
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({}), // Empty body
      );

      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200) {
        return MarketingPartnerAgreementListResponse.fromJson(
            jsonDecode(response.body));
      }

      return MarketingPartnerAgreementListResponse(
        success: false,
        message: 'Failed: ${response.statusCode}',
        count: 0,
        data: [],
      );
    } catch (e) {
      print('❌ Fetch My Agreements Error: $e');
      return MarketingPartnerAgreementListResponse(
        success: false,
        message: 'Error: $e',
        count: 0,
        data: [],
      );
    }
  }

  // ✅ 2. CREATE
  static Future<MarketingPartnerAgreementCreateResponse?>
  createMarketingPartnerAgreement(
      MarketingPartnerAgreementModel model) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiUrls.marketingPartnerAgreementCreate),
      );
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.fields['agreement_number'] = model.agreementNumber;
      request.fields['marketing_partner'] = model.marketingPartnerId.toString();
      request.fields['agreement_role'] = model.agreementRole;
      request.fields['agreement_start_date'] = model.agreementStartDate;
      request.fields['agreement_end_date'] = model.agreementEndDate;
      request.fields['marketing_partner_name'] = model.marketingPartnerName;
      request.fields['marketing_partner_address'] = model.marketingPartnerAddress;
      request.fields['company_commission_percentage'] = model.companyCommissionPercentage;
      request.fields['profit_share_percentage'] = model.profitSharePercentage;
      request.fields['selling_commission_percentage'] = model.sellingCommissionPercentage;
      request.fields['additional_points'] = model.additionalPoints;
      request.fields['qnx_mart_representative'] = model.qnxMartRepresentative;
      if (model.adharNumber != null && model.adharNumber!.isNotEmpty) {
        request.fields['adhar_number'] = model.adharNumber!;
      }
      if (model.panNumber != null && model.panNumber!.isNotEmpty) {
        request.fields['pan_number'] = model.panNumber!;
      }
      if (model.remarks != null && model.remarks!.isNotEmpty) {
        request.fields['remarks'] = model.remarks!;
      }

      if (model.qnxMartSign != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'qnx_mart_sign_s3_key',
          model.qnxMartSign!,
          filename: 'qnx_mart_sign.png',
          contentType: MediaType('image', 'png'),
        ));
      }
      if (model.marketingPartnerSign != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'marketing_partner_sign_s3_key',
          model.marketingPartnerSign!,
          filename: 'marketing_partner_sign.png',
          contentType: MediaType('image', 'png'),
        ));
      }
      if (model.qnxMartPicture != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'qnx_mart_picture_s3_key',
          model.qnxMartPicture!,
          filename: 'qnx_mart_picture.jpg',
          contentType: MediaType('image', 'jpeg'),
        ));
      }
      if (model.marketingPartnerPicture != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'marketing_partner_picture_s3_key',
          model.marketingPartnerPicture!,
          filename: 'marketing_partner_picture.jpg',
          contentType: MediaType('image', 'jpeg'),
        ));
      }
      if (model.uploadedAgreementPdf != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'uploaded_agreement_pdf_s3_key',
          model.uploadedAgreementPdf!,
          filename: 'agreement.pdf',
          contentType: MediaType('application', 'pdf'),
        ));
      }

      print('========================================');
      print('📤 Create MP Agreement: ${ApiUrls.marketingPartnerAgreementCreate}');
      print('📤 Fields: ${request.fields.length}');
      print('📤 Files: ${request.files.length}');
      print('========================================');

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return MarketingPartnerAgreementCreateResponse.fromJson(
            jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('❌ Create MP Agreement Error: $e');
      return null;
    }
  }

  // ✅ 3. APPROVE
  static Future<MarketingPartnerAgreementApproveResponse?>
  approveMarketingPartnerAgreement({
    required int agreementId,
    String? remarks,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      final body = {
        'agreement_id': agreementId,
        'status': 'approved',
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
      };

      final response = await http.post(
        Uri.parse(ApiUrls.marketingPartnerAgreementApprove),
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      print('📤 Approve MP Agreement: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return MarketingPartnerAgreementApproveResponse.fromJson(
            jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ✅ 4. REJECT
  static Future<MarketingPartnerAgreementRejectResponse?>
  rejectMarketingPartnerAgreement({
    required int agreementId,
    required String rejectionReason,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      final body = {
        'agreement_id': agreementId,
        'status': 'rejected',
        'rejection_reason': rejectionReason,
      };

      final response = await http.post(
        Uri.parse(ApiUrls.marketingPartnerAgreementReject),
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      print('📤 Reject MP Agreement: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return MarketingPartnerAgreementRejectResponse.fromJson(
            jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

// ============================================================
// ✅ AGREEMENT LIST SERVICE
// ============================================================


//-----------------------------send registrationotp -----------------------------------------------------------------
class RegistrationSendOtpService {
  Future<RegistrationSendOtpResponse> sendOtp(SendOtpModel model) async {
    final response = await http.post(
      Uri.parse(ApiUrls.registersendOtp),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(model.toJson()),
    );
    if (response.statusCode == 200) {
      return RegistrationSendOtpResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to send OTP: ${response.body}');
    }
  }
}

//--------------------verify otp registration--------------------------------------------------------
class RegistrationVerifyOtpService {
  Future<RegistrationVerifyOtpResponse> verifyOtp(VerifyOtpModel model) async {
    final response = await http.post(
      Uri.parse(ApiUrls.registerverifyOtp),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(model.toJson()),
    );
    if (response.statusCode == 200) {
      return RegistrationVerifyOtpResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to verify OTP: ${response.body}');
    }
  }
}
//------------------------registration service -------------------------------------------------------
class RegisterService {
  Future<RegisterResponse> register(RegisterModel model) async {
    final response = await http.post(
      Uri.parse(ApiUrls.register), // we'll add this URL
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(model.toJson()),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return RegisterResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }
}
//----------------------------all user service ----------------------------------------------------------
class UserService {
  Future<UserListResponse> getUsers() async {
    final response = await http.post(
      Uri.parse(ApiUrls.userList),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({}),
    );
    if (response.statusCode == 200) {
      return UserListResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load users');
    }
  }
}

//------------------------------------------agriment company list -------------------------------------------------------

class AgreementCompanyService {
  Future<AgreementCompanyResponse> getCompanies() async {
    final response = await http.post(
      Uri.parse(ApiUrls.companyAll),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({}),
    );
    if (response.statusCode == 200) {
      return AgreementCompanyResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load companies: ${response.statusCode}');
    }
  }
}

//-----------------------------------agreement product--------------------------------------------------
class AgreementProductService {
  Future<AgreementProductResponse> getProductsByCompany(String companyId) async {
    final response = await http.post(
      Uri.parse(ApiUrls.companyWiseProducts),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'company_id': int.parse(companyId)}),
    );
    print("Product API Response Status: ${response.statusCode}");
    print("Product API Response Body: ${response.body}");
    if (response.statusCode == 200) {
      return AgreementProductResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load products: ${response.statusCode}');
    }
  }
}

//-----------------------------------update request reject approve services------------------------------------

class UpdateRequestService {
  Future<UpdateRequestListResponse> getUpdateRequests() async {
    final response = await http.post(
      Uri.parse(ApiUrls.updateRequestList),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"full": true}),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return UpdateRequestListResponse.fromJson(jsonData);
    } else {
      throw Exception('Failed to load update requests: ${response.statusCode}');
    }
  }

  Future<ApproveUpdateResponse> approveUpdate(int requestId) async {
    final response = await http.post(
      Uri.parse(ApiUrls.approveUpdateRequest),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"request_id": requestId}),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return ApproveUpdateResponse.fromJson(jsonData);
    } else {
      throw Exception('Approve failed: ${response.statusCode}');
    }
  }

  Future<RejectUpdateResponse> rejectUpdate(int requestId, String reason) async {
    final response = await http.post(
      Uri.parse(ApiUrls.rejectUpdateRequest),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"request_id": requestId, "reason": reason}),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return RejectUpdateResponse.fromJson(jsonData);
    } else {
      throw Exception('Reject failed: ${response.statusCode}');
    }
  }
}
//-------------------------marketing head ---------------------------------------------------------


class MarketingHeadService {
  Future<MarketingHeadListResponse> getMarketingHeads() async {
    final response = await http.post(
      Uri.parse(ApiUrls.marketingHeadsList),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({}),
    );
    if (response.statusCode == 200) {
      return MarketingHeadListResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load marketing heads');
    }
  }

  Future<RejectPartnerResponse> rejectPartner(int partnerId, String reason) async {
    final response = await http.post(
      Uri.parse(ApiUrls.rejectPartner),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"partner_id": partnerId, "reason": reason}),
    );
    if (response.statusCode == 200) {
      return RejectPartnerResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Reject failed');
    }
  }

  // ✅ Use registration OTP endpoints
  Future<SendOtpResponse> sendOtp(String email) async {
    final response = await http.post(
      Uri.parse(ApiUrls.registersendOtp),   // changed
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"email": email}),
    );
    print("📤 Send OTP request to: ${ApiUrls.registersendOtp}");
    print("📦 Response: ${response.body}");
    if (response.statusCode == 200) {
      return SendOtpResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to send OTP: ${response.body}');
    }
  }

  Future<VerifyOtpResponse> verifyOtp(String email, String otp) async {
    final response = await http.post(
      Uri.parse(ApiUrls.registerverifyOtp), // changed
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"email": email, "otp": otp}),
    );
    if (response.statusCode == 200) {
      return VerifyOtpResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('OTP verification failed');
    }
  }

  // ✅ FIXED: Complete Registration - DOES NOT throw exception on success
  // lib/api/api_service.dart - MarketingPartnerService class

  Future<CompleteRegistrationResponse> completeRegistration({
    required String email,
    required String username,
    required String password,
    required String role,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        "email": email,
        "username": username,
        "password": password,
        "role": role,
      };

      print('📤 Complete Registration URL: ${ApiUrls.completeRegistrationPartner}');
      print('📤 Request Body: ${jsonEncode(requestData)}');

      final response = await http.post(
        Uri.parse(ApiUrls.completeRegistrationPartner),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestData),
      );

      print('📦 Response Status: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      final Map<String, dynamic> jsonData = jsonDecode(response.body);

      // ✅ Check if response contains detailed error information
      if (response.statusCode != 200 && response.statusCode != 201) {
        // Try to extract detailed error messages
        String errorMessage = jsonData['message'] ?? 'Registration failed';

        // Check for field-specific errors
        if (jsonData.containsKey('email')) {
          errorMessage = jsonData['email'].toString();
        } else if (jsonData.containsKey('username')) {
          errorMessage = jsonData['username'].toString();
        } else if (jsonData.containsKey('password')) {
          errorMessage = jsonData['password'].toString();
        } else if (jsonData.containsKey('non_field_errors')) {
          final errors = jsonData['non_field_errors'];
          if (errors is List) {
            errorMessage = errors.join(', ');
          } else {
            errorMessage = errors.toString();
          }
        }

        return CompleteRegistrationResponse(
          status: false,
          message: errorMessage,
          data: jsonData, // Pass the full error details
        );
      }

      return CompleteRegistrationResponse.fromJson(jsonData);
    } catch (e) {
      print('❌ Complete registration error: $e');
      return CompleteRegistrationResponse(
        status: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }
}

//--------------------marketing_partner_service---------------------------------------

class MarketingPartnerService {
  Future<MarketingPartnerListResponse> getMarketingPartners() async {
    final response = await http.post(
      Uri.parse(ApiUrls.marketingPartnersList),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({}),
    );
    if (response.statusCode == 200) {
      return MarketingPartnerListResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load marketing partners');
    }
  }

  Future<RejectPartnerResponse> rejectPartner(int partnerId, String reason) async {
    final response = await http.post(
      Uri.parse(ApiUrls.rejectPartner),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"partner_id": partnerId, "reason": reason}),
    );
    if (response.statusCode == 200) {
      return RejectPartnerResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Reject failed');
    }
  }

  Future<SendOtpResponse> sendOtp(String email) async {
    final response = await http.post(
      Uri.parse(ApiUrls.registersendOtp),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"email": email}),
    );
    if (response.statusCode == 200) {
      return SendOtpResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to send OTP');
    }
  }

  Future<VerifyOtpResponse> verifyOtp(String email, String otp) async {
    final response = await http.post(
      Uri.parse(ApiUrls.registerverifyOtp),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"email": email, "otp": otp}),
    );
    if (response.statusCode == 200) {
      return VerifyOtpResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('OTP verification failed');
    }
  }

  // lib/api/api_service.dart - MarketingPartnerService class मधील completeRegistration method

  Future<CompleteRegistrationResponse> completeRegistration({
    required String email,
    required String username,
    required String password,
    required String role,
  }) async {
    try {
      // ✅ Request body काय आहे ते print करा
      final Map<String, dynamic> requestData = {
        "email": email,
        "username": username,
        "password": password,
        "role": role,
      };

      print('📤 Complete Registration URL: ${ApiUrls.completeRegistrationPartner}');
      print('📤 Request Body: ${jsonEncode(requestData)}');

      final response = await http.post(
        Uri.parse(ApiUrls.completeRegistrationPartner),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestData),
      );

      print('📦 Response Status: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      // ✅ Parse the response
      final Map<String, dynamic> jsonData = jsonDecode(response.body);

      // ✅ Always return the response object
      return CompleteRegistrationResponse.fromJson(jsonData);

    } catch (e) {
      print('❌ Complete registration error: $e');
      return CompleteRegistrationResponse(
        status: false,
        message: 'Error: ${e.toString()}',
      );
    }
  }


  Future<MarketingProfileResponse> getMyPartnerProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        throw Exception('No access token found. Please login again.');
      }

      final response = await http.post(
        Uri.parse(ApiUrls.myMarketingProfile),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📤 Get My Partner Profile');
      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return MarketingProfileResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Get Profile Error: $e');
      rethrow;
    }
  }

}
//----------------------------------referral_partner_service---------------------------------------------


class ReferralPartnerService {
  Future<ReferredPartnersResponse> getReferredPartners(int partnerId) async {
    final response = await http.post(
      Uri.parse(ApiUrls.referredPartners),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"partner_id": partnerId}),
    );
    if (response.statusCode == 200) {
      return ReferredPartnersResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load referred partners');
    }
  }
}

//-----------------------CompanyProductEnquiryService-----------------------------------------



// ...

class PendingEnquiryService {
  // Updated method with optional date parameters
  static Future<PendingEnquiryResponse> fetchPendingEnquiries({
    String? fromDate,
    String? toDate,
  }) async {
    // Build request body
    Map<String, dynamic> requestBody = {};

    // Add date filters if provided
    if (fromDate != null && fromDate.isNotEmpty) {
      requestBody['from_date'] = fromDate;
    }
    if (toDate != null && toDate.isNotEmpty) {
      requestBody['to_date'] = toDate;
    }

    final response = await http.post(
      Uri.parse(ApiUrls.pendingEnquiries),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(requestBody),
    );

    print("📤 Request Body: ${jsonEncode(requestBody)}");
    print("📥 Response Status: ${response.statusCode}");
    print("📦 Response: ${response.body}");

    if (response.statusCode == 200) {
      return PendingEnquiryResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load pending enquiries: ${response.statusCode}');
    }
  }
}
//--------------------------ApprovedEnquiryService -------------------------------------


class ApprovedEnquiryService {
  static Future<ApprovedEnquiryResponse> fetchApprovedEnquiries() async {
    final response = await http.post(
      Uri.parse(ApiUrls.approvedEnquiries),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({}),
    );

    print("✅ Approved Enquiries API Status: ${response.statusCode}");
    print("📦 Approved Enquiries Response: ${response.body}");

    if (response.statusCode == 200) {
      return ApprovedEnquiryResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load approved enquiries: ${response.statusCode}');
    }
  }
}
//----------------------------------PartnerCompaniesService --------------------------------------



class PartnerCompaniesService {
  static Future<PartnerCompaniesResponse> fetchPartnerCompanies(int partnerId) async {
    final response = await http.post(
      Uri.parse(ApiUrls.partnerCompanies),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"partner_id": partnerId}),
    );
    if (response.statusCode == 200) {
      return PartnerCompaniesResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load partner companies');
    }
  }
}

//---------------------------------------BankDetailsService ------------------------------------------------

class BankDetailsService {

  final http.Client _client;

  BankDetailsService({http.Client? client})
      : _client = client ?? http.Client();
  static Future<BankDetailsResponse> createBankDetails(BankDetailsRequest request) async {
    final response = await http.post(
      Uri.parse(ApiUrls.createBankDetails),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(request.toJson()),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return BankDetailsResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create bank details: ${response.body}');
    }
  }

Future<int> _getMarketingPartnerId() async {
  final prefs = await SharedPreferences.getInstance();

// ✅ First try marketing_partner_id
  String? partnerId = prefs.getString('marketing_partner_id');

// ✅ If not found, try partner_id
  if (partnerId == null || partnerId.isEmpty) {
    partnerId = prefs.getString('partner_id');
  }

// ✅ If still not found, try user_id
  if (partnerId == null || partnerId.isEmpty) {
    partnerId = prefs.getString('user_id');
  }

  if (partnerId == null || partnerId.isEmpty) {
    throw Exception('Marketing Partner ID not found. Please login again.');
  }

  try {
    return int.parse(partnerId);
  } catch (e) {
    throw Exception('Invalid Marketing Partner ID format: $partnerId');
  }
}

}


class BankDetailService {
  static Future<BankDetailResponse> fetchBankDetails(int partnerId) async {
    final response = await http.post(
      Uri.parse(ApiUrls.retrieveBankDetails),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"marketing_partner": partnerId}),
    );
    if (response.statusCode == 200) {
      return BankDetailResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load bank details');
    }
  }
}


//---------------------------------franchise_service-----------------------------------------------------------



class FranchiseService {
  final http.Client _client;

  FranchiseService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetch all franchises (POST method)
  Future<FranchiseListResponse> getFranchises() async {
    try {
      final response = await http.post(
        Uri.parse(ApiUrls.franchiseList),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // Add if authentication is required
          // 'Authorization': 'Bearer ${yourToken}',
        },
        // Empty body or with parameters if needed
        body: jsonEncode({}),
      );

      print('📡 Franchise API Status: ${response.statusCode}');
      print('📦 Franchise API Response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return FranchiseListResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load franchises: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Franchise Service Error: $e');
      throw Exception('Error fetching franchises: $e');
    }
  }

  /// Fetch franchises by company ID
  Future<FranchiseListResponse> getFranchisesByCompany(int companyId) async {
    try {
      final response = await http.post(
        Uri.parse(ApiUrls.franchiseList),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'company_id': companyId,
        }),
      );

      print('📡 Franchise API (Company) Status: ${response.statusCode}');
      print('📦 Franchise API (Company) Response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return FranchiseListResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load franchises for company: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Franchise Service Error: $e');
      throw Exception('Error fetching franchises: $e');
    }
  }

  /// Search franchises
  Future<FranchiseListResponse> searchFranchises(String query) async {
    try {
      final response = await http.post(
        Uri.parse(ApiUrls.franchiseList),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'search': query,
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return FranchiseListResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to search franchises: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Franchise Search Error: $e');
      throw Exception('Error searching franchises: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}




// api_service.dart मध्ये
class ApiService {
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> postRequest(String url, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );
    return response;
  }

  Future<http.Response> getRequest(String url) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );
    return response;
  }
}

//----------------------approved marketing service count and list -----------------------------------------



class ApprovedMarketingPartnerService {
  /// Get count of approved marketing partners
  Future<ApprovedMarketingPartnerCountResponse> getCount() async {
    try {
      final response = await http.post(
        Uri.parse(ApiUrls.approvedMarketingPartnersCount),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApprovedMarketingPartnerCountResponse.fromJson(data);
      } else {
        throw Exception('Failed to load count: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Get list of approved marketing partners
  Future<ApprovedMarketingPartnerListResponse> getList() async {
    try {
      final response = await http.post(
        Uri.parse(ApiUrls.approvedMarketingPartnersList),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApprovedMarketingPartnerListResponse.fromJson(data);
      } else {
        throw Exception('Failed to load list: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
//--------------------------paid_company_service-----------------------------------------------------



class PaidCompanyService {
  /// Get count of paid companies
  Future<PaidCompanyCountResponse> getPaidCompaniesCount() async {
    try {
      final response = await http.post(
        Uri.parse(ApiUrls.paidCompaniesCount),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PaidCompanyCountResponse.fromJson(data);
      } else {
        throw Exception('Failed to load paid companies count: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Get unpaid companies pending amount
  Future<UnpaidCompanyPendingAmountResponse> getUnpaidCompaniesPendingAmount() async {
    try {
      final response = await http.post(
        Uri.parse(ApiUrls.unpaidCompaniesPendingAmount),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UnpaidCompanyPendingAmountResponse.fromJson(data);
      } else {
        throw Exception('Failed to load pending amount: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}

//-----------------------payment request_service---------------------------------
// lib/services/payment_request_service.dart



// lib/services/payment_request_service.dart



// lib/api/api_service.dart - PaymentRequestService class

class PaymentRequestService {
  final http.Client _client;

  PaymentRequestService({http.Client? client})
      : _client = client ?? http.Client();

  /// ✅ Get pending withdraw requests
  Future<PendingWithdrawResponse> getPendingWithdrawRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        return PendingWithdrawResponse(
          status: false,
          message: 'No access token found. Please login again.',
          count: 0,
          data: [],
        );
      }

      print('📤 Get Pending Withdraw Requests');
      print('URL: ${ApiUrls.pendingWithdrawRequests}');

      final response = await _client.post(
        Uri.parse(ApiUrls.pendingWithdrawRequests),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({}),
      );

      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return PendingWithdrawResponse.fromJson(jsonData);
      } else {
        return PendingWithdrawResponse(
          status: false,
          message: 'Failed to fetch pending requests: ${response.statusCode}',
          count: 0,
          data: [],
        );
      }
    } catch (e) {
      print('❌ Get Pending Requests Error: $e');
      return PendingWithdrawResponse(
        status: false,
        message: 'Error: ${e.toString()}',
        count: 0,
        data: [],
      );
    }
  }

  /// ✅ Generate Payment QR
  Future<PaymentQRResponse> generatePaymentQR({
    required int marketingPartnerId,
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        return PaymentQRResponse(
          status: false,
          message: 'No access token found. Please login again.',
          marketingPartnerId: 0,
          marketingPartner: '',
          amount: '0',
          qrImage: '',
          upiLink: '',
          paymentMethod: paymentMethod,
        );
      }

      final requestBody = {
        'marketing_partner_id': marketingPartnerId,
        'amount': amount,
        'payment_method': paymentMethod,
      };

      print('📤 Generate Payment QR');
      print('URL: ${ApiUrls.generatePaymentQR}');
      print('📤 Request Body: ${jsonEncode(requestBody)}');

      final response = await _client.post(
        Uri.parse(ApiUrls.generatePaymentQR),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return PaymentQRResponse.fromJson(jsonData);
      } else {
        return PaymentQRResponse(
          status: false,
          message: 'Failed to generate QR: ${response.statusCode}',
          marketingPartnerId: 0,
          marketingPartner: '',
          amount: '0',
          qrImage: '',
          upiLink: '',
          paymentMethod: paymentMethod,
        );
      }
    } catch (e) {
      print('❌ Generate QR Error: $e');
      return PaymentQRResponse(
        status: false,
        message: 'Error: ${e.toString()}',
        marketingPartnerId: 0,
        marketingPartner: '',
        amount: '0',
        qrImage: '',
        upiLink: '',
        paymentMethod: paymentMethod,
      );
    }
  }

  /// ✅ Mark payment as completed (Withdraw Amount)
  Future<PaymentWithdrawResponse> markPaymentAsPaid({
    required int requestId,
    required String paymentMethod,
    String? remarks,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        return PaymentWithdrawResponse(
          status: false,
          message: 'No access token found. Please login again.',
          data: null,
        );
      }

      final requestBody = {
        'request_id': requestId,
        'paid': true,
        'payment_method': paymentMethod,
        if (remarks != null) 'remarks': remarks,
      };

      print('📤 Mark Payment as Paid');
      print('URL: ${ApiUrls.withdrawAmount}');
      print('📤 Request Body: ${jsonEncode(requestBody)}');

      final response = await _client.post(
        Uri.parse(ApiUrls.withdrawAmount),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return PaymentWithdrawResponse.fromJson(jsonData);
      } else {
        return PaymentWithdrawResponse(
          status: false,
          message: 'Failed to mark payment: ${response.statusCode}',
          data: null,
        );
      }
    } catch (e) {
      print('❌ Mark Payment Error: $e');
      return PaymentWithdrawResponse(
        status: false,
        message: 'Error: ${e.toString()}',
        data: null,
      );
    }
  }

  /// ✅ ONLY ONE dispose method
  void dispose() {
    _client.close();
  }
}

//------------------------amount_update_service------------------------------------------


class AmountUpdateService {
  final http.Client _client;

  AmountUpdateService({http.Client? client}) : _client = client ?? http.Client();

  Future<AmountUpdateResponse> updateAmount(String amount) async {
    try {
      final url = Uri.parse(ApiUrls.amountUpdate);

      final requestBody = AmountUpdateRequest(amount: amount);

      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody.toJson()),
      );

      print('📤 Amount Update Request: ${requestBody.toJson()}');
      print('📥 Response Status: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        return AmountUpdateResponse.fromJson(jsonResponse);
      } else {
        return AmountUpdateResponse(
          status: false,
          message: 'Failed to update amount: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Amount Update Error: $e');
      return AmountUpdateResponse(
        status: false,
        message: 'Error: ${e.toString()}',
      );
    }
  }

  void dispose() {
    _client.close();
  }
}

//-------------------------paid unpaid count  service---------------------------------------------

class PaidUnpaidEnquiryService {
  static const String baseUrl = ApiUrls.baseUrl;

  // POST method to get paid/unpaid enquiry counts
  Future<PaidUnpaidEnquiryResponse> getPaidUnpaidEnquiryCounts() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/enquiry/product-enquiry/paid_unpaid_count/'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return PaidUnpaidEnquiryResponse.fromJson(data);
      } else {
        throw Exception('Failed to load paid/unpaid enquiry counts');
      }
    } catch (e) {
      print('Error fetching paid/unpaid enquiry counts: $e');
      throw Exception('Error: $e');
    }
  }
}

//---------------------complete incomplete enquiry count ----------------------------------------

class CompleteEnquiryService {
  Future<CompleteEnquiryResponse> getCompleteEnquiryCounts() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiUrls.baseUrl}/enquiry/product-enquiry-complete-count/'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return CompleteEnquiryResponse.fromJson(data);
      } else {
        throw Exception('Failed to load complete enquiry counts: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching complete enquiry counts: $e');
      throw Exception('Error: $e');
    }
  }
}

//---------------------banner service -------------------------------------------------------------

class BannerService {
  final http.Client _client;

  BannerService({http.Client? client}) : _client = client ?? http.Client();

  Future<BannerListResponse> getBannerList() async {
    try {
      final response = await _client.post(
        Uri.parse(ApiUrls.imageList),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({}),
      );

      print('📡 Banner List API Status: ${response.statusCode}');
      print('📦 Banner List Response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return BannerListResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load banner list: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Banner List Error: $e');
      throw Exception('Error fetching banner list: $e');
    }
  }
  /// Upload a new banner image
  Future<UploadImageResponse> uploadImage({
    required String imagePath,
    required String title,
    Uint8List? webImageBytes,
    String? webImageName,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiUrls.uploadImage),
      );

      // Add title field
      request.fields['title'] = title;

      // Add image file
      if (kIsWeb && webImageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            webImageBytes,
            filename: webImageName ?? 'banner_image.png',
            contentType: MediaType('image', _getImageExtension(webImageName)),
          ),
        );
      } else if (!kIsWeb) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            imagePath,
            contentType: MediaType('image', _getFileExtension(imagePath)),
          ),
        );
      }

      print('📤 Uploading banner image...');
      print('📤 Fields: ${request.fields}');
      print('📤 Files: ${request.files.length}');

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('📥 Response Status: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return UploadImageResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Upload Image Error: $e');
      throw Exception('Error uploading image: $e');
    }
  }

  /// Update an existing banner image
  Future<UpdateImageResponse> updateImage({
    required int id,
    required String title,
    String? imagePath,
    Uint8List? webImageBytes,
    String? webImageName,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiUrls.updateImage),
      );

      // Add fields
      request.fields['id'] = id.toString();
      request.fields['title'] = title;

      // Add image file if provided
      if (imagePath != null || webImageBytes != null) {
        if (kIsWeb && webImageBytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'image',
              webImageBytes,
              filename: webImageName ?? 'banner_image.png',
              contentType: MediaType('image', _getImageExtension(webImageName)),
            ),
          );
        } else if (!kIsWeb && imagePath != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'image',
              imagePath,
              contentType: MediaType('image', _getFileExtension(imagePath)),
            ),
          );
        }
      }

      print('📤 Updating banner image...');
      print('📤 Fields: ${request.fields}');
      print('📤 Files: ${request.files.length}');

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('📥 Response Status: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return UpdateImageResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to update image: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Update Image Error: $e');
      throw Exception('Error updating image: $e');
    }
  }

  /// Delete a banner image
  Future<DeleteImageResponse> deleteImage(int id) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiUrls.deleteImage),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'id': id}),
      );

      print('📤 Deleting banner image with ID: $id');
      print('📥 Response Status: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return DeleteImageResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to delete image: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Delete Image Error: $e');
      throw Exception('Error deleting image: $e');
    }
  }

  String _getFileExtension(String path) {
    return path.split('.').last.toLowerCase();
  }

  String _getImageExtension(String? filename) {
    if (filename == null) return 'png';
    return filename.split('.').last.toLowerCase();
  }

  void dispose() {
    _client.close();
  }
}

//-------------------------------------loan_enquiry_service---------------------------------------



class LoanEnquiryService {
  final http.Client _client;

  LoanEnquiryService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetch loan enquiries with pagination and filters
  Future<LoanEnquiryListResponse> getLoanEnquiries({
    int? page,
    int? limit,
    String? search,
    String? status,
    String? loanType,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final request = LoanEnquiryListRequest(
        page: page,
        limit: limit,
        search: search,
        status: status,
        loanType: loanType,
        fromDate: fromDate,
        toDate: toDate,
      );

      final response = await _client.post(
        Uri.parse(ApiUrls.loanEnquiryList),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      print('📤 Loan Enquiry Request: ${request.toJson()}');
      print('📥 Response Status: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return LoanEnquiryListResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load loan enquiries: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Loan Enquiry Service Error: $e');
      throw Exception('Error fetching loan enquiries: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}


// Add this to api_service.dart

// ============================================================
// ✅ PACKING VIDEO SERVICE
// ============================================================
class PackingVideoService {
  final http.Client _client;

  PackingVideoService({http.Client? client})
      : _client = client ?? http.Client();

  Future<PackingVideoResponse> retrievePackingVideo(int orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final requestBody = PackingVideoRequest(orderId: orderId);

      print('📤 Retrieve Packing Video');
      print('URL: ${ApiUrls.retrievePackingVideo}');
      print('📤 Request Body: ${jsonEncode(requestBody.toJson())}');

      final response = await _client.post(
        Uri.parse(ApiUrls.retrievePackingVideo),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody.toJson()),
      );

      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return PackingVideoResponse.fromJson(jsonData);
      } else {
        return PackingVideoResponse(
          success: false,
          message: 'Failed to retrieve packing video: ${response.statusCode}',
          data: null,
        );
      }
    } catch (e) {
      print('❌ Retrieve Packing Video Error: $e');
      return PackingVideoResponse(
        success: false,
        message: 'Error: ${e.toString()}',
        data: null,
      );
    }
  }

  void dispose() {
    _client.close();
  }
}


// ============================================================
//customer_subscription_plan_service
// ============================================================
// lib/api/customer_subscription_plan_service.dart




class CustomerSubscriptionPlanService {
  final http.Client _client;

  CustomerSubscriptionPlanService({http.Client? client})
      : _client = client ?? http.Client();

  // ==================== CREATE PLAN ====================
  Future<CustomerSubscriptionPlanCreateResponse> createPlan(
      CustomerSubscriptionPlanRequest request) async {
    try {
      final url = Uri.parse(ApiUrls.customerSubscriptionPlanCreate);

      print('📤 Create Customer Subscription Plan');
      print('URL: $url');
      print('Body: ${jsonEncode(request.toJson())}');

      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      final jsonData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return CustomerSubscriptionPlanCreateResponse.fromJson(jsonData);
      } else {
        return CustomerSubscriptionPlanCreateResponse(
          success: false,
          message: jsonData['message'] ?? 'Failed to create plan',
        );
      }
    } catch (e) {
      print('❌ Create Plan Error: $e');
      return CustomerSubscriptionPlanCreateResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  // ==================== GET ALL PLANS ====================
  Future<CustomerSubscriptionPlanListResponse> getPlans() async {
    try {
      final url = Uri.parse(ApiUrls.customerSubscriptionPlanList);

      print('📤 Get Customer Subscription Plans');
      print('URL: $url');

      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({}),
      );

      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return CustomerSubscriptionPlanListResponse.fromJson(jsonData);
      } else {
        return CustomerSubscriptionPlanListResponse(
          success: false,
          message: 'Failed to load plans: ${response.statusCode}',
          count: 0,
          data: [],
        );
      }
    } catch (e) {
      print('❌ Get Plans Error: $e');
      return CustomerSubscriptionPlanListResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
        count: 0,
        data: [],
      );
    }
  }

  void dispose() {
    _client.close();
  }
}


// lib/api/subscription_plan_service.dart


class SubscriptionPlanService {
  final http.Client _client;

  SubscriptionPlanService({http.Client? client})
      : _client = client ?? http.Client();

  // ==================== CREATE ====================
  Future<SubscriptionPlanCreateResponse> createPlan(
      SubscriptionPlanRequest request) async {
    try {
      final url = Uri.parse(ApiUrls.subscriptionPlanCreate);

      print('📤 Create Subscription Plan');
      print('URL: $url');
      print('Body: ${jsonEncode(request.toJson())}');

      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        return SubscriptionPlanCreateResponse.fromJson(jsonData);
      }
      return SubscriptionPlanCreateResponse(
        success: false,
        message: jsonData['message']?.toString() ?? 'Failed to create plan',
      );
    } catch (e) {
      print('❌ Create Plan Error: $e');
      return SubscriptionPlanCreateResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  // ==================== LIST ====================
  Future<SubscriptionPlanListResponse> getPlans() async {
    try {
      final url = Uri.parse(ApiUrls.subscriptionPlanList);

      print('📤 Get Subscription Plans');
      print('URL: $url');

      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({}),
      );

      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return SubscriptionPlanListResponse.fromJson(jsonData);
      }
      return SubscriptionPlanListResponse(
        success: false,
        message: 'Failed to load plans: ${response.statusCode}',
        count: 0,
        data: [],
      );
    } catch (e) {
      print('❌ Get Plans Error: $e');
      return SubscriptionPlanListResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
        count: 0,
        data: [],
      );
    }
  }

  void dispose() {
    _client.close();
  }
}



class PackingMaterialEnquiryService {
  final http.Client _client;

  PackingMaterialEnquiryService({http.Client? client})
      : _client = client ?? http.Client();

  /// Fetch all packing material enquiries (POST)
  /// Optionally filter by user id / company id / customer id
  Future<PackingMaterialEnquiryResponse> fetchEnquiries({
    int? userId,
    int? companyId,
    int? customerId,
    String? status,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';
      final loggedInUserId = prefs.getString('user_id');

      // Build request body
      final Map<String, dynamic> body = {};

      // Add user id filter if provided (or fallback to logged in user)
      if (userId != null) {
        body['user_id'] = userId;
      } else if (loggedInUserId != null && loggedInUserId.isNotEmpty) {
        body['user_id'] = int.tryParse(loggedInUserId) ?? loggedInUserId;
      }

      if (companyId != null) body['company_id'] = companyId;
      if (customerId != null) body['customer_id'] = customerId;
      if (status != null && status.isNotEmpty) body['status'] = status;

      final url = Uri.parse(ApiUrls.packingMaterialEnquiryList);

      print('📤 Packing Material Enquiry URL: $url');
      print('📤 Request Body: ${jsonEncode(body)}');

      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return PackingMaterialEnquiryResponse.fromJson(jsonData);
      }

      return PackingMaterialEnquiryResponse(
        success: false,
        message: 'Failed: ${response.statusCode}',
        count: 0,
        data: [],
      );
    } catch (e) {
      print('❌ Packing Material Enquiry Error: $e');
      return PackingMaterialEnquiryResponse(
        success: false,
        message: 'Error: ${e.toString()}',
        count: 0,
        data: [],
      );
    }
  }

  void dispose() {
    _client.close();
  }
}


//=================================boosting_plan_service============================================================


class BoostingPlanService {
  final http.Client _client;

  BoostingPlanService({http.Client? client})
      : _client = client ?? http.Client();

  // ==================== CREATE PLAN ====================
  Future<BoostingPlanCreateResponse> createPlan(
      BoostingPlanRequest request) async {
    try {
      final url = Uri.parse(ApiUrls.boostingPlanCreate);

      print('📤 Create Boosting Plan');
      print('URL: $url');
      print('Body: ${jsonEncode(request.toJson())}');

      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        return BoostingPlanCreateResponse.fromJson(jsonData);
      }
      return BoostingPlanCreateResponse(
        success: false,
        message: jsonData['message']?.toString() ?? 'Failed to create plan',
      );
    } catch (e) {
      print('❌ Create Boosting Plan Error: $e');
      return BoostingPlanCreateResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  // ==================== LIST PLANS ====================
  Future<BoostingPlanListResponse> getPlans() async {
    try {
      final url = Uri.parse(ApiUrls.boostingPlanList);

      print('📤 Get Boosting Plans');
      print('URL: $url');

      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({}),
      );

      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return BoostingPlanListResponse.fromJson(jsonData);
      }
      return BoostingPlanListResponse(
        success: false,
        message: 'Failed to load plans: ${response.statusCode}',
        count: 0,
        data: [],
      );
    } catch (e) {
      print('❌ Get Boosting Plans Error: $e');
      return BoostingPlanListResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
        count: 0,
        data: [],
      );
    }
  }

  void dispose() {
    _client.close();
  }
}