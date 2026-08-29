import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:naattulink/MVVM/model/models/app_location_model.dart';
import 'package:naattulink/MVVM/model/services/app_location_service.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:naattulink/MVVM/utils/Constants/constants.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';
import 'package:naattulink/MVVM/View/Screen/location/address_form_bottom_sheet.dart';

enum LocationPickerFlow {
  registration,
  addAddress,
}

class SelectLocationMapPage extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final LocationPickerFlow flow;

  /// Forwarded to [AddressFormBottomSheet.onAddressSaved] so the original
  /// caller (e.g. [LocationSelectionPage]) can persist the address to local
  /// storage and refresh its list without closing itself.
  final void Function(AppLocationModel saved)? onAddressSaved;

  /// Whether a detected zone is strictly required to save the address
  final bool requireZone;

  const SelectLocationMapPage({
    super.key,
    required this.initialLat,
    required this.initialLng,
    required this.flow,
    this.onAddressSaved,
    this.requireZone = true,
  });

  @override
  State<SelectLocationMapPage> createState() => _SelectLocationMapPageState();
}

class _SelectLocationMapPageState extends State<SelectLocationMapPage> {
  late GoogleMapController mapController;
  late LatLng centerLocation;
  AppLocationModel? _currentLocationModel;
  final AppLocationService _locationService = AppLocationService();
  bool _isLoading = false;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<dynamic> _predictions = [];
  Timer? _debounce;
  bool _isSearching = false;
  bool _isFetchingCurrentLocation = false;

  @override
  void initState() {
    super.initState();
    centerLocation = LatLng(widget.initialLat, widget.initialLng);
    _fetchAddressForCenter();
  }

  Future<void> _fetchAddressForCenter() async {
    setState(() {
      _isLoading = true;
    });

    final locDetails = await _locationService.getLocationDetailsFromCoordinates(
      centerLocation.latitude,
      centerLocation.longitude,
    );

    setState(() {
      _currentLocationModel = locDetails;
      _isLoading = false;
    });
  }

  Future<void> _fetchAndMoveToCurrentLocation() async {
    setState(() {
      _isFetchingCurrentLocation = true;
    });
    try {
      final loc = await _locationService.getCurrentLocation();
      if (loc != null && mounted) {
        final target = LatLng(loc.latitude, loc.longitude);
        try {
          mapController.animateCamera(CameraUpdate.newLatLng(target));
          setState(() {
            centerLocation = target;
          });
          await _fetchAddressForCenter();
        } catch (e) {
          debugPrint("Map not ready yet: $e");
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingCurrentLocation = false;
        });
      }
    }
  }

  void _onCameraMove(CameraPosition position) {
    centerLocation = position.target;
  }

  void _onCameraIdle() {
    _fetchAddressForCenter();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    // Only dispose if initialized
    try {
      mapController.dispose();
    } catch (e) {
      debugPrint("Map controller not initialized or already disposed: $e");
    }
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _searchPlaces(query);
      } else {
        setState(() {
          _predictions = [];
        });
      }
    });
  }

  Future<void> _searchPlaces(String query) async {
    setState(() {
      _isSearching = true;
    });

    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$googleMapApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'OK') {
          setState(() {
            _predictions = result['predictions'];
            _isSearching = false;
          });
        } else {
          setState(() {
            _predictions = [];
            _isSearching = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      debugPrint("Error fetching places: $e");
    }
  }

  Future<void> _onSuggestionSelected(String placeId, String description) async {
    _searchFocusNode.unfocus();
    _searchController.text = description;
    setState(() {
      _predictions = [];
      _isLoading = true;
    });

    final String url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$googleMapApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'OK') {
          final location = result['result']['geometry']['location'];
          final double lat = location['lat'];
          final double lng = location['lng'];

          final target = LatLng(lat, lng);
          mapController.animateCamera(CameraUpdate.newLatLng(target));
        }
      }
    } catch (e) {
      debugPrint("Error fetching place details: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: const Color(0xFF0F2E5A),
        foregroundColor: Colors.white,
        leading: const AppBackButton(),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: centerLocation,
              zoom: 15.0,
            ),
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
              if (widget.initialLat == 11.2588 &&
                  widget.initialLng == 75.7804) {
                _fetchAndMoveToCurrentLocation();
              }
            },
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          // Center Marker Pin
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      )
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search location...',
                      prefixIcon:
                          const Icon(Icons.search, color: Color(0xFF0F2E5A)),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _predictions = [];
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
                    ),
                  ),
                ),
                if (_isSearching)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                if (_predictions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                        )
                      ],
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _predictions.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final prediction = _predictions[index];
                          return ListTile(
                            leading: const Icon(Icons.location_on,
                                color: Colors.grey),
                            title: Text(prediction['description']),
                            onTap: () => _onSuggestionSelected(
                              prediction['place_id'],
                              prediction['description'],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Center(
            child: Icon(
              Icons.location_on,
              size: 40.0,
              color: Colors.red,
            ),
          ),
          // Current Location FAB
          Positioned(
            bottom: 180,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'myLocationBtn',
              backgroundColor: Colors.white,
              onPressed: _isFetchingCurrentLocation
                  ? null
                  : _fetchAndMoveToCurrentLocation,
              child: _isFetchingCurrentLocation
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Icon(Icons.my_location, color: Color(0xFF0F2E5A)),
            ),
          ),
          // Bottom Info Card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10.0,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selected Address',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Text(
                          _currentLocationModel?.formattedAddress ??
                              'Fetching address...',
                          style: const TextStyle(fontSize: 14.0),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                  const SizedBox(height: 16.0),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading || _currentLocationModel == null
                          ? null
                          : () async {
                              if (widget.flow ==
                                  LocationPickerFlow.registration) {
                                Navigator.pop(context, _currentLocationModel);
                                return;
                              }

                              if (widget.flow ==
                                  LocationPickerFlow.addAddress) {
                                // Show the address form so the user fills in
                                // delivery details before the map page closes.
                                final updatedModel = await showModalBottomSheet<
                                    AppLocationModel>(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  useSafeArea: true,
                                  showDragHandle: true,
                                  builder: (_) => AddressFormBottomSheet(
                                    initialAddress: _currentLocationModel,
                                    // Forward the callback so LocationSelectionPage
                                    // can save to local storage and refresh its list.
                                    onAddressSaved: widget.onAddressSaved,
                                    requireZone: widget.requireZone,
                                  ),
                                );
                                if (updatedModel != null && context.mounted) {
                                  Navigator.pop(context, updatedModel);
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F2E5A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      child: const Text('Confirm Location',
                          style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
