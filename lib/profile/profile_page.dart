// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class ProfilePage extends StatelessWidget {
//   const ProfilePage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final user = FirebaseAuth.instance.currentUser;

//     return Scaffold(
//       appBar: AppBar(title: const Text('Profile')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Name: ${user?.displayName ?? "Anonymous"}'),
//             const SizedBox(height: 8),
//             Text('Email: ${user?.email ?? "-"}'),
//           ],
//         ),
//       ),
//     );
//   }
// }
