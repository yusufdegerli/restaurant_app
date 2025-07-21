class PrintJobManager {
  final Map<int, int> _printCounts = {};

  int getPrintCount(int printerId) => _printCounts[printerId] ?? 0;

  void addPrintJob(int printerId) {
    _printCounts[printerId] = getPrintCount(printerId) + 1;
  }

  bool didPrintJobExecuted(int printerId) => getPrintCount(printerId) > 0;

  Map<int, int> createPrintCounts(String printJobData) {
    final printCounts = <int, int>{};
    try {
      for (final entry in printJobData.split('#')) {
        if (entry.isNotEmpty) {
          final parts = entry.split(':');
          final printerId = int.parse(parts[0]);
          final count = int.parse(parts[1]);
          printCounts[printerId] = count;
        }
      }
    } catch (e) {
      print('Error parsing PrintJobData $e');
    }
    return printCounts;
  }
}
