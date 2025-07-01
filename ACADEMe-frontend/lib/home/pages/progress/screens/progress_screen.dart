import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/home/pages/motivation_popup.dart';
import 'package:ACADEMe/localization/l10n.dart';
import '../controllers/progress_controller.dart';
import '../models/progress_models.dart';
import '../widgets/progress_activity.dart';
import '../widgets/progress_chart.dart';
import '../widgets/progress_course.dart';
import '../widgets/progress_summary.dart';

class ProgressScreen extends StatelessWidget {
  final ProgressController controller = ProgressController();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AcademeTheme.appColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            L10n.getTranslatedText(context, 'My Progress'),
            style: TextStyle(color: Colors.white, fontSize: 22),
          ),
          backgroundColor: AcademeTheme.appColor,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
        ),
        body: Padding(
          padding: const EdgeInsets.only(top: 0.0),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(26),
                      topRight: Radius.circular(26),
                    ),
                    border: Border.all(
                        color: const Color.fromARGB(0, 158, 158, 158),
                        width: 1),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(
                            top: 10,
                          bottom: 0,
                          right: 10,
                          left: 10
                        ),
                        child: StudyTimeCard(),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(73, 136, 189, 233),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(26),
                              topRight: Radius.circular(26),
                            ),
                            border: Border.all(
                                color: const Color.fromARGB(25, 16, 16, 16),
                                width: 1),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: EdgeInsets.only(
                                  top: 8,
                                    bottom: 4,
                                    left: 8,
                                  right: 8
                                ),
                                child: TabBar(
                                  labelColor: Colors.white,
                                  unselectedLabelColor: Colors.blueAccent,
                                  dividerColor: Colors.transparent,
                                  indicator: BoxDecoration(
                                    color: AcademeTheme.appColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  indicatorWeight: 0,
                                  indicatorPadding: EdgeInsets.zero,
                                  tabs: [
                                    Tab(
                                      child: SizedBox(
                                        width: 100,
                                        child: Center(
                                          child: Text(
                                            L10n.getTranslatedText(
                                                context, 'Summary'),
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Tab(
                                      child: SizedBox(
                                        width: 100,
                                        child: Center(
                                          child: Text(
                                            L10n.getTranslatedText(
                                                context, 'Progress'),
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Tab(
                                      child: SizedBox(
                                        width: 100,
                                        child: Center(
                                          child: Text(
                                            L10n.getTranslatedText(
                                                context, 'Activity'),
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(26),
                                      topRight: Radius.circular(26),
                                    ),
                                    border: Border.all(
                                        color: const Color.fromARGB(
                                            26, 16, 16, 16),
                                        width: 1),
                                  ),
                                  child: TabBarView(
                                    children: [
                                      SummarySection(controller: controller),
                                      CourseProgressSection(),
                                      ActivitySection(),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}