class Salon {
  final String id;
  final String name;
  final String city;
  final double rating;
  final bool isApproved;
  final int reviewsCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> images;
  final Map<String, dynamic>? extra;
  bool isFavorite;

  final String? ownerId;
  final String? categoryId;
  final String? phone;
  final double? lat;
  final double? lng;

  Salon({
    required this.id,
    required this.name,
    required this.city,
    required this.rating,
    required this.isApproved,
    required this.reviewsCount,
    this.createdAt,
    this.updatedAt,
    required this.images,
    this.extra,
    this.isFavorite = false,
    this.ownerId,
    this.categoryId,
    this.phone,
    this.lat,
    this.lng,
  });

  Salon copyWith({
    String? id,
    String? name,
    String? city,
    double? rating,
    bool? isApproved,
    int? reviewsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? images,
    Map<String, dynamic>? extra,
    bool? isFavorite,
    String? ownerId,
    String? categoryId,
    String? phone,
    double? lat,
    double? lng,
  }) {
    return Salon(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      rating: rating ?? this.rating,
      isApproved: isApproved ?? this.isApproved,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      images: images ?? this.images,
      extra: extra ?? this.extra,
      isFavorite: isFavorite ?? this.isFavorite,
      ownerId: ownerId ?? this.ownerId,
      categoryId: categoryId ?? this.categoryId,
      phone: phone ?? this.phone,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }

  factory Salon.fromMap(
    String id,
    Map<String, dynamic> map, {
    bool isFavorite = false,
  }) {
    final location = map['location'];

    return Salon(
      id: id,
      name: map['name']?.toString() ?? '',
      city: map['address']?.toString() ?? '',
      rating: map['rating'] != null
          ? double.tryParse(map['rating'].toString()) ?? 0.0
          : 0.0,
      isApproved: map['isApproved'] == true,
      reviewsCount: map['reviews_count'] != null
          ? int.tryParse(map['reviews_count'].toString()) ?? 0
          : 0,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString())
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString())
          : null,
      images: map['images'] != null ? List<String>.from(map['images']) : [],
      extra: Map<String, dynamic>.from(map),
      isFavorite: isFavorite,
      ownerId: map['ownerId']?.toString(),
      categoryId: map['categoryId']?.toString(),
      phone: map['phone']?.toString(),
      lat: location != null
          ? (location['lat'] is num
                ? (location['lat'] as num).toDouble()
                : double.tryParse(location['lat'].toString()))
          : null,
      lng: location != null
          ? (location['lng'] is num
                ? (location['lng'] as num).toDouble()
                : double.tryParse(location['lng'].toString()))
          : null,
    );
  }
}

class Service {
  final String id;
  final String name;
  final double price;
  final Map<String, dynamic>? extra;

  Service({
    required this.id,
    required this.name,
    required this.price,
    this.extra,
  });

  factory Service.fromMap(String id, Map<String, dynamic> map) {
    final rawName = map['name'] ?? map['title'] ?? '';

    return Service(
      id: id,
      name: rawName.toString(),
      price: map['price'] != null
          ? double.tryParse(map['price'].toString()) ?? 0.0
          : 0.0,
      extra: Map<String, dynamic>.from(map),
    );
  }
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? fcmToken;
  final DateTime? joinedAt;
  final Map<String, bool>? favorites;
  final String? image;
  final String? address;
  final Map<String, dynamic>? extra;

  final Map<String, bool>? managedSalons;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.fcmToken,
    this.joinedAt,
    this.favorites,
    this.image,
    this.address,
    this.extra,
    this.managedSalons,
  });

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? phone,
    String? fcmToken,
    DateTime? joinedAt,
    Map<String, bool>? favorites,
    String? image,
    String? address,
    Map<String, dynamic>? extra,
    Map<String, bool>? managedSalons,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      fcmToken: fcmToken ?? this.fcmToken,
      joinedAt: joinedAt ?? this.joinedAt,
      favorites: favorites ?? this.favorites,
      image: image ?? this.image,
      address: address ?? this.address,
      extra: extra ?? this.extra,
      managedSalons: managedSalons ?? this.managedSalons,
    );
  }

  factory AppUser.fromMap(String id, Map<String, dynamic> map) {
    return AppUser(
      id: id,
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      role: map['role']?.toString() ?? 'client',
      phone: map['phone']?.toString(),
      fcmToken: map['fcmToken']?.toString(),
      joinedAt: map['joinedAt'] != null
          ? DateTime.tryParse(map['joinedAt'].toString())
          : null,
      favorites: map['favorites'] != null
          ? Map<String, bool>.from(map['favorites'])
          : null,
      image: map['image']?.toString(),
      address: map['address']?.toString(),
      extra: Map<String, dynamic>.from(map),
      managedSalons: map['managedSalons'] != null
          ? Map<String, bool>.from(map['managedSalons'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'fcmToken': fcmToken,
      'joinedAt': joinedAt?.toIso8601String(),
      'favorites': favorites,
      'image': image ?? '',
      'address': address ?? '',
      'managedSalons': managedSalons,
    };
  }
}

class Booking {
  final String id;
  final String userId;
  final String salonId;
  final String serviceId;
  final String salonServiceId;
  final DateTime dateTime;
  final String status;
  final String paymentStatus; 
  final bool rated;
  final DateTime createdAt;
  final DateTime? updatedAt;

  final bool ownerSeen;

  Booking({
    required this.id,
    required this.userId,
    required this.salonId,
    required this.serviceId,
    required this.salonServiceId,
    required this.dateTime,
    required this.status,
    required this.paymentStatus,
    this.rated = false,
    required this.createdAt,
    this.updatedAt,
    this.ownerSeen = false,
  });

  Booking copyWith({
    String? id,
    String? userId,
    String? salonId,
    String? serviceId,
    String? salonServiceId,
    DateTime? dateTime,
    String? status,
    String? paymentStatus,
    bool? rated,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? ownerSeen,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      salonId: salonId ?? this.salonId,
      serviceId: serviceId ?? this.serviceId,
      salonServiceId: salonServiceId ?? this.salonServiceId,
      dateTime: dateTime ?? this.dateTime,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      rated: rated ?? this.rated,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ownerSeen: ownerSeen ?? this.ownerSeen,
    );
  }

  factory Booking.fromMap(String id, Map<String, dynamic> map) {
    final now = DateTime.now().toUtc();

    return Booking(
      id: id,
      userId: map['userId']?.toString() ?? '',
      salonId: map['salonId']?.toString() ?? '',
      serviceId: map['serviceId']?.toString() ?? '',
      salonServiceId: map['salonServiceId']?.toString() ?? '',
      dateTime: map['datetime'] != null
          ? (DateTime.tryParse(map['datetime'].toString()) ?? now)
          : now,
      status: map['status']?.toString() ?? 'pending',
      paymentStatus: map['paymentStatus']?.toString() ?? 'unpaid',
      rated: map['rated'] == true,
      createdAt: map['createdAt'] != null
          ? (DateTime.tryParse(map['createdAt'].toString()) ?? now)
          : now,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString())
          : null,
      ownerSeen: map['ownerSeen'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'salonId': salonId,
      'serviceId': serviceId,
      'salonServiceId': salonServiceId,
      'datetime': dateTime.toIso8601String(),
      'status': status,
      'paymentStatus': paymentStatus,
      'rated': rated,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'ownerSeen': ownerSeen,
    };
  }
}


class Review {
  final String id;
  final String userId;
  final String salonId;
  final int rating; 
  final String? comment;
  final String? bookingId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  final String? ownerReply;
  final DateTime? ownerReplyAt;

  Review({
    required this.id,
    required this.userId,
    required this.salonId,
    required this.rating,
    this.comment,
    this.bookingId,
    required this.createdAt,
    this.updatedAt,
    this.ownerReply,
    this.ownerReplyAt,
  });

  Review copyWith({
    String? id,
    String? userId,
    String? salonId,
    int? rating,
    String? comment,
    String? bookingId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? ownerReply,
    DateTime? ownerReplyAt,
  }) {
    return Review(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      salonId: salonId ?? this.salonId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      bookingId: bookingId ?? this.bookingId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ownerReply: ownerReply ?? this.ownerReply,
      ownerReplyAt: ownerReplyAt ?? this.ownerReplyAt,
    );
  }

  factory Review.fromMap(String keyId, Map<String, dynamic> map) {
    final now = DateTime.now().toUtc();

    int parseRating(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    DateTime parseDate(dynamic v, {DateTime? fallback}) {
      if (v == null) return fallback ?? now;
      if (v is DateTime) return v;
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v, isUtc: true);
      if (v is String) return DateTime.tryParse(v) ?? (fallback ?? now);
      return fallback ?? now;
    }

    return Review(
      id: map['id']?.toString() ?? keyId,
      userId: map['userId']?.toString() ?? '',
      salonId: map['salonId']?.toString() ?? '',
      rating: parseRating(map['rating']),
      comment: map['comment']?.toString(),
      bookingId: map['bookingId']?.toString(),
      createdAt: parseDate(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt']) : null,
      ownerReply: map['ownerReply']?.toString(),
      ownerReplyAt: map['ownerReplyAt'] != null
          ? parseDate(map['ownerReplyAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'salonId': salonId,
      'rating': rating,
      'comment': comment,
      'bookingId': bookingId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'ownerReply': ownerReply,
      'ownerReplyAt': ownerReplyAt?.toIso8601String(),
    };
  }
}
