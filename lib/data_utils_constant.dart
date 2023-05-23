// ignore_for_file: constant_identifier_names

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:xh_dio_utils/abstract_base_info.dart';
import 'package:toast_utils/toast_utils.dart';

abstract class BasicAction {
  void tokenExpired();
}

class DataUtilsBasic<T extends AbstractBaseInfo> extends BasicAction {
  static const String SERVER_ERROR = '服务器异常';
  static const String SERVER_TIMEOUT_ERROR = '请求超时';
  static const String SEND_TIMEOUT_ERROR = '发送请求超时';
  static const String NET_ERROR = '网络错误';
  static const String REQUEST_CANCEL_ERROR = '请求取消';
  static const String badCertificate = '证书错误';
  static const String connectionError = '连接出错';
  static const String X_TOKEN = 'X-Token';

  static int HTTP_SUCCESS_CODE = 20000;

  // static const int HTTP_NEED_LOGIN_AGAIN = 40005;
  static int HTTP_NEED_LOGIN_AGAIN = 40004;
  static int HTTP_NEED_RESET_PWD = 30001;


  @override
  void tokenExpired() {}

  ///token 身份验证过期处理
  void failAction(String tag, T abstractBaseInfo, {isShowToast = true}) {
    if (abstractBaseInfo.code == HTTP_NEED_LOGIN_AGAIN) {
      tokenExpired();
    }

    if (isShowToast && abstractBaseInfo.msg != null) {
      ToastUtil.show(abstractBaseInfo.msg!);
    }
    debugPrint('$tag api接口请求失败 ${abstractBaseInfo.toJson()}');
  }

  ///网络异常处理
  void errorAction(String tag, err, {bool isShowToast = true}) {
    if (err is DioError && isShowToast) {
      switch (err.type) {
        case DioErrorType.connectionTimeout:
          ToastUtil.show(SERVER_TIMEOUT_ERROR);
          break;
        case DioErrorType.sendTimeout:
          ToastUtil.show(SEND_TIMEOUT_ERROR);
          break;
        case DioErrorType.receiveTimeout:
          ToastUtil.show(SERVER_TIMEOUT_ERROR);
          break;
        case DioErrorType.badResponse:
          ToastUtil.show(SERVER_ERROR);
          break;
        case DioErrorType.cancel:
          ToastUtil.show(REQUEST_CANCEL_ERROR);
          break;
        case DioErrorType.unknown:
          ToastUtil.show(NET_ERROR);
          break;
        case DioErrorType.badCertificate:
          ToastUtil.show(badCertificate);
          break;
        case DioErrorType.connectionError:
          ToastUtil.show(connectionError);
          break;
      }
    }
    debugPrint('$tag api接口请求错误 $err');
  }
}
