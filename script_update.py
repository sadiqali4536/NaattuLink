import os
import re

files_to_update = [
    r"d:\nattulinkapp\NaattuLink\lib\MVVM\View\Screen\User\Booking_page\vehicles_auto_taxi_bookings\auto_taxi_page.dart",
    r"d:\nattulinkapp\NaattuLink\lib\MVVM\View\Screen\User\Booking_page\pickup_page.dart",
    r"d:\nattulinkapp\NaattuLink\lib\MVVM\View\Screen\User\Booking_page\jcbs_page.dart",
    r"d:\nattulinkapp\NaattuLink\lib\MVVM\View\Screen\User\Booking_page\healthcare_bookings\clinics_page.dart",
]

get_position_pattern = re.compile(
    r'final pos = await Geolocator\.getCurrentPosition\([^)]*\);',
    re.DOTALL
)

get_position_replacement = '''final locService = LocationService();
      await locService.startListening();
      final pos = locService.currentPosition ?? await locService.fetchCurrentLocation();
      
      if (pos == null) {
        throw Exception("Failed to get location");
      }'''

for file_path in files_to_update:
    if not os.path.exists(file_path): continue
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    content = get_position_pattern.sub(get_position_replacement, content)

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

print("Updated getCurrentPosition in all files.")
