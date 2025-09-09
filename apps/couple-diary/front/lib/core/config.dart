class AppConfig {
  // 서버 주소만 바꾸면 됩니다.
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.202.230:5050',
  ); // 에뮬레이터/기기 환경에 맞게
}
