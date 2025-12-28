import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:punit_label/navigation/routesManagement.dart';
import '../../constants/styles.dart';
import '/constants/colors.dart';
import 'logincontroller.dart';

// ---------------- View ----------------
class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset(
                "assets/images/splash-removebg-preview.png",
                width: 300,
                height: 300,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 40),

              // Email Field
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 15,
                      offset: const Offset(5, 5),
                    ),
                    const BoxShadow(
                      color: Colors.white,
                      blurRadius: 15,
                      offset: Offset(-5, -5),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (val) => controller.companyCode.value = val,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.account_circle),
                    hintText: "Enter Company Code",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(18),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Email Field
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 15,
                      offset: const Offset(5, 5),
                    ),
                    const BoxShadow(
                      color: Colors.white,
                      blurRadius: 15,
                      offset: Offset(-5, -5),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (val) => controller.email.value = val,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.email_outlined),
                    hintText: "Enter your email",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(18),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Password Field
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 15,
                      offset: const Offset(5, 5),
                    ),
                    const BoxShadow(
                      color: Colors.white,
                      blurRadius: 15,
                      offset: Offset(-5, -5),
                    ),
                  ],
                ),
                child: Obx(
                      () => TextField(
                    obscureText: controller.isPasswordHidden.value,
                    onChanged: (val) => controller.password.value = val,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline),
                      hintText: "Enter your password",
                      //hintStyle: Styles.black14,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(18),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Login Button
              Obx(() => GestureDetector(
                onTap: controller.isLoading.value
                    ? null
                    : () {
                  controller.login();
                 // RouteManagement.goToDashboardScreen();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 55,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: controller.isLoading.value
                        ? const LinearGradient(
                        colors: [Colors.grey, Colors.grey])
                        : LinearGradient(
                      colors: [ColorsValue.primaryColor, ColorsValue.primaryColor.withOpacity(0.5)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.5),
                        blurRadius: 15,
                        offset: const Offset(5, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: const Text(
                      "Login",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1),
                    ),
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
