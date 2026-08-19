import sys
path = r'd:\nattulinkapp\NaattuLink\lib\MVVM\View\Screen\User\Home\Homepage.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
import_str = "import 'package:naattulink/MVVM/View/Screen/User/Booking_page/nearby_services_page.dart';\n"
if import_str not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\n" + import_str)

# Replace routes
content = content.replace("const HealthcareCategoriesPage()", "const NearbyServicesPage(category: 'Healthcare')")
content = content.replace("const ShopsCategoriesPage()", "const NearbyServicesPage(category: 'Shops')")
content = content.replace("const TransportationCategoriesPage()", "const NearbyServicesPage(category: 'Transportation')")
content = content.replace("const EducationCategoriesPage()", "const NearbyServicesPage(category: 'Education')")
content = content.replace("const PublicServicesCategoriesPage()", "const NearbyServicesPage(category: 'Public Services')")
content = content.replace("const AutoTaxiPage()", "const NearbyServicesPage(category: 'Taxi Drivers')")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Done.')
