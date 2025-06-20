import 'dart:math';

class GreetingHelper {
  static final List<String> _greetings = [
    'Still Here!',
    'Been Waiting!',
    'Hi There!',
    'Beep Boop!',
  ];

  static String getRandomGreeting() {
    final random = Random();
    return _greetings[random.nextInt(_greetings.length)];
  }
}
