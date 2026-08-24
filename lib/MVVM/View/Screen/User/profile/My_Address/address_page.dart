import 'package:flutter/material.dart';
import 'package:naattulink/MVVM/View/Screen/User/User_Dashboard/user_Dashboard.dart';
import 'package:naattulink/MVVM/View/Screen/location/address_form_bottom_sheet.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';
import 'package:naattulink/MVVM/utils/widget/card/addresscard.dart';
import 'package:naattulink/MVVM/model/models/app_location_model.dart';
import 'package:naattulink/MVVM/View/Authentication/controller/location_controller.dart';
import 'package:naattulink/MVVM/utils/add_sample_zone.dart';

class AddressPage extends StatefulWidget {
  const AddressPage({super.key});

  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  AppLocationModel? _currentAddress;

  @override
  void initState() {
    super.initState();
    _currentAddress = LocationController.to.currentLocationModel.value;
  }

  String get _displayAddress {
    if (_currentAddress == null) {
      return '15/24, Rose Villa\nMG Road, Kochi - 682001\nKerala, India';
    }
    return _currentAddress!.formattedAddress;
  }

  Future<void> _openEditBottomSheet() async {
    final result = await showModalBottomSheet<AppLocationModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => AddressFormBottomSheet(
        initialAddress: _currentAddress,
      ),
    );

    if (result != null && mounted) {
      setState(() => _currentAddress = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ZoneSeeder.addSampleZone();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Adding sample zone to Firebase...')),
          );
        },
        child: const Icon(Icons.add_location_alt),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  AppBackButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => user_Dashboard()),
                      );
                    },
                  ),
                  const SizedBox(width: 75),
                  const Text(
                    "My Address",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: SizedBox(
                width: 370,
                height: 160,
                child: Addresscard(
                  address: _displayAddress,
                  onEdit: _openEditBottomSheet,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
