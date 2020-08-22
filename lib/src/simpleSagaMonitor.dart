import 'package:redux_saga/redux_saga.dart';

/// Handler for monitor logging. Current [monitor] is passed as argument.
typedef MonitorLogHandler = void Function(SimpleSagaMonitor monitor);

enum _EffectStatus { Pending, Resolved, Rejected, Cancelled }

class _EffectDescription {
  int effectId;
  int parentEffectId;
  String description;
  dynamic result;
  dynamic error;
  _EffectStatus status = _EffectStatus.Pending;
  dynamic effect;
  DateTime start = DateTime.now();
  DateTime end;

  _EffectDescription(
      this.effectId, this.parentEffectId, this.description, this.effect);
}

/// Implemented monitor logger to log console output.
MonitorLogHandler consoleMonitorLogger = (SimpleSagaMonitor monitor) {
  monitor.printToConsole();
};

/// Monitors running sagas and effects to track middleware
/// Output can be printed to console.
///
///```
///  ...
///  var monitor = SimpleSagaMonitor(
///      onLog: consoleMonitorLogger);
///
///  var sagaMiddleware = createSagaMiddleware(Options(sagaMonitor: monitor));
///  ...
///```
/// To handle where to log implement [onLog] event.
/// Following example demonstrates how to get lines and
/// output them to a div element on an html page.
///
///```
///  ...
///  var monitor = SimpleSagaMonitor(
///      onLog: (SimpleSagaMonitor monitor) {
///        var lines = monitor.getLines();
///        String s = '';
///        lines.forEach((element) {
///          s += element + '</br>';
///        });
///        querySelector('#monitor').innerHtml = s;
///      });
///
///  var sagaMiddleware = createSagaMiddleware(Options(sagaMonitor: monitor));
///  ...
///```
///
class SimpleSagaMonitor implements SagaMonitor {
  final _effectsById = <int, _EffectDescription>{};
  final _childByParent = <int, List<int>>{};

  /// If true monitor gives more details
  bool verbose;

  /// If true shows tree lines
  bool treeLines;

  /// Invoked on every new log entry
  MonitorLogHandler onLog;

  /// Creates an instance of a SimpleSagaMonitor
  SimpleSagaMonitor({
    this.verbose = false,
    this.treeLines = true,
    this.onLog,
  });

  @override
  void actionDispatched(dynamic action) {}

  @override
  void effectCancelled(int effectId) {
    var ed = _effectsById[effectId];
    ed.status = _EffectStatus.Cancelled;

    _log();
  }

  @override
  void effectRejected(int effectId, dynamic error) {
    var ed = _effectsById[effectId];
    ed.error = error;
    ed.status = _EffectStatus.Rejected;

    _log();
  }

  @override
  void effectResolved(int effectId, dynamic result) {
    var ed = _effectsById[effectId];
    ed.end = DateTime.now();
    var duration = ed.end.difference(ed.start);
    ed.result = result;
    ed.status = _EffectStatus.Resolved;
    ed.description += ', duration:${duration.inMilliseconds}ms';
    if (ed.effect is EffectWithResult || (!(ed.effect is Effect))) {
      ed.description += ', result:($result)';
    }

    _log();
  }

  @override
  void effectTriggered(
      int effectId, int parentEffectId, dynamic label, dynamic effect) {
    var ed = _EffectDescription(
        effectId, parentEffectId, '${effect.runtimeType}', effect);

    _effectsById[effectId] = ed;
    _addChild(parentEffectId, effectId);

    _log();
  }

  void _addChild(int parentEffectId, int effectId) {
    var list = _childByParent[parentEffectId];
    if (list == null) {
      list = <int>[];
      _childByParent[parentEffectId] = list;
    }
    list.add(effectId);
  }

  @override
  void rootSagaStarted(int effectId, Function saga, List args,
      Map<Symbol, dynamic> namedArgs, String name) {
    var ed = _EffectDescription(
        effectId, 0, 'Root${name == null ? '[$name]' : ''}', null);

    _effectsById[effectId] = ed;
    _addChild(0, effectId);

    _log();
  }

  void _log() {
    if (onLog != null) {
      onLog(this);
    }
  }

  /// Prints everything to the console
  void printToConsole() {
    getLines().forEach(print);
  }

  /// Returns log lines as a string array
  List<String> getLines() {
    var lines = <String>[];
    lines.add('.');
    _logChildren(lines, 0, 0, '');
    return lines;
  }

  final _defaultSpace = '   ';

  void _logChildren(
      List<String> lines, int parentId, int level, String prefix) {
    var list = _childByParent[parentId];
    if (list != null && list.isNotEmpty) {
      for (var i = 0; i < list.length; i++) {
        var treeStart = '';
        var treeSubStart = '';

        if (level == 0 && list.length == 1) {
          //dont start tree. there is only one root item
        } else {
          if (treeLines) {
            if (i == list.length - 1) {
              treeStart = '└─ ';
              treeSubStart = ' ';
            } else {
              treeStart = '├─ ';
              treeSubStart = '│';
            }
          }
        }

        var id = list[i];
        var ed = _effectsById[id];
        if (ed != null) {
          _logEffect(lines, ed, '$prefix$treeStart');
          _logChildren(
              lines, id, level + 1, '$prefix$treeSubStart$_defaultSpace');
        }
      }
    }
  }

  void _logEffect(List<String> lines, _EffectDescription ed, String prefix) {
    lines.add('.$prefix'
        '${_getStatusSymbol(ed.status)}${ed.description} '
        '${verbose ? ed.effect : ''}');
  }

  String _getStatusSymbol(_EffectStatus status) {
    switch (status) {
      case _EffectStatus.Resolved:
        return '✓';
      case _EffectStatus.Pending:
        return '⌛';
      case _EffectStatus.Rejected:
        return '⛔';
      case _EffectStatus.Cancelled:
        return '✘';
    }
    return null;
  }
}
