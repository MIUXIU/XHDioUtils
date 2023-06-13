library xh_dio_utils;
import 'package:dio/dio.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:xh_dio_utils/data_utils_constant.dart';


/// 请求方法
enum DioMethod {
  get,
  post,
  put,
  delete,
  patch,
  head,
}

const _methodValues = {
  DioMethod.get: 'get',
  DioMethod.post: 'post',
  DioMethod.put: 'put',
  DioMethod.delete: 'delete',
  DioMethod.patch: 'patch',
  DioMethod.head: 'head'
};

///解密方法函数
typedef DecryptFunction =String Function({required String data,required String key});
///加密方法函数
typedef EncryptFunction =Object Function({required Object data,required String key});

///生成Key的方法
typedef GenerateKeyFunction = Map<String, String> Function();

class XHDioUtil {
  static const String _tag = 'DioUtil';
  ///Key:aesKey  ，baseKey: X_Signature
  static const String key = "key1", baseKey = "key2";
  static final LogInterceptor logInterceptor =  LogInterceptor(responseHeader: true, responseBody: true,requestBody: true);

  static final Map _dioMap = <String, XHDioUtil>{};

  /// 连接超时时间
  static Duration _connectTimeout = const Duration(seconds: 8);

  /// 响应超时时间
  static Duration _receiveTimeout = const Duration(seconds: 30);

  final Map<String, Object> _commonHeaders = {};

  DecryptFunction? decryptFunction;
  EncryptFunction? encryptFunction;
  GenerateKeyFunction? generateKeyFunction;

  var isOpenLog = false;

  /// Dio实例
  Dio? _dio;
  late BaseOptions baseoptions;
  static String? _baseUrl;

  dynamic _expiredHandle;
  int? _expiredCode;

  void _printLog(String log) {
    if (isOpenLog) {
      debugPrint('$_tag $log');
    }
  }

  Map<String, dynamic> get commonHeaders{
    return _dio?.options.headers??{};
  }

  void setExpiredWork(int expiredCode, dynamic expiredWork) {
    _expiredHandle = expiredWork;
    _expiredCode = expiredCode;
  }

  static XHDioUtil getDioUtil(String key) {
    return _dioMap[key];
  }

  //设置连接超时时间 @duration
  void setConnectMaxTime(Duration duration) {
    _connectTimeout = duration;
  }

  //设置接受数据超时时间
  void setReceiveMaxTime(Duration duration) {
    _receiveTimeout = duration;
  }

  //设置公共头
  void setCommonHeaders(Map<String, Object> headers) {
    _commonHeaders.clear();
    _commonHeaders.addAll(headers);
  }

  //设置BaseUrl
  void setBaseUrl(String baseUrl) {
    if (baseUrl.isEmpty || Uri.parse(baseUrl).host.isEmpty) {
      _printLog('setBaseUrl Error : url is not a host');
      return;
    }

    _baseUrl = baseUrl;
    if (_dio != null) {
      _dio?.options.baseUrl = baseUrl;
    }
  }

  /// 开启日志打印
  void setLog(bool isOpen) {
    isOpenLog = isOpen;
    if(isOpenLog) {
      _dio?.interceptors.add(logInterceptor);
    }else{
      _dio?.interceptors.remove(logInterceptor);
    }
  }

  /// 初始化
  XHDioUtil build({String? key}) {
    _initDio();
    if(isOpenLog) {
      _dio?.interceptors.add(logInterceptor);
    }
    _dio?.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          // 如果你想完成请求并返回一些自定义数据，你可以使用 `handler.resolve(response)`。
          // 如果你想终止请求并触发一个错误,你可以使用 `handler.reject(error)`。

          _printLog('onRequest');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // 如果你想终止请求并触发一个错误,你可以使用 `handler.reject(error)`。

          if (_expiredHandle != null && response.statusCode == _expiredCode) {
            //请求过期，调用应用层给出的过期处理方法
            _expiredHandle();
            handler.reject(DioError(requestOptions: response.requestOptions, message: 'Expired'));
            return;
          }
          _printLog('onResponse');
          return handler.next(response);
        },
      ),
    );

    if (key != null) {
      _dioMap[key] = this;
    }

    return this;
  }

  // 初始化dio
  void _initDio() {
    try {
      baseoptions = BaseOptions(
          baseUrl: _baseUrl ?? '',
          headers: _commonHeaders,
          responseType: ResponseType.plain,
          connectTimeout: _connectTimeout,
          receiveTimeout: _receiveTimeout);

      _dio = Dio(baseoptions);
    } catch (e) {
      _printLog('initDio Error :$e');
      _dio = Dio(BaseOptions(
          responseType: ResponseType.plain, connectTimeout: _connectTimeout, receiveTimeout: _receiveTimeout));
    }
  }

  /// 请求类
  Future request<T>(String path,
      {DioMethod method = DioMethod.get,
        Map<String, dynamic>? params,
        data,
        CancelToken? cancelToken,
        Options? options,
        bool useDecrypt = false,
        bool useEncrypt = false,
        bool useSignature = false,
        bool useRaw = false,
        ProgressCallback? onSendProgress,
        ProgressCallback? onReceiveProgress,
        Function? beanFromJson}) async {
    if (_dio == null) {
      _printLog('DioUtil must build first');
    }
    options ??= Options();
    options.headers ??= <String, dynamic>{};

    String? key;
    String? baseKey;
    if(useSignature) {
      Map<String, String> mapKey = generateKeyFunction?.call()??{};
      key = mapKey[XHDioUtil.key];
      baseKey = mapKey[XHDioUtil.baseKey];
      options.headers?[DataUtilsBasic.X_SIGNATURE] = baseKey;

      ///需要加密
      if(useEncrypt && key != null){
        if(data != null) {
          try {
            data = encryptFunction?.call(data:data,key:key);
          } catch (e) {
            _printLog('encryptFunction data Error: $e');
          }
        }

        if(params != null){
          try {
            params = encryptFunction?.call(data:params,key:key) as Map<String, dynamic>?;
          } catch (e) {
            _printLog('encryptFunction params Error: $e');
          }
        }
      }
    }

    options.method = _methodValues[method];
    try {
      Response response;
      response = await _dio!.request(path,
          data: data,
          queryParameters: params,
          cancelToken: cancelToken,
          options: options,
          onSendProgress: onSendProgress,
          onReceiveProgress: onReceiveProgress);

      if(useRaw){
        return response;
      }

      String responseData = response.data.toString();
      DecryptFunction? decrypt = decryptFunction;
      if(useDecrypt && decrypt != null && key != null){
        responseData = decrypt(data:responseData,key: key);
      }
      if (beanFromJson != null) {
        Map dataMap = json.decode(responseData);
        dynamic resultBean = beanFromJson(dataMap);
        return resultBean;
      }

      return response.data;
    } on DioError catch (e) {
      _printLog('DioError: $e');
      rethrow;
    } catch (e) {
      _printLog('catch: $e');
      rethrow;
    }
  }
}