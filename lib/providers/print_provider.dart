class PrintJobManager {
  Map<int, int> _printCounts = {};

  int getPrintCount(int printerId) {
    return _printCounts[printerId] ?? 0;
  }

  void addPrintJob(int printerId) {
    if (_printCounts.containsKey(printerId)) {
      _printCounts[printerId] = 0;
    }
    _printCounts[printerId] = _printCounts[printerId]! + 1;
  }

  bool didPrintJobExecuted(int printerId) {
    return getPrintCount(printerId) > 0;
  }

  Map<int, int> createPrintCounts(String printJobData) {
    Map<int, int> printCounts = {};
    try {
      List<String> entries = printJobData.split('#');
      for (String entry in entries) {
        if (entry.isNotEmpty) {
          List<String> parts = entry.split(':');
          int printerId = int.parse(parts[0]);
          int count = int.parse(parts[1]);
          printCounts[printerId] = count;
        }
      }
    } catch (e) {
      print("Error parsing PrintJobData $e");
    }
    return printCounts;
  }
}
