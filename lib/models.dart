/// =======================
/// موديل الصالون Salon
/// =======================
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
  bool isFavorite; // لتخزين حالة المفضلة

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
    this.isFavorite = false, // القيمة الافتراضية false
  });

  // ✅ copyWith لتعديل أي حقل أو extra
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
    );
  }

  // إنشاء كائن من خريطة البيانات
  factory Salon.fromMap(
    String id,
    Map<String, dynamic> map, {
    bool isFavorite = false,
  }) {
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
    );
  }
}

/// =======================
/// موديل الخدمة Service
/// =======================
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

  // إنشاء كائن من خريطة البيانات
  factory Service.fromMap(String id, Map<String, dynamic> map) {
    return Service(
      id: id,
      name: map['name']?.toString() ?? '',
      price: map['price'] != null
          ? double.tryParse(map['price'].toString()) ?? 0.0
          : 0.0,
      extra: Map<String, dynamic>.from(map),
    );
  }
}

/// =======================
/// موديل اليوزر AppUser
/// =======================
class AppUser {
  final String id; // نفس الـ key في الداتابيس (user_1, owner_1, ...)
  final String name;
  final String email;
  final String role; // client / owner / admin
  final String? phone;
  final String? fcmToken;
  final DateTime? joinedAt;
  final Map<String, bool>? favorites; // salons المفضلة (لليوزر العادي)
  final String? image; // رابط صورة البروفايل
  final String? address; // العنوان
  final Map<String, dynamic>? extra;

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
    };
  }
}

/// =======================
/// موديل الحجز Booking
/// =======================
/// نستخدمه لقراءة/كتابة الحجوزات من /bookings في Realtime DB
class Booking {
  final String id;
  final String userId;
  final String salonId;
  final String serviceId;
  final String salonServiceId;
  final DateTime dateTime;
  final String status; // pending / accepted / completed / cancelled
  final String paymentStatus; // paid / unpaid
  final bool rated; // true إذا هذا الحجز تم تقييمه
  final DateTime createdAt;
  final DateTime? updatedAt;

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
    );
  }

  factory Booking.fromMap(String id, Map<String, dynamic> map) {
    return Booking(
      id: id,
      userId: map['userId']?.toString() ?? '',
      salonId: map['salonId']?.toString() ?? '',
      serviceId: map['serviceId']?.toString() ?? '',
      salonServiceId: map['salonServiceId']?.toString() ?? '',
      dateTime: map['datetime'] != null
          ? DateTime.tryParse(map['datetime'].toString()) ??
                DateTime.now().toUtc()
          : DateTime.now().toUtc(),
      status: map['status']?.toString() ?? 'pending',
      paymentStatus: map['paymentStatus']?.toString() ?? 'unpaid',
      rated: map['rated'] == true,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ??
                DateTime.now().toUtc()
          : DateTime.now().toUtc(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString())
          : null,
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
    };
  }
}

/// =======================
/// موديل التقييم Review
/// =======================
/// يمثل سطر في /reviews في Realtime DB
class Review {
  final String id;
  final String userId;
  final String salonId;
  final int rating; // من 1 إلى 5
  final String? comment;
  final String? bookingId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Review({
    required this.id,
    required this.userId,
    required this.salonId,
    required this.rating,
    this.comment,
    this.bookingId,
    required this.createdAt,
    this.updatedAt,
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
    );
  }

  factory Review.fromMap(String id, Map<String, dynamic> map) {
    return Review(
      id: id,
      userId: map['userId']?.toString() ?? '',
      salonId: map['salonId']?.toString() ?? '',
      rating: int.tryParse(map['rating'].toString()) ?? 0,
      comment: map['comment']?.toString(),
      bookingId: map['bookingId']?.toString(),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ??
                DateTime.now().toUtc()
          : DateTime.now().toUtc(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString())
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
    };
  }
}
