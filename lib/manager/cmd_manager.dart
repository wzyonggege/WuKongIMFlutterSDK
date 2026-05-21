import 'dart:collection';

import 'package:wukongimfluttersdk/db/const.dart';

import '../entity/cmd.dart';

/// 命令管理器，处理和分发命令
class WKCMDManager {
  WKCMDManager._privateConstructor() {
    _cmdListeners = HashMap<String, Function(WKCMD)>();
  }
  static final WKCMDManager _instance = WKCMDManager._privateConstructor();
  static WKCMDManager get shared => _instance;

  /// 命令监听器集合
  late final HashMap<String, Function(WKCMD)> _cmdListeners;

  /// 处理从服务器接收的命令
  void handleCMD(dynamic json) {
    // 解析命令
    String cmd = WKDBConst.readString(json, 'cmd');
    dynamic param = json['param'];
    
    // 补充频道信息（如果缺失）。原版只在 param 是非 null Map 时才补 ——
    // 服务端推送的某些 CMD（包括 syncMessageReaction）param 字段为
    // null，而 channel_id / channel_type 在 json 顶层。原逻辑导致
    // 业务侧拿不到 channel 信息，无法触发 reaction/extras 同步。
    // 这里在 param == null 时也构造一个新 Map 用 json 顶层填充。
    if (param == null) {
      final ch = json['channel_id'];
      final ct = json['channel_type'];
      if (ch != null || ct != null) {
        param = <String, dynamic>{
          'channel_id': ch,
          'channel_type': ct,
        };
      }
    } else if (param is Map) {
      if (!param.containsKey('channel_id')) {
        param['channel_id'] = json['channel_id'];
        param['channel_type'] = json['channel_type'];
      }
    }
    
    // 创建命令对象并分发
    WKCMD wkcmd = WKCMD();
    wkcmd.cmd = cmd;
    wkcmd.param = param;
    _notifyListeners(wkcmd);
  }

  /// 分发命令到所有监听器
  void _notifyListeners(WKCMD wkcmd) {
    _cmdListeners.forEach((key, listener) {
      listener(wkcmd);
    });
  }

  /// 添加命令监听器
  /// [key] 监听器唯一标识
  /// [listener] 命令回调函数
  void addOnCmdListener(String key, Function(WKCMD) listener) {
    _cmdListeners[key] = listener;
  }

  /// 移除命令监听器
  /// [key] 监听器唯一标识
  void removeCmdListener(String key) {
    _cmdListeners.remove(key);
  }
}
