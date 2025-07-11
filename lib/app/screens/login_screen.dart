import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qadam_app/app/services/auth_service.dart';
import 'package:qadam_app/app/screens/home_screen.dart';
import 'package:qadam_app/app/screens/register_screen.dart';
import 'package:qadam_app/app/screens/forgot_password_screen.dart';
import 'package:qadam_app/app/components/loading_widget.dart';
import 'package:qadam_app/app/components/error_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  final String? referralCode;

  const LoginScreen({Key? key, this.referralCode}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // URL dan referral code ni olish
    _checkForReferralCode();
  }

  void _checkForReferralCode() {
    // Bu yerda URL dan referral code ni olish mumkin
    // Hozircha widget.referralCode ni ishlatamiz
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.directions_walk,
                      size: 60,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Title
                Text(
                  'Qadam++',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Theme.of(context).primaryColor,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Ilovaga kirish',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),

                // Referral code banner
                if (widget.referralCode != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.card_giftcard, color: Colors.green),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Referral kod: ${widget.referralCode}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 30),

                // Login form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Email field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Emailni kiriting';
                          }
                          if (!value.contains('@')) {
                            return 'To\'g\'ri email kiriting';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),

                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Parol',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Parolni kiriting';
                          }
                          if (value.length < 6) {
                            return 'Parol kamida 6 ta belgidan iborat bo\'lishi kerak';
                          }
                          return null;
                        },
                      ),

                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: const Text('Parolni unutdingizmi?'),
                        ),
                      ),

                      // Login button
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: authService.isLoading
                              ? null
                              : () async {
                                  if (_formKey.currentState!.validate()) {
                                    final success =
                                        await authService.signInWithEmail(
                                      _emailController.text.trim(),
                                      _passwordController.text.trim(),
                                    );

                                    if (success && mounted) {
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                          builder: (_) => const HomeScreen(),
                                        ),
                                      );
                                    }
                                  }
                                },
                          child: authService.isLoading
                              ? const LoadingWidget(message: 'Kirish...')
                              : const Text(
                                  'Kirish',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (authService.errorMessage != null)
                        AppErrorWidget(
                          message: authService.errorMessage!,
                        ),

                      const SizedBox(height: 20),

                      // OR divider
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 15),
                            child: Text(
                              'YOKI',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.grey.withOpacity(0.3),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Google login button
                      SizedBox(
                        height: 50,
                        child: OutlinedButton.icon(
                          icon: Image.asset(
                            'assets/images/google_logo.png',
                            height: 24,
                          ),
                          label: const Text(
                            'Google bilan kirish',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.grey.withOpacity(0.5),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          onPressed: authService.isLoading
                              ? null
                              : () async {
                                  final success =
                                      await authService.signInWithGoogle();
                                  if (success && mounted) {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (_) => const HomeScreen(),
                                      ),
                                    );
                                  }
                                },
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Register link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Hisobingiz yo\'qmi?'),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RegisterScreen(
                                    referralCode: widget.referralCode,
                                  ),
                                ),
                              );
                            },
                            child: const Text('Ro\'yxatdan o\'tish'),
                          ),
                        ],
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
