import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../constants/app_colors.dart';

class NotificationService {
  static void showSuccess(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppColors.certainGreen,
      textColor: Colors.white,
      fontSize: 15.0,
    );
  }

  static void showError(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppColors.priorityP1,
      textColor: Colors.white,
      fontSize: 15.0,
    );
  }

  static void showInfo(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppColors.primary,
      textColor: Colors.white,
      fontSize: 15.0,
    );
  }

  static void showMockSMS({
    required String recipientPhone,
    required String tokenNumber,
    required String priority,
  }) {
    Fluttertoast.showToast(
      msg: '📱 [SMS Sent to $recipientPhone]: AyuDwar Token $tokenNumber ($priority). Proceed to waiting lounge.',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: const Color(0xFF1E293B),
      textColor: Colors.amberAccent,
      fontSize: 14.0,
    );
  }
}
