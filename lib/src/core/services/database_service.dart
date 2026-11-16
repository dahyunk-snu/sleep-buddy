import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:logging/logging.dart';
import 'package:sleepy/src/core/models/child_profile.dart';
import 'package:sleepy/src/core/models/sleep_analysis.dart';
import 'package:sleepy/src/core/models/sleep_data.dart';
import 'package:sleepy/src/features/dream_friend/domain/dream_content.dart';
import 'package:sleepy/src/features/dream_friend/domain/dream_friend.dart';

part 'database_service.g.dart';

/// [_log] DatabaseService 전용 로거
final _log = Logger('DatabaseService');

/// [databaseService] DatabaseService 의존성 주입
@riverpod
DatabaseService databaseService(Ref ref) {
  return DatabaseService(FirebaseFirestore.instance);
}

/// [DatabaseService] Firestore 데이터 액세스 레이어
/// [ _db ] Firestore 인스턴스
class DatabaseService {
  DatabaseService(this._db);
  final FirebaseFirestore _db;

  /// [_userDoc] users/{userId} 문서 참조
  /// [userId] 사용자 ID
  DocumentReference<Map<String, dynamic>> _userDoc(String userId) =>
      _db.collection('users').doc(userId);

  /// [_childrenCol] users/{userId}/children 컬렉션 참조
  /// [userId] 사용자 ID
  CollectionReference<Map<String, dynamic>> _childrenCol(String userId) =>
      _userDoc(userId).collection('children');

  /// [_sleepCol] users/{userId}/children/{childId}/sleep_data 컬렉션 참조
  /// [userId] 사용자 ID
  /// [childId] 아동 ID
  CollectionReference<Map<String, dynamic>> _sleepCol(
    String userId,
    String childId,
  ) => _childrenCol(userId).doc(childId).collection('sleep_data');

  /// [_sleepDocRef] sleep_data 문서 참조
  /// [userId] 사용자 ID
  /// [childId] 아동 ID
  /// [sleepDataId] 수면 데이터 문서 ID
  DocumentReference<Map<String, dynamic>> _sleepDocRef(
    String userId,
    String childId,
    String sleepDataId,
  ) => _sleepCol(userId, childId).doc(sleepDataId);

  /// [createNewUser] 최초 로그인 시 user 문서를 생성
  /// [user] Firebase Auth User
  Future<void> createNewUser(User user) async {
    try {
      final userDocRef = _userDoc(user.uid);
      final doc = await userDocRef.get();
      if (!doc.exists) {
        await userDocRef.set({
          'email': user.email,
          'displayName': user.displayName,
        });
      }
    } on FirebaseException catch (e, s) {
      _log.severe('신규 유저 저장 실패', e, s);
      rethrow;
    }
  }

  /// [deleteUserData] 사용자 전체 데이터 삭제(하위 컬렉션 포함)
  /// [userId] 사용자 ID
  Future<void> deleteUserData(String userId) async {
    try {
      // dream_friends 삭제
      final dreamsSnap = await _userDoc(
        userId,
      ).collection('dream_friends').get();
      final batch = _db.batch();
      for (final d in dreamsSnap.docs) {
        batch.delete(d.reference);
      }

      // children 및 하위 sleep_data 삭제
      final children = await _childrenCol(userId).get();
      for (final c in children.docs) {
        final sleeps = await c.reference.collection('sleep_data').get();
        for (final s in sleeps.docs) {
          batch.delete(s.reference);
        }
        batch.delete(c.reference);
      }

      // users/{userId} 삭제
      batch.delete(_userDoc(userId));
      await batch.commit();
    } on FirebaseException catch (e, s) {
      _log.severe('사용자 전체 데이터 삭제 실패', e, s);
      rethrow;
    }
  }

  /// [addChildProfile] 아동 프로필 추가(users/{userId}/children)
  /// [userId] 부모 ID
  /// [profile] 아동 프로필
  Future<void> addChildProfile(String userId, ChildProfile profile) async {
    try {
      await _childrenCol(userId).add(profile.toFirestore());
    } on FirebaseException catch (e, s) {
      _log.severe('아이 프로필 생성 실패', e, s);
      rethrow;
    }
  }

  /// [hasChildProfiles] 아동 프로필 존재 여부(최소 1개)
  /// [userId] 부모 ID
  Future<bool> hasChildProfiles(String userId) async {
    try {
      final snap = await _childrenCol(userId).limit(1).get();
      return snap.docs.isNotEmpty;
    } catch (e, s) {
      _log.warning('아이 프로필 존재 확인 실패', e, s);
      return false;
    }
  }

  /// [getChildProfile] 특정 아동 프로필 조회
  /// [userId] 부모 ID
  /// [childId] 아동 ID
  Future<ChildProfile?> getChildProfile(String userId, String childId) async {
    try {
      final docSnapshot = await _childrenCol(userId)
          .doc(childId)
          .withConverter<ChildProfile>(
            fromFirestore: (snap, _) => ChildProfile.fromFirestore(snap, null),
            toFirestore: (profile, _) => profile.toFirestore(),
          )
          .get();
      return docSnapshot.data();
    } on FirebaseException catch (e, s) {
      _log.severe('아이 프로필 조회 실패', e, s);
      rethrow;
    }
  }

  /// [getChildProfiles] 모든 아동 프로필 목록
  /// [userId] 부모 ID
  Future<List<ChildProfile>> getChildProfiles(String userId) async {
    try {
      final snapshot = await _childrenCol(userId)
          .withConverter<ChildProfile>(
            fromFirestore: (snap, _) => ChildProfile.fromFirestore(snap, null),
            toFirestore: (profile, _) => profile.toFirestore(),
          )
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } on FirebaseException catch (e, s) {
      _log.severe('아이 프로필 목록 조회 실패', e, s);
      rethrow;
    }
  }

  /// [updateChildProfile] 아동 프로필 업데이트
  /// [userId] 부모 ID
  /// [profile] 업데이트할 프로필(profile.id 필수)
  Future<void> updateChildProfile(String userId, ChildProfile profile) async {
    try {
      await _childrenCol(userId).doc(profile.id).update(profile.toFirestore());
    } on FirebaseException catch (e, s) {
      _log.severe('아이 프로필 업데이트 실패', e, s);
      rethrow;
    }
  }

  /// [deleteChildProfile] 아동 프로필 삭제(하위 sleep_data 포함)
  /// [userId] 부모 ID
  /// [childId] 아동 ID
  Future<void> deleteChildProfile(String userId, String childId) async {
    try {
      final batch = _db.batch();
      final sleeps = await _sleepCol(userId, childId).get();
      for (final s in sleeps.docs) {
        batch.delete(s.reference);
      }
      batch.delete(_childrenCol(userId).doc(childId));
      await batch.commit();
    } on FirebaseException catch (e, s) {
      _log.severe('아이 프로필 삭제 실패', e, s);
      rethrow;
    }
  }

  /// [addSleepData] 수면 데이터 추가/병합 저장(upsert)
  /// [userId] 부모 ID
  /// [sleepData] 저장할 수면 데이터
  Future<String> addSleepData(String userId, SleepData sleepData) async {
    try {
      final docId = sleepData.docIdForDay();
      await _sleepCol(
        userId,
        sleepData.childId,
      ).doc(docId).set(sleepData.toFirestore(), SetOptions(merge: true));
      return docId;
    } on FirebaseException catch (e, s) {
      _log.severe('수면 데이터 추가 실패', e, s);
      rethrow;
    }
  }

  /// [updateSleepData] 수면 데이터 일부 필드 업데이트
  /// [userId] 부모 ID
  /// [childId] 아동 ID
  /// [sleepDataId] 수면 데이터 문서 ID
  /// [data] 업데이트할 맵
  Future<void> updateSleepData(
    String userId,
    String childId,
    String sleepDataId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _sleepDocRef(userId, childId, sleepDataId).update(data);
    } on FirebaseException catch (e, s) {
      _log.severe('수면 데이터 업데이트 실패', e, s);
      rethrow;
    }
  }

  /// [updateSleepTimes] 수면 시작/종료 시각 업데이트
  /// [userId] 부모 ID
  /// [childId] 아동 ID
  /// [sleepDataId] 수면 데이터 문서 ID
  /// [startTime] 시작 시각
  /// [endTime] 종료 시각
  Future<void> updateSleepTimes(
    String userId,
    String childId,
    String sleepDataId, {
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      await _sleepDocRef(userId, childId, sleepDataId).update({
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
      });
    } on FirebaseException catch (e, s) {
      _log.severe('수면 시간 업데이트 실패', e, s);
      rethrow;
    }
  }

  /// [setAnalysisAndCondition] 분석/아침 컨디션 저장
  /// [userId] 부모 ID
  /// [childId] 아동 ID
  /// [sleepDataId] 수면 데이터 문서 ID
  /// [analysis] 수면 분석
  /// [condition] 아침 컨디션(옵션)
  Future<void> setAnalysisAndCondition(
    String userId,
    String childId,
    String sleepDataId, {
    required SleepAnalysis analysis,
    MorningCondition? condition,
  }) async {
    try {
      final update = <String, dynamic>{'analysis': analysis.toJson()};
      if (condition != null) update['morningCondition'] = condition.name;
      await _sleepDocRef(userId, childId, sleepDataId).update(update);
    } on FirebaseException catch (e, s) {
      _log.severe('분석/컨디션 저장 실패', e, s);
      rethrow;
    }
  }

  /// [deleteSleepData] 수면 데이터 문서 삭제
  /// [userId] 부모 ID
  /// [childId] 아동 ID
  /// [sleepDataId] 문서 ID
  Future<void> deleteSleepData(
    String userId,
    String childId,
    String sleepDataId,
  ) async {
    try {
      await _sleepDocRef(userId, childId, sleepDataId).delete();
    } on FirebaseException catch (e, s) {
      _log.severe('수면 데이터 삭제 실패', e, s);
      rethrow;
    }
  }

  /// [getSleepDataById] ID로 수면 데이터 단건 조회(collectionGroup 사용)
  /// [userId] 부모 ID(소유자 확인 용도)
  /// [sleepDataId] 수면 데이터 문서 ID
  Future<SleepData?> getSleepDataById(
    String userId,
    String childId,
    String sleepDataId,
  ) async {
    try {
      final snap = await _sleepDocRef(userId, childId, sleepDataId).get();
      if (!snap.exists) return null;
      return SleepData.fromFirestore(snap);
    } on FirebaseException catch (e, s) {
      _log.severe('ID로 수면 데이터 조회 실패', e, s);
      rethrow;
    }
  }

  /// [getRecentSleepData] 특정 아동의 최근 수면 데이터를 가져옵니다.
  /// [userId] 부모 ID
  /// [childId] 아동 프로필 ID
  /// [limit] 가져올 데이터 개수
  Future<List<SleepData>> getRecentSleepData(
    String userId,
    String childId, {
    int limit = 30,
  }) async {
    try {
      final snap = await _sleepCol(
        userId,
        childId,
      ).orderBy('date', descending: true).limit(limit).get();
      return snap.docs.map((doc) => SleepData.fromFirestore(doc)).toList();
    } on FirebaseException catch (e, s) {
      _log.severe('기간별 수면 데이터 조회 실패', e, s);
      rethrow;
    }
  }

  /// [getSleepDataForPeriod] 기간 내 밤 수면 데이터 조회(최신 순)
  /// [userId] 부모 ID
  /// [childId] 아동 ID
  /// [startDate] 시작일(포함)
  /// [endDate] 종료일(포함)
  Future<List<SleepData>> getSleepDataForPeriod(
    String userId,
    String childId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snap = await _sleepCol(userId, childId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .where('sessionType', isEqualTo: SleepSessionType.night.name)
          .orderBy('date', descending: true)
          .get();
      return snap.docs.map(SleepData.fromFirestore).toList();
    } on FirebaseException catch (e, s) {
      _log.severe('기간별 수면 데이터 조회 실패', e, s);
      rethrow;
    }
  }

  /// [getSleepDataListForDate] 특정 날짜의 수면 데이터 조회(최신 시작 시각 순)
  /// [userId] 부모 ID
  /// [childId] 아동 ID
  /// [date] 대상 날짜
  Future<List<SleepData>> getSleepDataListForDate(
    String userId,
    String childId,
    DateTime date,
  ) async {
    try {
      final dayStart = DateTime(date.year, date.month, date.day);
      final nextDay = dayStart.add(
        const Duration(days: 1),
      ); // [dayStart, nextDay)

      final snap = await _sleepCol(userId, childId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
          .where('date', isLessThan: Timestamp.fromDate(nextDay))
          .orderBy('date') // 범위 필드 우선 정렬
          .get();

      final list = snap.docs.map(SleepData.fromFirestore).toList()
        ..sort((a, b) => b.startTime.compareTo(a.startTime)); // 최신 시작 시각 우선
      return list;
    } on FirebaseException catch (e, s) {
      _log.severe('일자별 수면 데이터 목록 조회 실패', e, s);
      rethrow;
    }
  }

  /// [getDreamContentStream] 카테고리별 꿈친구 콘텐츠 스트림(order 오름차순)
  /// [category] 컬렉션 이름(lullabies, fairy_tales 등)
  Stream<List<DreamContent>> getDreamContentStream(String category) {
    try {
      return _db
          .collection(category)
          .orderBy('order')
          .snapshots()
          .map((snap) => snap.docs.map(DreamContent.fromFirestore).toList());
    } on FirebaseException catch (e, s) {
      _log.severe('$category 콘텐츠 스트림 조회 실패', e, s);
      return Stream.error(e);
    }
  }

  /// [getDreamFriendsStream] 사용자의 꿈친구 목록 스트림
  /// [userId] 부모 ID
  Stream<List<DreamFriend>> getDreamFriendsStream(String userId) {
    try {
      final col = _userDoc(userId)
          .collection('dream_friends')
          .withConverter<DreamFriend>(
            fromFirestore: (snap, _) => DreamFriend.fromJson(snap.data()!),
            toFirestore: (f, _) => f.toJson(),
          );
      return col.snapshots().map(
        (snap) => snap.docs.map((d) => d.data()).toList(),
      );
    } on FirebaseException catch (e, s) {
      _log.severe('꿈친구 목록 스트림 조회 실패', e, s);
      return Stream.error(e);
    }
  }

  /// [setDreamFriend] 꿈친구 추가/수정
  /// [userId] 부모 ID
  /// [friend] 꿈친구 데이터
  Future<void> setDreamFriend(String userId, DreamFriend friend) async {
    try {
      await _userDoc(
        userId,
      ).collection('dream_friends').doc(friend.id).set(friend.toJson());
    } on FirebaseException catch (e, s) {
      _log.severe('꿈친구 저장 실패', e, s);
      rethrow;
    }
  }

  /// [deleteDreamFriend] 꿈친구 삭제
  /// [userId] 부모 ID
  /// [friendId] 꿈친구 ID
  Future<void> deleteDreamFriend(String userId, String friendId) async {
    try {
      await _userDoc(userId).collection('dream_friends').doc(friendId).delete();
    } on FirebaseException catch (e, s) {
      _log.severe('꿈친구 삭제 실패', e, s);
      rethrow;
    }
  }
}
