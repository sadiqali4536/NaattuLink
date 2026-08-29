import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/model/user/cart_item_model.dart';
import 'package:naattulink/MVVM/model/models/app_location_model.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';
import 'package:naattulink/MVVM/View/Screen/User/checkout/controller/payment_controller.dart';

class PaymentPage extends StatelessWidget {
  final List<CartItemModel> cartItems;
  final double totalAmount;
  final AppLocationModel address;
  final bool isFromCart;

  PaymentPage({
    Key? key,
    required this.cartItems,
    required this.totalAmount,
    required this.address,
    this.isFromCart = false,
  }) : super(key: key);

  final PaymentController controller = Get.put(PaymentController());
  final TextEditingController _transactionIdController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const AppBackButton(),
        title: const Text(
          'Payments',
          style: TextStyle(
            color: Color(0xFF0F2E5A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Obx(() {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTotalAmountCard(),
              const SizedBox(height: 24),
              const Text(
                'Select Payment Method',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2E5A),
                ),
              ),
              const SizedBox(height: 16),
              _buildPaymentOption(
                title: 'Cash on Delivery',
                method: PaymentMethod.cashOnDelivery,
                icon: Icons.local_shipping,
              ),
              const SizedBox(height: 12),
              _buildPaymentOption(
                title: 'UPI',
                method: PaymentMethod.upi,
                icon: Icons.currency_rupee,
              ),
              if (controller.selectedPaymentMethod.value == PaymentMethod.upi)
                _buildUpiSection(),
            ],
          ),
        );
      }),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildTotalAmountCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total Amount',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '₹${totalAmount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F2E5A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required PaymentMethod method,
    required IconData icon,
  }) {
    final isSelected = controller.selectedPaymentMethod.value == method;
    return GestureDetector(
      onTap: () => controller.selectPaymentMethod(method),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEBF0FF) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF2956D3) : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF2956D3)
                  : const Color(0xFF64748B),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: const Color(0xFF0F2E5A),
                ),
              ),
            ),
            Radio<PaymentMethod>(
              value: method,
              groupValue: controller.selectedPaymentMethod.value,
              onChanged: (value) {
                if (value != null) {
                  controller.selectPaymentMethod(value);
                }
              },
              activeColor: const Color(0xFF2956D3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpiSection() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Scan the QR code and complete the payment',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Placeholder for QR Code (We could use qr_flutter package but for now an icon/placeholder as we didn't add the package)
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Icon(
              Icons.qr_code_2,
              size: 100,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                controller.initiateUpiPayment(totalAmount);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2956D3),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Pay Now',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          if (controller.upiPaymentState.value != UpiPaymentState.initial) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Payment completed?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F2E5A),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _transactionIdController,
              decoration: InputDecoration(
                hintText: 'Enter UPI Transaction ID / UTR',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                controller.updateTransactionId(value);
              },
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Obx(() {
      final isUpi = controller.selectedPaymentMethod.value == PaymentMethod.upi;
      final isPlacingOrder = controller.isPlacingOrder.value;

      bool isButtonDisabled = isPlacingOrder;

      if (isUpi) {
        final state = controller.upiPaymentState.value;
        if (state == UpiPaymentState.initial) {
          isButtonDisabled = true;
        } else if (controller.transactionId.value.trim().isEmpty) {
          isButtonDisabled = true;
        }
      }

      final buttonText =
          isUpi ? 'Confirm Payment & Place Order' : 'Place Order';

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: isButtonDisabled
                ? null
                : () {
                    controller.placeOrder(
                      cartItems: cartItems,
                      totalAmount: totalAmount,
                      address: address,
                      isFromCart: isFromCart,
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isButtonDisabled ? Colors.grey[400] : const Color(0xFF2956D3),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isPlacingOrder
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      );
    });
  }
}
