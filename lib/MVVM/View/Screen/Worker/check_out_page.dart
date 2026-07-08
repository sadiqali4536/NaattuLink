import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:naattulink/MVVM/View/Screen/Worker/payment_screen.dart';
import 'package:naattulink/MVVM/utils/Constants/colors.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/custombackbutton.dart';

class CheckOutPage extends StatefulWidget {
  const CheckOutPage({super.key});

  @override
  State<CheckOutPage> createState() => _CheckOutPageState();
}

class _CheckOutPageState extends State<CheckOutPage> {
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  String selectedWorkType = 'Select Work Type';

  final Map<String, int> workTypes = {
    'Home Cleaning': 200,
    'Room Cleaning': 180,
    'Grass Cutting': 170,
  };

  String formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return "Choose Time";
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dt);
  }

  Duration getWorkingDuration() {
    if (startTime == null || endTime == null) return Duration.zero;

    final now = DateTime.now();
    var start = DateTime(
        now.year, now.month, now.day, startTime!.hour, startTime!.minute);
    var end =
        DateTime(now.year, now.month, now.day, endTime!.hour, endTime!.minute);

    if (end.isBefore(start)) {
      end = end.add(const Duration(days: 1));
    }

    return end.difference(start);
  }

  void pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startTime = picked;
        } else {
          endTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final duration = getWorkingDuration();
    final hourlyRate = workTypes[selectedWorkType] ?? 0;
    final totalPrice = (duration.inMinutes / 60.0) * hourlyRate;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 102, 214, 10),
                  Color.fromARGB(255, 113, 191, 4),
                  Color.fromARGB(255, 26, 159, 6),
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Row(
              children: [
                customBackbutton1(
                  onpress: () {
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(width: 30),
                const Text(
                  'Checkout Work Payment',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 40),
        child: Center(
          child: Material(
            elevation: 5,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 480,
              width: 362,
              decoration: BoxDecoration(
                border:
                    Border.all(color: const Color.fromARGB(255, 228, 228, 228)),
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: Stack(
                children: [
                  // Dropdown for work type
                  Padding(
                    padding: const EdgeInsets.only(top: 20, left: 80),
                    child: Material(
                      elevation: 5,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 200,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: const Color.fromARGB(255, 202, 202, 202)),
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 15),
                          child: DropdownButton<String>(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(10),
                            value: selectedWorkType,
                            underline: const SizedBox(),
                            items: [
                              const DropdownMenuItem(
                                value: 'Select Work Type',
                                child: Padding(
                                  padding: EdgeInsets.only(left: 12),
                                  child: Text('Select Work Type',
                                      style: TextStyle(color: Colors.grey)),
                                ),
                              ),
                              ...workTypes.keys.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  selectedWorkType = value;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Start Time
                  const Padding(
                    padding: EdgeInsets.only(left: 30, top: 120),
                    child: Text("Start Time:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 110, left: 130),
                    child: Material(
                      elevation: 5,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 45,
                        width: 170,
                        decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 255, 255, 255),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color:
                                    const Color.fromARGB(255, 220, 220, 220))),
                        child: InkWell(
                          onTap: () => pickTime(true),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formatTimeOfDay(startTime),
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const Icon(Icons.access_time),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // End Time
                  const Padding(
                    padding: EdgeInsets.only(left: 30, top: 200),
                    child: Text("End Time:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 190, left: 130),
                    child: Material(
                      elevation: 5,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 45,
                        width: 170,
                        decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 255, 255, 255),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color:
                                    const Color.fromARGB(255, 210, 210, 210))),
                        child: InkWell(
                          onTap: () => pickTime(false),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formatTimeOfDay(endTime),
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const Icon(Icons.access_time),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Duration
                  Padding(
                    padding: const EdgeInsets.only(top: 270, left: 36),
                    child: const Text("Duration:",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 270, left: 140),
                    child: Text("${duration.inHours}",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: gradientgreen2.c)),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 270, left: 155),
                    child: Text(" hrs ",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 270, left: 190),
                    child: Text("${duration.inMinutes % 60}",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: gradientgreen2.c)),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 270, left: 210),
                    child: Text(" mins",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),

                  // Hourly Rate
                  const Padding(
                    padding: EdgeInsets.only(top: 305, left: 36),
                    child: Text("Hourly Rate:",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 305, left: 139),
                    child: Text(" ₹",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 305, left: 148),
                    child: Text(" $hourlyRate",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: gradientgreen2.c)),
                  ),
                  // Horizontal line
                  const Padding(
                    padding: EdgeInsets.only(top: 210),
                    child: Center(
                      child: Divider(
                        thickness: 1,
                        indent: 30,
                        endIndent: 30,
                        color: Colors.grey,
                      ),
                    ),
                  ),

                  // Total Price
                  const Padding(
                    padding: EdgeInsets.only(top: 360, left: 100),
                    child: Text(
                      "Total Price:",
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 360, left: 200),
                    child: Text(
                      "₹${totalPrice.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: gradientgreen2.c,
                      ),
                    ),
                  ),

                  // Proceed Button
                  Padding(
                    padding: const EdgeInsets.only(top: 410, left: 80),
                    child: SizedBox(
                      height: 43,
                      width: 206,
                      child: ElevatedButton.icon(
                        label: const Text(
                          "Proceed to Payment",
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          if (startTime == null ||
                              endTime == null ||
                              duration == Duration.zero ||
                              selectedWorkType == 'Select Work Type') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      "Please select all required fields")),
                            );
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaymentScreen(
                                price: totalPrice,
                                workType: selectedWorkType,
                                duration: duration,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gradientgreen2.c,
                          minimumSize: const Size.fromHeight(50),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
