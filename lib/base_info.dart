class BaseInfo {
  int? code;
  String? msg;

  static BaseInfo fromJson(Map<String, dynamic> json) {
    BaseInfo baseInfo = BaseInfo();
    baseInfo.code = json['code'];
    baseInfo.msg = json['msg'];
    return baseInfo;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['code'] = code;
    data['msg'] = msg;
    return data;
  }
}
