// services/firebase_service_ext.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:marsa/fierbase/fire_base_services.dart';


enum SessionType { video, audio, chat }

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime? createdAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    this.createdAt,
  });

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return ChatMessage(
      id: doc.id,
      senderId: d['senderId'] as String? ?? '',
      text: d['text'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

extension FirebaseServiceBookings on MarsaFirebaseService {
  Future<String> bookSession({
    required String consultantId,
    required DateTime scheduledAt,
    required SessionType type,
    String? notes,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw const FirebaseServiceException('unauthenticated', 'User is not signed in');
    }
    if (scheduledAt.isBefore(DateTime.now())) {
      throw const FirebaseServiceException('invalid-time', 'Selected time has passed');
    }
    final db = FirebaseFirestore.instance;
    final slotRef = db
        .collection('booking_slots')
        .doc('${consultantId}_${scheduledAt.toUtc().millisecondsSinceEpoch}');
    final consultantRef = db.collection('consultants').doc(consultantId);
    final bookingRef = db.collection('bookings').doc();
    try {
      await db.runTransaction((tx) async {
        final slot = await tx.get(slotRef);
        final consultant = await tx.get(consultantRef);
        if (!consultant.exists) {
          throw const FirebaseServiceException('not-found', 'Consultant not found');
        }
        if (slot.exists) {
          throw const FirebaseServiceException('slot-taken', 'Time slot already booked');
        }
        tx.set(slotRef, {
          'consultantId': consultantId,
          'bookingId': bookingRef.id,
          'scheduledAt': Timestamp.fromDate(scheduledAt),
        });
        tx.set(bookingRef, {
          'patientId': user.uid,
          'consultantId': consultantId,
          'consultantName': consultant.data()?['name'] ?? '',
          'scheduledAt': Timestamp.fromDate(scheduledAt),
          'sessionType': type.name,
          'status': BookingStatus.pending.name,
          'notes': notes,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (e) {
      throw FirebaseServiceException(e.code, e.message ?? 'Database error');
    }
    return bookingRef.id;
  }

  Future<Set<int>> fetchTakenSlotHours(String consultantId, DateTime day) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('booking_slots')
          .where('consultantId', isEqualTo: consultantId)
          .get();
      final hours = <int>{};
      for (final doc in snap.docs) {
        final ts = (doc.data()['scheduledAt'] as Timestamp?)?.toDate().toLocal();
        if (ts != null && ts.year == day.year && ts.month == day.month && ts.day == day.day) {
          hours.add(ts.hour);
        }
      }
      return hours;
    } on FirebaseException catch (e) {
      throw FirebaseServiceException(e.code, e.message ?? 'Database error');
    }
  }

  // Reflects the `e2eEncrypted` flag on the session document. Messages below are stored as
  // plaintext; the flag must only be set to true by a real client-side encryption layer.
  Stream<bool> streamSessionEncryption(String sessionId) {
    return FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .snapshots()
        .map((d) => d.data()?['e2eEncrypted'] == true);
  }

  Stream<List<ChatMessage>> streamMessages(String sessionId, {int limit = 200}) {
    return FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(ChatMessage.fromDoc).toList());
  }

  Future<void> sendMessage(String sessionId, String text) async {
    final user = currentUser;
    if (user == null) {
      throw const FirebaseServiceException('unauthenticated', 'User is not signed in');
    }
    final clean = text.trim();
    if (clean.isEmpty) return;
    if (clean.length > 2000) {
      throw const FirebaseServiceException('too-long', 'Message is too long');
    }
    try {
      await FirebaseFirestore.instance
          .collection('sessions')
          .doc(sessionId)
          .collection('messages')
          .add({
        'senderId': user.uid,
        'text': clean,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw FirebaseServiceException(e.code, e.message ?? 'Database error');
    }
  }

  // The feedback document stores patientId; security rules must hide it from consultant reads.
  Future<void> attachFeedbackTags(String sessionId, List<String> tags) async {
    try {
      await FirebaseFirestore.instance
          .collection('feedback')
          .doc(sessionId)
          .update({'tags': tags});
    } on FirebaseException catch (e) {
      throw FirebaseServiceException(e.code, e.message ?? 'Database error');
    }
  }
}


// lib/fierbase/fire_base_ext.dart  (A) paste at the END of the file, outside the extension
String anonId(String patientId) {
  var h = 0x811c9dc5;
  for (final u in patientId.codeUnits) {
    h = ((h ^ u) * 0x01000193) & 0xFFFFFFFF;
  }
  return 'GA-${(h % 9000) + 1000}';
}

Future<T> _fs<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on FirebaseServiceException {
    rethrow;
  } on FirebaseException catch (e) {
    throw FirebaseServiceException(e.code, e.message ?? 'Database error');
  }
}

// lib/fierbase/fire_base_ext.dart  (B) paste INSIDE the extension, BEFORE its last "}"
String get _myUid {
  final u = currentUser;
  if (u == null) {
    throw const FirebaseServiceException('unauthenticated', 'User is not signed in');
  }
  return u.uid;
}

Stream<bool> streamIsOnline() => FirebaseFirestore.instance
    .collection('hotlines')
    .snapshots(includeMetadataChanges: true)
    .map((s) => !s.metadata.isFromCache);

Future<bool> isConsultant() async {
  final u = currentUser;
  if (u == null) return false;
  try {
    final d = await FirebaseFirestore.instance.collection('consultants').doc(u.uid).get();
    return d.exists;
  } on FirebaseException {
    return false;
  }
}

Stream<Map<String, dynamic>?> streamConsultantProfile() => FirebaseFirestore.instance
    .collection('consultants')
    .doc(_myUid)
    .snapshots()
    .map((d) => d.data());

Future<void> setSosOnline(bool v) => _fs(() => FirebaseFirestore.instance
    .collection('consultants')
    .doc(_myUid)
    .update({'sosOnline': v, 'sosUpdatedAt': FieldValue.serverTimestamp()}).timeout(
  const Duration(seconds: 5),
));

Stream<List<ConsultantRequest>> streamConsultantBookings(
    BookingStatus status, {
      int limit = 50,
    }) {
  return FirebaseFirestore.instance
      .collection('bookings')
      .where('consultantId', isEqualTo: _myUid)
      .where('status', isEqualTo: status.name)
      .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.now())
      .orderBy('scheduledAt')
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(ConsultantRequest.fromDoc).toList());
}

Stream<List<ConsultantRequest>> streamTodayBookings() {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = DateTime(now.year, now.month, now.day + 1);
  return FirebaseFirestore.instance
      .collection('bookings')
      .where('consultantId', isEqualTo: _myUid)
      .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
      .where('scheduledAt', isLessThan: Timestamp.fromDate(end))
      .orderBy('scheduledAt')
      .snapshots()
      .map((s) => s.docs.map(ConsultantRequest.fromDoc).toList());
}

Future<void> acceptBooking(String bookingId) => _fs(() async {
  final uid = _myUid;
  final db = FirebaseFirestore.instance;
  final ref = db.collection('bookings').doc(bookingId);
  await db.runTransaction((tx) async {
    final d = (await tx.get(ref)).data();
    if (d == null || d['consultantId'] != uid) {
      throw const FirebaseServiceException('not-found', 'Booking not found');
    }
    if (d['status'] != BookingStatus.pending.name) {
      throw const FirebaseServiceException('invalid-state', 'Booking is not pending');
    }
    tx.update(ref, {
      'status': BookingStatus.confirmed.name,
      'acceptedAt': FieldValue.serverTimestamp(),
    });
  });
});

Future<void> rescheduleBooking(String bookingId, DateTime newTime) => _fs(() async {
  if (newTime.isBefore(DateTime.now())) {
    throw const FirebaseServiceException('invalid-time', 'Selected time has passed');
  }
  final uid = _myUid;
  final db = FirebaseFirestore.instance;
  final ref = db.collection('bookings').doc(bookingId);
  String slotId(DateTime t) => '${uid}_${t.toUtc().millisecondsSinceEpoch}';
  await db.runTransaction((tx) async {
    final d = (await tx.get(ref)).data();
    if (d == null || d['consultantId'] != uid) {
      throw const FirebaseServiceException('not-found', 'Booking not found');
    }
    final status = d['status'];
    if (status != BookingStatus.pending.name && status != BookingStatus.confirmed.name) {
      throw const FirebaseServiceException('invalid-state', 'Booking is closed');
    }
    final oldSlot = db
        .collection('booking_slots')
        .doc(slotId((d['scheduledAt'] as Timestamp).toDate()));
    final newSlot = db.collection('booking_slots').doc(slotId(newTime));
    if ((await tx.get(newSlot)).exists) {
      throw const FirebaseServiceException('slot-taken', 'Time slot already booked');
    }
    tx.delete(oldSlot);
    tx.set(newSlot, {
      'consultantId': uid,
      'bookingId': bookingId,
      'scheduledAt': Timestamp.fromDate(newTime),
    });
    tx.update(ref, {
      'scheduledAt': Timestamp.fromDate(newTime),
      'rescheduledBy': 'consultant',
      'rescheduledAt': FieldValue.serverTimestamp(),
    });
  });
});

Future<void> saveClinicalNote({
  required String patientId,
  String? sessionId,
  required String cipher,
  required String iv,
}) =>
    _fs(() => FirebaseFirestore.instance.collection('consultant_notes').add({
      'consultantId': _myUid,
      'patientId': patientId,
      'sessionId': sessionId,
      'cipher': cipher,
      'iv': iv,
      'createdAt': FieldValue.serverTimestamp(),
    }).timeout(const Duration(seconds: 5)));

Stream<List<Map<String, dynamic>>> streamClinicalNotes(String patientId, {int limit = 30}) {
  return FirebaseFirestore.instance
      .collection('consultant_notes')
      .where('consultantId', isEqualTo: _myUid)
      .where('patientId', isEqualTo: patientId)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map((d) {
    final data = d.data();
    return <String, dynamic>{
      'id': d.id,
      'cipher': data['cipher'],
      'iv': data['iv'],
      'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
    };
  }).toList());
}

Stream<({List<LibraryResource> items, bool fromCache})> streamLibrary() =>
    FirebaseFirestore.instance
        .collection('resources')
        .orderBy('order')
        .snapshots(includeMetadataChanges: true)
        .map((s) => (
    items: s.docs.map(LibraryResource.fromDoc).toList(),
    fromCache: s.metadata.isFromCache,
    ));

class ConsultantRequest {
  final String id;
  final String patientId;
  final DateTime scheduledAt;
  final SessionType type;
  final BookingStatus status;

  const ConsultantRequest({
    required this.id,
    required this.patientId,
    required this.scheduledAt,
    required this.type,
    required this.status,
  });

  String get anon => anonId(patientId);

  factory ConsultantRequest.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return ConsultantRequest(
      id: doc.id,
      patientId: d['patientId'] as String? ?? '',
      scheduledAt: (d['scheduledAt'] as Timestamp).toDate(),
      type: SessionType.values.asNameMap()[d['sessionType']] ?? SessionType.video,
      status: BookingStatus.values.asNameMap()[d['status']] ?? BookingStatus.pending,
    );
  }
}

class LibraryResource {
  final String id;
  final String title;
  final String body;
  final String category;
  final bool featured;
  final String? audioUrl;

  const LibraryResource({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.featured,
    this.audioUrl,
  });

  factory LibraryResource.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return LibraryResource(
      id: doc.id,
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
      category: d['category'] as String? ?? 'article',
      featured: d['featured'] as bool? ?? false,
      audioUrl: d['audioUrl'] as String?,
    );
  }
}