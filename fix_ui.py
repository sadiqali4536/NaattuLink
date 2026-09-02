import re

with open(r"d:\nattulinkapp\NaattuLink\lib\MVVM\View\Screen\Seller\Products\add_product_screen.dart", "r", encoding="utf-8") as f:
    content = f.read()

start_marker = "if (controller.variants.isNotEmpty) ...["
end_marker = "]\n            ]\n          ],\n        );\n      }),"

start_idx = content.find(start_marker)
end_idx = content.find(end_marker)

if start_idx == -1 or end_idx == -1:
    print("Could not find markers")
    exit(1)

replacement = """if (controller.selectedVariantOptions.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F2E5A).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF0F2E5A).withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      const Text("Stock Allocation",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text("Total",
                                  style: TextStyle(color: Colors.grey)),
                              Text("${controller.totalStock}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18)),
                            ],
                          ),
                          Column(
                            children: [
                              const Text("Allocated",
                                  style: TextStyle(color: Colors.grey)),
                              Text("${controller.allocatedStock}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.orange)),
                            ],
                          ),
                          Column(
                            children: [
                              const Text("Available",
                                  style: TextStyle(color: Colors.grey)),
                              Text("${controller.availableStock}",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: controller.availableStock < 0
                                          ? Colors.red
                                          : Colors.green)),
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
                      0, (sum, opt) => sum + ((opt['stock'] as int?) ?? 0));
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
                            offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: options.isNotEmpty
                              ? () => controller
                                  .toggleAllocationExpanded(attribute)
                              : null,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  attribute,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF0F2E5A)),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
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
                                )
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
                                              color: Color(0xFF1E293B)),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: stock > 0
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.red.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
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
                                        onTap: () => controller
                                            .removeVariantOption(
                                                attribute, optionName),
                                        child: const Icon(Icons.delete_outline,
                                            color: Colors.red, size: 20),
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
                                            const Text("Original Price",
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey)),
                                            Text("?$origPrice",
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                    decoration: TextDecoration
                                                        .lineThrough)),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text("Selling Price",
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey)),
                                            Text("?$discPrice",
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green,
                                                    fontSize: 14)),
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
                                          icon: const Icon(Icons.edit, size: 14),
                                          label: const Text("Edit Price",
                                              style: TextStyle(fontSize: 12)),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                const Color(0xFF0F2E5A),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4),
                                          ),
                                          onPressed: () {
                                            String priceInput =
                                                origPrice.toString();
                                            String discountInput =
                                                discPrice.toString();
                                            Get.defaultDialog(
                                              title: "Edit Price",
                                              content: Column(
                                                children: [
                                                  TextField(
                                                    keyboardType:
                                                        TextInputType.number,
                                                    decoration: const InputDecoration(
                                                        labelText:
                                                            "Original Price (MRP)"),
                                                    onChanged: (val) =>
                                                        priceInput = val,
                                                    controller:
                                                        TextEditingController(
                                                            text: priceInput),
                                                  ),
                                                  TextField(
                                                    keyboardType:
                                                        TextInputType.number,
                                                    decoration: const InputDecoration(
                                                        labelText:
                                                            "Selling Price"),
                                                    onChanged: (val) =>
                                                        discountInput = val,
                                                    controller:
                                                        TextEditingController(
                                                            text: discountInput),
                                                  ),
                                                ],
                                              ),
                                              textConfirm: "Save",
                                              textCancel: "Cancel",
                                              confirmTextColor: Colors.white,
                                              buttonColor:
                                                  const Color(0xFF0F2E5A),
                                              onConfirm: () {
                                                double p = double.tryParse(
                                                        priceInput) ??
                                                    origPrice;
                                                double d = double.tryParse(
                                                        discountInput) ??
                                                    discPrice;
                                                controller.updateOptionPrice(
                                                    attribute,
                                                    optionName,
                                                    p,
                                                    d);
                                                Get.back();
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          icon: const Icon(Icons.add_box,
                                              size: 14),
                                          label: const Text("Add Stock",
                                              style: TextStyle(fontSize: 12)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF0F2E5A),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4),
                                          ),
                                          onPressed: () {
                                            String stockInput =
                                                stock.toString();
                                            Get.defaultDialog(
                                              title: "Add Stock",
                                              content: Column(
                                                children: [
                                                  Text(
                                                      "Available to allocate: ${controller.availableStock + stock}",
                                                      style: const TextStyle(
                                                          color: Colors.green)),
                                                  const SizedBox(height: 16),
                                                  TextField(
                                                    keyboardType:
                                                        TextInputType.number,
                                                    decoration: const InputDecoration(
                                                        labelText:
                                                            "Stock Quantity"),
                                                    onChanged: (val) =>
                                                        stockInput = val,
                                                    controller:
                                                        TextEditingController(
                                                            text: stockInput),
                                                  ),
                                                ],
                                              ),
                                              textConfirm: "Save",
                                              textCancel: "Cancel",
                                              confirmTextColor: Colors.white,
                                              buttonColor:
                                                  const Color(0xFF0F2E5A),
                                              onConfirm: () {
                                                int s = int.tryParse(
                                                        stockInput) ??
                                                    stock;
                                                controller.updateOptionStock(
                                                    attribute, optionName, s);
                                                Get.back();
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            );
                          }).toList()
                        ]
                      ],
                    ),
                  );
                }).toList(),
              """

new_content = content[:start_idx] + replacement + content[end_idx:]

with open(r"d:\nattulinkapp\NaattuLink\lib\MVVM\View\Screen\Seller\Products\add_product_screen.dart", "w", encoding="utf-8") as f:
    f.write(new_content)

print("Done")
