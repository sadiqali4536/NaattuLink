import re

with open(r"d:\nattulinkapp\NaattuLink\lib\MVVM\View\Screen\Seller\Products\add_product_screen.dart", "r", encoding="utf-8") as f:
    content = f.read()

edit_price_start = content.find('Get.defaultDialog(\n                                              title: "Edit Price",')
edit_price_end = content.find(';\n                                            },', edit_price_start) + 1

if edit_price_start != -1 and edit_price_end != -1:
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
    content = content[:edit_price_start] + edit_price_new + content[edit_price_end:]

add_stock_start = content.find('Get.defaultDialog(\n                                              title: "Add Stock",')
add_stock_end = content.find(';\n                                            },', add_stock_start) + 1

if add_stock_start != -1 and add_stock_end != -1:
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
    content = content[:add_stock_start] + add_stock_new + content[add_stock_end:]

with open(r"d:\nattulinkapp\NaattuLink\lib\MVVM\View\Screen\Seller\Products\add_product_screen.dart", "w", encoding="utf-8") as f:
    f.write(content)

print("Dialogs updated successfully")
