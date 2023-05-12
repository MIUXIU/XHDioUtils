// ignore_for_file: constant_identifier_names


import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:xh_dio_utils/base_info.dart';

import 'toast_util.dart';

class DataUtilsBasic {
  static const String SERVER_ERROR = '服务器异常';
  static const String SERVER_TIMEOUT_ERROR = '请求超时';
  static const String SEND_TIMEOUT_ERROR = '发送请求超时';
  static const String NET_ERROR = '网络错误';
  static const String REQUEST_CANCEL_ERROR = '请求取消';
  static const String badCertificate = '证书错误';
  static const String connectionError = '连接出错';
  static const String X_TOKEN = 'X-Token';

  static const int HTTP_SUCCESS_CODE = 20000;
  // static const int HTTP_NEED_LOGIN_AGAIN = 40005;
  static const int HTTP_NEED_LOGIN_AGAIN = 40004;
  static const int HTTP_NEED_RESET_PWD = 30001;


  ///token dept身份验证过期处理
  void failAction(String tag,BaseInfo baseInfo,{isShowToast = true}) {
    if (baseInfo.code == HTTP_NEED_LOGIN_AGAIN) {
      //todo Global.clearAllInfo();
    }
    
    if (isShowToast && baseInfo.msg != null) {
      ToastUtil.show(baseInfo.msg!);
    }
    debugPrint('$tag api接口请求失败 ${baseInfo.toJson()}');
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
