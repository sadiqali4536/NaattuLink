import 'package:flutter/material.dart';
import 'package:naattulink/MVVM/View/Screen/User/services/service_booking_summary_page.dart';

class ServiceSchedulePage extends StatefulWidget {
  final String serviceName;
  final dynamic price;
  final String image;
  final double rating;
  final String? serviceId;
  final String? providerId;
  final String? providerName;
  final String? providerPhone;
  final String? serviceDescription;
  final String? estimatedDuration;
  final String? serviceCategory;

  const ServiceSchedulePage({
    Key? key,
    required this.serviceName,
    required this.price,
    required this.image,
    required this.rating,
    this.serviceId,
    this.providerId,
    this.providerName,
    this.providerPhone,
    this.serviceDescription,
    this.estimatedDuration,
    this.serviceCategory,
  }) : super(key: key);

  @override
  State<ServiceSchedulePage> createState() => _ServiceSchedulePageState();
}

class _ServiceSchedulePageState extends State<ServiceSchedulePage> {
  DateTime _selectedDate = DateTime.now();
  String _selectedTimeSlot = "";

  final List<String> _timeSlots = [
    "07:00AM - 09:00AM",
    "09:00AM - 11:00AM",
    "11:00AM - 01:00PM",
    "01:00PM - 03:00PM",
    "03:00PM - 05:00PM",
    "05:00PM - 07:00PM",
  ];

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF0F2E5A);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Schedule Service",
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Select service date",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Pick a convenient date for your booking.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Calendar Container
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: primaryColor, // Selection color
                            onPrimary: Colors.white,
                            onSurface: Colors.black87,
                          ),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              foregroundColor: primaryColor, // Today text color
                            ),
                          ),
                        ),
                        child: CalendarDatePicker(
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          onDateChanged: (newDate) {
                            setState(() {
                              _selectedDate = newDate;
                            });
                          },
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    const Text(
                      "Choose an Arrival Time-Slot",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _timeSlots.map((slot) {
                        final isSelected = _selectedTimeSlot == slot;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTimeSlot = slot;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primaryColor.withOpacity(0.1)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isSelected
                                    ? primaryColor
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              slot,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? primaryColor
                                    : Colors.black54,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom Sticky Button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                      onPressed: _selectedTimeSlot.isEmpty
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ServiceBookingSummaryPage(
                              serviceName: widget.serviceName,
                              price: widget.price,
                              image: widget.image,
                              rating: widget.rating,
                              selectedDate: _selectedDate,
                              selectedTimeSlot: _selectedTimeSlot,
                              serviceId: widget.serviceId,
                              providerId: widget.providerId,
                              providerName: widget.providerName,
                              providerPhone: widget.providerPhone,
                              serviceDescription: widget.serviceDescription,
                              estimatedDuration: widget.estimatedDuration,
                              serviceCategory: widget.serviceCategory,
                            ),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    "Proceed",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
