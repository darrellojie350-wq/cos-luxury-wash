class ServiceItem {
  final String id, name, description, icon;
  final String category;
  final double pricePerBag;
  const ServiceItem({required this.id, required this.name, required this.description, required this.icon, required this.category, required this.pricePerBag});
  factory ServiceItem.fromJson(Map<String, dynamic> j) => ServiceItem(
    id: j['id'], name: j['name'] ?? '', description: j['description'] ?? '',
    icon: j['icon'] ?? 'laundry', category: j['category'] ?? 'wash',
    pricePerBag: (j['price_per_bag'] ?? 0).toDouble(),
  );
}

class AppAddress {
  final String? id;
  final String label, fullAddress;
  final bool isDefault;
  AppAddress({this.id, required this.label, required this.fullAddress, this.isDefault = false});
  Map<String, dynamic> toJson() => {'label': label, 'full_address': fullAddress, 'is_default': isDefault};
  factory AppAddress.fromJson(Map<String, dynamic> j) => AppAddress(id: j['id'], label: j['label'] ?? '', fullAddress: j['full_address'] ?? '', isDefault: j['is_default'] ?? false);
}

class WashOrder {
  final String? id, serviceId, serviceName, status;
  final int bags;
  final String pickupAddress, pickupDate, pickupTime;
  final String deliveryAddress, deliveryDate, deliveryTime;
  final double rideFee, laundryTotal;
  final String paymentMethod, laundryPaymentStatus;
  final DateTime createdAt;
  WashOrder({this.id, this.serviceId, this.serviceName, this.status, this.bags = 1, this.pickupAddress = '', this.pickupDate = '', this.pickupTime = '', this.deliveryAddress = '', this.deliveryDate = '', this.deliveryTime = '', this.rideFee = 0, this.laundryTotal = 0, this.paymentMethod = '', this.laundryPaymentStatus = 'unpaid', DateTime? createdAt}) : createdAt = createdAt ?? DateTime.now();
  factory WashOrder.fromJson(Map<String, dynamic> j) => WashOrder(
    id: j['id'], serviceId: j['service_id'], serviceName: j['service']?['name'], status: j['status'],
    bags: j['bags'] ?? 1, pickupAddress: j['pickup_address'] ?? '', pickupDate: j['pickup_date'] ?? '',
    pickupTime: j['pickup_time'] ?? '', deliveryAddress: j['delivery_address'] ?? '',
    deliveryDate: j['delivery_date'] ?? '', deliveryTime: j['delivery_time'] ?? '',
    rideFee: (j['ride_fee'] ?? 0).toDouble(), laundryTotal: (j['laundry_total'] ?? 0).toDouble(),
    paymentMethod: j['payment_method'] ?? '', laundryPaymentStatus: j['laundry_payment_status'] ?? 'unpaid',
    createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
  );
  Map<String, dynamic> toJson() => {
    'service_id': serviceId, 'status': 'booked', 'bags': bags,
    'pickup_address': pickupAddress, 'pickup_date': pickupDate, 'pickup_time': pickupTime,
    'delivery_address': deliveryAddress, 'delivery_date': deliveryDate, 'delivery_time': deliveryTime,
    'ride_fee': rideFee, 'laundry_total': laundryTotal, 'payment_method': paymentMethod,
    'laundry_payment_status': laundryPaymentStatus,
  };
}

const orderStatuses = ['booked','picked_up','washing','out_for_delivery','delivered'];
const statusLabel = {'booked':'Booked','picked_up':'Picked Up','washing':'Washing','out_for_delivery':'Out for Delivery','delivered':'Delivered'};
