abstract interface class Clock {
  DateTime nowUtc();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}

class TestClock implements Clock {
  DateTime _current;

  TestClock([DateTime? initial])
      : _current =
            (initial ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true))
                .toUtc();

  @override
  DateTime nowUtc() => _current;

  void setTime(DateTime time) {
    _current = time.toUtc();
  }

  void advance(Duration duration) {
    _current = _current.add(duration);
  }
}
