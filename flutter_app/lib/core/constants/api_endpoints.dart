class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'https://api.play-casino.app/api/v1';  // ✅ CORRECT';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String googleLogin = '/auth/google';

  // User
  static const String profile = '/user/profile';
  static const String updateProfile = '/user/profile';
  static const String uploadAvatar = '/user/avatar';

  // Wallet
  static const String walletBalance = '/wallet/balance';
  static const String deposit = '/wallet/deposit';
  static const String withdraw = '/wallet/withdraw';
  static const String transactions = '/wallet/transactions';

  // Tournaments
  static const String tournaments = '/tournaments';
  static const String tournamentDetails = '/tournaments/:id';
  static const String joinTournament = '/tournaments/:id/join';
  static const String tournamentResults = '/tournaments/:id/results';

  // Ludo
  static const String ludoMatches = '/ludo/matches';
  static const String ludoMatchDetails = '/ludo/matches/:matchId';
  static const String ludoResult = '/ludo/matches/:matchId/result';

  // Wagers
  static const String wagers = '/wagers';

  // Bonuses
  static const String bonuses = '/bonuses';
  static const String claimBonus = '/bonuses/:id/claim';

  // Leaderboard
  static const String leaderboard = '/leaderboard';

  // Referral
  static const String referral = '/referral';
  static const String referralStats = '/referral/stats';

  // Notifications
  static const String notifications = '/notifications';
  static const String markNotificationRead = '/notifications/:id/read';
  static const String fcmToken = '/notifications/fcm-token';

  // Free Fire Tournaments
  static const String freefireTournaments = '/freefire/tournaments';
  static const String freefireTournamentDetails = '/freefire/tournaments/:id';
  static const String freefireJoinTournament = '/freefire/tournaments/:id/join';
  static const String freefireCheckIn = '/freefire/tournaments/:id/checkin';
  static const String freefireRoomDetails = '/freefire/tournaments/:id/room';
  static const String freefireSubmitResult = '/freefire/tournaments/:id/result';

  // WebSocket namespaces
  static const String wsBaseUrl = 'wss://api.play-casino.app';  
  static const String wsLudoNamespace = '/ludo';
}
