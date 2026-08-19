import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/controller/nearby_services_controller.dart';
import 'package:naattulink/MVVM/model/nearby_service_model.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';
import 'package:naattulink/MVVM/utils/service_functions/availability_utils.dart';
import 'package:geolocator/geolocator.dart'; // For openAppSettings

class NearbyServicesPage extends StatefulWidget {
  final String category;

  const NearbyServicesPage({Key? key, required this.category})
      : super(key: key);

  @override
  State<NearbyServicesPage> createState() => _NearbyServicesPageState();
}

class _NearbyServicesPageState extends State<NearbyServicesPage> {
  final NearbyServicesController _controller =
      Get.put(NearbyServicesController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fetchNearbyServices(widget.category);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: 10.0),
          child: AppBackButton(),
        ),
        centerTitle: true,
        title: Text(
          widget.category,
          style: const TextStyle(
            color: Color(0xFF0F2E5A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _controller.refreshLocation();
              },
              child: Obx(() {
                if (_controller.isLoading.value) {
                  return ListView(
                    children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.3),
                      const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(color: Color(0xFF0F2E5A)),
                            SizedBox(height: 16),
                            Text(
                              'Finding services near you...',
                              style: TextStyle(
                                  color: Color(0xFF64748B), fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                if (_controller.isError.value) {
                  return ListView(
                    children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.3),
                      Center(
                        child: Column(
                          children: [
                            const Icon(Icons.location_off_rounded,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              _controller.errorMessage.value,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 16, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F2E5A)),
                              onPressed: () {
                                if (_controller.errorMessage.value
                                    .contains('permission')) {
                                  Geolocator.openAppSettings();
                                } else if (_controller.errorMessage.value
                                    .contains('disabled')) {
                                  Geolocator.openLocationSettings();
                                } else {
                                  _controller.refreshLocation();
                                }
                              },
                              child: Text(_controller.errorMessage.value
                                          .contains('permission') ||
                                      _controller.errorMessage.value
                                          .contains('disabled')
                                  ? 'Open Settings'
                                  : 'Retry'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                if (_controller.isEmpty.value) {
                  return ListView(
                    children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.3),
                      const Center(
                        child: Column(
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No services available in your area.',
                              style: TextStyle(
                                  fontSize: 16, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                // Data found
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_controller.services.isNotEmpty)
                      ..._controller.services
                          .map((service) => _buildServiceCard(service)),
                    if (_controller.categorizedResults.isNotEmpty)
                      ..._buildCategorizedSections(),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (val) => _controller.performSearch(val),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "Search in ${widget.category}...",
                  hintStyle:
                      const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  prefixIcon: const Icon(Icons.search,
                      color: Color(0xFF0F2E5A), size: 20),
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCategorizedSections() {
    final sections = <Widget>[];

    _controller.categorizedResults.forEach((header, list) {
      sections.add(
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: Text(
            header,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F2E5A),
            ),
          ),
        ),
      );

      for (var service in list) {
        sections.add(_buildServiceCard(service));
      }
    });

    return sections;
  }

  Widget _buildServiceCard(NearbyServiceModel service) {
    // Determine title
    final title = service.rawData['facility_name'] ??
        service.rawData['workerName'] ??
        service.rawData['name'] ??
        'Unknown Service';

    final address =
        service.rawData['address'] ?? service.rawData['main_stand'] ?? '';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF0F2E5A).withOpacity(0.1),
          child:
              const Icon(Icons.home_repair_service, color: Color(0xFF0F2E5A)),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (address.toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                address.toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                AvailabilityBadge(
                  scheduleString:
                      service.rawData['available_time']?.toString() ??
                          service.rawData['operating_hours']?.toString(),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.location_on, size: 16, color: Colors.blue),
                const SizedBox(width: 4),
                Text(
                  '${service.distanceKm.toStringAsFixed(1)} km away',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
