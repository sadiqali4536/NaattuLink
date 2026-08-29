import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:naattulink/MVVM/utils/Config/Toast.dart';
import 'package:naattulink/MVVM/model/seller/store_product_model.dart';
import 'package:naattulink/MVVM/model/seller/product_variant.dart';
import 'package:naattulink/MVVM/model/seller/dynamic_specifications_config.dart';
import 'package:uuid/uuid.dart';

class AddProductController extends GetxController {
  static AddProductController get to => Get.find();

  final formKey = GlobalKey<FormState>();

  // --- Step Management ---
  final RxInt currentStep = 0.obs;

  // --- Step 1: Basic Info ---
  final productNameController = TextEditingController();
  final brandController = TextEditingController();
  final descriptionController = TextEditingController();

  final RxString selectedCategoryId = ''.obs;
  final subcategoryController = TextEditingController();
  final productTypeController = TextEditingController();

  final RxList<File> images = <File>[].obs;
  final RxList<String> existingImages = <String>[].obs;
  final int maxImages = 8;

  final ImagePicker _picker = ImagePicker();

  // Navigation Options
  final RxList<CategoryDefinition> categories = <CategoryDefinition>[].obs;

  // --- Step 2: Specifications ---
  final RxMap<String, dynamic> specifications = <String, dynamic>{}.obs;
  final RxMap<String, TextEditingController> customSpecControllers =
      <String, TextEditingController>{}.obs;

  // --- Step 3: Variants ---
  final RxBool hasVariants = false.obs;
  final RxList<ProductVariant> variants = <ProductVariant>[].obs;

  // Cartesian Generator State
  final RxMap<String, List<Map<String, dynamic>>> selectedVariantOptions =
      <String, List<Map<String, dynamic>>>{}.obs;
  final RxInt expectedVariantCount = 0.obs;

  // --- Computed Stock Getters ---
  int get totalStock => int.tryParse(stockQuantityController.text) ?? 0;
  int get allocatedStock {
    if (variants.isNotEmpty) {
      return variants.fold(0, (sum, v) => sum + v.stockQuantity);
    } else {
      if (selectedVariantOptions.isEmpty) return 0;
      return selectedVariantOptions.values.first
          .fold(0, (sum, opt) => sum + ((opt['stock'] as int?) ?? 0));
    }
  }

  int get availableStock => totalStock - allocatedStock;

  // --- Step 4: Pricing & Stock (Global for no-variants) ---
  final priceController = TextEditingController();
  final discountPriceController = TextEditingController();
  final stockQuantityController = TextEditingController();
  final skuController = TextEditingController();

  // --- Step 5: Delivery ---
  final weightController = TextEditingController();
  final dimensionsController = TextEditingController();
  final deliveryChargeController = TextEditingController();
  final estimatedDeliveryTimeController = TextEditingController();
  final returnPolicyController = TextEditingController();

  final RxBool isSubmitting = false.obs;
  StoreProductModel? productToEdit;

  @override
  void onInit() {
    super.onInit();
    _fetchCategories().then((_) {
      if (Get.arguments != null && Get.arguments is StoreProductModel) {
        initForEdit(Get.arguments as StoreProductModel);
      }
    });
  }

  @override
  void onClose() {
    productNameController.dispose();
    subcategoryController.dispose();
    productTypeController.dispose();
    brandController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    discountPriceController.dispose();
    stockQuantityController.dispose();
    skuController.dispose();
    weightController.dispose();
    dimensionsController.dispose();
    deliveryChargeController.dispose();
    estimatedDeliveryTimeController.dispose();
    returnPolicyController.dispose();
    customSpecControllers.values.forEach((c) => c.dispose());
    super.onClose();
  }

  // --- Image Handling ---

  Future<void> pickImages() async {
    try {
      final int remaining = maxImages - (existingImages.length + images.length);
      if (remaining <= 0) {
        toastError("Maximum $maxImages images allowed.");
        return;
      }
      final List<XFile> picked = await _picker.pickMultiImage();
      if (picked.isNotEmpty) {
        final toAdd = picked.take(remaining).toList();
        for (var xfile in toAdd) {
          File? compressed = await _compressImage(File(xfile.path), 1600);
          if (compressed != null) {
            images.add(compressed);
          }
        }
      }
    } catch (e) {
      debugPrint("Error picking images: $e");
      toastError("Could not pick images.");
    }
  }

  Future<File?> _compressImage(File file, int minSize) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.path}/${const Uuid().v4()}.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 85,
        minWidth: minSize,
        minHeight: minSize,
      );
      return result != null ? File(result.path) : null;
    } catch (e) {
      debugPrint("Compression error: $e");
      return file; // fallback to original if compression fails
    }
  }

  void removeImage(int index) {
    if (index < images.length) images.removeAt(index);
  }

  void removeExistingImage(int index) {
    if (index < existingImages.length) existingImages.removeAt(index);
  }

  // --- Variant Generator ---

  void addVariantOption(String attribute, String option, double origPrice,
      double discPrice, int stock) {
    if (option.trim().isEmpty) return;

    int currentAlloc = allocatedStock;
    if (currentAlloc + stock > totalStock) {
      toastError(
          "Cannot allocate more than available stock (${totalStock - currentAlloc})");
      return;
    }

    final list = selectedVariantOptions[attribute] ?? [];
    if (!list.any((item) => item['name'] == option)) {
      list.add({
        'name': option,
        'origPrice': origPrice,
        'discPrice': discPrice,
        'stock': stock
      });
      selectedVariantOptions[attribute] = list;
    }
    _calculateExpectedVariants();
  }

  void removeVariantOption(String attribute, String optionName) {
    final list = selectedVariantOptions[attribute] ?? [];
    list.removeWhere((item) => item['name'] == optionName);
    selectedVariantOptions[attribute] = list;
    _calculateExpectedVariants();
  }

  void removeVariantAttribute(String attribute) {
    selectedVariantOptions.remove(attribute);
    _calculateExpectedVariants();
  }

  void _calculateExpectedVariants() {
    if (selectedVariantOptions.isEmpty) {
      expectedVariantCount.value = 0;
      return;
    }
    int count = 1;
    for (var opts in selectedVariantOptions.values) {
      if (opts.isNotEmpty) count *= opts.length;
    }
    expectedVariantCount.value = count;
  }

  void generateVariants() {
    if (expectedVariantCount.value > 50) {
      toastError(
          "Cannot generate more than 50 variants. Please reduce options.");
      return;
    }

    List<Map<String, dynamic>> combinations = [
      {
        'attributes': <String, String>{},
        'origPrice': 0.0,
        'discPrice': 0.0,
        'stock': 0
      }
    ];

    for (var entry in selectedVariantOptions.entries) {
      if (entry.value.isEmpty) continue;

      List<Map<String, dynamic>> newCombinations = [];
      for (var map in combinations) {
        for (var option in entry.value) {
          final newAttrs = Map<String, String>.from(map['attributes']);
          newAttrs[entry.key] = option['name'];

          double p = (option['origPrice'] != null &&
                  (option['origPrice'] as double) > 0)
              ? (option['origPrice'] as double)
              : (map['origPrice'] as double);
          double d = (option['discPrice'] != null &&
                  (option['discPrice'] as double) > 0)
              ? (option['discPrice'] as double)
              : (map['discPrice'] as double);
          int s = (option['stock'] != null && (option['stock'] as int) > 0)
              ? (option['stock'] as int)
              : (map['stock'] as int);

          newCombinations.add({
            'attributes': newAttrs,
            'origPrice': p,
            'discPrice': d,
            'stock': s
          });
        }
      }
      combinations = newCombinations;
    }

    if (combinations.length == 1 &&
        (combinations.first['attributes'] as Map).isEmpty) {
      toastError("Select options to generate variants.");
      return;
    }

    double basePrice = double.tryParse(priceController.text) ?? 0.0;
    double baseDiscount = double.tryParse(discountPriceController.text) ?? 0.0;

    final existingVariantsMap = <String, ProductVariant>{};
    for (var v in variants) {
      final key =
          v.attributes.entries.map((e) => '${e.key}:${e.value}').join('|');
      existingVariantsMap[key] = v;
    }

    variants.clear();

    for (var combo in combinations) {
      final attrs = combo['attributes'] as Map<String, String>;
      final key = attrs.entries.map((e) => '${e.key}:${e.value}').join('|');

      if (existingVariantsMap.containsKey(key)) {
        variants.add(existingVariantsMap[key]!);
      } else {
        double finalOrig = (combo['origPrice'] as double) > 0
            ? (combo['origPrice'] as double)
            : basePrice;
        double finalDisc = (combo['discPrice'] as double) > 0
            ? (combo['discPrice'] as double)
            : baseDiscount;
        int finalStock = combo['stock'] as int;

        variants.add(ProductVariant(
          id: const Uuid().v4(),
          attributes: attrs,
          price: finalOrig,
          discountPrice: finalDisc,
          stockQuantity: finalStock,
          isAvailable: true,
        ));
      }
    }
    toastSuccess("Generated ${variants.length} variants.");
  }

  void updateVariantPrice(String id, double price, double discount) {
    final index = variants.indexWhere((v) => v.id == id);
    if (index != -1) {
      final v = variants[index];
      variants[index] = ProductVariant(
        id: v.id,
        sku: v.sku,
        attributes: v.attributes,
        price: price,
        discountPrice: discount,
        stockQuantity: v.stockQuantity,
        isAvailable: v.isAvailable,
        images: v.images,
      );
    }
  }

  void updateVariantStock(String id, int stock) {
    final index = variants.indexWhere((v) => v.id == id);
    if (index != -1) {
      final v = variants[index];
      final currentStock = v.stockQuantity;
      final diff = stock - currentStock;
      if (diff > availableStock) {
        toastError(
            "Cannot allocate more than available stock ($availableStock)");
        return;
      }
      variants[index] = ProductVariant(
        id: v.id,
        sku: v.sku,
        attributes: v.attributes,
        price: v.price,
        discountPrice: v.discountPrice,
        stockQuantity: stock,
        isAvailable: v.isAvailable,
        images: v.images,
      );
    }
  }

  void deleteVariant(String id) {
    variants.removeWhere((v) => v.id == id);
  }

  // --- Step Navigation ---

  void nextStep() {
    if (currentStep.value < 4) {
      if (currentStep.value == 0) {
        if (productNameController.text.trim().isEmpty ||
            selectedCategoryId.value.isEmpty ||
            subcategoryController.text.trim().isEmpty ||
            productTypeController.text.trim().isEmpty ||
            priceController.text.trim().isEmpty ||
            stockQuantityController.text.trim().isEmpty) {
          toastError(
              "Please fill required Basic Info fields (including pricing and stock).");
          return;
        }
      } else if (currentStep.value == 2 && hasVariants.value) {
        if (variants.isEmpty) {
          toastError("You selected 'hasVariants' but generated no variants.");
          return;
        }
      }
      currentStep.value++;
    }
  }

  void previousStep() {
    if (currentStep.value > 0) currentStep.value--;
  }

  // --- Edit Mode ---
  void initForEdit(StoreProductModel product) {
    productToEdit = product;
    productNameController.text = product.productName;
    brandController.text = product.brand;
    descriptionController.text = product.description;

    selectedCategoryId.value = '';
    subcategoryController.text = '';
    productTypeController.text = '';

    if (product.categoryId.isNotEmpty &&
        DynamicSpecificationsConfig.getCategoryById(product.categoryId) !=
            null) {
      selectedCategoryId.value = product.categoryId;
    } else {
      // Try to find by name for legacy
      try {
        final match = categories.firstWhere((c) =>
            c.name.toLowerCase().contains(product.categoryName.toLowerCase()));
        selectedCategoryId.value = match.id;
      } catch (_) {
        if (product.categoryName.isNotEmpty) {
          selectedCategoryId.value = 'other'; // fallback
        }
      }
    }

    subcategoryController.text = product.subcategoryName.isNotEmpty
        ? product.subcategoryName
        : product.subcategoryId;
    productTypeController.text = product.productTypeName.isNotEmpty
        ? product.productTypeName
        : product.productTypeId;

    existingImages.addAll(product.images);
    specifications.assignAll(product.specifications);

    hasVariants.value = product.hasVariants;
    variants.assignAll(product.variants);

    priceController.text = product.price.toInt().toString();
    discountPriceController.text = product.discountPrice.toInt() > 0
        ? product.discountPrice.toInt().toString()
        : '';
    stockQuantityController.text = product.stockQuantity.toString();
    skuController.text = product.sku;

    weightController.text = product.weight?.toString() ?? '';
    dimensionsController.text = product.dimensions ?? '';
    deliveryChargeController.text =
        product.deliveryCharge?.toInt().toString() ?? '';
    estimatedDeliveryTimeController.text = product.estimatedDeliveryTime ?? '';
    returnPolicyController.text = product.returnPolicy ?? '';
  }

  // --- Submit ---
  Future<void> submitProduct(String status) async {
    if (isSubmitting.value) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      toastError("Please login to perform this action.");
      return;
    }

    isSubmitting.value = true;
    try {
      List<String> uploadedImageUrls = List.from(existingImages);

      for (File file in images) {
        final ref = FirebaseStorage.instance.ref().child(
            'product_images/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4()}');
        await ref.putFile(file);
        final url = await ref.getDownloadURL();
        uploadedImageUrls.add(url);
      }

      final docId = productToEdit?.id ??
          FirebaseFirestore.instance.collection('store_products').doc().id;

      final cat = categories.firstWhere((c) => c.id == selectedCategoryId.value,
          orElse: () =>
              CategoryDefinition(id: '', name: 'Unknown', subcategories: []));

      final product = StoreProductModel(
        id: docId,
        sellerId: user.uid,
        productName: productNameController.text.trim(),
        categoryId: selectedCategoryId.value,
        categoryName: cat.name,
        subcategoryId: subcategoryController.text
            .trim()
            .toLowerCase()
            .replaceAll(' ', '_'),
        subcategoryName: subcategoryController.text.trim(),
        productTypeId: productTypeController.text
            .trim()
            .toLowerCase()
            .replaceAll(' ', '_'),
        productTypeName: productTypeController.text.trim(),
        brand: brandController.text.trim(),
        description: descriptionController.text.trim(),
        price: double.tryParse(priceController.text.trim()) ?? 0.0,
        discountPrice:
            double.tryParse(discountPriceController.text.trim()) ?? 0.0,
        images: uploadedImageUrls,
        sku: skuController.text.trim(),
        stockQuantity: int.tryParse(stockQuantityController.text.trim()) ?? 0,
        status: status, // e.g. 'active', 'draft', 'pendingApproval'
        specifications: specifications,
        hasVariants: hasVariants.value,
        variantAttributes: selectedVariantOptions.keys.toList(),
        variants: hasVariants.value ? variants : [],
        weight: double.tryParse(weightController.text.trim()),
        dimensions: dimensionsController.text.trim(),
        deliveryCharge: double.tryParse(deliveryChargeController.text.trim()),
        estimatedDeliveryTime: estimatedDeliveryTimeController.text.trim(),
        returnPolicy: returnPolicyController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('store_products')
          .doc(docId)
          .set(product.toMap(), SetOptions(merge: true));

      toastSuccess("Product saved successfully.");
      Get.back();
    } catch (e) {
      debugPrint("Error saving product: $e");
      toastError("An error occurred while saving. Please try again.");
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('store_product_categories')
          .get();

      final List<CategoryDefinition> fetchedCategories =
          snapshot.docs.map((doc) {
        final data = doc.data();
        final name =
            data['name'] ?? data['Name'] ?? data['category'] ?? 'Unknown';
        return CategoryDefinition(id: doc.id, name: name, subcategories: []);
      }).toList();

      categories.assignAll(fetchedCategories);

      if (fetchedCategories.isEmpty) {
        Get.snackbar('Debug', 'Collection exists but has 0 documents',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 5));
      }
    } catch (e) {
      debugPrint("Error fetching categories: $e");
      Get.snackbar('Error', 'Failed to fetch categories: $e',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 10),
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }
}
