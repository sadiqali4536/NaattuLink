import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:swiftclean_project/MVVM/View/Screen/User/Booking_page/booking_confirm.dart';
import 'package:swiftclean_project/MVVM/View/Screen/User/cart/cart_service.dart';
import 'package:swiftclean_project/MVVM/View/Screen/User/cart/cart_service.dart'
    as CartService;
import 'package:swiftclean_project/MVVM/View/Authentication/controller/recommendation_controller.dart';
import 'package:swiftclean_project/MVVM/model/models/cart_model.dart';
import 'package:swiftclean_project/MVVM/utils/Constants/colors.dart';
import 'package:swiftclean_project/MVVM/utils/widget/backbutton/custombackbutton.dart';
import 'package:swiftclean_project/MVVM/utils/widget/custom_message_dialog/customsnakbar.dart';

class InteriorBookingPage extends StatefulWidget {
  final String? serviceId;
  String? serviceName;
  String? image;
  String? originalPrice;
  String? discountPrice;
  String? discount;
  int? rating;
  String? category;
  String? serviceType;

  InteriorBookingPage({
    super.key,
    this.serviceId,
    this.category,
    this.discount,
    this.discountPrice,
    this.image,
    this.originalPrice,
    this.rating,
    this.serviceName,
    this.serviceType,
  });

  @override
  State<InteriorBookingPage> createState() => _InteriorBookingPageState();
}

class _InteriorBookingPageState extends State<InteriorBookingPage> {
  DateTime selectedDate = DateTime.now();
  int selectedIndex = 0;
  double realPrice = 0.0;
  int hour = DateTime.now().hour % 12;
  int minute = DateTime.now().minute;
  String meridiem = 'AM';
  String selectedRoom = 'No Room';
  int count = 1;
  DateTime? _selectedDate;
  bool isAddedToCart = false;

  @override
  void initState() {
    super.initState();
    checkIfServiceInCart();
    fetchServicePrice();
    RecommendationController.to.trackProductView(widget.serviceId ?? widget.serviceName ?? '');
  }

 bool isBookingFormComplete() {
  if (widget.serviceName == null ||
      widget.category == null ||
      widget.serviceType == null ||
      widget.discountPrice == null ||
      selectedRoom == 'No Room' || 
      count <= 0 ||
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

    if (!mounted) {
      setState(() {
        isAddedToCart = existing.docs.isNotEmpty;
      });
    }
  }

  Future<void> fetchServicePrice() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('services')
          .where('service_name', isEqualTo: widget.serviceName)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        final price = double.tryParse(data['price'].toString());
        if (price != null) {
          setState(() {
            realPrice = price;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching price: $e');
    }
  }

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

  void selectRoom(String room) {
    setState(() {
      selectedRoom = room;
    });
  }

  void incrementCount() {
    setState(() {
      count++;
    });
  }

  void decrementCount() {
    setState(() {
      if (count > 0) count--;
    });
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        selectedDate = picked;
      });
    }
  }

  String get formattedDate {
    final date = selectedDate;
    return '${DateFormat.E().format(date)}, ${DateFormat.MMMd().format(date)}';
  }

  String get formattedTime {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $meridiem';
  }

  Future<void> bookNow() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  if (!isBookingFormComplete()) {
    CustomSnackBar.show(
      icon: Icons.cancel,
      iconcolor: Colors.red,
      context: context,
      message: "Please fill all fields correctly before booking.",
      color: Colors.white,
    );
    return;
  }

  try {
    final bookingData = {
      'userId': user.uid,
      'service_id': widget.serviceId ?? '',
      'service_name': widget.serviceName ?? '',
      'image': widget.image ?? '',
      'original_price': widget.originalPrice ?? '',
      'price': widget.discountPrice ?? '',
      'discount': widget.discount ?? '',
      'rating': widget.rating ?? 0,
      'category': widget.category ?? '',
      'service_type': widget.serviceType ?? '',
      'room_name': selectedRoom,
      'scheduledDate': DateFormat('yyyy-MM-dd').format(selectedDate),
      'scheduledTime': formattedTime,
      'squareFeet': count.toString(),
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
      message: "Booking request for ${widget.serviceName ?? ''} submitted successfully.",
      color: Colors.white,
    );
  } catch (e) {
    if (!mounted) return;
    CustomSnackBar.show(
      icon: Icons.error,
      iconcolor: Colors.red,
      context: context,
      message: "Failed to book. Please try again.",
      color: Colors.white,
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(
                  height: 280,
                  width: double.infinity,
                  child: Image.asset("assets/image/interior_room.png",
                      fit: BoxFit.cover),
                ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color(0xFFF9F9F9),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Select Room",
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w600)),
                      SizedBox(height: 15),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildRoomButton("No Room"),
                            _buildRoomButton("Living Room"),
                            _buildRoomButton("Bedroom"),
                            _buildRoomButton("Dining Room"),
                            _buildRoomButton("Bathroom"),
                            _buildRoomButton("Laundry Room"),
                            _buildRoomButton("Study Room"),
                          ],
                        ),
                      ),
                      SizedBox(height: 25),
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
                          itemCount: getWeekDates().length,
                          itemBuilder: (context, index) {
                            final date = getWeekDates()[index];
                            final isSelected = index == selectedIndex;
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
                                      : Color(0xFFE5E5E5),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(DateFormat.E().format(date),
                                        style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black,
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(height: 5),
                                    Text('${date.day}',
                                        style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black,
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(height: 5),
                                    Text(_getMonthName(date.month),
                                        style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 25),
                      Text("Select Time",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w500)),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTimeColumn(
                              "Hour", hour, incrementHour, decrementHour),
                          SizedBox(width: 15),
                          Text(":", style: TextStyle(fontSize: 24)),
                          SizedBox(width: 15),
                          _buildTimeColumn(
                              "Min", minute, incrementMinute, decrementMinute),
                          SizedBox(width: 20),
                          Column(
                            children: [
                              _buildAMPMButton("AM"),
                              SizedBox(height: 12),
                              _buildAMPMButton("PM"),
                            ],
                          ),
                          SizedBox(width: 20),
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
                              SizedBox(height: 5),
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
                              SizedBox(height: 5),
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
                      SizedBox(height: 110),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              left: 10,
              top: 40,
              child: customBackbutton1(
                onpress: () {
                  Navigator.pop(context);
                },
              ),
            ),
            Positioned(
              top: 300,
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
                    selectedRoom: selectedRoom,
                    count: count,
                    selectedDate: selectedDate,
                    selectedTime: formattedTime,
                     gardenSize: null,
                  );

                  setState(() => isAddedToCart = true);
                  RecommendationController.to.trackCart(widget.serviceId ?? widget.serviceName ?? '', true);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Row(
          children: [
            Text("₹", style: TextStyle(color: Colors.white, fontSize: 30)),
            SizedBox(width: 5),
            Text("${widget.discountPrice ?? '0'}",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold)),
            Text("/Day",
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            Spacer(),
            SizedBox(
              height: 57,
              width: 160,
              child: ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: gradientgreen2.c),
                onPressed: bookNow,
                child: Text("Book Now",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildRoomButton(String room) {
    final isSelected = selectedRoom == room;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: TextButton(
        onPressed: () => selectRoom(room),
        style: TextButton.styleFrom(
          backgroundColor: isSelected ? gradientgreen2.c : Color(0xFFE7E7E7),
          foregroundColor: isSelected ? Colors.white : Colors.black,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: Size(100, 40),
        ),
        child: Text(room),
      ),
    );
  }

  Widget _buildTimeColumn(
      String label, int value, VoidCallback onAdd, VoidCallback onRemove) {
    return Column(
      children: [
        Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(30),
          child: IconButton(
              icon: Icon(Icons.add, color: gradientgreen2.c), onPressed: onAdd),
        ),
        SizedBox(height: 10),
        Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Text(value.toString().padLeft(2, '0'),
                style: TextStyle(fontSize: 20)),
          ),
        ),
        SizedBox(height: 10),
        Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(30),
          child: IconButton(
              icon: Icon(Icons.remove, color: gradientgreen2.c),
              onPressed: onRemove),
        ),
      ],
    );
  }


Widget _buildAMPMButton(String value) {
  return _buildSelectableButton(
    value: value,
    selectedValue: meridiem,
    onTap: () => toggleMeridiem(value),
    width: 60, // smaller width for AM/PM
  );
}


  Widget _buildSelectableButton({
  required String value,
  required String selectedValue,
  required VoidCallback onTap,
  double width = 100,
}) {
  final isSelected = value == selectedValue;

  return Padding(
    padding: const EdgeInsets.only(right: 10),
    child: TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: isSelected ? gradientgreen2.c : Color(0xFFE7E7E7),
        foregroundColor: isSelected ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: Size(width, 44),
      ),
      child: Text(value, style: const TextStyle(fontSize: 18)),
    ),
  );
}

}
