import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:naattulink/MVVM/View/Screen/User/cart/cart_service.dart';
import 'package:naattulink/MVVM/View/Screen/User/cart/cart_service.dart'
    as CartService;
import 'package:naattulink/MVVM/View/Authentication/controller/recommendation_controller.dart';
import 'package:naattulink/MVVM/model/models/cart_model.dart';
import 'package:naattulink/MVVM/utils/Constants/colors.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';
import 'package:naattulink/MVVM/utils/widget/custom_message_dialog/customsnakbar.dart';

class PetCleaning extends StatefulWidget {
  final String? serviceId;
  String? category;
  String? serviceName;
  int? rating;
  String? originalPrice;
  String? discount;
  String? image;
  String? discountPrice;
  String? serviceType;
  String? selectedPet;
  PetCleaning(
      {super.key,
      this.serviceId,
      this.category,
      this.serviceName,
      this.rating,
      this.originalPrice,
      this.discount,
      this.image,
      this.discountPrice,
      this.serviceType});

  @override
  State<PetCleaning> createState() => _PetCleaningState();
}

class _PetCleaningState extends State<PetCleaning> {
  DateTime selectedDate = DateTime.now();
  int selectedIndex = 0;

  bool isAddedToCart = false;

  @override
  void initState() {
    super.initState();
    checkIfServiceInCart();
    RecommendationController.to
        .trackProductView(widget.serviceId ?? widget.serviceName ?? '');
  }

  bool isBookingFormComplete() {
    if (widget.serviceName == null ||
        widget.category == null ||
        widget.serviceType == null ||
        widget.discountPrice == null ||
        selectedPet == null ||
        hour < 1 ||
        hour > 12 ||
        minute < 0 ||
        minute > 59 ||
        meridiem.isEmpty) {
      return false;
    }

    int convertedHour = hour;
    if (meridiem == 'PM' && hour != 12) convertedHour += 12;
    if (meridiem == 'AM' && hour == 12) convertedHour = 0;

    DateTime selectedDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      convertedHour,
      minute,
    );

    return selectedDateTime.isAfter(DateTime.now());
  }

  Future<void> checkIfServiceInCart() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final cartRef = FirebaseFirestore.instance
        .collection('carts')
        .doc(userId)
        .collection('cartItems');

    final existing = await cartRef
        .where('serviceName', isEqualTo: widget.serviceName)
        .where('category', isEqualTo: widget.category)
        .where('serviceType', isEqualTo: widget.serviceType)
        .get();

    if (mounted) {
      setState(() {
        isAddedToCart = existing.docs.isNotEmpty;
      });
    }
  }

  int hour = DateTime.now().hour % 12;
  int minute = DateTime.now().minute;
  String meridiem = 'AM';

  List<String> petTypes = ['Dog', 'Cat'];
  String? selectedPet;

  int count = 1;

  List<String> offers = [
    'Bathing and drying',
    'Hair trimming and styling',
    'Nail clipping and paw care',
    'Ear cleaning and teeth brushing'
  ];

  List<DateTime> getWeekDates() {
    final today = DateTime.now();
    return List.generate(30, (index) => today.add(Duration(days: index)));
  }

  String _getMonthName(int month) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return monthNames[month - 1];
  }

  void incrementHour() {
    setState(() {
      if (hour == 11) {
        hour = 12;
        meridiem = meridiem == 'AM' ? 'PM' : 'AM';
      } else if (hour == 12) {
        hour = 1;
      } else {
        hour++;
      }
    });
  }

  void decrementHour() {
    setState(() {
      if (hour == 12) {
        hour = 11;
      } else if (hour == 1) {
        hour = 12;
        meridiem = meridiem == 'AM' ? 'PM' : 'AM';
      } else {
        hour--;
      }
    });
  }

  void incrementMinute() {
    setState(() {
      minute += 1;
      if (minute >= 60) {
        minute = 0;
        incrementHour();
      }
    });
  }

  void decrementMinute() {
    setState(() {
      minute -= 1;
      if (minute < 0) {
        minute = 59;
        decrementHour();
      }
    });
  }

  void toggleMeridiem(String value) {
    setState(() {
      meridiem = value;
    });
  }

  void incrementCount() {
    setState(() {
      count++;
    });
  }

  void decrementCount() {
    setState(() {
      if (count > 1) count--;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Format date and time for display in SnackBar
    final formattedDate = DateFormat('EEE, MMM d, yyyy').format(selectedDate);
    final formattedTime =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $meridiem';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 300,
                  child: Image.asset(
                    "assets/image/pet2.png",
                    fit: BoxFit.cover,
                  ),
                ),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 250, 249, 249),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // What we offer title
                        const Text(
                          "What we offer",
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 15),

                        // Offers grid buttons
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: offers
                              .map(
                                (offer) => Material(
                                  elevation: 3,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    width: (MediaQuery.of(context).size.width -
                                            60) /
                                        2,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                          255, 243, 243, 243),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Center(
                                      child: Text(
                                        offer,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 25),

                        // Date selector label
                        const Text(
                          "Select Date",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 10),

                        // Horizontal date selector
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            padding: EdgeInsets.only(left: 10, right: 10),
                            scrollDirection: Axis.horizontal,
                            itemCount: getWeekDates().length,
                            itemBuilder: (context, index) {
                              final date = getWeekDates()[index];
                              final isSelected = index == selectedIndex;
                              final monthName = _getMonthName(date.month);

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedIndex = index;
                                    selectedDate = date;
                                  });
                                },
                                child: Container(
                                  margin: EdgeInsets.only(right: 10),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? gradientgreen2.c
                                        : const Color.fromRGBO(
                                            229, 229, 229, 1),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        DateFormat.E().format(date),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        '${date.day} ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        '${monthName} ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Time selector label
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Select Time",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w500),
                              ),
                              DropdownButton<String>(
                                hint: const Text("Select Pet"),
                                value: selectedPet,
                                items: petTypes
                                    .map((pet) => DropdownMenuItem(
                                          value: pet,
                                          child: Text(pet),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedPet = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Time selector row (hour, minute, AM/PM)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Hour selector
                            Column(
                              children: [
                                Material(
                                  elevation: 6,
                                  borderRadius: BorderRadius.circular(30),
                                  child: IconButton(
                                    icon: const Icon(Icons.add),
                                    color: gradientgreen2.c,
                                    onPressed: incrementHour,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Material(
                                  elevation: 6,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.grey.shade300,
                                            blurRadius: 4)
                                      ],
                                    ),
                                    child: Text(
                                      hour.toString().padLeft(2, '0'),
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Material(
                                  elevation: 6,
                                  borderRadius: BorderRadius.circular(30),
                                  child: IconButton(
                                    icon: Icon(Icons.remove,
                                        color: gradientgreen2.c),
                                    onPressed: decrementHour,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 15),

                            const Text(":", style: TextStyle(fontSize: 24)),

                            const SizedBox(width: 15),

                            // Minute selector
                            Column(
                              children: [
                                Material(
                                  elevation: 6,
                                  borderRadius: BorderRadius.circular(30),
                                  child: IconButton(
                                    icon: Icon(Icons.add,
                                        color: gradientgreen2.c),
                                    onPressed: incrementMinute,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Material(
                                  elevation: 6,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.grey.shade300,
                                            blurRadius: 4)
                                      ],
                                    ),
                                    child: Text(
                                      minute.toString().padLeft(2, '0'),
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Material(
                                  elevation: 6,
                                  borderRadius: BorderRadius.circular(30),
                                  child: IconButton(
                                    icon: Icon(Icons.remove,
                                        color: gradientgreen2.c),
                                    onPressed: decrementMinute,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(width: 20),

                            // AM/PM toggle buttons
                            Column(
                              children: [
                                TextButton(
                                  style: TextButton.styleFrom(
                                    backgroundColor: meridiem == 'AM'
                                        ? gradientgreen2.c
                                        : const Color(0xFFE7E7E7),
                                    foregroundColor: meridiem == 'AM'
                                        ? Colors.white
                                        : Colors.black,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    minimumSize: const Size(60, 44),
                                  ),
                                  onPressed: () => toggleMeridiem('AM'),
                                  child: const Text("AM",
                                      style: TextStyle(fontSize: 18)),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    backgroundColor: meridiem == 'PM'
                                        ? gradientgreen2.c
                                        : const Color(0xFFE7E7E7),
                                    foregroundColor: meridiem == 'PM'
                                        ? Colors.white
                                        : Colors.black,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    minimumSize: const Size(60, 44),
                                  ),
                                  onPressed: () => toggleMeridiem('PM'),
                                  child: const Text("PM",
                                      style: TextStyle(fontSize: 18)),
                                ),
                              ],
                            ),
                            SizedBox(
                              width: 20,
                            ),
                            Column(
                              children: [
                                Material(
                                  elevation: 4,
                                  borderRadius: BorderRadius.circular(15),
                                  child: Container(
                                    height: 32,
                                    width: 32,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(15),
                                        color: Colors.white),
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: Icon(Icons.add,
                                          color: gradientgreen3.c),
                                      onPressed: incrementCount,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Material(
                                  elevation: 4,
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    height: 40,
                                    width: 47,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.white),
                                    child: Center(
                                      child: Text(
                                        '$count',
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Material(
                                  elevation: 4,
                                  borderRadius: BorderRadius.circular(15),
                                  child: Container(
                                    height: 32,
                                    width: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: Icon(Icons.remove,
                                          color: gradientgreen3.c),
                                      onPressed: decrementCount,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 60),

                        // Book now button
                        Center(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: gradientgreen2.c,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 70, vertical: 15),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                            ),
                            onPressed: () {
                              if (selectedPet == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please select a pet type.'),
                                  ),
                                );
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Booking confirmed on $formattedDate at $formattedTime\nPet: $selectedPet, Count: $count'),
                                ),
                              );
                            },
                            child: const Text(
                              "Book Now",
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 10,
              top: 40,
              child: const AppBackButton(),
            ),
            Positioned(
              top: 310,
              left: 300,
              child: IconButton(
                icon: isAddedToCart
                    ? const Icon(Icons.check_circle,
                        color: gradientgreen2.c, size: 30)
                    : const Icon(Icons.add_shopping_cart_outlined),
                onPressed: () async {
                  if (isAddedToCart) return;

                  if (!isBookingFormComplete()) {
                    CustomSnackBar.show(
                        iconcolor: erroriconcolor,
                        icon: Icons.cancel,
                        context: context,
                        message:
                            " Please fill the booking before adding to cart.",
                        color: const Color.fromARGB(255, 249, 246, 246));
                    return;
                  }

                  final userId = FirebaseAuth.instance.currentUser?.uid;
                  if (userId == null) return;

                  final cartRef = FirebaseFirestore.instance
                      .collection('carts')
                      .doc(userId)
                      .collection('cartItems');

                  final existing = await cartRef
                      .where('serviceName', isEqualTo: widget.serviceName)
                      .where('category', isEqualTo: widget.category)
                      .where('serviceType', isEqualTo: widget.serviceType)
                      .get();

                  if (existing.docs.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.white,
                        content: Text("Item already in cart",
                            style: TextStyle(color: Colors.black)),
                      ),
                    );
                    setState(() => isAddedToCart = true);
                    RecommendationController.to.trackCart(
                        widget.serviceId ?? widget.serviceName ?? '', true);
                    return;
                  }

                  await CartService.addToCart(
                    context: context,
                    serviceName: widget.serviceName,
                    image: widget.image,
                    originalPrice: widget.originalPrice,
                    discountPrice: widget.discountPrice,
                    discount: widget.discount,
                    rating: widget.rating,
                    category: widget.category,
                    serviceType: widget.serviceType,
                    selectedDate: null,
                    selectedTime: '',
                    extraDetails: {
                      'selectedPet': selectedPet,
                      'count': count,
                    },
                  );

                  setState(() => isAddedToCart = true);
                  RecommendationController.to.trackCart(
                      widget.serviceId ?? widget.serviceName ?? '', true);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            Text(
              "₹",
              style: TextStyle(color: Colors.white, fontSize: 30),
            ),
            SizedBox(width: 05),
            Text("${widget.discountPrice}",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold)),
            Text("/Day",
                style: TextStyle(
                    color: const Color.fromRGBO(133, 130, 130, 1),
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            Spacer(),
            SizedBox(
              height: 57,
              width: 160,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: gradientgreen2.c,
                ),
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;

                  if (widget.serviceName == null ||
                      widget.category == null ||
                      widget.serviceType == null ||
                      widget.discountPrice == null) {
                    return;
                  }

                  try {
                    final bookingData = {
                      'userId': user.uid,
                      'serviceId': widget.serviceId ?? '',
                      'serviceTitle': widget.serviceName ?? '',
                      'image': widget.image ?? '',
                      'originalPrice': widget.originalPrice ?? '',
                      'discountPrice': widget.discountPrice ?? '',
                      'discount': widget.discount ?? '',
                      'rating': widget.rating ?? 0,
                      'category': widget.category ?? '',
                      'serviceType': widget.serviceType ?? '',
                      'selectedDate': selectedDate,
                      'selectedTime': formattedTime,
                      'bookingType': 'Interior',
                      'status': 'booked',
                      'createdAt': FieldValue.serverTimestamp(),
                    };

                    await FirebaseFirestore.instance
                        .collection('bookings')
                        .add(bookingData);
                    RecommendationController.to.trackPurchase(
                        [widget.serviceId ?? widget.serviceName ?? ''],
                        double.tryParse(widget.discountPrice ?? '') ?? 0.0);

                    if (!mounted) return;
                    CustomSnackBar.show(
                        useTick: true,
                        context: context,
                        message:
                            "Booking request for ${widget.serviceName} submitted.",
                        color: Colors.white);
                  } catch (e) {
                    print("Direct Booking error: $e");
                    if (!mounted) return;
                    CustomSnackBar.show(
                        icon: Icons.cancel,
                        iconcolor: erroriconcolor,
                        context: context,
                        message: "Failed to book ${widget.serviceName}.",
                        color: Colors.white);
                  }
                },
                child: Text("Book Now",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
