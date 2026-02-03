DateTime addFractionalYear(DateTime date, double year) {
  int wholeYears = year.floor();
  double fractionalPart = year - wholeYears;
  int daysToAdd = (fractionalPart * 365.25).round();
  
  return date.add(Duration(days: daysToAdd)).add(Duration(days: wholeYears * 365)).add(Duration(days: (wholeYears / 4).floor()));
}   

DateTime addYear(DateTime date, int yearToAdd) {
  // Create a new DateTime by adding years to the current date
  return DateTime(date.year + yearToAdd, date.month, date.day);
}

DateTime addMonth(DateTime date, int monthsToAdd) {
  // Add the months and adjust the year accordingly
  int newMonth = date.month + monthsToAdd;
  int newYear = date.year + (newMonth - 1) ~/ 12; // Adjust year if month exceeds 12
  newMonth = (newMonth - 1) % 12 + 1; // Keep month between 1 and 12
  
  return DateTime(newYear, newMonth, 1); // always say its first of month
}

double yearsBetween(DateTime start, DateTime end) {
  // Now calculate the exact number of years, including fractional years
  Duration duration = end.difference(start);
  double years = duration.inDays / 365.25; // Account for leap years by dividing by 365.25

  return years;
}

int monthsBetween(DateTime start, DateTime end) {
  // Calculate the difference in months
  int months = (end.year - start.year) * 12 + (end.month - start.month);
  return months;
}