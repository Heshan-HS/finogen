import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'widgets/email_auth_sheet.dart';
import '../../../core/theme/app_colors.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/legal_texts.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _isLoading = false;
  bool _isTermsAccepted = false;

  @override
  void initState() {
    super.initState();
    // Auto-forward immediately if already authenticated or logged in
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final isGuest = prefs.getBool('isGuest') ?? false;
      if (FirebaseAuth.instance.currentUser != null || isLoggedIn || isGuest) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/main');
        }
      }
    });

    if (kIsWeb) {
      FirebaseAuth.instance.getRedirectResult().then((userCredential) async {
        if (userCredential.user != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isGuest', false);
          await prefs.setBool('isLoggedIn', true);
          if (mounted) _navigateToMain();
        }
      }).catchError((err) {
        debugPrint('Redirect auth error: $err');
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        try {
          await FirebaseAuth.instance.signInWithPopup(googleProvider);
        } catch (popupError) {
          debugPrint('Popup sign-in failed ($popupError). Trying signInWithRedirect...');
          await FirebaseAuth.instance.signInWithRedirect(googleProvider);
          return;
        }
      } else {
        bool signedIn = false;
        try {
          final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
          if (googleUser != null) {
            final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
            final AuthCredential credential = GoogleAuthProvider.credential(
              accessToken: googleAuth.accessToken,
              idToken: googleAuth.idToken,
            );
            await FirebaseAuth.instance.signInWithCredential(credential);
            signedIn = true;
          } else {
            // User cancelled Google sign-in dialog
            setState(() => _isLoading = false);
            return;
          }
        } catch (nativeError) {
          debugPrint('Native Google Sign-In failed ($nativeError). Falling back to Web/Browser OAuth...');
          // Fallback for non-GMS devices (e.g. Huawei Y7a) via Custom Tabs / Browser
          final googleProvider = GoogleAuthProvider();
          googleProvider.addScope('email');
          googleProvider.addScope('profile');
          await FirebaseAuth.instance.signInWithProvider(googleProvider);
          signedIn = true;
        }

        if (!signedIn) {
          setState(() => _isLoading = false);
          return;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isGuest', false);
      await prefs.setBool('isLoggedIn', true);

      if (!mounted) return;
      _navigateToMain();
    } catch (e) {
      if (!mounted) return;
      String errorMsg = e.toString();
      if (errorMsg.contains('internal-error') || errorMsg.contains('unauthorized-domain')) {
        errorMsg = 'Sign-in blocked: Please turn OFF Brave Shields (Lion icon) or add "finance.novagen.software" to Firebase Authorized Domains.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEmailAuthModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EmailAuthSheet(
        onSuccess: () {
          Navigator.pop(context);
          _navigateToMain();
        },
      ),
    );
  }

  Future<void> _signInAnonymously() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isGuest', true);
      if (!mounted) return;
      _navigateToMain();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to enter as guest: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToMain() {
    Navigator.of(context).pushReplacementNamed('/main');
  }

  void _showPolicyDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Text(content, style: const TextStyle(color: AppColors.textMuted)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        );
      },
    );
  }


  Widget _buildAdvancedFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardElevated.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              color: AppColors.textMuted.withOpacity(0.9),
              fontSize: 10,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textMuted.withOpacity(0.8),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTickItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.check, color: AppColors.primary, size: 12),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Subtle Top Glow
          Positioned(
            top: -150,
            left: 0,
            right: 0,
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.12),
                    blurRadius: 150,
                    spreadRadius: 80,
                  ),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  
                  // Compact Logo
                  Row(
                    children: [
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: const DecorationImage(
                            image: AssetImage('assets/images/mainlogo.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'FinoGen.',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(flex: 1),
                  
                  // Professional Typography
                  const Text(
                    'The ultimate financial\noperating system.',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      height: 1.1,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Engineered for precision. FinoGen combines AI-driven insights, bank-level security, and real-time synchronization to give you absolute control over your wealth.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // System Metrics Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetric('99.9%', 'UPTIME'),
                      _buildMetric('256-bit', 'AES ENCRYPTION'),
                      _buildMetric('<10ms', 'SYNC LATENCY'),
                    ],
                  ),
                  
                  const Spacer(flex: 1),
                  
                  // Detailed 2x2 Feature Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildAdvancedFeatureItem(
                          icon: LucideIcons.brainCircuit,
                          title: 'AI Analytics',
                          description: 'Predictive algorithms forecast spending habits and flag anomalies instantly.',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildAdvancedFeatureItem(
                          icon: LucideIcons.shieldCheck,
                          title: 'AES-256 Security',
                          description: 'Military-grade encryption ensures your financial data is permanently secure.',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAdvancedFeatureItem(
                          icon: LucideIcons.cloudLightning,
                          title: 'Real-time Sync',
                          description: 'Distributed cloud architecture syncs your data seamlessly across all devices.',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildAdvancedFeatureItem(
                          icon: LucideIcons.fingerprint,
                          title: 'Smart Categories',
                          description: 'Automated tagging classifies your transactions for effortless tax prep.',
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(flex: 1),
                  
                  // Pro Features List
                  _buildTickItem('End-to-end data encryption protocol'),
                  _buildTickItem('Multi-currency global wallet support'),
                  _buildTickItem('Automated advanced tax report exports'),
                  
                  const Spacer(flex: 1),
                  
                  // Terms and Privacy Checkbox
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isTermsAccepted = !_isTermsAccepted;
                          });
                        },
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: _isTermsAccepted ? AppColors.primary : Colors.transparent,
                            border: Border.all(
                              color: _isTermsAccepted ? AppColors.primary : AppColors.textMuted.withOpacity(0.5),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: _isTermsAccepted
                              ? const Icon(LucideIcons.check, color: AppColors.background, size: 14)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            text: 'I agree to the ',
                            style: TextStyle(color: AppColors.textMuted.withOpacity(0.8), fontSize: 11),
                            children: [
                              TextSpan(
                                text: 'Terms of Service',
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    _showPolicyDialog(
                                      'Terms of Service',
                                      LegalTexts.termsOfService,
                                    );
                                  },
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    _showPolicyDialog(
                                      'Privacy Policy',
                                      LegalTexts.privacyPolicy,
                                    );
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  
                  // Buttons
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  else ...[
                    GestureDetector(
                      onTap: _isTermsAccepted ? _signInWithGoogle : null,
                      child: Opacity(
                        opacity: _isTermsAccepted ? 1.0 : 0.5,
                        child: Container(
                          height: 50,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.textPrimary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/images/google_logo.svg',
                                height: 18,
                                width: 18,
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Continue with Google',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.background,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _isTermsAccepted ? _showEmailAuthModal : null,
                      child: Opacity(
                        opacity: _isTermsAccepted ? 1.0 : 0.5,
                        child: Container(
                          height: 50,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.cardElevated,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border, width: 1),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.mail,
                                color: AppColors.primary,
                                size: 18,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Continue with Email & Password',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: _isTermsAccepted ? _signInAnonymously : null,
                      child: Opacity(
                        opacity: _isTermsAccepted ? 1.0 : 0.5,
                        child: const Center(
                          child: Text(
                            'Continue as guest (Local only)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
