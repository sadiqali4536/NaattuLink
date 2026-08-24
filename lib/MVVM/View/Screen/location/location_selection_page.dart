import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naattulink/MVVM/View/Screen/location/address_form_bottom_sheet.dart';
import 'package:naattulink/MVVM/model/models/app_location_model.dart';
import 'package:naattulink/MVVM/View/Authentication/controller/location_controller.dart';
import 'package:naattulink/MVVM/View/Screen/location/select_location_map_page.dart';
import 'package:naattulink/MVVM/utils/Constants/constants.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';

class LocationSelectionPage extends StatefulWidget {
  const LocationSelectionPage({Key? key}) : super(key: key);

  @override
  State<LocationSelectionPage> createState() => _LocationSelectionPageState();
}

class _LocationSelectionPageState extends State<LocationSelectionPage> {
  final _storage = GetStorage();
  List<AppLocationModel> _firebaseAddresses = [];
  List<AppLocationModel> _historyAddresses = [];

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<dynamic> _predictions = [];
  Timer? _debounce;
  bool _isSearching = false;
  bool _isLoadingAddresses = true;

  @override
  void initState() {
    super.initState();
    _loadSavedAddresses();
  }

  String get _storageKey {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    return 'location_history_$uid';
  }

  Future<void> _loadSavedAddresses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('delivery_addresses')
            .orderBy('createdAt', descending: true)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final fetched = querySnapshot.docs.map((doc) {
            final data = doc.data();
            return AppLocationModel(
              id: doc.id,
              latitude: data['latitude'] ?? 11.2588,
              longitude: data['longitude'] ?? 75.7804,
              formattedAddress: data['address'] ?? '',
              district: data['district'] ?? '',
              city: data['city'] ?? '',
              state: data['state'] ?? '',
              pincode: data['pincode'] ?? '',
              receiverName: data['name'] ?? '',
              receiverPhone: data['phone'] ?? '',
              alternatePhone: data['alternativeNumber'] ?? '',
              landmark: data['buildingName'] ?? '',
              addressType: data['addressType'] ?? 'Home',
              isPrimary: data['isDefault'] == 1,
            );
          }).toList();

          setState(() {
            _firebaseAddresses = fetched;
          });
        } else {
          setState(() {
            _firebaseAddresses = [];
          });
        }
      } catch (e) {
        debugPrint("Error loading addresses from Firebase: $e");
      }
    }

    // Load history from local storage independently
    final List<dynamic>? storedData = _storage.read<List<dynamic>>(_storageKey);
    if (storedData != null) {
      setState(() {
        _historyAddresses = storedData
            .map((e) => AppLocationModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      });
    }

    if (mounted) {
      setState(() {
        _isLoadingAddresses = false;
      });
    }
  }

  Future<void> _refreshFirebaseAddresses(AppLocationModel loc) async {
    // Called when a new address is saved via AddressFormBottomSheet
    await _loadSavedAddresses();
  }

  void _saveToHistory(AppLocationModel loc) {
    // Only save searched/picked locations to local storage history
    setState(() {
      _historyAddresses
          .removeWhere((a) => a.formattedAddress == loc.formattedAddress);
      _historyAddresses.insert(0, loc);
      if (_historyAddresses.length > 20) {
        _historyAddresses = _historyAddresses.sublist(0, 20); // Keep max 20
      }
    });
    final List<Map<String, dynamic>> jsonData =
        _historyAddresses.map((e) => e.toJson()).toList();
    _storage.write(_storageKey, jsonData);
  }

  void _deleteAddress(int index, {required bool isDefault}) async {
    if (isDefault) {
      // Deleting a Firebase Saved Address
      final address = _firebaseAddresses[index];
      setState(() {
        _firebaseAddresses.removeAt(index);
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          if (address.id != null) {
            final roleCollections = [
              'users',
              'workers',
              'healthcare',
              'transports',
              'shops_businesses'
            ];
            for (String collectionName in roleCollections) {
              final docRef = FirebaseFirestore.instance
                  .collection(collectionName)
                  .doc(user.uid)
                  .collection('delivery_addresses')
                  .doc(address.id);
              final docSnap = await docRef.get();
              if (docSnap.exists) {
                await docRef.delete();
              }
            }
          } else {
            // Fallback for older addresses without ID in model
            final snapshot = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('delivery_addresses')
                .where('address', isEqualTo: address.formattedAddress)
                .get();
            for (var doc in snapshot.docs) {
              await doc.reference.delete();
            }
          }
        } catch (e) {
          debugPrint("Error deleting from Firebase: $e");
        }
      }
    } else {
      // Deleting a History Address
      setState(() {
        _historyAddresses.removeAt(index);
      });
      final List<Map<String, dynamic>> jsonData =
          _historyAddresses.map((e) => e.toJson()).toList();
      _storage.write(_storageKey, jsonData);
    }
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
      _isSearching = true;
    });

    final String url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$googleMapApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'OK') {
          final location = result['result']['geometry']['location'];
          final addressComponents =
              result['result']['address_components'] as List<dynamic>? ?? [];

          String? locality;
          String? district;
          String? state;
          String? postalCode;

          for (var comp in addressComponents) {
            final types = comp['types'] as List<dynamic>;
            if (types.contains('locality')) {
              locality = comp['long_name'];
            }
            if (types.contains('administrative_area_level_3') ||
                types.contains('administrative_area_level_2')) {
              district = comp['long_name'];
            }
            if (types.contains('administrative_area_level_1')) {
              state = comp['long_name'];
            }
            if (types.contains('postal_code')) {
              postalCode = comp['long_name'];
            }
          }

          final double lat = location['lat'];
          final double lng = location['lng'];

          final locModel = AppLocationModel(
            latitude: lat,
            longitude: lng,
            formattedAddress: description,
            district: district ?? 'Unknown',
            city: locality,
            state: state,
            pincode: postalCode,
          );

          LocationController.to.updateLocationManually(locModel);
          _saveToHistory(locModel);
          if (mounted) {
            Navigator.pop(context);
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching place details: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Select a location',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: const AppBackButton(),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search for a location',
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                    prefixIcon:
                        Icon(Icons.search, color: Colors.grey[600], size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
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
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),
            if (_isSearching)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0F2E5A))),
              ),
            if (_predictions.isNotEmpty)
              Container(
                color: Colors.white,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _predictions.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final prediction = _predictions[index];
                    return ListTile(
                      leading:
                          const Icon(Icons.location_on, color: Colors.grey),
                      title: Text(prediction['description']),
                      onTap: () => _onSuggestionSelected(
                        prediction['place_id'],
                        prediction['description'],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () async {
                        await LocationController.to
                            .fetchLocation(forceRefresh: true);
                        if (mounted) {
                          Navigator.pop(context);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Icon(Icons.my_location,
                                color: Color(0xFF0F2E5A), size: 24),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Use current location',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0F2E5A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Obx(() {
                                    final loc = LocationController
                                        .to.currentLocationModel.value;
                                    final displayAddress =
                                        loc?.formattedAddress ??
                                            'Fetching current location...';
                                    return Text(
                                      displayAddress,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                        height: 1.4,
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(
                        height: 1,
                        color: Colors.grey[200],
                        indent: 16,
                        endIndent: 16),
                    InkWell(
                      onTap: () async {
                        final initialLat =
                            LocationController.to.latitude.value ?? 11.2588;
                        final initialLng =
                            LocationController.to.longitude.value ?? 75.7804;
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SelectLocationMapPage(
                              initialLat: initialLat,
                              initialLng: initialLng,
                              onAddressSaved: _refreshFirebaseAddresses,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Icon(Icons.add,
                                color: Color(0xFF0F2E5A), size: 24),
                            const SizedBox(width: 16),
                            const Text(
                              'Add address',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F2E5A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ...() {
              final defaultAddresses = _firebaseAddresses;
              final historyAddresses = _historyAddresses;

              return [
                if (_isLoadingAddresses)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF0F2E5A)),
                    ),
                  )
                else ...[
                  if (defaultAddresses.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
                      child: Text(
                        'SAVED ADDRESS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: defaultAddresses.length,
                      itemBuilder: (context, index) {
                        return _buildDetailedAddressCard(
                            defaultAddresses[index], index, true);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (historyAddresses.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
                      child: Text(
                        'HISTORY',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: historyAddresses.length,
                      itemBuilder: (context, index) {
                        return _buildSimpleHistoryCard(
                            historyAddresses[index], index, false);
                      },
                    ),
                  ],
                  if (defaultAddresses.isEmpty && historyAddresses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          'No saved addresses yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                ]
              ];
            }(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedAddressCard(
      AppLocationModel address, int index, bool isDefault) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            LocationController.to.updateLocationManually(address);
            Navigator.pop(context, address);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on,
                    color: Color(0xFF0F2E5A), size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name & Type/Default Badges
                        if ((address.receiverName != null &&
                                address.receiverName!.isNotEmpty) ||
                            (address.addressType != null &&
                                address.addressType!.isNotEmpty) ||
                            address.isPrimary == true)
                          Row(
                            children: [
                              if (address.receiverName != null &&
                                  address.receiverName!.isNotEmpty) ...[
                                Text(
                                  address.receiverName!,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (address.addressType != null &&
                                  address.addressType!.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    address.addressType!,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                              if (address.isPrimary == true) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(4),
                                    border:
                                        Border.all(color: Colors.blue[200]!),
                                  ),
                                  child: Text(
                                    'Default',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        if ((address.receiverName != null &&
                                address.receiverName!.isNotEmpty) ||
                            (address.addressType != null &&
                                address.addressType!.isNotEmpty) ||
                            address.isPrimary == true)
                          const SizedBox(height: 6),

                        // Building Name (Landmark)
                        if (address.landmark != null &&
                            address.landmark!.isNotEmpty)
                          Text(
                            address.landmark!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        if (address.landmark != null &&
                            address.landmark!.isNotEmpty)
                          const SizedBox(height: 2),

                        // Full Address
                        Text(
                          address.formattedAddress,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                        ),

                        // Phones
                        if (address.receiverPhone != null &&
                            address.receiverPhone!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Phone: ${address.receiverPhone}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (address.alternatePhone != null &&
                            address.alternatePhone!.isNotEmpty)
                          Text(
                            'Alt Phone: ${address.alternatePhone}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  child:
                      const Icon(Icons.more_vert, color: Colors.grey, size: 24),
                  color: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      final result = await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        useSafeArea: true,
                        showDragHandle: true,
                        builder: (context) {
                          return AddressFormBottomSheet(
                            initialAddress: address,
                            isEdit: true,
                          );
                        },
                      );
                      if (result != null) {
                        await _loadSavedAddresses();
                      }
                    } else if (value == 'delete') {
                      _deleteAddress(index, isDefault: isDefault);
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined,
                              color: Colors.grey[800], size: 20),
                          const SizedBox(width: 12),
                          Text(
                            'Edit',
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(height: 1),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              color: Colors.red[800], size: 20),
                          const SizedBox(width: 12),
                          Text(
                            'Delete',
                            style: TextStyle(
                              color: Colors.red[800],
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleHistoryCard(
      AppLocationModel address, int index, bool isDefault) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            LocationController.to.updateLocationManually(address);
            Navigator.pop(context, address);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.history, color: Colors.grey, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Building Name (Landmark)
                        if (address.landmark != null &&
                            address.landmark!.isNotEmpty)
                          Text(
                            address.landmark!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        if (address.landmark != null &&
                            address.landmark!.isNotEmpty)
                          const SizedBox(height: 2),

                        // Full Address only
                        Text(
                          address.formattedAddress,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  child:
                      const Icon(Icons.more_vert, color: Colors.grey, size: 24),
                  color: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onSelected: (value) async {
                    if (value == 'delete') {
                      _deleteAddress(index, isDefault: isDefault);
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              color: Colors.red[800], size: 20),
                          const SizedBox(width: 12),
                          Text(
                            'Delete',
                            style: TextStyle(
                              color: Colors.red[800],
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
