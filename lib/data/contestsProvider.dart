import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cofoda/model/contest.dart';

class ContestsProvider {
  static Stream<List<Contest>> stream() {
    return FirebaseFirestore.instance
        .collection('contests')
        .orderBy('startTimeSeconds', descending: true)
        .snapshots()
        .map((event) => event.docs.map((c) => Contest.fromFire(c)).toList());
  }
}
