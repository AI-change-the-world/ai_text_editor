import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class ToastUtils {
  ToastUtils._();

  static void sucess(BuildContext? context,
      {required String title, String? description, VoidCallback? onTap}) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.flatColored,
      autoCloseDuration: const Duration(seconds: 2),
      title: Text(title),
      // you can also use RichText widget for title and description parameters
      description: description != null
          ? RichText(
              text: TextSpan(
                  text: description,
                  style: TextStyle(color: Colors.greenAccent.withAlpha(128))))
          : null,
      alignment: Alignment.topRight,
      direction: TextDirection.ltr,
      animationDuration: const Duration(milliseconds: 300),
      animationBuilder: (context, animation, alignment, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      icon: const Icon(
        Icons.check,
        color: Colors.green,
      ),
      primaryColor: Colors.green,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      // borderRadius: BorderRadius.circular(12),
      // boxShadow: const [
      //   BoxShadow(
      //     color: Color(0x07000000),
      //     blurRadius: 16,
      //     offset: Offset(0, 16),
      //     spreadRadius: 0,
      //   )
      // ],
      showProgressBar: true,
      closeButtonShowType: CloseButtonShowType.onHover,
      closeOnClick: false,
      pauseOnHover: true,
      dragToClose: true,
      // applyBlurEffect: true,
      callbacks: ToastificationCallbacks(
        onTap: (toastItem) => onTap,
        onCloseButtonTap: (toastItem) {
          toastification.dismiss(toastItem);
        },
      ),
    );
  }

  static void info(BuildContext? context,
      {required String title, String? descryption, VoidCallback? onTap}) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.flatColored,
      autoCloseDuration: const Duration(seconds: 2),
      title: Text(title),
      // you can also use RichText widget for title and description parameters
      description: descryption != null
          ? RichText(
              text: TextSpan(
                  text: descryption,
                  style: TextStyle(color: Colors.blueAccent.withAlpha(128))))
          : null,
      alignment: Alignment.topRight,
      direction: TextDirection.ltr,
      animationDuration: const Duration(milliseconds: 300),
      animationBuilder: (context, animation, alignment, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      icon: const Icon(
        Icons.info,
        color: Colors.blueAccent,
      ),
      primaryColor: Colors.blueAccent,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      // borderRadius: BorderRadius.circular(12),
      // boxShadow: const [
      //   BoxShadow(
      //     color: Color(0x07000000),
      //     blurRadius: 16,
      //     offset: Offset(0, 16),
      //     spreadRadius: 0,
      //   )
      // ],
      showProgressBar: true,
      closeButtonShowType: CloseButtonShowType.onHover,
      closeOnClick: false,
      pauseOnHover: true,
      dragToClose: true,
      // applyBlurEffect: true,
      callbacks: ToastificationCallbacks(
        onTap: (toastItem) => onTap,
        onCloseButtonTap: (toastItem) {
          toastification.dismiss(toastItem);
        },
      ),
    );
  }

  static void error(BuildContext? context,
      {required String title, String? descryption, VoidCallback? onTap}) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.flatColored,
      autoCloseDuration: const Duration(seconds: 5),
      title: Text(title),
      // you can also use RichText widget for title and description parameters
      description: descryption != null
          ? RichText(text: TextSpan(text: descryption))
          : null,
      alignment: Alignment.topRight,
      direction: TextDirection.ltr,
      animationDuration: const Duration(milliseconds: 300),
      animationBuilder: (context, animation, alignment, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      icon: const Icon(
        Icons.clear,
        color: Colors.red,
      ),
      primaryColor: Colors.red,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      // borderRadius: BorderRadius.circular(12),
      // boxShadow: const [
      //   BoxShadow(
      //     color: Color(0x07000000),
      //     blurRadius: 16,
      //     offset: Offset(0, 16),
      //     spreadRadius: 0,
      //   )
      // ],
      showProgressBar: true,
      closeButtonShowType: CloseButtonShowType.onHover,
      closeOnClick: false,
      pauseOnHover: true,
      dragToClose: true,
      // applyBlurEffect: true,
      callbacks: ToastificationCallbacks(
        onTap: (toastItem) => onTap,
        onCloseButtonTap: (toastItem) {
          toastification.dismiss(toastItem);
        },
      ),
    );
  }
}
