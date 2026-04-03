/// Referral / reward coins applied as ride discount (not withdrawable bank cash).
/// Fixed rate used across app and backend: **10 coins = ₹1** off fare.
abstract final class CoinWalletInr {
  static const int coinsPerRupee = 10;

  /// Whole-coin balance → rupee value at fixed rate.
  static double toInr(int coins) {
    final c = coins < 0 ? 0 : coins;
    return c / coinsPerRupee;
  }

  static String formatInrLabel(int coins) =>
      '₹${toInr(coins).toStringAsFixed(2)}';

  static String rateCaption() => '10 coins = ₹1';
}
