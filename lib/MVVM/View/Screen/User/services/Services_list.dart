import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:swiftclean_project/MVVM/utils/service_functions/servicecard2.dart';
import 'package:swiftclean_project/MVVM/utils/widget/button/Scrollable/scrollable_horizontal_buttons.dart';
import 'package:swiftclean_project/MVVM/utils/widget/containner/premium_app_background.dart';
import 'package:swiftclean_project/MVVM/utils/widget/containner/shimmer_skeleton.dart';

class ServicesList extends StatefulWidget {
  const ServicesList({super.key});

  @override
  State<ServicesList> createState() => _ServicesListState();
}

class _ServicesListState extends State<ServicesList> {
  int selectedCategoryIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Center(
          child: Text(
            "Most Popular Services",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
      ),
      body: PremiumAppBackground(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('services').snapshots(),
          builder: (context, snapshot) {
            final allServices = snapshot.hasData ? snapshot.data!.docs : [];
            final List<String> currentCategoryList = [
              "For You",
              "Workers",
              "Bus",
              "Local Ads",
              "Emergency"
            ];

            for (var doc in allServices) {
              final data = doc.data() as Map<String, dynamic>;
              final cat = (data['category'] ?? '').toString().trim();
              if (cat.isNotEmpty) {
                String norm = cat.toLowerCase();
                bool isDuplicate = const {
                  'exterior',
                  'workers',
                  'interior',
                  'bus',
                  'vehicle',
                  'local ads',
                  'all',
                  'for you',
                  'emergency',
                  'home',
                }.contains(norm);

                for (var existing in currentCategoryList) {
                  if (existing.trim().toLowerCase() == norm) {
                    isDuplicate = true;
                  }
                }

                if (!isDuplicate) {
                  currentCategoryList.add(cat);
                }
              }
            }

            if (selectedCategoryIndex >= currentCategoryList.length) {
              selectedCategoryIndex = 0;
            }

            Widget listContent;
            if (snapshot.connectionState == ConnectionState.waiting) {
              listContent = Expanded(
                child: ShimmerEffect(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 110),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: Column(
                        children: List.generate(
                          4,
                          (index) => const Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: SkeletonPlaceholder(
                              width: double.infinity,
                              height: 120,
                              borderRadius: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            } else if (snapshot.hasError) {
              listContent = const Expanded(
                child: Center(child: Text("Something went wrong")),
              );
            } else if (allServices.isEmpty) {
              listContent = const Expanded(
                child: Center(child: Text("No services found")),
              );
            } else {
              final display = currentCategoryList[selectedCategoryIndex];
              final String categoryName;
              if (display == "For You") {
                categoryName = "All";
              } else if (display == "Workers") {
                categoryName = "Exterior";
              } else if (display == "Bus") {
                categoryName = "Interior";
              } else if (display == "Local Ads") {
                categoryName = "Vehicle";
              } else {
                categoryName = display;
              }

              listContent = Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 110),
                  child: Servicecard2(
                    category: categoryName,
                  ),
                ),
              );
            }

            return Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  child: ScrollableHorizontalButtons(
                    categories: currentCategoryList,
                    selectedIndex: selectedCategoryIndex,
                    onSelected: (index) {
                      setState(() => selectedCategoryIndex = index);
                    },
                  ),
                ),
                listContent,
              ],
            );
          },
        ),
      ),
    );
  }
}
