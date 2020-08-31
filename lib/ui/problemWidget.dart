import 'package:cofoda/codeforcesAPI.dart';
import 'package:cofoda/model/problem.dart';
import 'package:cofoda/model/submissions.dart';
import 'package:flutter/material.dart';

Color problemStatusToColor(Data data, Problem problem, {int ratingLimit}) {
  final status = data.statusOfProblem(problem, ratingLimit: ratingLimit);
  return statusToColor(status);
}

Color statusToColor(ProblemStatus status) {
  switch (status) {
    case ProblemStatus.solvedLive:
      return Colors.green[500];
    case ProblemStatus.solvedVirtual:
      return Colors.green[300];
    case ProblemStatus.solvedPractice:
      return Colors.green[100];
    case ProblemStatus.tried:
      return Colors.red[200];
    case ProblemStatus.toUpSolve:
      return Colors.yellow[200];
    default:
      return Colors.grey[200];
  }
}

/* Rating colors palette:
  '#a50026', '#a70226', '#a90426', '#ab0626', '#ad0826', '#af0926', '#b10b26', '#b30d26', '#b50f26', '#b61127',
  '#b81327', '#ba1527', '#bc1727', '#be1927', '#c01b27', '#c21d28', '#c41f28', '#c52128', '#c72328', '#c92529',
  '#cb2729', '#cc2929', '#ce2b2a', '#d02d2a', '#d12f2b', '#d3312b', '#d4332c', '#d6352c', '#d7382d', '#d93a2e',
  '#da3c2e', '#dc3e2f', '#dd4030', '#de4331', '#e04532', '#e14733', '#e24a33', '#e34c34', '#e44e35', '#e55136',
  '#e75337', '#e85538', '#e95839', '#ea5a3a', '#eb5d3c', '#ec5f3d', '#ed613e', '#ed643f', '#ee6640', '#ef6941',
  '#f06b42', '#f16e43', '#f17044', '#f27346', '#f37547', '#f37848', '#f47a49', '#f57d4a', '#f57f4b', '#f6824d',
  '#f6844e', '#f7864f', '#f78950', '#f88b51', '#f88e53', '#f89054', '#f99355', '#f99556', '#f99858', '#fa9a59',
  '#fa9c5a', '#fa9f5b', '#fba15d', '#fba35e', '#fba660', '#fba861', '#fcaa62', '#fcad64', '#fcaf65', '#fcb167',
  '#fcb368', '#fcb56a', '#fdb86b', '#fdba6d', '#fdbc6e', '#fdbe70', '#fdc071', '#fdc273', '#fdc474', '#fdc676',
  '#fdc878', '#fdca79', '#fecc7b', '#fecd7d', '#fecf7e', '#fed180', '#fed382', '#fed584', '#fed685', '#fed887',
  '#feda89', '#fedb8b', '#fedd8d', '#fede8f', '#fee090', '#fee192', '#fee394', '#fee496', '#fee698', '#fee79a',
  '#fee89b', '#feea9d', '#feeb9f', '#feeca0', '#feeda2', '#feeea3', '#fdefa5', '#fdf0a6', '#fdf1a7', '#fdf2a9',
  '#fcf3aa', '#fcf4ab', '#fcf5ab', '#fbf5ac', '#fbf6ad', '#faf6ad', '#faf7ad', '#f9f7ae', '#f8f7ae', '#f7f8ad',
  '#f7f8ad', '#f6f8ad', '#f5f8ac', '#f4f8ab', '#f3f8ab', '#f1f8aa', '#f0f7a9', '#eff7a8', '#eef7a6', '#edf6a5',
  '#ebf6a4', '#eaf6a2', '#e8f5a1', '#e7f59f', '#e6f49d', '#e4f39c', '#e2f39a', '#e1f298', '#dff297', '#def195',
  '#dcf093', '#daef92', '#d9ef90', '#d7ee8e', '#d5ed8d', '#d3ec8b', '#d2ec89', '#d0eb88', '#ceea86', '#cce985',
  '#cae983', '#c8e882', '#c6e780', '#c4e67f', '#c2e57e', '#c0e47c', '#bee47b', '#bce37a', '#bae279', '#b8e178',
  '#b6e076', '#b4df75', '#b2de74', '#b0dd73', '#aedc72', '#acdb71', '#a9da70', '#a7d970', '#a5d86f', '#a3d86e',
  '#a0d76d', '#9ed66c', '#9cd56c', '#99d36b', '#97d26b', '#95d16a', '#92d069', '#90cf69', '#8ece68', '#8bcd68',
  '#89cc67', '#86cb67', '#84ca66', '#81c966', '#7fc866', '#7cc665', '#79c565', '#77c464', '#74c364', '#71c263',
  '#6fc063', '#6cbf62', '#69be62', '#67bd62', '#64bc61', '#61ba60', '#5eb960', '#5cb85f', '#59b65f', '#56b55e',
  '#53b45e', '#51b25d', '#4eb15c', '#4baf5c', '#48ae5b', '#46ad5a', '#43ab5a', '#40aa59', '#3da858', '#3ba757',
  '#38a557', '#36a456', '#33a255', '#31a154', '#2e9f54', '#2c9d53', '#2a9c52', '#289a51', '#259950', '#23974f',
  '#21954f', '#1f944e', '#1e924d', '#1c904c', '#1a8f4b', '#188d4a', '#178b49', '#158948', '#148747', '#128646',
  '#118446', '#108245', '#0e8044', '#0d7e43', '#0c7d42', '#0b7b41', '#0a7940', '#08773f', '#07753e', '#06733d',
  '#05713c', '#04703b', '#036e3a', '#026c39', '#016a38', '#006837'
*/

const Color _unratedColor = Colors.grey;
const Map<int, Color> _ratingColors = {
  3500: Color(0xFFA50026),
  3400: Color(0xFFB61127),
  3300: Color(0xFFC92529),
  3200: Color(0xFFD7382D),
  3100: Color(0xFFE44E35),
  3000: Color(0xFFED643F),
  2900: Color(0xFFF57d4A),
  2800: Color(0xFFF99355),
  2700: Color(0xFFFCAA62),
  2600: Color(0xFFFDBE70),
  2500: Color(0xFFFECF7E),
  2400: Color(0xFFFEE090),
  2300: Color(0xFFFEECA0),
  2200: Color(0xFFFBF5AC),
  2100: Color(0xFFF5F8AC),
  2000: Color(0xFFE8F5A1),
  1900: Color(0xFFDAEF92),
  1800: Color(0xFFC8E882),
  1700: Color(0xFFB6E076),
  1600: Color(0xFFA3D86E),
  1500: Color(0xFF8BCD68),
  1400: Color(0xFF74C364),
  1300: Color(0xFF59B65F),
  1200: Color(0xFF40AA59),
  1100: Color(0xFF289A51),
  1000: Color(0xFF178B49),
  900: Color(0xFF0A7940),
  800: Color(0xFF006837)
};

Color problemRatingToColor(Problem problem) => problem.rating != null ? _ratingColors[problem.rating] : _unratedColor;

class ProblemWidget extends StatelessWidget {
  final Problem problem;
  final Data data;

  ProblemWidget(this.data, this.problem);

  @override
  Widget build(BuildContext context) {
    final ratingColor = problemRatingToColor(problem);
    final textColor = ratingColor.computeLuminance() < 0.5 ? Colors.white : Colors.black;
    final id = Chip(
      label: Text('${problem.contestId}${problem.index}', style: TextStyle(color: textColor)),
      backgroundColor: ratingColor,
    );
    final tagsText = problem.tags.isEmpty ? '' : '(${problem.tags.join(', ')})';
    final tags = Text(tagsText, overflow: TextOverflow.ellipsis);
    final title = Text(problem.name);
    final card = Card(
      child: ListTile(leading: id, title: title, subtitle: tags),
      color: problemStatusToColor(data, problem),
    );
    return GestureDetector(onTap: () => problem.open(), child: card);
  }
}
