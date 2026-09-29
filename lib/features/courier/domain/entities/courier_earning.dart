class CourierEarning {
  final String id;
  final String? orderId;
  final double amount;
  final String currency;
  final String type;
  final String status;
  final String? description;
  final DateTime? releasedAt;
  final DateTime createdAt;
  final String? trackingNumber;

  const CourierEarning({
    required this.id,
    this.orderId,
    required this.amount,
    required this.currency,
    required this.type,
    required this.status,
    this.description,
    this.releasedAt,
    required this.createdAt,
    this.trackingNumber,
  });
}

class CourierEarningsSummary {
  final double pending;
  final double released;
  final double paid;
  final String currency;

  const CourierEarningsSummary({
    required this.pending,
    required this.released,
    required this.paid,
    required this.currency,
  });
}

class CourierJobsStats {
  final int todayAssigned;
  final int todayCompleted;
  final int todayInProgress;
  final double todayEarnings;
  final int allTotalDeliveries;
  final int allTotalFailed;
  final double allRating;

  const CourierJobsStats({
    required this.todayAssigned,
    required this.todayCompleted,
    required this.todayInProgress,
    required this.todayEarnings,
    required this.allTotalDeliveries,
    required this.allTotalFailed,
    required this.allRating,
  });
}
