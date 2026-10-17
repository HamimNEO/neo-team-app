import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/department.dart';

extension DepartmentPresentation on DepartmentItem {
  Color get iconColor => AppColors.brandLight;

  String get subtitle => [
        if (code != null) code!,
        if (leadName != null) 'Lead: $leadName',
        if (memberCount != null) '$memberCount members',
        if (teamCount != null)
          '$teamCount ${teamCount == 1 ? 'team' : 'teams'}',
        if (status != null) status!,
      ].join(' · ');
}
