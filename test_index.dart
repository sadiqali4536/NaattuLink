void main() {
  dynamic a = "hello";
  try {
    print(a['practice']);
  } catch(e) {
    print(e.toString());
  }
}
