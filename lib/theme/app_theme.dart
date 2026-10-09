import 'package:flutter/material.dart';

class Pal {
  static const bg = Color(0xFF0B1026);
  static const card = Color(0xFF161B33);
  static const card2 = Color(0xFF1E2542);
  static const border = Color(0xFF2B3358);
  static const nav = Color(0xFF080C1F);
  static const magenta = Color(0xFFD946EF);
  static const violet = Color(0xFF8B5CF6);
  static const cyan = Color(0xFF22D3EE);
  static const blue = Color(0xFF3B82F6);
  static const green = Color(0xFF22C55E);
  static const amber = Color(0xFFF59E0B);
  static const red = Color(0xFFEF4444);
  static const textDim = Color(0xFF94A3B8);

  static const gradPrimary = LinearGradient(
    colors: [magenta, violet],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const gradCool = LinearGradient(
    colors: [cyan, blue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Pal.violet,
    brightness: Brightness.dark,
  ).copyWith(
    primary: Pal.magenta,
    onPrimary: Colors.white,
    secondary: Pal.cyan,
    onSecondary: Colors.black,
    tertiary: Pal.blue,
    surface: Pal.bg,
    onSurface: Colors.white,
    outline: Pal.textDim,
    outlineVariant: Pal.border,
    surfaceContainerLowest: Pal.bg,
    surfaceContainerLow: Pal.card,
    surfaceContainer: Pal.nav,
    surfaceContainerHigh: Pal.card2,
    surfaceContainerHighest: Pal.card2,
    secondaryContainer: Pal.card2,
    onSecondaryContainer: Colors.white,
    tertiaryContainer: Pal.card2,
    onTertiaryContainer: Colors.white,
    errorContainer: const Color(0xFF4A1D2B),
    onErrorContainer: const Color(0xFFFFB4C0),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Pal.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Pal.nav,
      indicatorColor: Pal.magenta.withValues(alpha: 0.22),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
          color: s.contains(WidgetState.selected) ? Pal.magenta : Pal.textDim)),
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color:
              s.contains(WidgetState.selected) ? Colors.white : Pal.textDim)),
    ),
    chipTheme: const ChipThemeData(
      backgroundColor: Pal.card2,
      selectedColor: Pal.blue,
      side: BorderSide(color: Pal.border),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12))),
      labelStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      showCheckmark: false,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? Pal.blue : Pal.card2),
        foregroundColor: WidgetStateProperty.all(Colors.white),
        side: WidgetStateProperty.all(const BorderSide(color: Pal.border)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Pal.violet,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Pal.border),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Pal.card2,
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.gradient = Pal.gradPrimary,
    this.height = 54,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Gradient gradient;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                  color: Pal.magenta.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: onPressed,
            child: SizedBox(
              height: height,
              child: Center(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          fontSize: 15)),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GradientFab extends StatelessWidget {
  const GradientFab(
      {super.key,
      required this.label,
      required this.icon,
      required this.onPressed});
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: Pal.gradPrimary,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
                color: Pal.magenta.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800)),
            ]),
          ),
        ),
      ),
    );
  }
}

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.size = 44,
    this.color = Colors.white,
  });
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final w = Material(
      color: Pal.card2,
      shape: const CircleBorder(side: BorderSide(color: Pal.border)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: size * 0.5, color: color)),
      ),
    );
    return tooltip == null ? w : Tooltip(message: tooltip!, child: w);
  }
}

class AppHeader extends StatelessWidget {
  const AppHeader(
      {super.key,
      required this.eyebrow,
      required this.title,
      this.actions = const []});
  final String eyebrow;
  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
              shape: BoxShape.circle, gradient: Pal.gradPrimary),
          child: const Icon(Icons.kitchen, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(eyebrow,
                style: const TextStyle(color: Pal.textDim, fontSize: 12)),
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ]),
        ),
        for (final a in actions) a,
      ]),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Text(text,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
      );
}

class StatBox extends StatelessWidget {
  const StatBox(
      {super.key,
      required this.label,
      required this.value,
      required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Pal.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Pal.border),
      ),
      child: Column(children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label.toUpperCase(),
              style: const TextStyle(
                  color: Pal.textDim, fontSize: 10, letterSpacing: 0.8)),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value,
              style: TextStyle(
                  color: color, fontSize: 24, fontWeight: FontWeight.w800)),
        ),
      ]),
    );
  }
}

class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
  });
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Pal.magenta, Pal.violet],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 16),
              Material(
                color: Colors.white,
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: onPressed,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                    child: Text(buttonLabel,
                        style: const TextStyle(
                            color: Pal.magenta,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 0.5)),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
