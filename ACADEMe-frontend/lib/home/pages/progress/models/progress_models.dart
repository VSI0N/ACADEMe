import 'package:flutter/cupertino.dart';

import '../../../../localization/l10n.dart';

class ProgressHelpers {
  static String getLetterGrade(BuildContext context, double score) {
    if (score >= 90) return "A++";
    if (score >= 80) return "A+";
    if (score >= 70) return "A";
    if (score >= 60) return "B+";
    if (score >= 50) return "B";
    if (score >= 40) return "C";
    if (score == 0) {
      return "${L10n.getTranslatedText(context, 'Start your')}\n${L10n.getTranslatedText(context, 'Journey')}";
    }
    return "F";
  }

  static String getMotivationMessage(BuildContext context, double score) {
    if (score >= 90) return L10n.getTranslatedText(context, 'Outstanding! Keep shining!');
    if (score >= 80) return L10n.getTranslatedText(context, 'Excellent job! Almost perfect!');
    if (score >= 70) return L10n.getTranslatedText(context, 'Great work! Keep pushing!');
    if (score >= 60) return L10n.getTranslatedText(context, 'Good effort! You can do better!');
    if (score >= 50) return L10n.getTranslatedText(context, 'Keep trying! Progress is progress!');
    if (score >= 40) return L10n.getTranslatedText(context, 'Don’t give up! Keep learning!');
    if (score == 0) return L10n.getTranslatedText(context, 'It\'s time to start your journey!');
    return L10n.getTranslatedText(context, 'Failure is the first step to success!');
  }
}