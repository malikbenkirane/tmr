enum RoutineBin { backlog(), archives(), today() }

extension RoutineBinStringer on RoutineBin {
  String toStringValue() {
    switch (this) {
      case RoutineBin.backlog:
        return 'backlog';
      case RoutineBin.archives:
        return 'archives';
      case RoutineBin.today:
        return 'today';
    }
  }
}
