// import 'package:flutter/material.dart';
// import 'package:swiftclean_project/MVVM/utils/Constants/colors.dart';

// class ScrollableHorizontalButtons extends StatelessWidget {
//   final List<String> categories;
//   final int selectedIndex;
//   final ValueChanged<int>? onSelected;

//   const ScrollableHorizontalButtons({
//     super.key,
//     required this.categories,
//     required this.selectedIndex,
//     this.onSelected,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 39,
//       child: ListView.builder(
//         scrollDirection: Axis.horizontal,
//         itemCount: categories.length,
//         itemBuilder: (context, index) {
//           bool isSelected = selectedIndex == index;

//           return GestureDetector(
//             onTap: () {
//               if (onSelected != null) {
//                 onSelected!(index);
//               }
//             },
//             child: Container(
//               margin: const EdgeInsets.symmetric(horizontal: 2),
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(20),
//                 border: Border.all(
//                   color: isSelected ? gradientgreen2.c : const Color.fromRGBO(189, 189, 189, 1),
//                 ),
//                 gradient: isSelected
//                     ? const LinearGradient(
//                         colors: [gradientgreen1.c, gradientgreen2.c, gradientgreen3.c],
//                         begin: Alignment.topLeft,
//                         end: Alignment.topRight,
//                       )
//                     : null,
//                 color: isSelected ? null : Colors.white,
//                 boxShadow: isSelected
//                     ? [
//                         BoxShadow(
//                           color: gradientgreen2.c.withOpacity(0.4),
//                           blurRadius: 1.5,
//                         ),
//                       ]
//                     : [],
//               ),
//               child: Center(
//                 child: Text(
//                   categories[index],
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.bold,
//                     color: isSelected ? Colors.white : black.c,
//                   ),
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:swiftclean_project/MVVM/utils/Constants/colors.dart';

class ScrollableHorizontalButtons extends StatelessWidget {
  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;
  final bool isDark;

  const ScrollableHorizontalButtons({
    super.key,
    required this.categories,
    required this.selectedIndex,
    this.onSelected,
    this.isDark = false,
  });

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'all':
      case 'for you':
        return Icons.auto_awesome;
      case 'exterior':
      case 'workers':
        return Icons.engineering_outlined;
      case 'interior':
      case 'bus':
        return Icons.directions_bus_filled_outlined;
      case 'vehicle':
      case 'local ads':
        return Icons.campaign_outlined;
      case 'pet':
      case 'market':
      case 'online shops':
        return Icons.storefront_outlined;
      case 'home':
        return Icons.home_outlined;
      case 'emergency':
        return Icons.local_hospital_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isDark) {
      if (categories.length <= 5) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: List.generate(categories.length, (index) {
              bool isSelected = selectedIndex == index;
              String category = categories[index];

              return Expanded(
                child: GestureDetector(
                  onTap: () => onSelected?.call(index),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.12),
                        ),
                        child: Icon(
                          _getIconForCategory(category),
                          color: isSelected
                              ? const Color(0xFFFFB800)
                              : Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        category,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? const Color(0xFFFFB800)
                              : Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 2.5,
                        width: 24,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFFB800)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        );
      } else {
        return SizedBox(
          height: 88,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              bool isSelected = selectedIndex == index;
              String category = categories[index];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: GestureDetector(
                  onTap: () => onSelected?.call(index),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.12),
                        ),
                        child: Icon(
                          _getIconForCategory(category),
                          color: isSelected
                              ? const Color(0xFFFFB800)
                              : Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        category,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? const Color(0xFFFFB800)
                              : Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 2.5,
                        width: 24,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFFB800)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }
    } else {
      return SizedBox(
        height: 39,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            bool isSelected = selectedIndex == index;
            String category = categories[index];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => onSelected?.call(index),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF0F2E5A)
                          : const Color(0xFFE2E8F0),
                    ),
                    color: isSelected ? const Color(0xFF0F2E5A) : Colors.white,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF0F2E5A).withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color:
                            isSelected ? Colors.white : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
  }
}
