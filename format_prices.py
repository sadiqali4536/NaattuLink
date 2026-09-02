import re

with open(r"d:\nattulinkapp\NaattuLink\lib\MVVM\View\Screen\Seller\Products\add_product_screen.dart", "r", encoding="utf-8") as f:
    content = f.read()

# Fix ? back to ₹
content = content.replace('"?$', '"₹$')

# Now fix the formatting from Text("₹$origPrice" to Text("₹${origPrice.toString().replaceAll(RegExp(r'\.0$'), '')}"
content = content.replace('Text("₹$origPrice"', 'Text("₹${origPrice.toString().replaceAll(RegExp(r\'\\\\.0$\'), \'\')}"')
content = content.replace('Text("₹$discPrice"', 'Text("₹${discPrice.toString().replaceAll(RegExp(r\'\\\\.0$\'), \'\')}"')

# There might also be a case for controller.variants map where it was v.price and v.discountPrice
content = content.replace('Text("₹${v.price}"', 'Text("₹${v.price.toString().replaceAll(RegExp(r\'\\\\.0$\'), \'\')}"')
content = content.replace('Text("₹${v.discountPrice}"', 'Text("₹${v.discountPrice.toString().replaceAll(RegExp(r\'\\\\.0$\'), \'\')}"')

with open(r"d:\nattulinkapp\NaattuLink\lib\MVVM\View\Screen\Seller\Products\add_product_screen.dart", "w", encoding="utf-8") as f:
    f.write(content)

print("Formatting applied")
