import 'package:dio/dio.dart';
import '../http_manager/http_manager.dart';
import '../wrapper_mixin/wrapper_mixin.dart';

/// 请求结果
class HttpResultContainer {
  /// 响应状态码
  final int statusCode;

  /// 错误原因
  final String err;

  /// 数据
  final dynamic data;

  /// 是否请求成功
  final bool isSuccess;

  final Headers? headers;

  HttpResultContainer(this.statusCode,
      {dynamic err, this.data, this.isSuccess = true,
        this.headers}): this.err = (err ?? "").toString();

  /// 最终解析
  T finalize<T>({required WrapperMixin wrapper, void Function(String)? failure, void Function(dynamic)? success}){
    if (this.isSuccess) {
      wrapper.fromJson(this.data);
      if (wrapper.isSuccess) {
        success?.call(wrapper.object);
      }else {
        failure?.call(wrapper.msg);
        if(wrapper.code == 401 || wrapper.code==400 ){
          HttpManager.manager.getConfig()?.errorDeal.tokenError(wrapper.msg);
        }
      }
    }else {
      failure?.call(this.err);
    }
    return wrapper as T;
  }
}