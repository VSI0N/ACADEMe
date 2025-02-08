import 'package:flutter/material.dart';
import 'package:ACADEMe/utils/theme/customm_themes/text_theme.dart'; // Import FontTheme
import 'package:ACADEMe/utils/theme/customm_themes/appbar_theme.dart';
import 'package:ACADEMe/utils/theme/customm_themes/bottom_sheet_theme.dart';
import 'package:ACADEMe/utils/theme/customm_themes/checkbox_theme.dart';
import 'package:ACADEMe/utils/theme/customm_themes/chip_theme.dart';
import 'package:ACADEMe/utils/theme/customm_themes/elevated_button_theme.dart';
import 'package:ACADEMe/utils/theme/customm_themes/outlined_button_theme.dart';
import 'package:ACADEMe/utils/theme/customm_themes/text_field_theme.dart';

class AppTheme {
  AppTheme._();

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'poppins',
    brightness: Brightness.light,
    primaryColor: Colors.blue,
    textTheme: FontTheme.lightTextTheme, // FontTheme is now correctly imported
    chipTheme: AChipTheme.lightChipTheme,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppbarTheme.lightAppBarTheme,
    checkboxTheme: CheckBoxTheme.lightCheckboxTheme,
    bottomSheetTheme: BottomSheetTheme.lightBottomSheetTheme,
    elevatedButtonTheme: AElevatedButtonTheme.lightElevatedButtonTheme,
    outlinedButtonTheme: AOutlinedButtonTheme.lightOutlineButtonTheme,
    inputDecorationTheme: TextFieldTheme.lightInputDecorationTheme,
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'poppins',
    brightness: Brightness.dark,
    primaryColor: Colors.blue,
    textTheme: FontTheme.darkTextTheme, // FontTheme is now correctly imported
    chipTheme: AChipTheme.darkChipTheme,
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: AppbarTheme.darkAppBarTheme,
    checkboxTheme: CheckBoxTheme.darkCheckboxTheme,
    bottomSheetTheme: BottomSheetTheme.darkBottomSheetTheme,
    elevatedButtonTheme: AElevatedButtonTheme.darkElevatedButtonTheme,
    outlinedButtonTheme: AOutlinedButtonTheme.darkOutlineButtonTheme,
    inputDecorationTheme: TextFieldTheme.darkInputDecorationTheme,
  );
}
