import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cofoda/model/contest.dart';
import 'package:cofoda/model/contestList.dart';

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
