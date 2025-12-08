import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'contract_linking.dart';
import 'helloUI.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ContractLinking(),
      child: MaterialApp(
        title: 'Hello World DApp',
        theme: ThemeData(
          brightness: Brightness.light,
          primaryColor: Colors.blue,
          colorScheme: ColorScheme.light(
            primary: Colors.blue,
            secondary: Colors.blueAccent,
            background: Colors.grey[50]!,
          ),
          scaffoldBackgroundColor: Colors.grey[50],
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              minimumSize: Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: Colors.blue, width: 1.5),
            ),
          ),
          fontFamily: 'Inter',
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: Colors.blue[300],
          colorScheme: ColorScheme.dark(
            primary: Colors.blue[300]!,
            secondary: Colors.blueAccent[200]!,
            background: Colors.grey[900]!,
          ),
        ),
        home: HelloUI(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}