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
import 'package:naattulink/core/imagekit/imagekit_base_service.dart';
import 'package:naattulink/core/imagekit/imagekit_config.dart';
import 'package:naattulink/core/imagekit/image_storage_type.dart';
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

  final Rx<File?> coverImage = Rx<File?>(null);
  final RxString existingCoverImage = ''.obs;

  final RxList<File> images = <File>[].obs;
  final RxList<String> existingImages = <String>[].obs;
  final int maxImages = 4;

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
    if (selectedVariantOptions.isEmpty) return 0;
    int total = 0;
    for (var list in selectedVariantOptions.values) {
      total += list.fold(0, (sum, opt) => sum + ((opt['stock'] as int?) ?? 0));
    }
    return total;
  }

  int get availableStock {
    int remain = totalStock - allocatedStock;
    return remain < 0 ? 0 : remain;
  }

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

  final RxBool isCashOnDelivery = true.obs;
  final RxBool isOnlinePayment = true.obs;
  final RxBool isFreeShipping = false.obs;
  final RxBool isReturnsAvailable = false.obs;

  final RxString submittingStatus = ''.obs;
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

  int get currentTotalImages =>
      (coverImage.value != null || existingCoverImage.value.isNotEmpty
          ? 1
          : 0) +
      existingImages.length +
      images.length;

  Future<void> pickCoverImage() async {
    try {
      final hasCover =
          coverImage.value != null || existingCoverImage.value.isNotEmpty;
      if (!hasCover && currentTotalImages >= maxImages) {
        toastError("Maximum $maxImages images allowed in total.");
        return;
      }
      final XFile? picked =
          await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        File? compressed = await _compressImage(File(picked.path), 1600);
        if (compressed != null) {
          coverImage.value = compressed;
          existingCoverImage.value = '';
        }
      }
    } catch (e) {
      toastError("Error picking cover image.");
    }
  }

  void removeCoverImage() {
    coverImage.value = null;
    existingCoverImage.value = '';
  }

  Future<void> pickImages() async {
    try {
      final int remaining = maxImages - currentTotalImages;
      if (remaining <= 0) {
        toastError("Maximum $maxImages images allowed in total.");
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
          "Cannot allocate more than available stock ${totalStock - currentAlloc}");
      return;
    }

    final list = List<Map<String, dynamic>>.from(
        selectedVariantOptions[attribute] ?? []);
    if (!list.any((item) => item['name'] == option)) {
      list.add({
        'name': option,
        'origPrice': origPrice,
        'discPrice': discPrice,
        'stock': stock
      });
      selectedVariantOptions[attribute] = list;
    } else {
      toastError("Option '$option' already exists for $attribute.");
      return;
    }

    final currentMap = Map<String, List<Map<String, dynamic>>>.from(
      selectedVariantOptions,
    );
    currentMap[attribute] = list;
    selectedVariantOptions.assignAll(currentMap);

    _syncGeneratedVariantsWithOptions();
    _calculateExpectedVariants();

    debugPrint("DEBUG AddVariant: attribute=$attribute, option=$option");
    debugPrint(
        "DEBUG selectedVariantOptions: ${selectedVariantOptions.toString()}");
    debugPrint("DEBUG Variant keys: ${selectedVariantOptions.keys.toList()}");
  }

  void removeVariantOption(String attribute, String optionName) {
    final list = List<Map<String, dynamic>>.from(
        selectedVariantOptions[attribute] ?? []);
    list.removeWhere((item) => item['name'] == optionName);
    selectedVariantOptions[attribute] = list;
    selectedVariantOptions.refresh();
    _syncGeneratedVariantsWithOptions();
    _calculateExpectedVariants();
  }

  void removeVariantAttribute(String attribute) {
    selectedVariantOptions.remove(attribute);
    selectedVariantOptions.refresh();
    _syncGeneratedVariantsWithOptions();
    _calculateExpectedVariants();
  }

  void _syncGeneratedVariantsWithOptions() {
    variants.removeWhere((variant) {
      bool containsDeleted = false;
      variant.attributes.forEach((attrKey, optVal) {
        if (!selectedVariantOptions.containsKey(attrKey)) {
          containsDeleted = true;
        } else {
          final list = selectedVariantOptions[attrKey]!;
          if (!list.any((item) => item['name'] == optVal)) {
            containsDeleted = true;
          }
        }
      });
      return containsDeleted;
    });
    variants.refresh();
  }

  void _calculateExpectedVariants() {
    if (selectedVariantOptions.isEmpty) {
      expectedVariantCount.value = 0;
      return;
    }
    int count = 1;
    bool hasAny = false;
    for (var opts in selectedVariantOptions.values) {
      if (opts.isNotEmpty) {
        count *= opts.length;
        hasAny = true;
      }
    }
    expectedVariantCount.value = hasAny ? count : 0;
    debugPrint("DEBUG ExpectedVariants: count=${expectedVariantCount.value}");
  }

  void generateVariants() {
    debugPrint(
      'Stage 1 — Selected variant keys: '
      '${selectedVariantOptions.keys.toList()}',
    );

    if (selectedVariantOptions.isEmpty) return;

    if (expectedVariantCount.value == 0) {
      toastError("Please add at least one option to generate variants.");
      return;
    }

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
              : 0.0;
          double d = (option['discPrice'] != null &&
                  (option['discPrice'] as double) > 0)
              ? (option['discPrice'] as double)
              : 0.0;
          int s = (option['stock'] != null && (option['stock'] as int) > 0)
              ? (option['stock'] as int)
              : 0;

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
      final sortedKeys = v.attributes.keys.toList()..sort();
      final key = sortedKeys.map((k) => '$k:${v.attributes[k]}').join('|');
      existingVariantsMap[key] = v;
    }

    final newVariantsList = <ProductVariant>[];

    for (var combo in combinations) {
      final attrs = combo['attributes'] as Map<String, String>;
      final sortedKeys = attrs.keys.toList()..sort();
      final key = sortedKeys.map((k) => '$k:${attrs[k]}').join('|');

      if (existingVariantsMap.containsKey(key)) {
        newVariantsList.add(existingVariantsMap[key]!);
      } else {
        double finalOrig = (combo['origPrice'] as double) > 0
            ? (combo['origPrice'] as double)
            : basePrice;
        double finalDisc = (combo['discPrice'] as double) > 0
            ? (combo['discPrice'] as double)
            : baseDiscount;
        int finalStock = combo['stock'] as int;

        newVariantsList.add(ProductVariant(
          id: const Uuid().v4(),
          attributes: attrs,
          price: finalOrig,
          discountPrice: finalDisc,
          stockQuantity: finalStock,
          isAvailable: true,
        ));
      }
    }

    variants.assignAll(newVariantsList);

    debugPrint(
      'Stage 2 — Generated combinations: ${combinations.length}',
    );
    debugPrint(
      'Stage 3 — Stock allocation cards: ${variants.length}',
    );

    for (final variant in variants) {
      debugPrint('Generated variant: ${variant.toString()}');
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

  // --- Grouped Stock Allocation UI Methods ---

  final RxMap<String, bool> expandedAllocations = <String, bool>{}.obs;

  void toggleAllocationExpanded(String attribute) {
    expandedAllocations[attribute] = !(expandedAllocations[attribute] ?? false);
  }

  void updateOptionPrice(
      String attribute, String optionName, double price, double discount) {
    final currentMap =
        Map<String, List<Map<String, dynamic>>>.from(selectedVariantOptions);
    if (currentMap.containsKey(attribute)) {
      final list = List<Map<String, dynamic>>.from(currentMap[attribute]!);
      final index = list.indexWhere((item) => item['name'] == optionName);
      if (index != -1) {
        final item = Map<String, dynamic>.from(list[index]);
        item['origPrice'] = price;
        item['discPrice'] = discount;
        list[index] = item;
        currentMap[attribute] = list;
        selectedVariantOptions.assignAll(currentMap);
      }
    }
  }

  void updateOptionStock(String attribute, String optionName, int stock) {
    final currentMap =
        Map<String, List<Map<String, dynamic>>>.from(selectedVariantOptions);
    if (currentMap.containsKey(attribute)) {
      final list = List<Map<String, dynamic>>.from(currentMap[attribute]!);
      final index = list.indexWhere((item) => item['name'] == optionName);
      if (index != -1) {
        final item = Map<String, dynamic>.from(list[index]);
        final currentStock = item['stock'] as int? ?? 0;
        final diff = stock - currentStock;
        if (diff > availableStock) {
          toastError(
              "Cannot allocate more than available stock ($availableStock)");
          return;
        }
        item['stock'] = stock;
        list[index] = item;
        currentMap[attribute] = list;
        selectedVariantOptions.assignAll(currentMap);
      }
    }
  }

  void deleteVariant(String id) {
    variants.removeWhere((v) => v.id == id);
    variants.refresh();
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

    existingCoverImage.value = product.coverImage;
    List<String> imgs = List.from(product.images);
    if (product.coverImage.isNotEmpty) {
      imgs.remove(product.coverImage);
    }
    existingImages.assignAll(imgs);
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
    if (submittingStatus.value.isNotEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      toastError("Please login to perform this action.");
      return;
    }

    submittingStatus.value = status;
    try {
      List<String> uploadedImageUrls = List.from(existingImages);
      List<Map<String, dynamic>> uploadedImageMetadata =
          List.from(productToEdit?.imageMetadata ?? []);

      final config =
          ImageKitConfigManager.getConfig(ImageStorageType.seller_product_1);
      final imageKitService = ImageKitBaseService(
        publicKey: config.publicKey,
        urlEndpoint: config.urlEndpoint,
        storageType: ImageStorageType.seller_product_1,
      );

      String finalCoverImageUrl = existingCoverImage.value;

      if (coverImage.value != null) {
        final originalName = coverImage.value!.path.split('/').last;
        final fileName =
            imageKitService.generateFileName(originalName, 'product_cover');
        final bytes = await coverImage.value!.readAsBytes();

        final result = await imageKitService.uploadImage(
          imageBytes: bytes,
          fileName: fileName,
          folder: config.defaultFolder,
        );

        finalCoverImageUrl = result.imageUrl;
        uploadedImageUrls.insert(0, result.imageUrl);
        uploadedImageMetadata.insert(0, {
          'imageUrl': result.imageUrl,
          'imageFileId': result.imageFileId,
          'providerId': result.providerId,
          'storageType': ImageStorageType.seller_product_1.name,
        });
      } else if (finalCoverImageUrl.isNotEmpty &&
          !uploadedImageUrls.contains(finalCoverImageUrl)) {
        uploadedImageUrls.insert(0, finalCoverImageUrl);
      }

      for (File file in images) {
        final originalName = file.path.split('/').last;
        final fileName =
            imageKitService.generateFileName(originalName, 'product');
        final bytes = await file.readAsBytes();

        final result = await imageKitService.uploadImage(
          imageBytes: bytes,
          fileName: fileName,
          folder: config.defaultFolder,
        );

        uploadedImageUrls.add(result.imageUrl);
        uploadedImageMetadata.add({
          'imageUrl': result.imageUrl,
          'imageFileId': result.imageFileId,
          'providerId': result.providerId,
          'storageType': ImageStorageType.seller_product_1.name,
        });
      }

      final docId = productToEdit?.id ??
          FirebaseFirestore.instance.collection('store_products').doc().id;

      final cat = categories.firstWhere((c) => c.id == selectedCategoryId.value,
          orElse: () =>
              CategoryDefinition(id: '', name: 'Unknown', subcategories: []));

      final product = StoreProductModel(
        id: docId,
        sellerId: user.uid,
        ownerId: user.uid,
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
        imageMetadata: uploadedImageMetadata,
        coverImage: finalCoverImageUrl,
        sku: skuController.text.trim(),
        stockQuantity: int.tryParse(stockQuantityController.text.trim()) ?? 0,
        status: status, // e.g. 'active', 'draft', 'pendingApproval'
        specifications: specifications,
        hasVariants: hasVariants.value,
        variantAttributes: selectedVariantOptions.keys.toList(),
        variants: hasVariants.value ? variants : [],
        weight: double.tryParse(weightController.text.trim()),
        dimensions: dimensionsController.text.trim(),
        deliveryCharge: isFreeShipping.value
            ? 0.0
            : double.tryParse(deliveryChargeController.text.trim()),
        estimatedDeliveryTime: estimatedDeliveryTimeController.text.trim(),
        returnPolicy: isReturnsAvailable.value
            ? returnPolicyController.text.trim()
            : null,
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
      submittingStatus.value = '';
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
