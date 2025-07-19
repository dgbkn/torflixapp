import 'dart:convert';
import 'dart:ui'; // Required for BackdropFilter
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';
import 'package:http/http.dart';
import 'package:seedr_app/pages/SearchPage.dart';
import 'package:seedr_app/utils.dart';
// import 'package:lottie/lottie.dart'; // Lottie is no longer needed
import 'package:seedr_app/pages/SearchPage.dart';
import 'package:seedr_app/utils.dart';
import '../constants.dart';
import '../controller/simple_ui_controller.dart';

class LoginScreen extends StatefulWidget {
  final dynamic switchTheme; // Kept as 'dynamic' to match original param

  const LoginScreen({Key? key, required this.switchTheme}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController nameController = TextEditingController();
  // Email controller was unused in the logic, so it is commented out but kept for reference
  // TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    nameController.dispose();
    // emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool showProg = false;

  // --- NO CHANGES TO THE LOGIC BELOW ---
  Future loginToSeedr(user, pass) async {
    var connected = await checkUserConnection();

    if (connected) {
      var details = {
        "grant_type": "password",
        "client_id": "seedr_chrome",
        "type": "login",
        "username": user,
        "password": pass
      };

      final response = await post(
        Uri.parse('https://www.seedr.cc/oauth_test/token.php'),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        encoding: Encoding.getByName('utf-8'),
        body: details,
      );

      if (response.statusCode == 200) {
        var d = jsonDecode(response.body);
        Get.snackbar("Login Success", "",
            backgroundColor: Colors.greenAccent, colorText: Colors.white);
        var token = d["access_token"];
        print(response.body);
        var boxLogin = Hive.box("login_info");

        boxLogin.put("user", user);
        boxLogin.put("pass", pass);
        boxLogin.put("token", token);
        changePageTo(
            context,
            SearchPage(
              switchTheme: widget.switchTheme,
            ),
            true);
      } else {
        var d = jsonDecode(response.body);
        Get.snackbar(d["error_description"], "Please Check The Form",
            backgroundColor: Colors.redAccent, colorText: Colors.white);
        print(response.body + user + pass);
      }

      setState(() {
        showProg = false;
      });
    }
  }
  // --- NO CHANGES TO THE LOGIC ABOVE ---

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    Get.put(SimpleUIController());
    SimpleUIController simpleUIController = Get.find<SimpleUIController>();
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F2F5), // Softer background color
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // Decorative Blobs
            Positioned(
              top: size.height * -0.1,
              left: size.width * -0.2,
              child: _buildBlob(Colors.purple.shade200, 300),
            ),
            Positioned(
              bottom: size.height * -0.15,
              right: size.width * -0.25,
              child: _buildBlob(Colors.teal.shade200, 400),
            ),
            // Blur Effect
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80.0, sigmaY: 80.0),
              child: Container(color: Colors.transparent),
            ),
            // Content
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return _buildLargeScreen(size, simpleUIController);
                } else {
                  return _buildSmallScreen(size, simpleUIController);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlob(Color color, double size) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.4),
        shape: BoxShape.circle,
      ),
    );
  }

  /// For large screens
  Widget _buildLargeScreen(Size size, SimpleUIController simpleUIController) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Image.asset(
              'assets/img/logo/splash_logo_new.png', // <-- Replaced Lottie with Image
              height: size.height * 0.5,
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: _buildMainBody(size, simpleUIController),
        ),
      ],
    );
  }

  /// For Small screens
  Widget _buildSmallScreen(Size size, SimpleUIController simpleUIController) {
    return _buildMainBody(size, simpleUIController);
  }

  /// Main Body
  Widget _buildMainBody(Size size, SimpleUIController simpleUIController) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: size.width > 600 ? 60 : 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (size.width <= 600)
              Center(
                child: Image.asset(
                  'assets/img/logo/splash_logo_new.png', // <-- Replaced Lottie with Image
                  height: size.height * 0.25,
                ),
              ),
            const SizedBox(height: 20),
            Text('Login To Torflix.', style: kLoginTitleStyle(size)),
            const SizedBox(height: 10),
            Text('Welcome Back Cachy', style: kLoginSubtitleStyle(size)),
            SizedBox(height: size.height * 0.04),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  /// Username or Gmail
                  _buildTextFormField(
                    controller: nameController,
                    hintText: 'Username or Gmail',
                    prefixIcon: Icons.person_outline_rounded,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter username';
                      } else if (value.length < 4) {
                        return 'at least enter 4 characters';
                      } else if (value.length > 26) {
                        return 'maximum character is 26';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: size.height * 0.02),

                  /// Password
                  Obx(
                    () => _buildTextFormField(
                      controller: passwordController,
                      hintText: 'Password',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: simpleUIController.isObscure.value,
                      suffixIcon: IconButton(
                        icon: Icon(
                          simpleUIController.isObscure.value
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey.shade600,
                        ),
                        onPressed: () => simpleUIController.isObscureActive(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter some text';
                        } else if (value.length < 7) {
                          return 'at least enter 6 characters';
                        } else if (value.length > 30) {
                          return 'maximum character is 30';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: size.height * 0.04),

                  /// Login Button
                  _loginButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade500),
        prefixIcon: Icon(prefixIcon, color: Colors.grey.shade600),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.deepPurple.shade300, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
        ),
      ),
    );
  }

  // Login Button
  Widget _loginButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          colors: [Colors.deepPurple, Colors.teal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: ElevatedButton(
        onPressed: showProg
            ? null // Disable button when loading
            : () {
                if (_formKey.currentState!.validate()) {
                  setState(() {
                    showProg = true;
                  });
                  loginToSeedr(
                      nameController.value.text, passwordController.value.text);
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: showProg
              ? const CircularProgressIndicator(
                  key: ValueKey('progress'),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
              : const Text(
                  'Login',
                  key: ValueKey('text'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
