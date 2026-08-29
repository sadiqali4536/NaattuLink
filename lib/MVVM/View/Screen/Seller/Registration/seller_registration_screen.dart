import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/controller/seller/seller_registration_controller.dart';

class SellerRegistrationScreen extends StatelessWidget {
  const SellerRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is registered
    if (!Get.isRegistered<SellerRegistrationController>()) {
      Get.put(SellerRegistrationController());
    }
    final controller = SellerRegistrationController.to;

    return Obx(() {
      final isReview = controller.isReviewMode.value;
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: isReview ? Colors.white : const Color(0xFF0F2E5A),
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isReview ? const Color(0xFF0F2E5A) : Colors.white,
            ),
            onPressed: () {
              if (isReview) {
                controller.goBackToForm();
              } else {
                Get.back();
              }
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isReview ? "Review & Submit" : "Create Your Store",
                style: TextStyle(
                  color: isReview ? const Color(0xFF0F2E5A) : Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!isReview)
                const Text(
                  "NaattuLink Seller",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: isReview
                    ? _buildReviewMode(controller)
                    : _buildFormMode(controller),
              ),
            ),
            _buildBottomBar(controller, isReview),
          ],
        ),
      );
    });
  }

  Widget _buildFormMode(SellerRegistrationController controller) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.storefront, color: Color(0xFF0F2E5A)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Create your store",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F2E5A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Tell us a little about you and your business to get started.",
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: const [
                        Icon(Icons.check, color: Color(0xFF0EA5E9), size: 14),
                        SizedBox(width: 4),
                        Text(
                          "Takes less than a minute",
                          style: TextStyle(
                              color: Color(0xFF0EA5E9),
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputLabel("Seller Name"),
              _buildTextField(
                controller: controller.sellerNameController,
                hint: "Enter your name",
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 20),
              _buildInputLabel("Location"),
              _buildTextField(
                controller: controller.locationController,
                hint: "Select your location",
                icon: Icons.location_on_outlined,
                suffixIcon: Icons.my_location,
                onSuffixIconTap: controller.openMapPicker,
              ),
              const SizedBox(height: 20),
              _buildInputLabel("Phone Number"),
              _buildTextField(
                controller: controller.phoneController,
                hint: "Enter phone number",
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              _buildInputLabel("Store Name"),
              _buildTextField(
                controller: controller.storeNameController,
                hint: "Enter your store name",
                icon: Icons.storefront_outlined,
              ),
              const Padding(
                padding: EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  "This is how customers will see your store.",
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20),
              _buildInputLabel("Category"),
              Obx(() => Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        prefixIcon:
                            Icon(Icons.category_outlined, color: Colors.grey),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      hint: const Text("Select a category",
                          style: TextStyle(color: Colors.grey, fontSize: 14)),
                      value: controller.selectedCategory.value.isEmpty
                          ? null
                          : controller.selectedCategory.value,
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: Colors.grey),
                      items: controller.categories.map((c) {
                        return DropdownMenuItem(
                            value: c,
                            child:
                                Text(c, style: const TextStyle(fontSize: 14)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null)
                          controller.selectedCategory.value = val;
                      },
                    ),
                  )),
              const SizedBox(height: 20),
              _buildInputLabel("About Your Business"),
              _buildTextField(
                controller: controller.aboutController,
                hint: "Tell customers about your business...",
                icon: Icons.description_outlined,
                maxLines: 4,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: const [
              Icon(Icons.check_circle_outline,
                  color: Color(0xFF0F2E5A), size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Your information helps us create your NaattuLink seller profile.",
                  style: TextStyle(color: Color(0xFF0F2E5A), fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildReviewMode(SellerRegistrationController controller) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Please review your details carefully. This information will be visible to customers on NaattuLink.",
            style: TextStyle(color: Colors.black87, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 24),
          _buildReviewCard(
            title: "Business Profile",
            icon: Icons.storefront,
            onEdit: controller.goBackToForm,
            children: [
              _buildReviewField(
                  "Seller Name", controller.sellerNameController.text),
              const Divider(height: 24, color: Color(0xFFF1F5F9)),
              _buildReviewField(
                  "Store Name", controller.storeNameController.text),
              const Divider(height: 24, color: Color(0xFFF1F5F9)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Category",
                      style: TextStyle(color: Colors.grey, fontSize: 11)),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F6FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      controller.selectedCategory.value,
                      style: const TextStyle(
                          color: Color(0xFF0F2E5A),
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildReviewCard(
            title: "Contact & Location",
            icon: Icons.location_on,
            onEdit: controller.goBackToForm,
            children: [
              _buildReviewField(
                  "Phone Number", controller.phoneController.text),
              const Divider(height: 24, color: Color(0xFFF1F5F9)),
              _buildReviewField("Location", controller.locationController.text),
            ],
          ),
          const SizedBox(height: 16),
          _buildReviewCard(
            title: "About Your Business",
            icon: Icons.info,
            onEdit: controller.goBackToForm,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Text(
                  '"${controller.aboutController.text}"',
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Obx(() => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: controller.acceptedTerms.value,
                      onChanged: (val) {
                        controller.acceptedTerms.value = val ?? false;
                      },
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      activeColor: const Color(0xFF0F2E5A),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                            color: Colors.black87, fontSize: 12, height: 1.4),
                        children: [
                          TextSpan(text: "I agree to the "),
                          TextSpan(
                              text: "NaattuLink Seller Terms and Conditions",
                              style: TextStyle(
                                  color: Color(0xFF0F2E5A),
                                  fontWeight: FontWeight.bold)),
                          TextSpan(text: " and Privacy Policy."),
                        ],
                      ),
                    ),
                  ),
                ],
              )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildReviewCard(
      {required String title,
      required IconData icon,
      required VoidCallback onEdit,
      required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: const Color(0xFF0F2E5A), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF0F2E5A)),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onEdit,
                child: const Text("Edit",
                    style: TextStyle(
                        color: Color(0xFF0EA5E9),
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildReviewField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B)),
          children: [
            TextSpan(text: label),
            const TextSpan(text: " *", style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    IconData? suffixIcon,
    VoidCallback? onSuffixIconTap,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey),
        suffixIcon: suffixIcon != null
            ? GestureDetector(
                onTap: onSuffixIconTap,
                child: Icon(suffixIcon, color: const Color(0xFF0F2E5A)),
              )
            : null,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0F2E5A)),
        ),
      ),
    );
  }

  Widget _buildBottomBar(
      SellerRegistrationController controller, bool isReview) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: Obx(() => ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F2E5A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: controller.isLoading.value
                    ? null
                    : (isReview
                        ? controller.submitRegistration
                        : controller.proceedToReview),
                child: controller.isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Create My Store",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward,
                              color: Colors.white, size: 20),
                        ],
                      ),
              )),
        ),
      ),
    );
  }
}
