import 'package:flutter/material.dart';

const kPrimary = Color(0xFF00BFA5);
const kPrimaryLight = Color(0xFFE0F5F2);
const kBg = Color(0xFFF8F8F8);
const kTextDark = Color(0xFF1A1A1A);
const kTextGray = Color(0xFF9E9E9E);
const kTextOrange = Color(0xFFFF9800);
const kTextRed = Color(0xFFE53935);

final appTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: kPrimary),
  scaffoldBackgroundColor: Colors.white,
  fontFamily: 'Paperlogy',
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: kTextDark,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      fontFamily: 'Paperlogy',
      color: kTextDark,
      fontSize: 20,
      fontWeight: FontWeight.w700,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPrimary,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(
        fontFamily: 'Paperlogy',
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF2F2F2),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kPrimary, width: 1.8),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kTextRed, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kTextRed, width: 1.5),
    ),
  ),
);
