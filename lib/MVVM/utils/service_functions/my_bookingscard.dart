import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:naattulink/MVVM/utils/Constants/colors.dart';
import 'package:naattulink/MVVM/utils/Constants/image_strings.dart';

class MyBookingscard extends StatelessWidget {
  MyBookingscard({super.key});
  final List<Map<String, dynamic>> service = [
    {
      "title": "Garden ",
      "image": AppImages.grassCutImg,
      "rating": 3.8,
      "discount": 33,
      "old_Price": 299,
      "new_Price": 200,
      "Hour": "/Hour",
      "per_hour": "(Per Hour)"
    },
    {
      "title": "Pet Cleaning",
      "image": AppImages.petCleaning,
      "rating": 4.8,
      "discount": 25,
      "old_Price": 399,
      "new_Price": 299,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 238, 238, 238),
      body: SafeArea(
        child: ListView.builder(
          itemCount: service.length,
          shrinkWrap: true,
          itemBuilder: (_, index) {
            var item = service[index];
            return GestureDetector(
              onTap: () {},
              child: Card(
                color: primary.c,
                elevation: 4,
                margin:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          item['image'],
                          height: 120,
                          width: 95.5,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            height: 120,
                            width: 95.5,
                            color: primary.c,
                            child: const Icon(
                              Icons.broken_image,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item["title"],
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                RatingBarIndicator(
                                  rating: item["rating"],
                                  itemBuilder: (_, index) => const Icon(
                                    Icons.star,
                                    color: gradientgreen2.c,
                                  ),
                                  itemCount: 5,
                                  itemSize: 23.0,
                                  direction: Axis.horizontal,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  item["rating"].toString(),
                                  style:
                                      const TextStyle(color: gradientgreen2.c),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.arrow_downward,
                                  size: 15,
                                  color: gradientgreen2.c,
                                ),
                                Text(
                                  "${item["discount"]}%",
                                  style: const TextStyle(
                                      color: gradientgreen2.c, fontSize: 14),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  "₹${item["old_Price"]}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  "₹${item["new_Price"]}",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 10, 10, 10),
                                  ),
                                ),
                                const SizedBox(width: 1),
                                Text(
                                  item["Hour"]?.toString() ?? "",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Container(
                              height: 1,
                              width: 280,
                              color: const Color.fromARGB(255, 200, 200, 200),
                            ),
                            SizedBox(
                              height: 2,
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {},
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: primary.c,
                                    ),
                                    height: 30,
                                    width: 120,
                                    child: Row(
                                      children: [
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(left: 20),
                                          child: Image.asset(
                                            "assets/icons/can.png",
                                          ),
                                        ),
                                        SizedBox(
                                          width: 10,
                                        ),
                                        Text(
                                          "Remove",
                                          style: TextStyle(
                                              color: const Color.fromARGB(
                                                  255, 0, 0, 0)),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                Container(
                                  color:
                                      const Color.fromARGB(255, 200, 200, 200),
                                  height: 32,
                                  width: 1.5,
                                ),
                                GestureDetector(
                                  onTap: () {},
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: primary.c,
                                    ),
                                    height: 30,
                                    width: 120,
                                    child: Row(
                                      children: [
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(left: 10),
                                          child: Image.asset(
                                              "assets/icons/booking.png"),
                                        ),
                                        SizedBox(
                                          width: 10,
                                        ),
                                        Text("Book now")
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
