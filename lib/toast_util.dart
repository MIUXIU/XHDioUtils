import 'package:fluttertoast/fluttertoast.dart';

class ToastUtil {
  static void show(
    String msg, {
    Toast toastLength = Toast.LENGTH_SHORT,
    ToastGravity gravity = ToastGravity.BOTTOM,
  }) {
    Fluttertoast.cancel();
    Fluttertoast.showToast(
      msg: msg,
      toastLength: toastLength,
      gravity: gravity,
    );
  }
}
