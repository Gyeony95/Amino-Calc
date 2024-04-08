import 'dart:isolate';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:mass_finder/helper/mass_finder_helper.dart';
import 'package:mass_finder/util/alert_toast.dart';

part 'logic_app.dart';

part 'logic_web.dart';

part 'logic_repository.dart';

class LogicHelper {
  LogicHelper._();

  static final LogicHelper _lh = LogicHelper._();

  factory LogicHelper() => _lh;

  static _LogicRepository? _repository;

  _LogicRepository get repository {
    final database = _repository;
    if (database != null) return database;

    _repository = _initRepo();
    return _repository!;
  }

  _LogicRepository _initRepo() {
    if (kIsWeb) {
      return _LogicWeb();
    } else {
      return _LogicApp();
    }
  }
}
