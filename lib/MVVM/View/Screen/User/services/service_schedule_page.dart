import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:intl/intl.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';
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
  int _currentStep = 1;
  String? _selectedServiceType; // "Urgent" or "Scheduled"

  DateTime? _selectedDate;
  String? _selectedTimeSlot;

  // We no longer display the 2-hour slots per requirements, but keep the array
  // if needed for other features in the future.
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
        leading: Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: AppBackButton(
            onPressed: () {
              if (_currentStep == 2) {
                setState(() {
                  _currentStep = 1;
                });
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ),
        title: Text(
          'schedule_service'.tr,
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
                child: _currentStep == 1
                    ? _buildStep1(primaryColor)
                    : _buildStep2(primaryColor),
              ),
            ),
            _buildBottomStickyButton(primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'choose_service_type'.tr,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildServiceTypeCard(
          title: 'urgent'.tr,
          subtitle: 'need_worker_soon'.tr,
          icon: Icons.flash_on,
          primaryColor: primaryColor,
        ),
        const SizedBox(height: 16),
        _buildServiceTypeCard(
          title: 'scheduled'.tr,
          subtitle: 'choose_specific_date'.tr,
          icon: Icons.calendar_month,
          primaryColor: primaryColor,
        ),
      ],
    );
  }

  Widget _buildServiceTypeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color primaryColor,
  }) {
    final isSelected = _selectedServiceType == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedServiceType != title) {
            _selectedServiceType = title;
            // Clear previous selections if type changes
            _selectedDate = null;
            _selectedTimeSlot = null;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor.withOpacity(0.1)
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? primaryColor : Colors.black54,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2(Color primaryColor) {
    if (_selectedServiceType == 'urgent'.tr) {
      return _buildUrgentFlow(primaryColor);
    } else {
      return _buildScheduledFlow(primaryColor);
    }
  }

  Widget _buildUrgentFlow(Color primaryColor) {
    final now = DateTime.now();

    // Generate dates dynamically (Tomorrow, Day After Tomorrow, Third Day)
    final dates = [
      now.add(const Duration(days: 1)),
      now.add(const Duration(days: 2)),
      now.add(const Duration(days: 3)),
    ];

    String getFriendlyLabel(DateTime date, int index) {
      if (index == 0) return 'tomorrow'.tr;
      if (index == 1) return 'day_after_tomorrow'.tr;
      return DateFormat('EEE, MMM d').format(date);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'select_service_date'.tr,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: List.generate(dates.length, (index) {
            final date = dates[index];
            final dateStr = DateFormat('dd-MM-yyyy').format(date);
            final label = getFriendlyLabel(date, index);

            // Compare by yyyy-MM-dd to ignore time
            final isSelected = _selectedDate != null &&
                DateFormat('yyyy-MM-dd').format(_selectedDate!) ==
                    DateFormat('yyyy-MM-dd').format(date);

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDate = date;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor.withOpacity(0.05)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? primaryColor : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, color: primaryColor)
                    else
                      Icon(Icons.circle_outlined, color: Colors.grey.shade300),
                  ],
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 32),
        Text(
          'choose_arrival_time'.tr,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTimeOption('morning'.tr, primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTimeOption('afternoon'.tr, primaryColor),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeOption(String title, Color primaryColor) {
    final isSelected = _selectedTimeSlot == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTimeSlot = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade200,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? primaryColor : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildScheduledFlow(Color primaryColor) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final minimumDate = today.add(const Duration(days: 2));

    DateTime initDate = _selectedDate ?? minimumDate;
    if (initDate.isBefore(minimumDate)) {
      initDate = minimumDate;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'select_service_date'.tr,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'pick_convenient_date'.tr,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'advance_notice_warning'.tr,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
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
              initialDate: initDate,
              firstDate: minimumDate,
              lastDate: DateTime.now().add(const Duration(days: 365)),
              onDateChanged: (newDate) {
                setState(() {
                  _selectedDate = newDate;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomStickyButton(Color primaryColor) {
    bool isEnabled = false;

    if (_currentStep == 1) {
      isEnabled = _selectedServiceType != null;
    } else if (_currentStep == 2) {
      if (_selectedServiceType == 'urgent'.tr) {
        isEnabled = _selectedDate != null && _selectedTimeSlot != null;
      } else {
        isEnabled = _selectedDate != null;
      }
    }

    return Container(
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
          onPressed: isEnabled
              ? () {
                  if (_currentStep == 1) {
                    setState(() {
                      _currentStep = 2;
                    });
                  } else {
                    if (_selectedServiceType != 'urgent'.tr &&
                        _selectedDate != null) {
                      final now = DateTime.now();
                      final today = DateTime(now.year, now.month, now.day);
                      final minimumDate = today.add(const Duration(days: 2));

                      final selected = DateTime(_selectedDate!.year,
                          _selectedDate!.month, _selectedDate!.day);
                      if (selected.isBefore(minimumDate)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'date_must_be_two_days'.tr),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }
                    }

                    // Navigate to Summary Page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ServiceBookingSummaryPage(
                          serviceName: widget.serviceName,
                          price: widget.price,
                          image: widget.image,
                          rating: widget.rating,
                          selectedDate: _selectedDate!,
                          serviceType: _selectedServiceType,
                          // Pass empty string for scheduled to satisfy non-nullable String
                          selectedTimeSlot: _selectedServiceType == 'urgent'.tr
                              ? _selectedTimeSlot!
                              : "",
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
                  }
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            disabledBackgroundColor: Colors.grey.shade300,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: Text(
            'continue_btn'.tr,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
