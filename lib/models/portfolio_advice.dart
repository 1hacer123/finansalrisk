class PortfolioAdviceResponse {
  final String reasoning;
  final List<AllocationItem> allocations;

  PortfolioAdviceResponse({
    required this.reasoning,
    required this.allocations,
  });

  factory PortfolioAdviceResponse.fromJson(Map<String, dynamic> json) {
    final list = json['allocations'] as List? ?? [];
    final allocationsList = list
        .map((i) => AllocationItem.fromJson(Map<String, dynamic>.from(i)))
        .toList();
    return PortfolioAdviceResponse(
      reasoning: json['reasoning'] ?? '',
      allocations: allocationsList,
    );
  }
}

class AllocationItem {
  final String asset;
  final String name;
  final double pct;
  final String note;

  AllocationItem({
    required this.asset,
    required this.name,
    required this.pct,
    required this.note,
  });

  factory AllocationItem.fromJson(Map<String, dynamic> json) {
    return AllocationItem(
      asset: json['asset'] ?? '',
      name: json['name'] ?? '',
      pct: double.tryParse((json['pct'] ?? json['percentage'] ?? 0.0).toString()) ?? 0.0,
      note: json['note'] ?? '',
    );
  }
}
