import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/controller/seller/add_product_controller.dart';
import 'package:naattulink/MVVM/utils/Config/Toast.dart';

String formatPrice(dynamic value) {
  final price = double.tryParse(value.toString()) ?? 0;
  if (price == price.truncateToDouble()) {
    return '₹${price.toInt()}';
  }
  return '₹${price.toStringAsFixed(2)}';
}

class AddProductScreen extends StatelessWidget {
  const AddProductScreen({super.key});

  InputDecoration _inputDecor(String label, {IconData? icon, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      prefixIcon: icon != null
          ? Icon(icon, color: const Color(0xFF64748B), size: 20)
          : null,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0F2E5A), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AddProductController());
    final isEdit = controller.productToEdit != null;
    final primaryColor = const Color(0xFF0F2E5A);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF1E293B),
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          isEdit ? "Edit Product" : "Add New Product",
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Obx(() {
        return Theme(
          data: ThemeData(
            colorScheme: ColorScheme.light(primary: primaryColor),
            canvasColor: const Color(0xFFF8FAFC),
          ),
          child: Stepper(
            type: StepperType.vertical,
            elevation: 0,
            margin: const EdgeInsets.only(left: 60.0, right: 24.0, bottom: 4.0),
            currentStep: controller.currentStep.value,
            onStepTapped: (index) => controller.currentStep.value = index,
            controlsBuilder: (BuildContext context, ControlsDetails details) {
              return const SizedBox.shrink();
            },
            steps: [
              _buildStep1BasicInfo(controller),
              _buildStep2Specs(controller),
              _buildStep3Variants(controller),
              _buildStep4Delivery(controller),
              _buildStep5Preview(controller),
            ],
          ),
        );
      }),
    );
  }

  Step _buildStep1BasicInfo(AddProductController controller) {
    return Step(
      title: const Text(
        'Basic Information',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: const Text('Images, name, brand, and category'),
      content: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Text(
              "Cover Image *",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 10),
            Obx(() {
              final hasCover = controller.coverImage.value != null ||
                  controller.existingCoverImage.value.isNotEmpty;
              return Row(
                children: [
                  if (!hasCover)
                    GestureDetector(
                      onTap: controller.pickCoverImage,
                      child: Container(
                        height: 85,
                        width: 85,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: const Color(0xFF0F2E5A).withOpacity(0.3),
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              color: const Color(0xFF0F2E5A).withOpacity(0.7),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Add Cover",
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFF0F2E5A).withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (hasCover)
                    _imageTile(
                      controller.coverImage.value ??
                          controller.existingCoverImage.value,
                      controller.removeCoverImage,
                      isNetwork: controller.coverImage.value == null,
                      isCover: true,
                    ),
                ],
              );
            }),
            const SizedBox(height: 24),
            const Text(
              "Product Images",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Obx(() {
              final count =
                  controller.existingImages.length + controller.images.length;
              return Text(
                "You can add up to 3 images ($count/3 added)",
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              );
            }),
            const SizedBox(height: 10),
            Row(
              children: [
                GestureDetector(
                  onTap: controller.pickImages,
                  child: Container(
                    height: 85,
                    width: 85,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: const Color(0xFF0F2E5A).withOpacity(0.3),
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          color: const Color(0xFF0F2E5A).withOpacity(0.7),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Add",
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(0xFF0F2E5A).withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 85,
                    child: Obx(
                      () => ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: controller.existingImages.length +
                            controller.images.length,
                        itemBuilder: (context, index) {
                          if (index < controller.existingImages.length) {
                            return _imageTile(
                              controller.existingImages[index],
                              () => controller.removeExistingImage(index),
                              isNetwork: true,
                            );
                          } else {
                            return _imageTile(
                              controller.images[
                                  index - controller.existingImages.length],
                              () => controller.removeImage(
                                index - controller.existingImages.length,
                              ),
                              isNetwork: false,
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: controller.productNameController,
              decoration: _inputDecor(
                'Product Name *',
                icon: Icons.shopping_bag_outlined,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.brandController,
              decoration: _inputDecor(
                'Brand',
                icon: Icons.branding_watermark_outlined,
              ),
            ),
            const SizedBox(height: 16),
            Obx(() {
              final val = controller.selectedCategoryId.value;
              final isValid = val.isNotEmpty &&
                  controller.categories.any((c) => c.id == val);
              return DropdownButtonFormField<String>(
                value: isValid ? val : null,
                decoration: _inputDecor(
                  'Category *',
                  icon: Icons.category_outlined,
                ),
                icon: const Icon(Icons.keyboard_arrow_down),
                dropdownColor: Colors.white,
                items: controller.categories
                    .map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                    )
                    .toList(),
                onChanged: (val) {
                  controller.selectedCategoryId.value = val ?? '';
                },
              );
            }),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.subcategoryController,
              decoration: _inputDecor(
                'Subcategory *',
                icon: Icons.subdirectory_arrow_right_outlined,
                hint: 'e.g. Men\'s Clothing',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.productTypeController,
              decoration: _inputDecor(
                'Product Type *',
                icon: Icons.style_outlined,
                hint: 'e.g. T-Shirt',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.descriptionController,
              maxLines: 4,
              decoration: _inputDecor(
                'Description',
                icon: Icons.description_outlined,
              ).copyWith(alignLabelWithHint: true),
            ),
            const SizedBox(height: 24),
            const Text(
              "Pricing & Inventory",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.priceController,
              keyboardType: TextInputType.number,
              decoration: _inputDecor(
                'MRP (Original Price) *',
                icon: Icons.currency_rupee,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.discountPriceController,
              keyboardType: TextInputType.number,
              decoration: _inputDecor(
                'Selling Price',
                icon: Icons.sell_outlined,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.stockQuantityController,
              keyboardType: TextInputType.number,
              decoration: _inputDecor(
                'Total Stock Quantity *',
                icon: Icons.inventory_2_outlined,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.skuController,
              decoration: _inputDecor(
                'SKU / Barcode',
                icon: Icons.qr_code_scanner,
              ),
            ),
          ],
        ),
      ),
      isActive: controller.currentStep.value >= 0,
      state: controller.currentStep.value > 0
          ? StepState.complete
          : StepState.indexed,
    );
  }

  Widget _imageTile(
    dynamic image,
    VoidCallback onRemove, {
    required bool isNetwork,
    bool isCover = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: isNetwork
                  ? Image.network(
                      image,
                      height: 85,
                      width: 85,
                      fit: BoxFit.cover,
                    )
                  : Image.file(image, height: 85, width: 85, fit: BoxFit.cover),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.red),
              ),
            ),
          ),
          if (isCover)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F2E5A).withOpacity(0.85),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: const Text(
                  "Cover",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Step _buildStep2Specs(AddProductController controller) {
    return Step(
      title: const Text(
        'Specifications',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: const Text('Material, Capacity, Memory, etc.'),
      content: Obx(() {
        List<Widget> fields = [];

        if (controller.customSpecControllers.isEmpty) {
          fields.add(
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.list_alt, size: 40, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    "No specifications added yet.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        } else {
          fields.addAll(
            controller.customSpecControllers.keys.map((key) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          key,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: controller.customSpecControllers[key],
                        onChanged: (val) =>
                            controller.specifications[key] = val,
                        decoration: _inputDecor('Value').copyWith(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        controller.customSpecControllers.remove(key);
                        controller.specifications.remove(key);
                      },
                    ),
                  ],
                ),
              );
            }),
          );
        }

        fields.add(const SizedBox(height: 16));
        fields.add(
          OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text("Add Specification"),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F2E5A),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: const Color(0xFF0F2E5A).withOpacity(0.3)),
            ),
            onPressed: () {
              String newKey = '';
              Get.dialog(
                AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    "New Specification",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: "e.g., Battery Life",
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        onChanged: (v) => newKey = v,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F2E5A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        if (newKey.trim().isNotEmpty &&
                            !controller.customSpecControllers.containsKey(
                              newKey.trim(),
                            )) {
                          controller.customSpecControllers[newKey.trim()] =
                              TextEditingController();
                        }
                        Get.back();
                      },
                      child: const Text(
                        "Add",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: fields,
        );
      }),
      isActive: controller.currentStep.value >= 1,
      state: controller.currentStep.value > 1
          ? StepState.complete
          : StepState.indexed,
    );
  }

  Step _buildStep3Variants(AddProductController controller) {
    return Step(
      title: const Text(
        'Variants',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: const Text('Sizes, Colors, etc.'),
      content: Obx(() {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
              child: SwitchListTile(
                title: const Text(
                  "Does this product have variants?",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  "e.g. Multiple sizes, colors, etc.",
                  style: TextStyle(fontSize: 12),
                ),
                activeColor: const Color(0xFF0F2E5A),
                value: controller.hasVariants.value,
                onChanged: (val) => controller.hasVariants.value = val,
              ),
            ),
            if (controller.hasVariants.value) ...[
              const SizedBox(height: 24),
              ...controller.selectedVariantOptions.keys.map((attr) {
                final opts = controller.selectedVariantOptions[attr] ?? [];
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            attr,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                controller.removeVariantAttribute(attr),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: opts.map((opt) {
                          final name = opt['name'] as String;
                          final origPrice = opt['origPrice'] as double? ?? 0.0;
                          final discPrice = opt['discPrice'] as double? ?? 0.0;
                          final stock = opt['stock'] as int? ?? 0;
                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF0F2E5A),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      if (origPrice > 0 || discPrice > 0)
                                        Wrap(
                                          spacing: 8,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            if (origPrice > 0)
                                              Text(
                                                formatPrice(origPrice),
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey,
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                ),
                                              ),
                                            if (discPrice > 0)
                                              Text(
                                                formatPrice(discPrice),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green,
                                                  fontSize: 14,
                                                ),
                                              ),
                                          ],
                                        ),
                                      if (stock > 0)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Text(
                                            "Stock: $stock",
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.orange,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => controller
                                      .removeVariantOption(attr, name),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: Text("Add option for $attr"),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF0F2E5A),
                        ),
                        onPressed: () {
                          String opt = '';
                          String origPriceStr = controller.priceController.text;
                          String discPriceStr =
                              controller.discountPriceController.text;
                          String stockStr = '';
                          Get.dialog(
                            AlertDialog(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: Text(
                                "Add $attr",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextField(
                                      autofocus: true,
                                      decoration: InputDecoration(
                                        labelText: "Option Name (e.g., Large)",
                                        filled: true,
                                        fillColor: Colors.grey[100],
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      onChanged: (v) => opt = v,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "Original Price: ${formatPrice(controller.priceController.text)}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Selling Price: ${formatPrice(controller.discountPriceController.text)}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Available Stock: ${controller.totalStock - controller.allocatedStock}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: "Stock Quantity to Allocate",
                                        filled: true,
                                        fillColor: Colors.grey[100],
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      onChanged: (v) => stockStr = v,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      "Variant Specific Pricing",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      keyboardType: TextInputType.number,
                                      controller: TextEditingController(
                                        text: origPriceStr,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: "Variant Original Price",
                                        filled: true,
                                        fillColor: Colors.grey[100],
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      onChanged: (v) => origPriceStr = v,
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      keyboardType: TextInputType.number,
                                      controller: TextEditingController(
                                        text: discPriceStr,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: "Variant Selling Price",
                                        filled: true,
                                        fillColor: Colors.grey[100],
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      onChanged: (v) => discPriceStr = v,
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Get.back(),
                                  child: const Text(
                                    "Cancel",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0F2E5A),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {
                                    String trimmedOpt = opt.trim();
                                    if (trimmedOpt.isEmpty) {
                                      toastError("Option name is required");
                                      return;
                                    }
                                    if (stockStr.trim().isEmpty) {
                                      toastError("Stock is required");
                                      return;
                                    }
                                    int? parsedStock = int.tryParse(
                                      stockStr.trim(),
                                    );
                                    if (parsedStock == null ||
                                        parsedStock <= 0) {
                                      toastError(
                                        "Stock must be greater than 0",
                                      );
                                      return;
                                    }

                                    double origP =
                                        double.tryParse(origPriceStr.trim()) ??
                                            0.0;
                                    double discP =
                                        double.tryParse(discPriceStr.trim()) ??
                                            0.0;
                                    controller.addVariantOption(
                                      attr,
                                      trimmedOpt,
                                      origP,
                                      discP,
                                      parsedStock,
                                    );
                                    Get.back();
                                  },
                                  child: const Text(
                                    "Add",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              }),
              OutlinedButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: const Text("Add New Variant Attribute"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F2E5A),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(
                    color: const Color(0xFF0F2E5A).withOpacity(0.3),
                  ),
                ),
                onPressed: () {
                  String newAttr = '';
                  Get.dialog(
                    AlertDialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text(
                        "New Attribute",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: "e.g., Material, Color",
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            onChanged: (v) => newAttr = v,
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F2E5A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            if (newAttr.trim().isNotEmpty) {
                              controller
                                  .selectedVariantOptions[newAttr.trim()] = [];
                            }
                            Get.back();
                          },
                          child: const Text(
                            "Add",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: controller.expectedVariantCount.value > 30
                      ? Colors.orange.withOpacity(0.1)
                      : const Color(0xFF0F2E5A).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: controller.expectedVariantCount.value > 30
                        ? Colors.orange.withOpacity(0.5)
                        : const Color(0xFF0F2E5A).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: controller.expectedVariantCount.value > 30
                          ? Colors.orange
                          : const Color(0xFF0F2E5A),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Expected Variants: ${controller.expectedVariantCount.value}\n"
                        "${controller.expectedVariantCount.value > 30 ? 'Warning: High variant count. ' : ''}"
                        "${controller.expectedVariantCount.value > 50 ? 'Cannot exceed 50 variants.' : ''}",
                        style: TextStyle(
                          color: controller.expectedVariantCount.value > 50
                              ? Colors.red
                              : const Color(0xFF1E293B),
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.auto_awesome),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F2E5A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: controller.expectedVariantCount.value <= 50
                      ? controller.generateVariants
                      : null,
                  label: const Text(
                    "Generate Variants",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (controller.selectedVariantOptions.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F2E5A).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF0F2E5A).withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Stock Allocation",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text(
                                "Total",
                                style: TextStyle(color: Colors.grey),
                              ),
                              Text(
                                "${controller.totalStock}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const Text(
                                "Allocated",
                                style: TextStyle(color: Colors.grey),
                              ),
                              Text(
                                "${controller.allocatedStock}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const Text(
                                "Available",
                                style: TextStyle(color: Colors.grey),
                              ),
                              Text(
                                "${controller.availableStock}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: controller.availableStock < 0
                                      ? Colors.red
                                      : Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...controller.selectedVariantOptions.entries.map((entry) {
                  final attribute = entry.key;
                  final options = entry.value;
                  final totalStock = options.fold<int>(
                    0,
                    (sum, opt) => sum + ((opt['stock'] as int?) ?? 0),
                  );
                  final isExpanded =
                      controller.expandedAllocations[attribute] ?? false;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: options.isNotEmpty
                              ? () => controller.toggleAllocationExpanded(
                                    attribute,
                                  )
                              : null,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  attribute,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF0F2E5A),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: totalStock > 0
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isExpanded
                                      ? "Total Stock: $totalStock"
                                      : "Stock: $totalStock",
                                  style: TextStyle(
                                    color: totalStock > 0
                                        ? Colors.green
                                        : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              if (options.isNotEmpty)
                                Icon(
                                  isExpanded
                                      ? Icons.arrow_drop_up
                                      : Icons.arrow_drop_down,
                                  color: const Color(0xFF0F2E5A),
                                ),
                            ],
                          ),
                        ),
                        if (isExpanded && options.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(),
                          ...options.map((opt) {
                            final optionName = opt['name'] as String;
                            final origPrice =
                                opt['origPrice'] as double? ?? 0.0;
                            final discPrice =
                                opt['discPrice'] as double? ?? 0.0;
                            final stock = opt['stock'] as int? ?? 0;

                            return Container(
                              margin: const EdgeInsets.only(top: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          optionName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: stock > 0
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          stock > 0
                                              ? "Stock: $stock"
                                              : "Out of Stock",
                                          style: TextStyle(
                                            color: stock > 0
                                                ? Colors.green
                                                : Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: () =>
                                            controller.removeVariantOption(
                                          attribute,
                                          optionName,
                                        ),
                                        child: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Original Price",
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            Text(
                                              formatPrice(origPrice),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Selling Price",
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            Text(
                                              formatPrice(discPrice),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          icon: const Icon(
                                            Icons.edit,
                                            size: 14,
                                          ),
                                          label: const Text(
                                            "Edit Price",
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(
                                              0xFF0F2E5A,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 4,
                                            ),
                                          ),
                                          onPressed: () {
                                            String priceInput = origPrice
                                                        .truncateToDouble() ==
                                                    origPrice
                                                ? origPrice.toInt().toString()
                                                : origPrice.toString();
                                            String discountInput = discPrice
                                                        .truncateToDouble() ==
                                                    discPrice
                                                ? discPrice.toInt().toString()
                                                : discPrice.toString();
                                            Get.dialog(
                                              AlertDialog(
                                                backgroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                title: const Text(
                                                  "Edit Price",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                                content: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    TextField(
                                                      keyboardType:
                                                          TextInputType.number,
                                                      controller:
                                                          TextEditingController(
                                                        text: priceInput,
                                                      ),
                                                      decoration:
                                                          InputDecoration(
                                                        labelText:
                                                            "Original Price (MRP)",
                                                        filled: true,
                                                        fillColor:
                                                            Colors.grey[100],
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                            12,
                                                          ),
                                                          borderSide:
                                                              BorderSide.none,
                                                        ),
                                                      ),
                                                      onChanged: (val) =>
                                                          priceInput = val,
                                                    ),
                                                    const SizedBox(height: 12),
                                                    TextField(
                                                      keyboardType:
                                                          TextInputType.number,
                                                      controller:
                                                          TextEditingController(
                                                        text: discountInput,
                                                      ),
                                                      decoration:
                                                          InputDecoration(
                                                        labelText:
                                                            "Selling Price",
                                                        filled: true,
                                                        fillColor:
                                                            Colors.grey[100],
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                            12,
                                                          ),
                                                          borderSide:
                                                              BorderSide.none,
                                                        ),
                                                      ),
                                                      onChanged: (val) =>
                                                          discountInput = val,
                                                    ),
                                                  ],
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Get.back(),
                                                    child: const Text(
                                                      "Cancel",
                                                      style: TextStyle(
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          const Color(
                                                        0xFF0F2E5A,
                                                      ),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          8,
                                                        ),
                                                      ),
                                                    ),
                                                    onPressed: () {
                                                      double p =
                                                          double.tryParse(
                                                                priceInput,
                                                              ) ??
                                                              origPrice;
                                                      double d =
                                                          double.tryParse(
                                                                discountInput,
                                                              ) ??
                                                              discPrice;
                                                      controller
                                                          .updateOptionPrice(
                                                        attribute,
                                                        optionName,
                                                        p,
                                                        d,
                                                      );
                                                      Get.back();
                                                    },
                                                    child: const Text(
                                                      "Save",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          icon: const Icon(
                                            Icons.add_box,
                                            size: 14,
                                          ),
                                          label: const Text(
                                            "Add Stock",
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF0F2E5A,
                                            ),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 4,
                                            ),
                                          ),
                                          onPressed: () {
                                            String stockInput =
                                                stock.toString();
                                            Get.dialog(
                                              AlertDialog(
                                                backgroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                title: const Text(
                                                  "Add Stock",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                                content: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "Available Stock: ${controller.availableStock}",
                                                      style: const TextStyle(
                                                        color: Colors.green,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 16),
                                                    TextField(
                                                      keyboardType:
                                                          TextInputType.number,
                                                      controller:
                                                          TextEditingController(
                                                        text: stockInput,
                                                      ),
                                                      decoration:
                                                          InputDecoration(
                                                        labelText:
                                                            "Stock Quantity",
                                                        filled: true,
                                                        fillColor:
                                                            Colors.grey[100],
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                            12,
                                                          ),
                                                          borderSide:
                                                              BorderSide.none,
                                                        ),
                                                      ),
                                                      onChanged: (val) =>
                                                          stockInput = val,
                                                    ),
                                                  ],
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Get.back(),
                                                    child: const Text(
                                                      "Cancel",
                                                      style: TextStyle(
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          const Color(
                                                        0xFF0F2E5A,
                                                      ),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          8,
                                                        ),
                                                      ),
                                                    ),
                                                    onPressed: () {
                                                      int s = int.tryParse(
                                                            stockInput,
                                                          ) ??
                                                          stock;
                                                      controller
                                                          .updateOptionStock(
                                                        attribute,
                                                        optionName,
                                                        s,
                                                      );
                                                      Get.back();
                                                    },
                                                    child: const Text(
                                                      "Save",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ],
            ],
          ],
        );
      }),
      isActive: controller.currentStep.value >= 2,
      state: controller.currentStep.value > 2
          ? StepState.complete
          : StepState.indexed,
    );
  }

  Step _buildStep4Delivery(AddProductController controller) {
    Widget buildSectionContainer({
      required String title,
      required IconData icon,
      required List<Widget> children,
    }) {
      return Card(
        margin: const EdgeInsets.only(bottom: 20),
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: const Color(0xFF0F2E5A)),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF0F2E5A),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ),
      );
    }

    return Step(
      title: const Text(
        'Delivery & Returns',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: const Text('Payment and Shipping details'),
      content: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildSectionContainer(
              title: "Payment Options",
              icon: Icons.payments_outlined,
              children: [
                CheckboxListTile(
                  title: const Text(
                    "Cash on Delivery",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  value: controller.isCashOnDelivery.value,
                  onChanged: (v) {
                    if (v == false && !controller.isOnlinePayment.value) {
                      toastError("At least one payment option is required");
                      return;
                    }
                    controller.isCashOnDelivery.value = v ?? false;
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeColor: const Color(0xFF0F2E5A),
                ),
                CheckboxListTile(
                  title: const Text(
                    "Online Payment",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  value: controller.isOnlinePayment.value,
                  onChanged: (v) {
                    if (v == false && !controller.isCashOnDelivery.value) {
                      toastError("At least one payment option is required");
                      return;
                    }
                    controller.isOnlinePayment.value = v ?? false;
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeColor: const Color(0xFF0F2E5A),
                ),
              ],
            ),
            buildSectionContainer(
              title: "Delivery Charge",
              icon: Icons.local_shipping_outlined,
              children: [
                RadioListTile<bool>(
                  title: const Text(
                    "Free Shipping",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  value: true,
                  groupValue: controller.isFreeShipping.value,
                  onChanged: (v) {
                    if (v != null) {
                      controller.isFreeShipping.value = v;
                      controller.deliveryChargeController.clear();
                    }
                  },
                  contentPadding: EdgeInsets.zero,
                  activeColor: const Color(0xFF0F2E5A),
                  dense: true,
                ),
                RadioListTile<bool>(
                  title: const Text(
                    "Paid Delivery",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  value: false,
                  groupValue: controller.isFreeShipping.value,
                  onChanged: (v) {
                    if (v != null) controller.isFreeShipping.value = v;
                  },
                  contentPadding: EdgeInsets.zero,
                  activeColor: const Color(0xFF0F2E5A),
                  dense: true,
                ),
                if (!controller.isFreeShipping.value) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: controller.deliveryChargeController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecor(
                      'Delivery Charge (₹)',
                      icon: Icons.currency_rupee,
                    ),
                  ),
                ],
              ],
            ),
            buildSectionContainer(
              title: "Returns",
              icon: Icons.replay_outlined,
              children: [
                RadioListTile<bool>(
                  title: const Text(
                    "Returns Available",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  value: true,
                  groupValue: controller.isReturnsAvailable.value,
                  onChanged: (v) {
                    if (v != null) controller.isReturnsAvailable.value = v;
                  },
                  contentPadding: EdgeInsets.zero,
                  activeColor: const Color(0xFF0F2E5A),
                  dense: true,
                ),
                RadioListTile<bool>(
                  title: const Text(
                    "Returns Not Available",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  value: false,
                  groupValue: controller.isReturnsAvailable.value,
                  onChanged: (v) {
                    if (v != null) {
                      controller.isReturnsAvailable.value = v;
                      controller.returnPolicyController.clear();
                    }
                  },
                  contentPadding: EdgeInsets.zero,
                  activeColor: const Color(0xFF0F2E5A),
                  dense: true,
                ),
                if (controller.isReturnsAvailable.value) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: controller.returnPolicyController,
                    decoration: _inputDecor(
                      'Return Validity (e.g., 7 days)',
                      icon: Icons.event_repeat,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
      isActive: controller.currentStep.value >= 3,
      state: controller.currentStep.value > 3
          ? StepState.complete
          : StepState.indexed,
    );
  }

  Step _buildStep5Preview(AddProductController controller) {
    return Step(
      title: const Text(
        'Publish',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: const Text('Review and save'),
      content: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: const Column(
              children: [
                Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
                SizedBox(height: 16),
                Text(
                  "You're all set!",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Review your product details before publishing.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Obx(
            () => Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: controller.submittingStatus.value == 'draft'
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF0F2E5A),
                            ),
                          )
                        : const Icon(Icons.drafts_outlined),
                    onPressed: controller.submittingStatus.value.isNotEmpty
                        ? null
                        : () => controller.submitProduct('draft'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F2E5A),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                        color: const Color(0xFF0F2E5A).withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    label: const Text(
                      "Save as Draft",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: controller.submittingStatus.value == 'active'
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.cloud_upload_outlined),
                    onPressed: controller.submittingStatus.value.isNotEmpty
                        ? null
                        : () => controller.submitProduct('active'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F2E5A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    label: const Text(
                      "Publish",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      isActive: controller.currentStep.value >= 4,
      state: StepState.indexed,
    );
  }
}
