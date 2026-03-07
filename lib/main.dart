import 'package:care_nexus/admin/admin_dashboard.dart';
import 'package:care_nexus/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'routes.dart' show RoleRouter;

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  runApp(const CareNexus());
}

// ============ CUSTOM WIDGETS ============

/// Professional gradient background for authentication pages
authBackground({required Widget child, bool isDark = false}) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: isDark
            ? [Color(0xFF1E3A8A), Color(0xFF3B82F6)]
            : [Color(0xFF2563EB), Color(0xFF60A5FA)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Center(child: SingleChildScrollView(child: child)),
  );
}

/// Professional app bar for all pages
PreferredSizeWidget customAppBar(
  String title, {
  bool showBackButton = true,
  List<Widget>? actions,
}) {
  return AppBar(
    elevation: 0,
    backgroundColor: Colors.blue.shade700,
    foregroundColor: Colors.white,
    title: Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 20,
        letterSpacing: 0.5,
      ),
    ),
    centerTitle: true,
    actions: actions,
    automaticallyImplyLeading: showBackButton,
  );
}

/// Reusable professional button
Widget professionalButton({
  required String label,
  required VoidCallback? onPressed,
  bool isLoading = false,
  Color bgColor = Colors.blue,
  double width = double.infinity,
  double height = 48,
  bool isOutlined = false,
}) {
  if (isOutlined) {
    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: bgColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(bgColor),
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: bgColor,
                ),
              ),
      ),
    );
  }

  return SizedBox(
    width: width,
    height: height,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        disabledBackgroundColor: bgColor.withOpacity(0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 4,
      ),
      child: isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
    ),
  );
}

// ============ MAIN APP ============

class CareNexus extends StatelessWidget {
  const CareNexus({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Care Nexus",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        scaffoldBackgroundColor: Colors.grey.shade50,
        fontFamily: 'Poppins',
      ),
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          return snapshot.hasData ? const RoleRouter() : const AuthModePage();
        },
      ),
    );
  }
}

// ============ AUTH MODE SELECTION ============

class AuthModePage extends StatelessWidget {
  const AuthModePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: authBackground(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo & Branding
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.local_hospital,
                        size: 56,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Care Nexus",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Healthcare Management Platform",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Role Selection Buttons
                      professionalButton(
                        label: "👤 User Login",
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        ),
                      ),
                      const SizedBox(height: 12),
                      professionalButton(
                        label: "🔐 Admin Dashboard",
                        bgColor: Colors.orange.shade600,
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminLoginPage(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      professionalButton(
                        label: "➕ Create Account",
                        isOutlined: true,
                        bgColor: Colors.blue.shade700,
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterPage(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============ FIXED LOGIN PAGE ============

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // FIX 1: Proper FormKey initialization
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _isPasswordVisible = false;

  // FIX 2: Improved error handling and validation
  Future<void> login() async {
    // Check if form is valid before proceeding
    if (_formKey.currentState == null) {
      _showError("Form not initialized properly");
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return; // Don't proceed if validation fails
    }

    setState(() => _loading = true);
    try {
      // Validate inputs before Firebase call
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        _showError("Email and password are required");
        return;
      }

      // Sign in with Firebase
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Success - no need to navigate, StreamBuilder will handle it
      if (!mounted) return;
    } on FirebaseAuthException catch (e) {
      // FIX 3: Better error messages for Firebase exceptions
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many login attempts. Please try again later';
          break;
        default:
          errorMessage = e.message ?? 'Authentication failed. Please try again';
      }
      _showError(errorMessage);
    } catch (e) {
      _showError('An unexpected error occurred: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        title: const Text(
          "User Login",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: authBackground(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            margin: const EdgeInsets.all(20),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                // FIX 5: Ensure Form widget wraps all fields
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person, size: 48, color: Colors.blue.shade700),
                      const SizedBox(height: 8),
                      const Text(
                        "Welcome Back",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Email Field
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: "Email",
                          hintText: "your@email.com",
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Email is required";
                          }
                          if (!value.contains("@") || !value.contains(".")) {
                            return "Please enter a valid email";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      // Password Field
                      TextFormField(
                        controller: passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: "Password",
                          hintText: "Enter your password",
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () => setState(
                              () => _isPasswordVisible = !_isPasswordVisible,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Password is required";
                          }
                          if (value.length < 6) {
                            return "Password must be at least 6 characters";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _loading ? null : login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            disabledBackgroundColor: Colors.blue.shade700
                                .withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 4,
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  "Login",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterPage(),
                              ),
                            ),
                            child: Text(
                              "Register",
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============ ADMIN LOGIN PAGE (FIXED) ============

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final adminKeyController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // FIX 1: Add proper type annotation <FormState>
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _isPasswordVisible = false;
  static const String ADMIN_KEY = "Admin2026"; // Change this to a secure key

  // FIX 2: Improved validation and error handling
  Future<void> adminLogin() async {
    // Check if form key is initialized
    if (_formKey.currentState == null) {
      _showError("Form not initialized properly");
      return;
    }

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return; // Stop if validation fails
    }

    // Get trimmed values
    final adminKey = adminKeyController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // Verify admin key first
    if (adminKey != ADMIN_KEY) {
      _showError("Invalid admin key");
      return;
    }

    // Check email format
    if (!email.contains("@") || !email.contains(".")) {
      _showError("Invalid email format");
      return;
    }

    // Check password length
    if (password.length < 6) {
      _showError("Password must be at least 6 characters");
      return;
    }

    setState(() => _loading = true);
    try {
      // Sign in with Firebase
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Verify user is admin in Firestore
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        await FirebaseAuth.instance.signOut();
        _showError("User profile not found");
        return;
      }

      final role = (userDoc.data()?['role'] ?? '').toString().toLowerCase();

      if (role != 'admin') {
        await FirebaseAuth.instance.signOut();
        _showError("You do not have admin privileges");
        return;
      }
      // Success - clear form
      if (mounted) {
        _formKey.currentState?.reset();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
        );
      }
    } on FirebaseAuthException catch (e) {
      // FIX 3: Better Firebase error handling
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many login attempts. Try again later';
          break;
        default:
          errorMessage = e.message ?? "Authentication failed";
      }
      _showError(errorMessage);
    } catch (e) {
      _showError('An unexpected error occurred: ${e.toString()}');
      print('Admin login error: $e');
    } finally {
      // Always check mounted before setState
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showError(String msg) {
    if (!mounted) return;

    // Clear previous snackbars
    ScaffoldMessenger.of(context).clearSnackBars();

    // Show new snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    adminKeyController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar("Admin Access"),
      body: authBackground(
        isDark: true,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Card(
            elevation: 12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            margin: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.blue.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                // FIX 4: Form widget properly wraps all fields
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Admin Icon
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.admin_panel_settings,
                            size: 48,
                            color: Colors.orange.shade700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Admin Dashboard",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Secure administrator access",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 28),
                        // Admin Key Field
                        TextFormField(
                          controller: adminKeyController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: "Admin Key",
                            hintText: "Enter security key",
                            prefixIcon: const Icon(Icons.key),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Colors.orange,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.orange.shade300,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.orange.shade700,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.orange.shade50,
                          ),
                          // FIX 5: Proper validator
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Admin key is required";
                            }
                            if (value.length < 5) {
                              return "Admin key is too short";
                            }
                            return null; // Valid
                          },
                        ),
                        const SizedBox(height: 16),
                        // Email Field
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: "Email",
                            hintText: "admin@carenexus.com",
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          // FIX 6: Better email validator
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Email is required";
                            }
                            if (!value.contains("@") || !value.contains(".")) {
                              return "Invalid email format";
                            }
                            return null; // Valid
                          },
                        ),
                        const SizedBox(height: 16),
                        // Password Field
                        TextFormField(
                          controller: passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: "Password",
                            hintText: "Enter your password",
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () => setState(
                                () => _isPasswordVisible = !_isPasswordVisible,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          // FIX 7: Better password validator
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Password is required";
                            }
                            if (value.length < 6) {
                              return "Password must be at least 6 characters";
                            }
                            return null; // Valid
                          },
                        ),
                        const SizedBox(height: 28),
                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _loading ? null : adminLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade600,
                              disabledBackgroundColor: Colors.orange.shade600
                                  .withOpacity(0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 4,
                            ),
                            child: _loading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    "Access Admin Dashboard",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Info Box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.blue.shade200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue.shade700),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Admin access is restricted and monitored",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Back Button
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_back,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Back to Login",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============ REGISTER PAGE ============

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State createState() => _RegisterPageState();
}

class _RegisterPageState extends State {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  bool loading = false;
  String role = "Patient";
  final roles = ["Doctor", "Patient", "Ambulance", "Medical"];

  Future register() async {
    if (password.text != confirmPassword.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    setState(() => loading = true);
    try {
      final u = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );
      await FirebaseFirestore.instance
          .collection("users")
          .doc(u.user!.uid)
          .set({
            "name": name.text.trim(),
            "email": email.text.trim(),
            "role": role,
            "createdAt": FieldValue.serverTimestamp(),
          });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account created 🎉"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? "Error")));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar("Create Account"),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 4,
            margin: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_add, size: 48, color: Colors.blue.shade700),
                  const SizedBox(height: 12),
                  const Text(
                    "Join Care Nexus",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: name,
                    decoration: InputDecoration(
                      labelText: "Full Name",
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: email,
                    decoration: InputDecoration(
                      labelText: "Email Address",
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPassword,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Confirm Password",
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField(
                    initialValue: role,
                    decoration: InputDecoration(
                      labelText: "Register As",
                      prefixIcon: const Icon(Icons.badge),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    items: roles
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => role = v!),
                  ),
                  const SizedBox(height: 24),
                  professionalButton(
                    label: "Create Account",
                    onPressed: loading ? null : register,
                    isLoading: loading,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Login"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============ FORGOT PASSWORD PAGE ============

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State {
  final email = TextEditingController();
  bool loading = false;

  Future reset() async {
    setState(() => loading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Reset link sent to your email 📩"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar("Reset Password"),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 4,
            margin: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_reset, size: 48, color: Colors.blue.shade700),
                  const SizedBox(height: 12),
                  const Text(
                    "Forgot Password?",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Enter your email to receive a reset link",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: email,
                    decoration: InputDecoration(
                      labelText: "Email Address",
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 24),
                  professionalButton(
                    label: "Send Reset Link",
                    onPressed: loading ? null : reset,
                    isLoading: loading,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============ PROFILE PAGE ============

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: customAppBar("My Profile"),
      body: FutureBuilder(
        future: FirebaseFirestore.instance.collection("users").doc(uid).get(),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!.data()!;
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.person,
                                size: 32,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data["name"] ?? "User",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    data["email"] ?? "",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 16),
                        _profileField("Role", data["role"] ?? "N/A"),
                        const SizedBox(height: 12),
                        _profileField(
                          "Member Since",
                          data["createdAt"]?.toDate().toString().split(
                                ' ',
                              )[0] ??
                              "N/A",
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _profileField(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
