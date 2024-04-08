import 'dart:isolate';

import 'package:flutter/foundation.dart';

part 'logic_app.dart';
part 'logic_web.dart';
part 'logic_repository.dart';

class LogicHelper {
  LogicHelper._();
  static final LogicHelper _lh = LogicHelper._();
  factory LogicHelper() => _lh;

  static _LogicRepository? _repository;

  Future<_LogicRepository> get __repository async {
    final database = _repository;
    if (database != null) return database;

    _repository = await _initRepo();
    return _repository!;
  }

  Future<_LogicRepository> _initRepo() async {
    if(kIsWeb){
      return _LogicWeb();
    } else{
      return _LogicApp();
    }
  }
}
