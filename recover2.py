import re

with open(r"d:\nattulinkapp\NaattuLink\lib\MVVM\View\Screen\Seller\Products\add_product_screen.dart", "r", encoding="utf-8") as f:
    content = f.read()

# 1. Option Validation Replacement
# We will just find the block that starts with `double origP = double.tryParse(` inside the onPressed block.
# Let's use a regex to replace it.
pattern_validation = re.compile(
    r'onPressed:\s*\(\)\s*\{\s*double\s*origP\s*=\s*double\.tryParse\(\s*origPriceStr\.trim\(\)\)\s*\?\?\s*0\.0;\s*double\s*discP\s*=\s*double\.tryParse\(\s*discPriceStr\.trim\(\)\)\s*\?\?\s*0\.0;\s*int\s*s\s*=\s*int\.tryParse\(\s*stockStr\.trim\(\)\)\s*\?\?\s*0;\s*controller\.addVariantOption\(\s*attr,\s*opt,\s*origP,\s*discP,\s*s\);\s*Get\.back\(\);\s*\}'
)

new_validation = """onPressed: () {
                                          String trimmedOpt = opt.trim();
                                          if (trimmedOpt.isEmpty) {
                                            toastError("Option name is required");
                                            return;
                                          }
                                          if (stockStr.trim().isEmpty) {
                                            toastError("Stock is required");
                                            return;
                                          }
                                          int? parsedStock = int.tryParse(stockStr.trim());
                                          if (parsedStock == null || parsedStock <= 0) {
                                            toastError("Stock must be greater than 0");
                                            return;
                                          }

                                          double origP = double.tryParse(
                                                  origPriceStr.trim()) ??
                                              0.0;
                                          double discP = double.tryParse(
                                                  discPriceStr.trim()) ??
                                              0.0;
                                          controller.addVariantOption(
                                              attr, trimmedOpt, origP, discP, parsedStock);
                                          Get.back();
                                        }"""

if pattern_validation.search(content):
    content = pattern_validation.sub(new_validation, content)
    print("Option Validation applied")
else:
    print("WARNING: Option validation block not found")

# 2. Edit Price Dialog
pattern_edit_price = re.compile(
    r'Get\.defaultDialog\(\s*title:\s*"Edit Price",.*?onConfirm:\s*\(\)\s*\{.*?Get\.back\(\);\s*\},?\s*\);?',
    re.DOTALL
)

edit_price_new = """Get.dialog(
                                              AlertDialog(
                                                backgroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(16)),
                                                title: const Text("Edit Price",
                                                    style: TextStyle(
                                                        fontWeight: FontWeight.bold, fontSize: 18)),
                                                content: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    TextField(
                                                      keyboardType: TextInputType.number,
                                                      controller: TextEditingController(text: priceInput),
                                                      decoration: InputDecoration(
                                                        labelText: "Original Price (MRP)",
                                                        filled: true,
                                                        fillColor: Colors.grey[100],
                                                        border: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(12),
                                                            borderSide: BorderSide.none),
                                                      ),
                                                      onChanged: (val) => priceInput = val,
                                                    ),
                                                    const SizedBox(height: 12),
                                                    TextField(
                                                      keyboardType: TextInputType.number,
                                                      controller: TextEditingController(text: discountInput),
                                                      decoration: InputDecoration(
                                                        labelText: "Selling Price",
                                                        filled: true,
                                                        fillColor: Colors.grey[100],
                                                        border: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(12),
                                                            borderSide: BorderSide.none),
                                                      ),
                                                      onChanged: (val) => discountInput = val,
                                                    ),
                                                  ],
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Get.back(),
                                                    child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                                                  ),
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                        backgroundColor: const Color(0xFF0F2E5A),
                                                        shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(8))),
                                                    onPressed: () {
                                                      double p = double.tryParse(priceInput) ?? origPrice;
                                                      double d = double.tryParse(discountInput) ?? discPrice;
                                                      controller.updateOptionPrice(attribute, optionName, p, d);
                                                      Get.back();
                                                    },
                                                    child: const Text("Save", style: TextStyle(color: Colors.white)),
                                                  ),
                                                ],
                                              ),
                                            )"""

if pattern_edit_price.search(content):
    content = pattern_edit_price.sub(edit_price_new, content)
    print("Edit Price Dialog applied")
else:
    print("WARNING: Edit Price Dialog block not found")

# 3. Add Stock Dialog
pattern_add_stock = re.compile(
    r'Get\.defaultDialog\(\s*title:\s*"Add Stock",.*?onConfirm:\s*\(\)\s*\{.*?Get\.back\(\);\s*\},?\s*\);?',
    re.DOTALL
)

add_stock_new = """Get.dialog(
                                              AlertDialog(
                                                backgroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(16)),
                                                title: const Text("Add Stock",
                                                    style: TextStyle(
                                                        fontWeight: FontWeight.bold, fontSize: 18)),
                                                content: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "Available to allocate: ${controller.availableStock + stock}",
                                                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)
                                                    ),
                                                    const SizedBox(height: 16),
                                                    TextField(
                                                      keyboardType: TextInputType.number,
                                                      controller: TextEditingController(text: stockInput),
                                                      decoration: InputDecoration(
                                                        labelText: "Stock Quantity",
                                                        filled: true,
                                                        fillColor: Colors.grey[100],
                                                        border: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(12),
                                                            borderSide: BorderSide.none),
                                                      ),
                                                      onChanged: (val) => stockInput = val,
                                                    ),
                                                  ],
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Get.back(),
                                                    child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                                                  ),
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                        backgroundColor: const Color(0xFF0F2E5A),
                                                        shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(8))),
                                                    onPressed: () {
                                                      int s = int.tryParse(stockInput) ?? stock;
                                                      controller.updateOptionStock(attribute, optionName, s);
                                                      Get.back();
                                                    },
                                                    child: const Text("Save", style: TextStyle(color: Colors.white)),
                                                  ),
                                                ],
                                              ),
                                            )"""

if pattern_add_stock.search(content):
    content = pattern_add_stock.sub(add_stock_new, content)
    print("Add Stock Dialog applied")
else:
    print("WARNING: Add Stock Dialog block not found")

with open(r"d:\nattulinkapp\NaattuLink\lib\MVVM\View\Screen\Seller\Products\add_product_screen.dart", "w", encoding="utf-8") as f:
    f.write(content)

print("Recover script completed successfully")
