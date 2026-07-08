import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/booking_confirm.dart';
import 'package:naattulink/MVVM/View/Screen/User/cart/cart_service.dart'
    as CartService;
import 'package:naattulink/MVVM/View/Authentication/controller/recommendation_controller.dart';
import 'package:naattulink/MVVM/utils/Constants/colors.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/custombackbutton.dart';
import 'package:naattulink/MVVM/utils/widget/custom_message_dialog/customsnakbar.dart';

class ExteriorBookingpage extends StatefulWidget {
  String? serviceName;
  String? image;
  String? originalPrice;
  String? discountPrice;
  String? discount;
  int? rating;
  String? category;
  String? serviceType;
  DateTime? selectedDate;
  String? selectedTime;

  ExteriorBookingpage(
      {super.key,
      this.serviceName,
      this.image,
      this.originalPrice,
      this.discountPrice,
      this.discount,
      this.rating,
      this.category,
      this.serviceType,
      this.selectedDate,
      this.selectedTime});

  @override
  State<ExteriorBookingpage> createState() => _ExteriorBookingpageState();
}

class _ExteriorBookingpageState extends State<ExteriorBookingpage> {
  double _currentSliderValue = 1000;
  DateTime selectedDate = DateTime.now();
  bool isAddedToCart = false;
  int hour = 8;
  int minute = 30;
  String meridiem = 'AM';

  @override
  void initState() {
    super.initState();
    checkIfServiceInCart();
    RecommendationController.to.trackProductView(widget.serviceName ?? '');
  }

  bool isBookingFormComplete() {
    if (widget.serviceName == null ||
        widget.category == null ||
        widget.serviceType == null ||
        widget.discountPrice == null ||
        _currentSliderValue <= 0 ||
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
        .where('service_name', isEqualTo: widget.serviceName)
        .where('category', isEqualTo: widget.category)
        .where('service_type', isEqualTo: widget.serviceType)
        .get();

    if (mounted) {
      setState(() {
        isAddedToCart = existing.docs.isNotEmpty;
      });
    }
  }

  bool _isDialogShown = false;

  showLoadingDialog(BuildContext context) {
    _isDialogShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  List<DateTime> getWeekDates() {
    final today = DateTime.now();
    return List.generate(30, (index) => today.add(Duration(days: index)));
  }

  String get formattedDate =>
      '${DateFormat.E().format(selectedDate)}, ${DateFormat.MMMd().format(selectedDate)}';

  String get formattedTime =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $meridiem';

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
      minute += 5;
      if (minute >= 60) {
        minute = 0;
        incrementHour();
      }
    });
  }

  void decrementMinute() {
    setState(() {
      minute -= 5;
      if (minute < 0) {
        minute = 55;
        decrementHour();
      }
    });
  }

  void toggleMeridiem(String value) {
    setState(() {
      meridiem = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final weekDates = getWeekDates();

    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Column(
              children: [
                Image.asset("assets/image/garden_size_large.png",
                    width: double.infinity),
                Container(
                  width: 440,
                  color: const Color.fromARGB(255, 250, 249, 249),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Garden Size",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w500)),
                        Slider(
                          activeColor: gradientgreen2.c,
                          value: _currentSliderValue,
                          max: 1500,
                          divisions: 30,
                          label: _currentSliderValue.round().toString(),
                          onChanged: (value) =>
                              setState(() => _currentSliderValue = value),
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Select Date",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: weekDates.length,
                            itemBuilder: (context, index) {
                              final date = weekDates[index];
                              final isSelected = selectedDate.day == date.day &&
                                  selectedDate.month == date.month;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => selectedDate = date),
                                child: Container(
                                  margin: EdgeInsets.symmetric(horizontal: 4),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? gradientgreen2.c
                                        : Color.fromRGBO(229, 229, 229, 1),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(DateFormat.E().format(date),
                                          style: TextStyle(
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.black)),
                                      SizedBox(height: 5),
                                      Text('${date.day}',
                                          style: TextStyle(
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.black)),
                                      SizedBox(height: 5),
                                      Text(DateFormat.MMM().format(date),
                                          style: TextStyle(
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.black)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 20),
                        Text("Select Time",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w500)),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Column(children: [
                              Material(
                                elevation: 6,
                                borderRadius: BorderRadius.circular(30),
                                child: IconButton(
                                    onPressed: incrementHour,
                                    icon: Icon(Icons.add,
                                        color: gradientgreen2.c)),
                              ),
                              SizedBox(height: 15),
                              Material(
                                elevation: 6,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.grey.shade300,
                                            blurRadius: 4)
                                      ],
                                    ),
                                    child:
                                        Text(hour.toString().padLeft(2, '0'))),
                              ),
                              SizedBox(height: 15),
                              Material(
                                elevation: 6,
                                borderRadius: BorderRadius.circular(30),
                                child: IconButton(
                                    onPressed: decrementHour,
                                    icon: Icon(Icons.remove,
                                        color: gradientgreen2.c)),
                              ),
                            ]),
                            SizedBox(width: 10),
                            Text(":", style: TextStyle(fontSize: 22)),
                            SizedBox(width: 10),
                            Column(children: [
                              Material(
                                elevation: 6,
                                borderRadius: BorderRadius.circular(30),
                                child: IconButton(
                                    onPressed: incrementMinute,
                                    icon: Icon(Icons.add,
                                        color: gradientgreen2.c)),
                              ),
                              SizedBox(height: 15),
                              Material(
                                elevation: 6,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
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
                                        minute.toString().padLeft(2, '0'))),
                              ),
                              SizedBox(height: 15),
                              Material(
                                elevation: 6,
                                borderRadius: BorderRadius.circular(30),
                                child: IconButton(
                                    onPressed: decrementMinute,
                                    icon: Icon(Icons.remove,
                                        color: gradientgreen2.c)),
                              ),
                            ]),
                            SizedBox(width: 10),
                            TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: meridiem == 'AM'
                                    ? gradientgreen2.c
                                    : Color.fromARGB(255, 231, 231, 231),
                                foregroundColor: meridiem == 'AM'
                                    ? Colors.white
                                    : Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                minimumSize: Size(52, 42),
                              ),
                              onPressed: () => toggleMeridiem('AM'),
                              child: Text("AM"),
                            ),
                            SizedBox(width: 13),
                            TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: meridiem == 'PM'
                                    ? gradientgreen2.c
                                    : Color.fromARGB(255, 231, 231, 231),
                                foregroundColor: meridiem == 'PM'
                                    ? Colors.white
                                    : Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                minimumSize: Size(52, 42),
                              ),
                              onPressed: () => toggleMeridiem('PM'),
                              child: Text("PM"),
                            ),
                          ],
                        ),
                        SizedBox(height: 110),
                      ],
                    ),
                  ),
                )
              ],
            ),
            Positioned(
              top: 10,
              left: 15,
              child: SafeArea(
                child: customBackbutton1(onpress: () => Navigator.pop(context)),
              ),
            ),
            Positioned(
              top: 280,
              left: 300,
              child: SafeArea(
                child: IconButton(
                  icon: isAddedToCart
                      ? Icon(Icons.check_circle,
                          color: gradientgreen2.c, size: 30)
                      : Icon(Icons.add_shopping_cart_outlined),
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
                    );

                    if (!mounted) return;
                    setState(() => isAddedToCart = true);
                    RecommendationController.to
                        .trackCart(widget.serviceName ?? '', true);
                    // CustomSnackBar.show(
                    // useTick: true,
                    // context: context, message: " Added to cart successfully.",color: Colors.white
                    // );
                  },
                ),
              ),
            )
          ],
        ),
      ),
      floatingActionButton: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Row(
          children: [
            Text("\u20B9", style: TextStyle(color: Colors.white, fontSize: 30)),
            SizedBox(width: 5),
            Text("${widget.discountPrice}",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold)),
            Text("/hour",
                style: TextStyle(color: Colors.grey[400], fontSize: 20)),
            Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: gradientgreen2.c,
                  minimumSize: Size(160, 57)),
              onPressed: () async {
                String selectedTime =
                    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $meridiem';
                if (selectedDate == null || selectedTime == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.white,
                      content: Text(
                        "📅 Please select a date and time before booking.",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  );
                  return;
                }

                showLoadingDialog(context);

                try {
                  final userId = FirebaseAuth.instance.currentUser?.uid;
                  if (userId == null) return;

// Fetch user details from Firestore
                  final userDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .get();
                  final userData = userDoc.data();

                  final bookingData = {
                    'userId': userId,
                    'serviceTitle': widget.serviceName ?? '',
                    'image': widget.image ?? '',
                    'originalPrice': widget.originalPrice ?? '',
                    'discountPrice': widget.discountPrice ?? '',
                    'discount': widget.discount ?? '',
                    'rating': widget.rating ?? 0,
                    'category': 'Exterior',
                    'serviceType': widget.serviceType ?? '',
                    'bookingType': 'Exterior',
                    'status': 'pending',
                    'workerId': null,
                    'workerName': null,
                    'createdAt': FieldValue.serverTimestamp(),
                    'selectedDate': selectedDate,
                    'selectedTime': selectedTime,
                    'gardenSize': _currentSliderValue.toStringAsFixed(0),

                    //  user details
                    'bookedUserName': userData?['username'] ?? '',
                    'bookedUserPhone': userData?['phone'] ?? '',
                    'bookedUserAddress': userData?['address'] ?? '',
                  };

                  await FirebaseFirestore.instance
                      .collection('bookings')
                      .add(bookingData);
                  RecommendationController.to.trackPurchase(
                      [widget.serviceName ?? ''],
                      double.tryParse(widget.discountPrice ?? '') ?? 0.0);

                  if (_isDialogShown) {
                    Navigator.of(context, rootNavigator: true).pop();
                    _isDialogShown = false;
                  }

                  await Future.delayed(const Duration(milliseconds: 300));

                  if (context.mounted) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      isDismissible: false,
                      enableDrag: false,
                      backgroundColor: Colors.transparent,
                      builder: (_) => BookingConfirmationModal(
                        bookedItems: [bookingData],
                        onDonePressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  }
                } catch (e) {
                  if (_isDialogShown) {
                    Navigator.of(context, rootNavigator: true).pop();
                    _isDialogShown = false;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color.fromARGB(255, 204, 175, 175),
                      content: Text(
                        "⚠️ Failed to book exterior service.",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  );
                }
              },
              child: Text("Book Now",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
