enum SpecFieldType { text, multilineText, number, dropdown, multiSelect, boolean, date, color, dimensions }

class SpecField {
  final String id;
  final String label;
  final SpecFieldType type;
  final bool isRequired;
  final List<String> options;

  const SpecField({
    required this.id,
    required this.label,
    this.type = SpecFieldType.text,
    this.isRequired = false,
    this.options = const [],
  });
}

class ProductTypeDefinition {
  final String id;
  final String name;
  final List<SpecField> specifications;
  final List<String> variantAttributes; // e.g. ['Size', 'Color']

  const ProductTypeDefinition({
    required this.id,
    required this.name,
    required this.specifications,
    required this.variantAttributes,
  });
}

class SubcategoryDefinition {
  final String id;
  final String name;
  final List<ProductTypeDefinition> productTypes;

  const SubcategoryDefinition({
    required this.id,
    required this.name,
    required this.productTypes,
  });
}

class CategoryDefinition {
  final String id;
  final String name;
  final List<SubcategoryDefinition> subcategories;

  const CategoryDefinition({
    required this.id,
    required this.name,
    required this.subcategories,
  });
}

class DynamicSpecificationsConfig {
  static const List<CategoryDefinition> categories = [
    CategoryDefinition(
      id: 'fashion',
      name: 'Fashion & Clothing',
      subcategories: [
        SubcategoryDefinition(
          id: 'mens_clothing',
          name: "Men's Clothing",
          productTypes: [
            ProductTypeDefinition(
              id: 'tshirt',
              name: 'T-Shirt',
              variantAttributes: ['Size', 'Color'],
              specifications: [
                SpecField(id: 'brand', label: 'Brand', type: SpecFieldType.text),
                SpecField(id: 'fabric', label: 'Fabric', type: SpecFieldType.dropdown, options: ['Cotton', 'Polyester', 'Linen', 'Blend']),
                SpecField(id: 'fit', label: 'Fit', type: SpecFieldType.dropdown, options: ['Slim', 'Regular', 'Oversized']),
                SpecField(id: 'pattern', label: 'Pattern', type: SpecFieldType.dropdown, options: ['Solid', 'Printed', 'Striped']),
                SpecField(id: 'neck_type', label: 'Neck Type', type: SpecFieldType.dropdown, options: ['Round Neck', 'V-Neck', 'Polo']),
              ],
            ),
            ProductTypeDefinition(
              id: 'jeans',
              name: 'Jeans',
              variantAttributes: ['Waist Size', 'Color'],
              specifications: [
                SpecField(id: 'brand', label: 'Brand', type: SpecFieldType.text),
                SpecField(id: 'fabric', label: 'Fabric', type: SpecFieldType.dropdown, options: ['Denim', 'Cotton Blend', 'Stretch Denim']),
                SpecField(id: 'fit', label: 'Fit', type: SpecFieldType.dropdown, options: ['Skinny', 'Slim', 'Regular', 'Relaxed']),
              ],
            ),
          ],
        ),
      ],
    ),
    CategoryDefinition(
      id: 'electronics',
      name: 'Electronics',
      subcategories: [
        SubcategoryDefinition(
          id: 'mobile_accessories',
          name: 'Mobile Accessories',
          productTypes: [
            ProductTypeDefinition(
              id: 'charger',
              name: 'Charger',
              variantAttributes: ['Color'],
              specifications: [
                SpecField(id: 'brand', label: 'Brand', type: SpecFieldType.text, isRequired: true),
                SpecField(id: 'output_wattage', label: 'Output Wattage', type: SpecFieldType.text),
                SpecField(id: 'port_type', label: 'Port Type', type: SpecFieldType.dropdown, options: ['USB-C', 'Micro-USB', 'Lightning']),
                SpecField(id: 'fast_charging', label: 'Fast Charging Support', type: SpecFieldType.boolean),
              ],
            ),
          ],
        ),
      ],
    ),
    CategoryDefinition(
      id: 'other',
      name: 'Other Products',
      subcategories: [
        SubcategoryDefinition(
          id: 'custom_subcat',
          name: 'Custom Subcategory',
          productTypes: [
            ProductTypeDefinition(
              id: 'custom_product',
              name: 'Custom Product',
              variantAttributes: ['Variant Attribute 1', 'Variant Attribute 2'],
              specifications: [],
            ),
          ],
        ),
      ],
    ),
  ];

  static CategoryDefinition? getCategoryById(String id) {
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  static SubcategoryDefinition? getSubcategoryById(String catId, String subcatId) {
    final cat = getCategoryById(catId);
    if (cat != null) {
      try {
        return cat.subcategories.firstWhere((s) => s.id == subcatId);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static ProductTypeDefinition? getProductTypeById(String catId, String subcatId, String prodTypeId) {
    final subcat = getSubcategoryById(catId, subcatId);
    if (subcat != null) {
      try {
        return subcat.productTypes.firstWhere((p) => p.id == prodTypeId);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
