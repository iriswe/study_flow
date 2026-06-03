class ApiConstants {
  static const String baseUrl = 'http://localhost:8080/api';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';

  // Goals
  static const String goals = '/goals';

  // Tasks
  static const String tasks = '/tasks';

  // Study Logs
  static const String studyLogs = '/study-logs';

  // Reviews
  static const String reviews = '/reviews';
  static const String todayReviews = '/reviews/today';
  static const String reviewStats = '/reviews/stats';

  // Stats
  static const String statsOverview = '/stats/overview';
  static const String statsLearning = '/stats/learning';
  static const String statsReview = '/stats/review';

  // Focus
  static const String focus = '/focus';
  static const String focusToday = '/focus/today';
  static const String focusTodayDuration = '/focus/today-duration';

  // Settings
  static const String settings = '/settings';
  static const String settingsSync = '/settings/sync';

  // Upload
  static const String uploadImage = '/upload/image';
  static const String presignedUrl = '/upload/presigned-url';

  // Health
  static const String health = '/health';
}

class StorageKeys {
  static const String accessToken = 'access_token';
  static const String userId = 'user_id';
  static const String username = 'username';
  static const String theme = 'theme';
}

class AppConstants {
  static const String appName = 'StudyFlow';
  static const int defaultPageSize = 20;
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;
}