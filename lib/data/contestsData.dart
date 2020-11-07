import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashforces/model/contest.dart';
import 'package:dashforces/model/contestList.dart';

class ContestsProvider {
  static Stream<ContestList> stream() {
    return FirebaseFirestore.instance
        .collection('contests')
        .orderBy('startTimeSeconds', descending: true)
        .snapshots()
        .map((event) => event.docs.map((c) => Contest.fromFire(c)).toList())
        .map((contests) => ContestList(contests));
  }
}
