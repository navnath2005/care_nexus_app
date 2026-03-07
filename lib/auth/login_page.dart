// import 'package:care_nexus/doctor/doctor_dashboard.dart';
// import 'package:care_nexus/firebase_options.dart';
// import 'package:care_nexus/patient/patient_dashboard.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:google_sign_in/google_sign_in.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   runApp(const CareNexus());
// }

// /* ******************** APP ROOT ******************** */

// class CareNexus extends StatelessWidget {
//   const CareNexus({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: "Care Nexus",
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         useMaterial3: true,
//         colorSchemeSeed: Colors.blue,
//         scaffoldBackgroundColor: Colors.grey.shade100,
//       ),
//       home: StreamBuilder<User?>(
//         stream: FirebaseAuth.instance.authStateChanges(),
//         builder: (context, snapshot) {
//           // 🔥 Prevent freeze
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Scaffold(
//               body: Center(child: CircularProgressIndicator()),
//             );
//           }

//           if (snapshot.hasError) {
//             return const Scaffold(
//               body: Center(child: Text("Something went wrong")),
//             );
//           }

//           return snapshot.data == null ? const LoginPage() : const RoleRouter();
//         },
//       ),
//     );
//   }
// }

// /* ******************** ROLE ROUTER ******************** */

// class RoleRouter extends StatelessWidget {
//   const RoleRouter({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final user = FirebaseAuth.instance.currentUser;

//     // Safety check
//     if (user == null) {
//       return const Scaffold(body: Center(child: Text("User not logged in")));
//     }

//     return FutureBuilder<DocumentSnapshot>(
//       future: FirebaseFirestore.instance
//           .collection("users")
//           .doc(user.uid)
//           .get(),
//       builder: (context, snapshot) {
//         // Loading
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Scaffold(
//             body: Center(child: CircularProgressIndicator()),
//           );
//         }

//         // Error
//         if (snapshot.hasError) {
//           return const Scaffold(
//             body: Center(child: Text("Failed to load user data")),
//           );
//         }

//         // No user document
//         if (!snapshot.hasData || !snapshot.data!.exists) {
//           return const Scaffold(
//             body: Center(child: Text("User record not found")),
//           );
//         }

//         final data = snapshot.data!.data() as Map<String, dynamic>;
//         final role = (data["role"] ?? "").toString().toLowerCase();

//         // Route by role
//         switch (role) {
//           case "doctor":
//             return const DoctorDashboard();

//           case "patient":
//             return const PatientDashboard();

//           default:
//             return Scaffold(
//               body: Center(child: Text("Unknown role: ${data["role"]}")),
//             );
//         }
//       },
//     );
//   }
// }

// /* ******************** LOGIN PAGE ******************** */

// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key});

//   @override
//   State<LoginPage> createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {
//   final email = TextEditingController();
//   final password = TextEditingController();
//   final _form = GlobalKey<FormState>();
//   bool loading = false;

//   final GoogleSignIn _googleSignIn = GoogleSignIn();

//   @override
//   void dispose() {
//     email.dispose();
//     password.dispose();
//     super.dispose();
//   }

//   Future<void> signInGoogle() async {
//     try {
//       final gUser = await _googleSignIn.signIn();
//       if (gUser == null) return;

//       final gAuth = await gUser.authentication;

//       final cred = GoogleAuthProvider.credential(
//         idToken: gAuth.idToken,
//         accessToken: gAuth.accessToken,
//       );

//       final userCred = await FirebaseAuth.instance.signInWithCredential(cred);

//       final userDoc = FirebaseFirestore.instance
//           .collection("users")
//           .doc(userCred.user!.uid);

//       if (!(await userDoc.get()).exists) {
//         await userDoc.set({
//           "name": userCred.user!.displayName,
//           "email": userCred.user!.email,
//           "role": "Patient",
//           "createdAt": FieldValue.serverTimestamp(),
//         });
//       }

//       if (!mounted) return;

//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("Signed in with Google 😎")));
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text(e.toString())));
//     }
//   }

//   bool _isPasswordVisible = false;

//   Future<void> login() async {
//     FocusManager.instance.primaryFocus?.unfocus();

//     if (!_form.currentState!.validate()) return;

//     setState(() => loading = true);

//     try {
//       final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
//         email: email.text.trim(),
//         password: password.text.trim(),
//       );

//       final user = cred.user;
//       final isEmailPasswordUser =
//           user?.providerData.any((p) => p.providerId == 'password') ?? false;

//       if (isEmailPasswordUser && user != null && !user.emailVerified) {
//         await FirebaseAuth.instance.signOut();
//         throw FirebaseAuthException(
//           code: "email-not-verified",
//           message: "Please verify your email 📩",
//         );
//       }

//       // Check mounted before showing SnackBar
//       if (mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(const SnackBar(content: Text("Welcome back 👋")));
//       }
//     } on FirebaseAuthException catch (e) {
//       // Check mounted before showing Error SnackBar
//       if (mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text(e.message ?? "Login failed")));
//       }
//     } finally {
//       // This is where the crash usually happens.
//       // If the AuthGate has already swapped pages, mounted is false.
//       if (mounted) {
//         setState(() => loading = false);
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: Center(
//           child: Card(
//             margin: const EdgeInsets.all(20),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Padding(
//               padding: const EdgeInsets.all(24),
//               child: Form(
//                 key: _form,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Icon(
//                       Icons.local_hospital,
//                       size: 48,
//                       color: Colors.blue,
//                     ),

//                     const SizedBox(height: 12),

//                     const Text(
//                       "Care Nexus Login",
//                       style: TextStyle(
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),

//                     const SizedBox(height: 20),

//                     TextFormField(
//                       controller: email,
//                       decoration: const InputDecoration(
//                         labelText: "Email",
//                         prefixIcon: Icon(Icons.email),
//                       ),
//                       validator: (v) => v != null && v.contains("@")
//                           ? null
//                           : "Enter valid email",
//                     ),

//                     const SizedBox(height: 12),

//                     TextFormField(
//                       controller: password,
//                       obscureText: !_isPasswordVisible,
//                       decoration: InputDecoration(
//                         labelText: "Password",
//                         prefixIcon: const Icon(Icons.lock),
//                         suffixIcon: IconButton(
//                           icon: Icon(
//                             _isPasswordVisible
//                                 ? Icons.visibility
//                                 : Icons.visibility_off,
//                           ),
//                           onPressed: () {
//                             setState(() {
//                               _isPasswordVisible = !_isPasswordVisible;
//                             });
//                           },
//                         ),
//                       ),
//                       validator: (v) => v != null && v.length >= 6
//                           ? null
//                           : "Min 6 characters",
//                     ),

//                     const SizedBox(height: 20),

//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: loading ? null : login,
//                         child: loading
//                             ? const CircularProgressIndicator(
//                                 color: Colors.white,
//                               )
//                             : const Text("Login"),
//                       ),
//                     ),

//                     const SizedBox(height: 10),
//                     SizedBox(
//                       width: double.infinity,
//                       height: 48,
//                       child: ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.white,
//                           foregroundColor: Colors.black87,
//                           elevation: 2,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             side: BorderSide(color: Colors.grey.shade300),
//                           ),
//                         ),
//                         onPressed: loading ? null : signInGoogle,
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Image.asset("assets/google.jpg", height: 22),
//                             const SizedBox(width: 10),
//                             const Text(
//                               "Continue with Google",
//                               style: TextStyle(
//                                 fontSize: 15,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),

//                     // OutlinedButton.icon(
//                     //   icon: const Icon(Icons.g_mobiledata),
//                     //   label: const Text("Login with Google"),
//                     //   onPressed: signInGoogle,
//                     // ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
