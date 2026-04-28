import 'package:flutter/material.dart';

class AppTheme {
  static ThemeStyle get style => ThemeStyle();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: ThemeStyle.primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ThemeStyle.primaryColor,
        primary: ThemeStyle.primaryColor,
        secondary: ThemeStyle.secondaryColor,
        surface: Colors.white,
        background: ThemeStyle.backgroundColor,
      ),
      scaffoldBackgroundColor: ThemeStyle.backgroundColor,
      fontFamily: 'Inter', // Fallback to Roboto if Inter is unavailable
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: ThemeStyle.primaryColor, size: 24),
        titleTextStyle: TextStyle(
          color: ThemeStyle.primaryColor,
          fontWeight: FontWeight.w800,
          fontSize: 22,
          letterSpacing: -0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: ThemeStyle.primaryColor,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ThemeStyle.primaryColor, width: 2),
        ),
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
    );
  }
}

class ThemeStyle {
  // Brand Colors
  static const Color primaryColor = Color(0xFF002366); // Navy Blue
  static const Color secondaryColor = Color(0xFF0047AB); // Royal Blue
  static const Color accentColor = Color(0xFFF59E0B); // Amber/Gold
  static const Color backgroundColor = Color(0xFFF8FAFC); // Slate 50
  static const Color textPrimary = Color(0xFF1E293B); // Slate 800
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color cardBorder = Color(0xFFE2E8F0); // Slate 200
  static const Color iconColor = Color(0xFF1E293B);
  static const Color dividerColor = Color(0xFFE2E8F0);

  // Gradients
  LinearGradient get mainGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, Color(0xFF0047AB)], // Navy to Royal Blue
  );

  LinearGradient get backgroundGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundColor, Colors.white],
  );

  LinearGradient get accentGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryColor, Color(0xFFB71C1C)], // Crimson to Deep Red
  );

  // Modern Card Decoration
  BoxDecoration get cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: cardBorder, width: 1),
    boxShadow: [
      BoxShadow(
        color: primaryColor.withOpacity(0.05),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ],
  );

  // Glassmorphism effect
  BoxDecoration get glassDecoration => BoxDecoration(
    color: Colors.white.withOpacity(0.7),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.white.withOpacity(0.5)),
  );

  // Icon Container
  BoxDecoration iconBoxDecoration(BuildContext context) => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Theme.of(context).primaryColor.withOpacity(0.1),
        Theme.of(context).primaryColor.withOpacity(0.05),
      ],
    ),
    borderRadius: BorderRadius.circular(18),
  );

  // Text Styles
  TextStyle get titleStyle => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  TextStyle get subtitleStyle => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );

  TextStyle headingStyle(BuildContext context) => const TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -1,
  );

  TextStyle appBarTitleStyle(BuildContext context) => const TextStyle(
    color: textPrimary,
    fontWeight: FontWeight.bold,
    fontSize: 22,
    letterSpacing: -0.5,
  );

  // Legacy Text Styles (Compatibility)
  TextStyle get buttonTextStyle => const TextStyle(
    fontSize: 16,
    color: Colors.white,
    fontWeight: FontWeight.bold,
  );

  TextStyle linkStyle(BuildContext context) => const TextStyle(
    color: primaryColor,
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );

  static const Color textPrimaryColor = textPrimary;

  // Common Dimensions
  static const double cardBorderRadius = 24.0;
  static const double defaultPadding = 20.0;
  static const double iconSize = 32.0;

  // Custom UI Builders
  Widget buildPageBackground({required Widget child}) {
    return Material(
      color: backgroundColor,
      child: child,
    );
  }

  AppBar buildAppBar(BuildContext context, String title, {List<Widget>? actions}) {
    return AppBar(
      title: Text(title),
      actions: actions,
    );
  }

  Widget buildCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
    bool hasHover = true,
  }) {
    return Container(
      decoration: cardDecoration,
      padding: padding,
      child: child,
    );
  }

  Widget buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: const Text('See All'),
            ),
        ],
      ),
    );
  }

  Widget buildDivider({double verticalPadding = 16.0}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: const Divider(color: cardBorder),
    );
  }

  InputDecoration inputDecoration({
    required String labelText,
    required IconData prefixIcon,
    Widget? suffixIcon,
    BuildContext? context,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, color: primaryColor, size: 22),
      suffixIcon: suffixIcon,
    );
  }

  InputDecoration searchDropdownDecoration({
    required String labelText,
    required IconData prefixIcon,
    BuildContext? context,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, color: primaryColor, size: 22),
    );
  }

  InputDecoration dropdownDecoration({
    required String labelText,
    required IconData prefixIcon,
    BuildContext? context,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, color: primaryColor, size: 22),
    );
  }

  // Legacy Button Styles (Compatibility)
  ButtonStyle primaryButtonStyle(BuildContext context) =>
      ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      );

  ButtonStyle secondaryButtonStyle(BuildContext context) =>
      ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor),
      );

  // Loading indicator (Compatibility)
  Widget loadingIndicator({Color? color}) {
    return SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(color ?? Colors.white),
        strokeWidth: 2.0,
      ),
    );
  }

  // Common UI components with premium look
  Widget buildPrimaryButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: mainGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(text),
      ),
    );
  }
}
