# Saga Monitor for Redux Saga Middleware Dart and Flutter

Saga Monitor monitors running sagas and effects to track middleware for [redux_saga](https://github.com/reduxsaga/redux_saga)

Package and installation details can be found at [pub.dev](https://pub.dev/packages/saga_monitor).

### Usage Example

Modify [vanilla_counter](https://github.com/reduxsaga/vanilla_counter) according to below to test monitor.

Output can be printed to console.

index.dart
```dart
  ...
  var monitor = SimpleSagaMonitor(
      onLog: consoleMonitorLogger);

  var sagaMiddleware = createSagaMiddleware(Options(sagaMonitor: monitor));
  ...
```

Sample output:

```dart
.✓Root, duration:11ms, result:(Task{Running:true, Cancelled:false, Aborted:false, Result:null, Error:null})
.   └─ ✓Fork, duration:4ms, result:(Task{Running:true, Cancelled:false, Aborted:false, Result:null, Error:null})
.       ├─ ✓Take, duration:7553ms, result:(Instance of 'IncrementAsyncAction')
.       ├─ ✓Fork, duration:5ms, result:(Task{Running:true, Cancelled:false, Aborted:false, Result:null, Error:null})
.       │   ├─ ✓Delay, duration:1004ms, result:(true)
.       │   └─ ✓Put, duration:2ms, result:(Instance of 'IncrementAction')
.       └─ ⌛Take
```

Check [vanilla_counter](https://github.com/reduxsaga/vanilla_counter) example `monitor-console` branch for completed code.

To handle where to log implement [onLog] event.
Following example demonstrates how to get lines and
output them to a div element on an html page.

index.dart
```dart
  ...
  var monitor = SimpleSagaMonitor(
      onLog: (SimpleSagaMonitor monitor) {
        var lines = monitor.getLines();
        String s = '';
        lines.forEach((element) {
          s += element + '</br>';
        });
        querySelector('#monitor').innerHtml = s;
      });

  var sagaMiddleware = createSagaMiddleware(Options(sagaMonitor: monitor));
  ...
```


index.html
```html
...
<p>
    Clicked: <span id="value">0</span> times
    <button id="increment">+</button>
    <button id="decrement">-</button>
    <button id="incrementIfOdd">Increment if odd</button>
    <button id="incrementAsync">Increment async</button>
    </br>
    </br>
    Saga Monitor: <div id="monitor"></div>
</p>
...
```

Check [vanilla_counter](https://github.com/reduxsaga/vanilla_counter) example `monitor-browser` branch for completed code.

### License
Copyright (c) 2020 Bilal Uslu.

Licensed under The MIT License (MIT).

