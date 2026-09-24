import 'package:flutter/material.dart';
import 'package:naattulink/MVVM/View/Screen/Seller/Products/add_product_screen.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naattulink/MVVM/model/seller/store_product_model.dart';
import 'package:naattulink/MVVM/model/seller/product_variant.dart';
import 'package:naattulink/core/imagekit/imagekit_base_service.dart';
import 'package:naattulink/core/imagekit/imagekit_config.dart';

class SellerProductsScreen extends StatefulWidget {
  const SellerProductsScreen({super.key});

  @override
  State<SellerProductsScreen> createState() => _SellerProductsScreenState();
}

class _SellerProductsScreenState extends State<SellerProductsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<QueryDocumentSnapshot> _products = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

  String _searchQuery = '';
  String _selectedCategory = 'All';

  int _totalCount = 0;
  int _activeCount = 0;
  int _draftCount = 0;
  int _outOfStockCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchCounts();
    _fetchProducts();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.9) {
        _fetchMoreProducts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCounts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final countSnap = await FirebaseFirestore.instance
          .collection('store_products')
          .where('sellerId', isEqualTo: uid)
          .count()
          .get();
      int total = countSnap.count ?? 0;

      final snap = await FirebaseFirestore.instance
          .collection('store_products')
          .where('sellerId', isEqualTo: uid)
          .limit(20)
          .get();
      int active = 0;
      int draft = 0;
      int outOfStock = 0;

      for (var doc in snap.docs) {
        final data = doc.data();
        final status = (data['status'] ?? '').toString().toUpperCase();

        // Check if out of stock via status string OR zero stock quantity
        bool isOutOfStock =
            status == 'OUT OF STOCK' || status == 'OUT_OF_STOCK';

        if (!isOutOfStock) {
          // Check stockQuantity field
          final stockQty = data['stockQuantity'];
          if (stockQty != null) {
            final qty = num.tryParse(stockQty.toString()) ?? 0;
            if (qty <= 0) isOutOfStock = true;
          }

          // Check variants — if ALL variants have 0 stock, mark as out of stock
          if (!isOutOfStock) {
            final variants = data['variants'];
            if (variants is List && variants.isNotEmpty) {
              final allVariantsEmpty = variants.every((v) {
                final vStock = num.tryParse(
                        (v is Map ? v['stockQuantity'] : null)?.toString() ??
                            '1') ??
                    1;
                return vStock <= 0;
              });
              if (allVariantsEmpty) isOutOfStock = true;
            }
          }
        }

        if (isOutOfStock) {
          outOfStock++;
        } else if (status == 'ACTIVE') {
          active++;
        } else if (status == 'DRAFT') {
          draft++;
        }
      }

      if (mounted) {
        setState(() {
          _totalCount = total;
          _activeCount = active;
          _draftCount = draft;
          _outOfStockCount = outOfStock;
        });
      }
    } catch (e) {
      debugPrint("Error fetching counts: $e");
    }
  }

  Query _buildQuery() {
    return FirebaseFirestore.instance
        .collection('store_products')
        .where('sellerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .limit(10);
  }

  Future<void> _fetchProducts() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _products = [];
      _lastDocument = null;
      _hasMoreData = true;
    });
    try {
      final snap = await _buildQuery().get();
      if (snap.docs.isNotEmpty) {
        _lastDocument = snap.docs.last;
        _products = snap.docs;
      } else {
        _hasMoreData = false;
      }
    } catch (e) {
      debugPrint("Error fetching products: $e");
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  Future<void> _fetchMoreProducts() async {
    if (_isLoadingMore || !_hasMoreData || _lastDocument == null) return;
    setState(() {
      _isLoadingMore = true;
    });
    try {
      final snap = await _buildQuery().startAfterDocument(_lastDocument!).get();
      if (snap.docs.isNotEmpty) {
        _lastDocument = snap.docs.last;
        _products.addAll(snap.docs);
      } else {
        _hasMoreData = false;
      }
    } catch (e) {
      debugPrint("Error fetching more products: $e");
    } finally {
      if (mounted)
        setState(() {
          _isLoadingMore = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "My Products",
              style: TextStyle(
                color: Color(0xFF0F2E5A),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            SizedBox(height: 2),
            Text(
              "Manage your store products",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _fetchCounts();
          await _fetchProducts();
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildYourProductsHeader(_totalCount),
              const SizedBox(height: 16),
              _buildSummaryCards(_activeCount, _draftCount, _outOfStockCount),
              const SizedBox(height: 20),
              _buildAddProductButton(),
              const SizedBox(height: 20),
              _buildSearchBar(),
              const SizedBox(height: 16),
              _buildFilterChips(),
              const SizedBox(height: 20),
              _buildProductList(),
              if (_isLoadingMore)
                const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 80), // For bottom nav bar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYourProductsHeader(int total) {
    return Row(
      children: [
        const Text(
          "Your Products",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            total.toString(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F2E5A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(int active, int draft, int outOfStock) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
              active.toString(), "Active", const Color(0xFF0EA5E9)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(draft.toString(), "Draft", Colors.orange),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
              outOfStock.toString(), "Out of Stock", Colors.red),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String count, String label, Color countColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: countColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddProductButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          await Get.to(() => const AddProductScreen());
          _fetchCounts();
          _fetchProducts();
        },
        icon: const Icon(Icons.add, color: Colors.white, size: 18),
        label: const Text(
          "ADD PRODUCT",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F2E5A),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchQuery = value.trim().toLowerCase();
        });
      },
      decoration: InputDecoration(
        hintText: "Search products...",
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final Set<String> uniqueCategories = {};
    for (var doc in _products) {
      final data = doc.data() as Map<String, dynamic>;
      final cat = (data['category'] as String?)?.trim() ?? '';
      if (cat.isNotEmpty) {
        uniqueCategories.add(cat);
      }
    }

    final filters = ['All', ...uniqueCategories.toList()..sort()];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = filter == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF0F2E5A),
              selected: isSelected,
              onSelected: (bool value) {
                setState(() {
                  _selectedCategory = filter;
                });
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF0F2E5A)
                      : Colors.grey.shade300,
                ),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Helper: check if a product is truly out of stock by quantity
  bool _isProductOutOfStock(
      StoreProductModel product, Map<String, dynamic> data) {
    final status = product.status.toUpperCase();
    if (status == 'OUT OF STOCK' || status == 'OUT_OF_STOCK') return true;
    final stockQty = data['stockQuantity'];
    if (stockQty != null) {
      final qty = num.tryParse(stockQty.toString()) ?? 0;
      if (qty <= 0) return true;
    }
    final variants = data['variants'];
    if (variants is List && variants.isNotEmpty) {
      return variants.every((v) {
        final vStock = num.tryParse(
                (v is Map ? v['stockQuantity'] : null)?.toString() ?? '1') ??
            1;
        return vStock <= 0;
      });
    }
    return false;
  }

  // Priority: 0 = Out of Stock (highest), 1 = Draft, 2 = Active
  int _productPriority(StoreProductModel product, bool isOutOfStock) {
    if (isOutOfStock) return 0;
    if (product.status.toUpperCase() == 'DRAFT') return 1;
    return 2;
  }

  Widget _buildProductList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Build list of (doc, product, isOutOfStock) tuples first
    var items = _products.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final product = StoreProductModel.fromMap(data, doc.id);
      final outOfStock = _isProductOutOfStock(product, data);
      return (product: product, data: data, outOfStock: outOfStock);
    }).toList();

    // Apply search and category filters
    if (_searchQuery.isNotEmpty) {
      items = items
          .where((item) =>
              item.product.productName.toLowerCase().contains(_searchQuery))
          .toList();
    }

    if (_selectedCategory != 'All') {
      items = items
          .where((item) =>
              item.product.category.toLowerCase() ==
              _selectedCategory.toLowerCase())
          .toList();
    }

    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.0),
          child: Text(
            "No products found.",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }

    items.sort((a, b) => _productPriority(a.product, a.outOfStock)
        .compareTo(_productPriority(b.product, b.outOfStock)));

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        final product = item.product;
        final isOutOfStock = item.outOfStock;

        Color statusColor = const Color(0xFF0EA5E9);
        Color statusBgColor = const Color(0xFFE0F2FE);

        if (isOutOfStock) {
          statusColor = Colors.red;
          statusBgColor = const Color(0xFFFFE4E6);
        } else if (product.status.toUpperCase() == 'DRAFT') {
          statusColor = Colors.grey.shade700;
          statusBgColor = Colors.grey.shade200;
        }

        return _buildProductCard(
          product: product,
          statusColor: statusColor,
          statusBgColor: statusBgColor,
          isOutOfStock: isOutOfStock,
        );
      },
    );
  }

  void _showProductDetails(StoreProductModel product) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(product.productName,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F2E5A))),
              const SizedBox(height: 8),
              if (product.brand.isNotEmpty)
                Text("Brand: ${product.brand}",
                    style: const TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.w600)),
              const Divider(height: 32),
              if (product.description.isNotEmpty) ...[
                const Text("Description",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text(product.description,
                    style: const TextStyle(color: Colors.black87)),
                const Divider(height: 32),
              ],
              const Text("Pricing & Inventory",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text("Price: ₹${product.price}",
                  style: const TextStyle(fontSize: 14)),
              if (product.discountPrice > 0)
                Text("Discount Price: ₹${product.discountPrice}",
                    style: const TextStyle(
                        color: Colors.green, fontWeight: FontWeight.w600)),
              Text("Stock: ${product.stockQuantity}"),
              if (product.sku.isNotEmpty) Text("SKU: ${product.sku}"),
              const Divider(height: 32),
              if (product.specifications.isNotEmpty) ...[
                const Text("Specifications",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ...product.specifications.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              flex: 2,
                              child: Text(e.key,
                                  style: const TextStyle(color: Colors.grey))),
                          Expanded(
                              flex: 3,
                              child: Text(e.value.toString(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500))),
                        ],
                      ),
                    )),
                const Divider(height: 32),
              ],
              if (product.hasVariants && product.variants.isNotEmpty) ...[
                const Text("Variants",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ...product.variants.map((v) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: v.attributes.entries
                                  .map((e) => Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                              color: Colors.blue.shade100),
                                        ),
                                        child: Text(
                                          "${e.key}: ${e.value}",
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.blue.shade900,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (v.price > 0 && v.discountPrice > 0)
                                Text("₹${v.price.toInt()}",
                                    style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                        decoration:
                                            TextDecoration.lineThrough)),
                              Text(
                                  v.discountPrice > 0
                                      ? "₹${v.discountPrice.toInt()}"
                                      : "₹${v.price.toInt()}",
                                  style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold)),
                              Text("Stock: ${v.stockQuantity}",
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    )),
              ]
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> _showStockUpdateDialog(StoreProductModel product) async {
    await Get.bottomSheet(
      QuickEditDialog(product: product),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildProductCard({
    required StoreProductModel product,
    required Color statusColor,
    required Color statusBgColor,
    bool isOutOfStock = false,
  }) {
    return Stack(children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isOutOfStock ? const Color(0xFFFFF5F5) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOutOfStock
                ? const Color(0xFFFFCDD2)
                : const Color(0xFFF1F5F9),
            width: isOutOfStock ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isOutOfStock
                  ? Colors.red.withOpacity(0.05)
                  : Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 80,
                height: 80,
                color: Colors.grey[200],
                child: product.coverImage.isNotEmpty
                    ? Image.network(product.coverImage,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) =>
                            Icon(Icons.image, color: Colors.grey[400]))
                    : Icon(Icons.image,
                        color: Colors.grey[400]), // Fallback icon
              ),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          product.category.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0857A0), // Blue category text
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: PopupMenuButton<String>(
                          color: Colors.white,
                          surfaceTintColor: Colors.white,
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.more_vert,
                              size: 20, color: Color(0xFF172033)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onSelected: (value) async {
                            if (value == 'view') {
                              _showProductDetails(product);
                            } else if (value == 'edit') {
                              Get.dialog(
                                  const Center(
                                      child: CircularProgressIndicator()),
                                  barrierDismissible: false);
                              try {
                                final doc = await FirebaseFirestore.instance
                                    .collection('store_products')
                                    .doc(product.id)
                                    .get();
                                if (Get.isDialogOpen ?? false)
                                  Get.back(); // close loading dialog
                                if (doc.exists && doc.data() != null) {
                                  final freshProduct =
                                      StoreProductModel.fromMap(
                                          doc.data() as Map<String, dynamic>,
                                          doc.id);
                                  await Get.to(() => const AddProductScreen(),
                                      arguments: freshProduct);
                                } else {
                                  await Get.to(() => const AddProductScreen(),
                                      arguments: product);
                                }
                              } catch (e) {
                                if (Get.isDialogOpen ?? false) Get.back();
                                await Get.to(() => const AddProductScreen(),
                                    arguments: product);
                              }
                              _fetchCounts();
                              _fetchProducts();
                            } else if (value == 'update_stock') {
                              await _showStockUpdateDialog(product);
                              _fetchCounts();
                              _fetchProducts();
                            } else if (value == 'delete') {
                              bool confirm = await Get.dialog<bool>(
                                    Dialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      backgroundColor: Colors.white,
                                      child: Padding(
                                        padding: const EdgeInsets.all(24.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade50,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red,
                                                size: 32,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            const Text(
                                              'Delete Product',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1E293B),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            const Text(
                                              'Are you sure you want to delete this product? This action cannot be undone.',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.black54,
                                                height: 1.4,
                                              ),
                                            ),
                                            const SizedBox(height: 24),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: TextButton(
                                                    onPressed: () =>
                                                        Get.back(result: false),
                                                    style: TextButton.styleFrom(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 14),
                                                      backgroundColor:
                                                          Colors.grey.shade100,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                    ),
                                                    child: const Text(
                                                      'Cancel',
                                                      style: TextStyle(
                                                        color: Colors.black87,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: ElevatedButton(
                                                    onPressed: () =>
                                                        Get.back(result: true),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.red,
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 14),
                                                      elevation: 0,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                    ),
                                                    child: const Text(
                                                      'Delete',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  ) ??
                                  false;

                              if (confirm) {
                                try {
                                  // Show blocking loading dialog
                                  Get.dialog(
                                    Center(
                                      child: Material(
                                        color: Colors.transparent,
                                        child: Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(10)),
                                          ),
                                          child: const Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              CircularProgressIndicator(
                                                  color: Color(0xFF0F2E5A)),
                                              SizedBox(height: 16),
                                              Text("Deleting product...",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    barrierDismissible: false,
                                  );

                                  // 1. Delete images from ImageKit first
                                  if (product.imageMetadata.isNotEmpty) {
                                    for (var meta in product.imageMetadata) {
                                      final fileId = meta['imageFileId'];
                                      final providerId = meta['providerId'];
                                      final storageTypeStr =
                                          meta['storageType'];

                                      if (fileId != null &&
                                          storageTypeStr != null) {
                                        try {
                                          final config =
                                              await ImageKitConfigManager
                                                  .getConfig(
                                                      storageType:
                                                          storageTypeStr);
                                          final imageKitService =
                                              ImageKitBaseService(
                                            publicKey: config.publicKey,
                                            urlEndpoint: config.urlEndpoint,
                                            storageType: config.storageType,
                                          );
                                          await imageKitService.deleteImage(
                                              fileId,
                                              providerId: providerId);
                                        } catch (e) {
                                          debugPrint(
                                              "Failed to delete image $fileId: $e");
                                          if (Get.isDialogOpen ?? false)
                                            Get.back();
                                          Get.snackbar('Error Deleting Image',
                                              e.toString(),
                                              backgroundColor: Colors.red,
                                              colorText: Colors.white,
                                              snackPosition:
                                                  SnackPosition.BOTTOM,
                                              duration:
                                                  const Duration(seconds: 10),
                                              margin: const EdgeInsets.all(16));
                                          return; // Abort product deletion
                                        }
                                      }
                                    }
                                  }

                                  // 2. Delete from Firestore
                                  await FirebaseFirestore.instance
                                      .collection('store_products')
                                      .doc(product.id)
                                      .delete();

                                  // Close loading dialog
                                  Get.back();

                                  // Refresh the list and counts
                                  _fetchCounts();
                                  _fetchProducts();

                                  Get.snackbar(
                                      'Success', 'Product deleted successfully',
                                      backgroundColor: Colors.green,
                                      colorText: Colors.white,
                                      snackPosition: SnackPosition.TOP,
                                      margin: const EdgeInsets.all(16));
                                } catch (e) {
                                  // Close loading dialog if open
                                  if (Get.isDialogOpen ?? false) Get.back();
                                  Get.snackbar(
                                      'Error', 'Failed to delete product',
                                      backgroundColor: Colors.red,
                                      colorText: Colors.white,
                                      snackPosition: SnackPosition.BOTTOM,
                                      margin: const EdgeInsets.all(16));
                                }
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'view',
                              child: Row(
                                children: [
                                  Icon(Icons.visibility_outlined,
                                      size: 20, color: Colors.black87),
                                  SizedBox(width: 12),
                                  Text('View',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined,
                                      size: 20, color: Colors.black87),
                                  SizedBox(width: 12),
                                  Text('Edit',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'update_stock',
                              child: Row(
                                children: [
                                  Icon(Icons.inventory_2_outlined,
                                      size: 20, color: Colors.orange),
                                  SizedBox(width: 12),
                                  Text('Update Stock',
                                      style: TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline,
                                      size: 20, color: Colors.red),
                                  SizedBox(width: 12),
                                  Text('Delete',
                                      style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.productName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        isOutOfStock
                            ? Icons.remove_shopping_cart_outlined
                            : Icons.inventory_2_outlined,
                        size: 14,
                        color: isOutOfStock ? Colors.red : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOutOfStock
                            ? 'Out of Stock'
                            : 'Stock: ${product.stockQuantity}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isOutOfStock ? Colors.red : Colors.grey,
                          fontWeight: isOutOfStock
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      if (product.rating['totalRatings'] != null &&
                          product.rating['totalRatings'] > 0) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${(product.rating['average'] as num?)?.toStringAsFixed(1) ?? '0.0'} (${product.rating['totalRatings']})',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ]
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Wrap(
                        spacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (product.discountPrice > 0)
                            Text(
                              '₹${product.price.toInt()}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          Text(
                            '₹${product.discountPrice > 0 ? product.discountPrice.toInt() : product.price.toInt()}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0EA5E9),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ]);
  }
}

class QuickEditDialog extends StatefulWidget {
  final StoreProductModel product;

  const QuickEditDialog({Key? key, required this.product}) : super(key: key);

  @override
  State<QuickEditDialog> createState() => _QuickEditDialogState();
}

class _QuickEditDialogState extends State<QuickEditDialog> {
  late TextEditingController origPriceCtrl;
  late TextEditingController sellPriceCtrl;
  late TextEditingController stockCtrl;
  late TextEditingController deliveryCtrl;

  List<Map<String, TextEditingController>> variantCtrls = [];

  bool isUpdating = false;
  bool isFeatured = false;

  @override
  void initState() {
    super.initState();
    origPriceCtrl =
        TextEditingController(text: widget.product.price.toInt().toString());
    sellPriceCtrl = TextEditingController(
        text: widget.product.discountPrice > 0
            ? widget.product.discountPrice.toInt().toString()
            : '');
    stockCtrl =
        TextEditingController(text: widget.product.stockQuantity.toString());
    deliveryCtrl = TextEditingController(
        text: widget.product.deliveryCharge?.toInt().toString() ?? '');
    isFeatured = widget.product.isFeatured;

    if (widget.product.hasVariants && widget.product.variants.isNotEmpty) {
      for (var v in widget.product.variants) {
        variantCtrls.add({
          'orig': TextEditingController(text: v.price.toInt().toString()),
          'sell': TextEditingController(
              text: v.discountPrice > 0
                  ? v.discountPrice.toInt().toString()
                  : ''),
          'stock': TextEditingController(text: v.stockQuantity.toString()),
        });
      }
    }
  }

  @override
  void dispose() {
    origPriceCtrl.dispose();
    sellPriceCtrl.dispose();
    stockCtrl.dispose();
    deliveryCtrl.dispose();
    for (var m in variantCtrls) {
      for (var c in m.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _updateProduct() async {
    setState(() => isUpdating = true);
    try {
      final origPrice =
          double.tryParse(origPriceCtrl.text.trim()) ?? widget.product.price;
      final sellPrice = double.tryParse(sellPriceCtrl.text.trim()) ??
          widget.product.discountPrice;
      final stock =
          int.tryParse(stockCtrl.text.trim()) ?? widget.product.stockQuantity;
      final delivery = double.tryParse(deliveryCtrl.text.trim()) ??
          widget.product.deliveryCharge;

      List<ProductVariant> updatedVariants = [];
      if (widget.product.hasVariants && widget.product.variants.isNotEmpty) {
        for (int i = 0; i < widget.product.variants.length; i++) {
          final oldV = widget.product.variants[i];
          final ctrls = variantCtrls[i];
          final vOrig =
              double.tryParse(ctrls['orig']!.text.trim()) ?? oldV.price;
          final vSell =
              double.tryParse(ctrls['sell']!.text.trim()) ?? oldV.discountPrice;
          final vStock =
              int.tryParse(ctrls['stock']!.text.trim()) ?? oldV.stockQuantity;

          updatedVariants.add(ProductVariant(
            id: oldV.id,
            sku: oldV.sku,
            attributes: oldV.attributes,
            price: vOrig,
            discountPrice: vSell,
            stockQuantity: vStock,
            isAvailable: oldV.isAvailable,
            images: oldV.images,
          ));
        }
      }

      final updateData = <String, dynamic>{
        'price': origPrice,
        'discountPrice': sellPrice,
        'stockQuantity': stock,
        'deliveryCharge': delivery,
        'isFeatured': isFeatured,
      };

      if (updatedVariants.isNotEmpty) {
        updateData['variants'] = updatedVariants.map((e) => e.toMap()).toList();
      }

      await FirebaseFirestore.instance
          .collection('store_products')
          .doc(widget.product.id)
          .update(updateData);

      Get.back();
      Get.snackbar('Success', 'Product updated successfully',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update product',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => isUpdating = false);
    }
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12),
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Quick Update",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F2E5A))),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text("Global Settings",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _buildField("Original Price", origPriceCtrl)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildField("Selling Price", sellPriceCtrl)),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: _buildField("Total Stock", stockCtrl)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildField("Delivery Charge", deliveryCtrl)),
                  ],
                ),
                SwitchListTile(
                  title: const Text(
                    "Featured Product",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text(
                    "Show as Ad in customer feeds",
                    style: TextStyle(fontSize: 12),
                  ),
                  value: isFeatured,
                  onChanged: (v) => setState(() => isFeatured = v),
                  activeColor: const Color(0xFF0F2E5A),
                  contentPadding: EdgeInsets.zero,
                ),
                if (widget.product.hasVariants &&
                    widget.product.variants.isNotEmpty) ...[
                  const Divider(height: 16),
                  const Text("Variants",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...List.generate(widget.product.variants.length, (index) {
                    final v = widget.product.variants[index];
                    final ctrls = variantCtrls[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            v.attributes.values.join(' - ').toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF0F2E5A),
                            ),
                          ),
                          const Divider(height: 24, thickness: 1),
                          Row(
                            children: [
                              Expanded(
                                  child: _buildField(
                                      "Original Price", ctrls['orig']!)),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: _buildField(
                                      "Selling Price", ctrls['sell']!)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildField("Total Stock", ctrls['stock']!),
                        ],
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isUpdating ? null : _updateProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F2E5A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: isUpdating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text("Save Changes",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
