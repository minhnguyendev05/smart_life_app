import 'package:intl/intl.dart';

class Formatters {
  static final _currency = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'VND ',
    decimalDigits: 0,
  );

  static final _day = DateFormat('dd/MM HH:mm');

  static String currency(num value) => _currency.format(value);

  static String dayTime(DateTime value) => _day.format(value);
}
