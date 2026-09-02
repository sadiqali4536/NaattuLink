with open(r"d:\nattulinkapp\NaattuLink\lib\MVVM\View\Screen\Seller\Products\add_product_screen.dart", "r", encoding="utf-8") as f:
    content = f.read()

content = content.replace('"?', '"₹')
content = content.replace("'?", "'₹")

with open(r"d:\nattulinkapp\NaattuLink\lib\MVVM\View\Screen\Seller\Products\add_product_screen.dart", "w", encoding="utf-8") as f:
    f.write(content)
print("Done")
