import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:naattulink/MVVM/utils/Constants/colors.dart';
import 'package:naattulink/MVVM/utils/widget/containner/shimmer_skeleton.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  String? selectedBookingId;
  String? verificationCode;
  bool waitingForCode = false;

  @override
  void initState() {
    super.initState();
    _startNewChat();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _clearChat();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startNewChat() async {
    _controller.clear();
    if (userId != null) {
      final messages = await FirebaseFirestore.instance
          .collection('chats')
          .doc(userId)
          .collection('messages')
          .get();
      for (var doc in messages.docs) {
        await doc.reference.delete();
      }
    }
    _sendInitialBotGreeting();
  }

  void _sendInitialBotGreeting() async {
    final response = "How can I help you today?";
    final options = [
      "My Bookings",
      "Cancel Booking",
      "Payment",
      "Something Else"
    ];

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(userId)
        .collection('messages')
        .add({
      "sender": "bot",
      "text": response,
      "time": DateTime.now(),
      "options": options,
    });
  }

  void _clearChat() async {
    if (userId == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('chats')
        .doc(userId)
        .collection('messages')
        .get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  void _sendMessage(String message) async {
    if (message.trim().isEmpty || userId == null) return;

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(userId)
        .collection('messages')
        .add({
      "sender": "user",
      "text": message,
      "time": DateTime.now(),
    });

    _controller.clear();
    _sendBotMessage(message);
  }

  Future<List<Map<String, dynamic>>> _getUserBookings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: user.uid)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        "title": data['serviceTitle'] ?? 'No title',
        "image": data['image'] ?? '', // <- using image safely
        "bookingId": doc.id,
      };
    }).toList();
  }

  void _sendBotMessage(String message) async {
    await Future.delayed(const Duration(milliseconds: 200));
    String response = "";
    List<dynamic>? options;

    if (message == "My Bookings") {
      final bookings = await _getUserBookings();
      if (bookings.isNotEmpty) {
        response = "Here are your bookings:";
        options = bookings;
      } else {
        response = "No bookings available";
        options = [];
      }
    } else if (waitingForCode && message == verificationCode) {
      response = "✅ Your booking has been cancelled successfully!";
      options = null;
      waitingForCode = false;
      verificationCode = null;
    } else if (message == "Cancel Booking") {
      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .get();

      if (snapshot.docs.isEmpty) {
        response = "No bookings available to cancel.";
        options = [];
      } else {
        response = "Select a booking to cancel:";
        options = snapshot.docs.map((doc) {
          return {
            "title": doc['serviceTitle'] ?? 'No title',
            "image": doc['image'] ?? '',
            "bookingId": doc.id,
          };
        }).toList();
      }
    } else if (message.startsWith("cancel:")) {
      selectedBookingId = message.replaceFirst("cancel:", "").trim();
      response = "Are you sure you want to cancel your booking?";
      options = ["Yes", "No"];
    } else if (message == "Yes" && selectedBookingId != null) {
      verificationCode =
          (10000 + DateTime.now().millisecondsSinceEpoch % 90000).toString();
      waitingForCode = true;

      response =
          "Please enter the code we sent to your email to confirm cancellation";
      options = null;

      print("DEBUG: Verification code sent to email: $verificationCode");
    } else if (message == "No") {
      response = "Booking was not cancelled.";
      options = ["My Bookings", "Cancel Booking", "Payment", "Something Else"];
    } else if (message == "Payment") {
      response = "You can view your recent payments in the Payment section.";
    } else if (message == "Something Else") {
      response = "Sure, please type your message below.";
    } else {
      response = "Thank you for sharing. We'll get back to you shortly.";
    }

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(userId)
        .collection('messages')
        .add({
      "sender": "bot",
      "text": response,
      "time": DateTime.now(),
      "options": options,
    });
  }

  String _formattedTime(DateTime time) {
    return DateFormat("hh:mm a").format(time);
  }

  String _getDateHeader(DateTime time) {
    DateTime now = DateTime.now();
    DateTime yesterday = now.subtract(const Duration(days: 1));
    if (DateFormat('yyyy-MM-dd').format(time) ==
        DateFormat('yyyy-MM-dd').format(now)) {
      return "Today";
    } else if (DateFormat('yyyy-MM-dd').format(time) ==
        DateFormat('yyyy-MM-dd').format(yesterday)) {
      return "Yesterday";
    } else {
      return DateFormat("dd MMM yyyy").format(time);
    }
  }

  Widget _buildMessage(Map<String, dynamic> message, bool showDateHeader) {
    bool isUser = message["sender"] == "user";
    return Column(
      crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (showDateHeader)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_getDateHeader(message["time"]),
                    style: const TextStyle(fontSize: 12)),
              ),
            ),
          ),
        Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUser
                  ? const Color.fromRGBO(53, 120, 1, 1)
                  : const Color.fromRGBO(241, 255, 239, 1),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(15),
                topRight: const Radius.circular(15),
                bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
                bottomRight: isUser ? Radius.zero : const Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(message["text"],
                    style:
                        TextStyle(color: isUser ? Colors.white : Colors.black)),
                const SizedBox(height: 5),
                Text(_formattedTime(message["time"]),
                    style: TextStyle(
                        fontSize: 10,
                        color: isUser ? Colors.white : Colors.black)),
              ],
            ),
          ),
        ),
        if (message["options"] != null) _buildOptions(message["options"]),
      ],
    );
  }

  Widget _buildOptions(List<dynamic> options) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Container(
        width: 230,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(241, 255, 239, 1),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: options.map((option) {
            if (option is String) {
              return GestureDetector(
                onTap: () => _sendMessage(option),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(option, style: const TextStyle(fontSize: 16)),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              );
            } else if (option is Map<String, dynamic>) {
              return GestureDetector(
                onTap: () => _sendMessage("cancel:${option["bookingId"]}"),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          option["image"] ?? '',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(option["title"],
                            style: const TextStyle(fontSize: 16)),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              );
            } else {
              return const SizedBox.shrink();
            }
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBottomInput() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 110, left: 10),
      child: Row(
        children: [
          Expanded(
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(15),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: "How Can I Help You?",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: SizedBox(
              width: 60,
              height: 50,
              child: FloatingActionButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                mini: true,
                backgroundColor: Colors.white,
                onPressed: () => _sendMessage(_controller.text.trim()),
                child: Icon(Icons.send, color: gradientgreen2.c),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: Column(
        children: [
          Container(
            height: 80,
            width: double.infinity,
            padding: const EdgeInsets.only(top: 30, left: 10, right: 10),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 102, 214, 10),
                  Color.fromARGB(255, 113, 191, 4),
                  Color.fromARGB(255, 26, 159, 6),
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 48),
                const Text("Swift Support",
                    style: TextStyle(fontSize: 20, color: Colors.white)),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _startNewChat,
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(userId)
                  .collection('messages')
                  .orderBy('time')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const ChatHistorySkeleton();
                }
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final msg = docs[index].data() as Map<String, dynamic>;
                    final time = (msg['time'] as Timestamp).toDate();
                    final showDateHeader = index == 0 ||
                        _getDateHeader(time) !=
                            _getDateHeader((docs[index - 1].data()
                                    as Map<String, dynamic>)['time']
                                .toDate());
                    return _buildMessage(
                        {...msg, 'time': time}, showDateHeader);
                  },
                );
              },
            ),
          ),
          _buildBottomInput(),
        ],
      ),
    );
  }
}



// import 'dart:convert';
// import 'dart:math';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
// import 'package:naattulink/MVVM/utils/Constants/colors.dart';

// class ChatPage extends StatefulWidget {
//   const ChatPage({super.key});

//   @override
//   State<ChatPage> createState() => _ChatPageState();
// }

// class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
//   final TextEditingController _controller = TextEditingController();
//   final String? userId = FirebaseAuth.instance.currentUser?.uid;

//   String? selectedBookingId;
//   String? verificationCode;
//   bool waitingForCode = false;

//   @override
//   void initState() {
//     super.initState();
//     _startNewChat();
//     WidgetsBinding.instance.addObserver(this);
//   }

//   @override
//   void dispose() {
//     _clearChat();
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }

//   void _startNewChat() async {
//     _controller.clear();
//     if (userId != null) {
//       final messages = await FirebaseFirestore.instance
//           .collection('chats')
//           .doc(userId)
//           .collection('messages')
//           .get();
//       for (var doc in messages.docs) {
//         await doc.reference.delete();
//       }
//     }
//     _sendInitialBotGreeting();
//   }

//   void _clearChat() async {
//     if (userId == null) return;
//     final snapshot = await FirebaseFirestore.instance
//         .collection('chats')
//         .doc(userId)
//         .collection('messages')
//         .get();
//     for (var doc in snapshot.docs) {
//       await doc.reference.delete();
//     }
//   }

//   void _sendInitialBotGreeting() async {
//     const response = "How can I help you today?";
//     const options = ["My Bookings", "Cancel Booking", "Payment", "Something Else"];
//     await _addBotMessage(response, options);
//   }

//   void _sendMessage(String message) async {
//     if (message.trim().isEmpty || userId == null) return;

//     await FirebaseFirestore.instance
//         .collection('chats')
//         .doc(userId)
//         .collection('messages')
//         .add({
//       "sender": "user",
//       "text": message,
//       "time": DateTime.now(),
//     });

//     _controller.clear();
//     _sendBotMessage(message);
//   }
  
//   Future<List<Map<String, dynamic>>> _getUserPayments() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user ==null ) return [];

//     final snapshot = await FirebaseFirestore.instance
//       .collection('payments')
//       .where('userId', isEqualTo: user.uid)
//       .orderBy('timestamp',descending: true)
//       .limit(5).get();

//     return snapshot.docs.map((doc){
//       final data = doc.data();
//       return {
//         "title": "paid: ₹${data['amount']}",
//         "image": "assets/icons/clock_payment.png",
//         "bookingId": data['bookingId'] ?? '',
//       };
//     }).toList();
//   }


//   Future<void> _sendBotMessage(String message) async {
//     await Future.delayed(const Duration(milliseconds: 300));
//     String response = "";
//     List<dynamic>? options;

//     final user = FirebaseAuth.instance.currentUser;

//     if (message == "My Bookings") {
//       final bookings = await _getUserBookings();
//       if (bookings.isNotEmpty) {
//         response = "Here are your bookings:";
//         options = bookings;
//       } else {
//         response = "No bookings available.";
//       }
//     } else if (waitingForCode && message == verificationCode) {
//       // Cancel the booking
//       await FirebaseFirestore.instance.collection('bookings').doc(selectedBookingId).delete();
//       response = "✅ Your booking has been cancelled successfully!";
//       waitingForCode = false;
//       verificationCode = null;
//       selectedBookingId = null;
//     } else if (message == "Cancel Booking") {
//       final snapshot = await FirebaseFirestore.instance
//           .collection('bookings')
//           .where('userId', isEqualTo: userId)
//           .get();
//       if (snapshot.docs.isEmpty) {
//         response = "No bookings available to cancel.";
//       } else {
//         response = "Select a booking to cancel:";
//         options = snapshot.docs.map((doc) {
//           return {
//             "title": doc['serviceTitle'] ?? 'No Title',
//             "image": doc['image'],
//             "bookingId": doc.id,
//           };
//         }).toList();
//       }
//     } else if (message.startsWith("cancel:")) {
//       selectedBookingId = message.replaceFirst("cancel:", "").trim();
//       response = "Are you sure you want to cancel this booking?";
//       options = ["Yes", "No"];
//     } else if (message == "Yes" && selectedBookingId != null) {
//       // Generate and send code
//       verificationCode = (Random().nextInt(90000) + 10000).toString();
//       waitingForCode = true;

//       if (user?.email != null) {
//         try {
//           await sendVerificationEmail(user!.email!, verificationCode!);
//           response = "We sent a 5-digit code to your email. Please enter it to confirm cancellation.";
//         } catch (e) {
//           response = "Failed to send verification code. Try again later.";
//           waitingForCode = false;
//           verificationCode = null;
//         }
//       }
//     } else if (message == "No") {
//       response = "Okay, your booking was not cancelled.";
//       options = ["My Bookings", "Cancel Booking", "Payment", "Something Else"];
//     } else if (message == "Payment") {
//       final payments = await _getUserPayments();
//       if(payments.isNotEmpty){
//         response = "Here are your recent found.";
//         options = payments;
//       } else{
//         response = "No payments found.";
//       }
//     } else if (message == "Something Else") {
//       response = "Sure, please type your message below.";
//     } else {
//       response = "Thanks for sharing. We'll get back to you shortly.";
//     }

//     await _addBotMessage(response, options);
//   }

//   Future<void> _addBotMessage(String text, List<dynamic>? options) async {
//     await FirebaseFirestore.instance
//         .collection('chats')
//         .doc(userId)
//         .collection('messages')
//         .add({
//       "sender": "bot",
//       "text": text,
//       "time": DateTime.now(),
//       "options": options,
//     });
//   }

//   Future<List<Map<String, dynamic>>> _getUserBookings() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return [];

//     final snapshot = await FirebaseFirestore.instance
//         .collection('bookings')
//         .where('userId', isEqualTo: user.uid)
//         .get();

//     return snapshot.docs.map((doc) {
//       final data = doc.data();
//       return {
//         "title": data['serviceTitle'] ?? 'No Title',
//         "image": data['image'],
//         "bookingId": doc.id,
//       };
//     }).toList();
//   }

//   Widget _buildMessage(Map<String, dynamic> message, bool showDateHeader) {
//     final isUser = message['sender'] == 'user';
//     final time = message['time'] as DateTime;
//     return Column(
//       crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//       children: [
//         if (showDateHeader)
//           Center(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(vertical: 8),
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade300,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Text(_getDateHeader(time), style: const TextStyle(fontSize: 12)),
//               ),
//             ),
//           ),
//         Align(
//           alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
//           child: Container(
//             margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: isUser ? gradientgreen2.c: const Color.fromRGBO(241, 255, 239, 1),
//               borderRadius: BorderRadius.only(
//                 topLeft: const Radius.circular(15),
//                 topRight: const Radius.circular(15),
//                 bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
//                 bottomRight: isUser ? Radius.zero : const Radius.circular(20),
//               ),
//             ),
//             child: Column(
//               crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//               children: [
//                 Text(message['text'], style: TextStyle(color: isUser ? Colors.white : Colors.black)),
//                 const SizedBox(height: 5),
//                 Text(DateFormat('hh:mm a').format(time),
//                     style: TextStyle(fontSize: 10, color: isUser ? Colors.white : Colors.black)),
//               ],
//             ),
//           ),
//         ),
//         if (message['options'] != null) _buildOptions(message['options']),
//       ],
//     );
//   }

//   Widget _buildOptions(List<dynamic> options) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//       child: Container(
//         width: 230,
//         padding: const EdgeInsets.all(10),
//         decoration: BoxDecoration(
//           color: const Color.fromRGBO(241, 255, 239, 1),
//           borderRadius: const BorderRadius.only(
//             topLeft: Radius.circular(20),
//             topRight: Radius.circular(20),
//             bottomRight: Radius.circular(20),
//           ),
//         ),
//         child: Column(
//           children: options.map((option) {
//             if (option is String) {
//               return GestureDetector(
//                 onTap: () => _sendMessage(option),
//                 child: _optionTile(option),
//               );
//             } else if (option is Map<String, dynamic>) {
//               return GestureDetector(
//                 onTap: () => _sendMessage("cancel:${option['bookingId']}"),
//                 child: _bookingTile(option),
//               );
//             }
//             return const SizedBox.shrink();
//           }).toList(),
//         ),
//       ),
//     );
//   }

//   Widget _optionTile(String text) {
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 5),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [Text(text), const Icon(Icons.arrow_forward_ios, size: 16)],
//       ),
//     );
//   }

//   Widget _bookingTile(Map<String, dynamic> data) {
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 5),
//       padding: const EdgeInsets.all(10),
//       decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
//       child: Row(
//         children: [
//           Image.asset(data['image'], width: 50, height: 50),
//           const SizedBox(width: 10),
//           Expanded(child: Text(data['title'], style: const TextStyle(fontSize: 16))),
//           const Icon(Icons.arrow_forward_ios, size: 16),
//         ],
//       ),
//     );
//   }

//   String _getDateHeader(DateTime time) {
//     final now = DateTime.now();
//     final yesterday = now.subtract(const Duration(days: 1));
//     if (DateFormat('yyyy-MM-dd').format(time) == DateFormat('yyyy-MM-dd').format(now)) {
//       return "Today";
//     } else if (DateFormat('yyyy-MM-dd').format(time) == DateFormat('yyyy-MM-dd').format(yesterday)) {
//       return "Yesterday";
//     } else {
//       return DateFormat("dd MMM yyyy").format(time);
//     }
//   }

//   Widget _buildBottomInput() {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 110, left: 10),
//       child: Row(
//         children: [
//           Expanded(
//             child: Material(
//               elevation: 2,
//               borderRadius: BorderRadius.circular(15),
//               child: TextField(
//                 controller: _controller,
//                 decoration: InputDecoration(
//                   hintText: "How can I help you?",
//                   filled: true,
//                   fillColor: Colors.white,
//                   border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(width: 15),
//           Padding(
//             padding: const EdgeInsets.only(right: 10),
//             child: SizedBox(
//               width: 60,
//               height: 50,
//               child: FloatingActionButton(
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//                 mini: true,
//                 backgroundColor: Colors.white,
//                 onPressed: () => _sendMessage(_controller.text.trim()),
//                 child: const Icon(Icons.send, color: gradientgreen2.c),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey.shade200,
//       body: Column(
//         children: [
//           Container(
//             height: 80,
//             padding: const EdgeInsets.only(top: 30, left: 10, right: 10),
//             decoration: const BoxDecoration(
//               borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
//               gradient: LinearGradient(colors: [
//                 Color(0xFF66D60A),
//                 Color(0xFF71BF04),
//                 Color(0xFF1A9F06),
//               ]),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const SizedBox(width: 48),
//                 const Text("Swift Support", style: TextStyle(fontSize: 20, color: Colors.white)),
//                 IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _startNewChat),
//               ],
//             ),
//           ),
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection('chats')
//                   .doc(userId)
//                   .collection('messages')
//                   .orderBy('time')
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

//                 final docs = snapshot.data!.docs;
//                 return ListView.builder(
//                   padding: const EdgeInsets.all(10),
//                   itemCount: docs.length,
//                   itemBuilder: (context, index) {
//                     final msg = docs[index].data() as Map<String, dynamic>;
//                     final time = (msg['time'] as Timestamp).toDate();
//                     final showDateHeader = index == 0 ||
//                         _getDateHeader(time) !=
//                             _getDateHeader((docs[index - 1].data() as Map<String, dynamic>)['time'].toDate());
//                     return _buildMessage({...msg, 'time': time}, showDateHeader);
//                   },
//                 );
//               },
//             ),
//           ),
//           _buildBottomInput(),
//         ],
//       ),
//     );
//   }
// }

// // 🔐 Send email using EmailJS
// Future<void> sendVerificationEmail(String email, String code) async {
//   const serviceId = 'your_emailjs_service_id';
//   const templateId = 'your_template_id';
//   const userId = 'your_emailjs_public_key';

//   final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
//   final response = await http.post(
//     url,
//     headers: {'Content-Type': 'application/json'},
//     body: json.encode({
//       'service_id': serviceId,
//       'template_id': templateId,
//       'user_id': userId,
//       'template_params': {
//         'to_email': email,
//         'verification_code': code,
//       },
//     }),
//   );

//   if (response.statusCode != 200) {
//     throw Exception("Email sending failed: ${response.body}");
//   }
// }



