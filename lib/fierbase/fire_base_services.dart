import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';




class FirebaseServiceException implements Exception {
  final String code;
  final String message;
  const FirebaseServiceException(this.code, this.message);

  @override
  String toString() => 'FirebaseServiceException($code): $message';
}

enum BookingStatus { pending, confirmed, cancelled, completed }

enum SessionStatus { waiting, active, ended }

class Consultant {
  final String id;
  final String name;
  final String specialty;
  final String? photoUrl;
  final double ratingAvg;
  final int ratingCount;
  final bool isAvailable;
  final List<String> languages;

  const Consultant({
    required this.id,
    required this.name,
    required this.specialty,
    this.photoUrl,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.isAvailable = false,
    this.languages = const [],
  });

  factory Consultant.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Consultant(
      id: doc.id,
      name: d['name'] as String? ?? '',
      specialty: d['specialty'] as String? ?? '',
      photoUrl: d['photoUrl'] as String?,
      ratingAvg: (d['ratingAvg'] as num?)?.toDouble() ?? 0,
      ratingCount: (d['ratingCount'] as num?)?.toInt() ?? 0,
      isAvailable: d['isAvailable'] as bool? ?? false,
      languages: List<String>.from(d['languages'] as List? ?? const []),
    );
  }
}

class Booking {
  final String id;
  final String patientId;
  final String consultantId;
  final String consultantName;
  final DateTime scheduledAt;
  final BookingStatus status;
  final String? notes;

  const Booking({
    required this.id,
    required this.patientId,
    required this.consultantId,
    required this.consultantName,
    required this.scheduledAt,
    required this.status,
    this.notes,
  });

  factory Booking.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Booking(
      id: doc.id,
      patientId: d['patientId'] as String? ?? '',
      consultantId: d['consultantId'] as String? ?? '',
      consultantName: d['consultantName'] as String? ?? '',
      scheduledAt: (d['scheduledAt'] as Timestamp).toDate(),
      status: BookingStatus.values.byName(d['status'] as String? ?? 'pending'),
      notes: d['notes'] as String?,
    );
  }
}

class Session {
  final String id;
  final String bookingId;
  final String patientId;
  final String consultantId;
  final SessionStatus status;
  final DateTime? startedAt;
  final DateTime? endedAt;

  const Session({
    required this.id,
    required this.bookingId,
    required this.patientId,
    required this.consultantId,
    required this.status,
    this.startedAt,
    this.endedAt,
  });

  factory Session.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Session(
      id: doc.id,
      bookingId: d['bookingId'] as String? ?? '',
      patientId: d['patientId'] as String? ?? '',
      consultantId: d['consultantId'] as String? ?? '',
      status: SessionStatus.values.byName(d['status'] as String? ?? 'waiting'),
      startedAt: (d['startedAt'] as Timestamp?)?.toDate(),
      endedAt: (d['endedAt'] as Timestamp?)?.toDate(),
    );
  }
}

class MarsaFirebaseService {
  MarsaFirebaseService._();
  static final MarsaFirebaseService instance = MarsaFirebaseService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _consultants => _db.collection('consultants');
  CollectionReference<Map<String, dynamic>> get _bookings => _db.collection('bookings');
  CollectionReference<Map<String, dynamic>> get _slots => _db.collection('booking_slots');
  CollectionReference<Map<String, dynamic>> get _sessions => _db.collection('sessions');
  CollectionReference<Map<String, dynamic>> get _feedback => _db.collection('feedback');

  static void configureOffline() {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw const FirebaseServiceException('unauthenticated', 'User is not signed in');
    }
    return user.uid;
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseServiceException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw FirebaseServiceException(e.code, e.message ?? 'Authentication error');
    } on FirebaseException catch (e) {
      throw FirebaseServiceException(e.code, e.message ?? 'Database error');
    }
  }

  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(FirebaseServiceException error) onError,
    void Function(User user)? onAutoVerified,
    int? resendToken,
  }) {
    return _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      forceResendingToken: resendToken,
      verificationCompleted: (credential) async {
        try {
          final result = await _auth.signInWithCredential(credential);
          if (result.user != null) onAutoVerified?.call(result.user!);
        } on FirebaseAuthException catch (e) {
          onError(FirebaseServiceException(e.code, e.message ?? 'Authentication error'));
        }
      },
      verificationFailed: (e) =>
          onError(FirebaseServiceException(e.code, e.message ?? 'Verification failed')),
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<User> verifyOtp({
    required String verificationId,
    required String smsCode,
    String role = 'patient',
  }) {
    return _guard(() async {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final result = await _auth.signInWithCredential(credential);
      final user = result.user;
      if (user == null) {
        throw const FirebaseServiceException('no-user', 'Sign-in failed');
      }
      await _ensureUserProfile(user, role);
      return user;
    });
  }

  Future<void> _ensureUserProfile(User user, String role) async {
    final ref = _users.doc(user.uid);
    final snap = await ref.get();
    if (snap.exists) return;
    await ref.set({
      'phone': user.phoneNumber,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> fetchUserProfile() {
    return _guard(() async => (await _users.doc(_uid).get()).data());
  }

  Future<void> updateUserProfile(Map<String, dynamic> data) {
    return _guard(() => _users.doc(_uid).set(data, SetOptions(merge: true)));
  }

  Future<void> signOut() => _guard(_auth.signOut);

  Query<Map<String, dynamic>> _consultantQuery({String? specialty, bool onlyAvailable = false}) {
    Query<Map<String, dynamic>> q = _consultants;
    if (specialty != null && specialty.isNotEmpty) {
      q = q.where('specialty', isEqualTo: specialty);
    }
    if (onlyAvailable) q = q.where('isAvailable', isEqualTo: true);
    return q.orderBy('ratingAvg', descending: true);
  }

  Future<List<Consultant>> fetchConsultants({
    String? specialty,
    bool onlyAvailable = false,
    int limit = 30,
  }) {
    return _guard(() async {
      final snap = await _consultantQuery(specialty: specialty, onlyAvailable: onlyAvailable)
          .limit(limit)
          .get();
      return snap.docs.map(Consultant.fromDoc).toList();
    });
  }

  Stream<List<Consultant>> streamConsultants({
    String? specialty,
    bool onlyAvailable = false,
    int limit = 30,
  }) {
    return _consultantQuery(specialty: specialty, onlyAvailable: onlyAvailable)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(Consultant.fromDoc).toList());
  }

  Future<Consultant?> fetchConsultant(String consultantId) {
    return _guard(() async {
      final doc = await _consultants.doc(consultantId).get();
      return doc.exists ? Consultant.fromDoc(doc) : null;
    });
  }

  Future<String> createBooking({
    required String consultantId,
    required DateTime scheduledAt,
    String? notes,
  }) {
    return _guard(() async {
      final uid = _uid;
      final slotId = '${consultantId}_${scheduledAt.toUtc().millisecondsSinceEpoch}';
      final slotRef = _slots.doc(slotId);
      final consultantRef = _consultants.doc(consultantId);
      final bookingRef = _bookings.doc();

      await _db.runTransaction((tx) async {
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
          'patientId': uid,
          'consultantId': consultantId,
          'consultantName': consultant.data()?['name'] ?? '',
          'scheduledAt': Timestamp.fromDate(scheduledAt),
          'status': BookingStatus.pending.name,
          'notes': notes,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
      return bookingRef.id;
    });
  }

  Future<void> cancelBooking(String bookingId) {
    return _guard(() async {
      final uid = _uid;
      final ref = _bookings.doc(bookingId);
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists || snap.data()?['patientId'] != uid) {
          throw const FirebaseServiceException('not-found', 'Booking not found');
        }
        final data = snap.data()!;
        final status = data['status'] as String;
        if (status == BookingStatus.cancelled.name || status == BookingStatus.completed.name) {
          throw FirebaseServiceException('invalid-state', 'Booking is already $status');
        }
        final slotId =
            '${data['consultantId']}_${(data['scheduledAt'] as Timestamp).toDate().toUtc().millisecondsSinceEpoch}';
        tx.update(ref, {
          'status': BookingStatus.cancelled.name,
          'cancelledAt': FieldValue.serverTimestamp(),
        });
        tx.delete(_slots.doc(slotId));
      });
    });
  }

  Stream<List<Booking>> streamUpcomingBookings({int limit = 20}) {
    return _bookings
        .where('patientId', isEqualTo: _uid)
        .where('status', whereIn: [BookingStatus.pending.name, BookingStatus.confirmed.name])
        .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.now())
        .orderBy('scheduledAt')
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(Booking.fromDoc).toList());
  }

  Future<List<Booking>> fetchBookingHistory({int limit = 30}) {
    return _guard(() async {
      final snap = await _bookings
          .where('patientId', isEqualTo: _uid)
          .orderBy('scheduledAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map(Booking.fromDoc).toList();
    });
  }

  Stream<Session?> streamActiveSession() {
    return _sessions
        .where('patientId', isEqualTo: _uid)
        .where('status', whereIn: [SessionStatus.waiting.name, SessionStatus.active.name])
        .limit(1)
        .snapshots()
        .map((s) => s.docs.isEmpty ? null : Session.fromDoc(s.docs.first));
  }

  Stream<Session?> streamSession(String sessionId) {
    return _sessions
        .doc(sessionId)
        .snapshots()
        .map((d) => d.exists ? Session.fromDoc(d) : null);
  }

  Future<String> joinSession(String bookingId) {
    return _guard(() async {
      final uid = _uid;
      final bookingRef = _bookings.doc(bookingId);
      final sessionRef = _sessions.doc(bookingId);

      await _db.runTransaction((tx) async {
        final booking = await tx.get(bookingRef);
        final existing = await tx.get(sessionRef);
        if (!booking.exists || booking.data()?['patientId'] != uid) {
          throw const FirebaseServiceException('not-found', 'Booking not found');
        }
        final status = booking.data()!['status'] as String;
        if (status == BookingStatus.cancelled.name || status == BookingStatus.completed.name) {
          throw FirebaseServiceException('invalid-state', 'Booking is $status');
        }
        if (existing.exists) return;
        tx.set(sessionRef, {
          'bookingId': bookingId,
          'patientId': uid,
          'consultantId': booking.data()!['consultantId'],
          'status': SessionStatus.waiting.name,
          'createdAt': FieldValue.serverTimestamp(),
        });
        tx.update(bookingRef, {'status': BookingStatus.confirmed.name});
      });
      return sessionRef.id;
    });
  }

  Future<void> endSession(String sessionId) {
    return _guard(() async {
      final uid = _uid;
      final sessionRef = _sessions.doc(sessionId);
      await _db.runTransaction((tx) async {
        final snap = await tx.get(sessionRef);
        if (!snap.exists || snap.data()?['patientId'] != uid) {
          throw const FirebaseServiceException('not-found', 'Session not found');
        }
        final data = snap.data()!;
        if (data['status'] == SessionStatus.ended.name) return;
        tx.update(sessionRef, {
          'status': SessionStatus.ended.name,
          'endedAt': FieldValue.serverTimestamp(),
        });
        tx.update(_bookings.doc(data['bookingId'] as String), {
          'status': BookingStatus.completed.name,
        });
      });
    });
  }

  Future<void> submitFeedback({
    required String sessionId,
    required int rating,
    String? comment,
  }) {
    return _guard(() async {
      if (rating < 1 || rating > 5) {
        throw const FirebaseServiceException('invalid-rating', 'Rating must be between 1 and 5');
      }
      final uid = _uid;
      final sessionRef = _sessions.doc(sessionId);
      final feedbackRef = _feedback.doc(sessionId);

      await _db.runTransaction((tx) async {
        final session = await tx.get(sessionRef);
        final existing = await tx.get(feedbackRef);
        if (!session.exists || session.data()?['patientId'] != uid) {
          throw const FirebaseServiceException('not-found', 'Session not found');
        }
        if (session.data()!['status'] != SessionStatus.ended.name) {
          throw const FirebaseServiceException('invalid-state', 'Session has not ended');
        }
        if (existing.exists) {
          throw const FirebaseServiceException('already-submitted', 'Feedback already submitted');
        }
        final consultantId = session.data()!['consultantId'] as String;
        final consultantRef = _consultants.doc(consultantId);
        final consultant = await tx.get(consultantRef);
        final count = (consultant.data()?['ratingCount'] as num?)?.toInt() ?? 0;
        final avg = (consultant.data()?['ratingAvg'] as num?)?.toDouble() ?? 0;
        final newCount = count + 1;
        final newAvg = ((avg * count) + rating) / newCount;

        tx.set(feedbackRef, {
          'sessionId': sessionId,
          'patientId': uid,
          'consultantId': consultantId,
          'rating': rating,
          'comment': comment?.trim().isEmpty ?? true ? null : comment!.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        tx.update(consultantRef, {
          'ratingAvg': double.parse(newAvg.toStringAsFixed(2)),
          'ratingCount': newCount,
        });
      });
    });
  }

  Future<bool> hasSubmittedFeedback(String sessionId) {
    return _guard(() async => (await _feedback.doc(sessionId).get()).exists);
  }
}