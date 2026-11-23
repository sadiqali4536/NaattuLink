void main() {
  dynamic data = {
    "status": true,
    "data": [
      {
        "can_access": true,
        "id": 387
      }
    ]
  };

  print(data is! Map);

  final canAccess = (data['data'] is Map)
      ? data['data']['can_access'] == true
      : (data['can_access'] == true);

  print(canAccess);
}
