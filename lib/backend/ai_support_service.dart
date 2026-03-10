import 'package:google_generative_ai/google_generative_ai.dart';
import '../app_state.dart';
import 'api_requests/api_calls.dart';
import '../core/app_config.dart';

class AiSupportService {
  static final AiSupportService _instance = AiSupportService._internal();
  factory AiSupportService() => _instance;
  AiSupportService._internal();

  GenerativeModel? _model;
  
  // Note: In a production app, this should be fetched from remote config or a secure backend.
  static const String _geminiApiKey = AppConfig.geminiApiKey; 

  void _initModel(String systemInstruction) {
    _model = GenerativeModel(
      model: 'gemini-flash-latest',
      apiKey: _geminiApiKey,
      systemInstruction: Content.system(systemInstruction),
    );
  }

  Future<String> generateResponse(String userMessage) async {
    try {
      final context = await _getUnifiedContext();
      _initModel(context);

      final prompt = [Content.text(userMessage)];
      final response = await _model?.generateContent(prompt);
      
      return response?.text ?? "I'm sorry, I couldn't generate a response. Please try again later.";
    } catch (e) {
      return "I'm having trouble connecting to my brain right now. Please try again in a bit! (Error: ${e.toString()})";
    }
  }

  Future<String> _getUnifiedContext() async {
    final appState = FFAppState();
    final userId = appState.userid;
    final token = appState.accessToken;

    if (userId == 0) return "User is not logged in. Be helpful but generic.";

    // 1. Fetch User Profile
    String userName = "User";
    try {
      final userRes = await GetUserDetailsCall.call(userId: userId, token: token);
      if (userRes.succeeded) {
        userName = GetUserDetailsCall.firstName(userRes.jsonBody) ?? "User";
      }
    } catch (_) {}

    // 2. Fetch Ride History
    String rideContext = "No recent rides found.";
    try {
      final historyRes = await GetRideHistoryCall.call(userId: userId, token: token);
      if (historyRes.succeeded) {
        final rides = GetRideHistoryCall.rides(historyRes.jsonBody);
        if (rides != null && rides.isNotEmpty) {
          final lastRides = rides.take(3).map((r) {
            return "Ride ID: ${r['ride_id']}, Status: ${r['status']}, From: ${r['from_location']}, To: ${r['to_location']}, Amount: ${r['amount']}, Date: ${r['date']}";
          }).join("\n");
          rideContext = "Last 3 rides:\n$lastRides";
        }
      }
    } catch (_) {}

    // 3. Fetch Scheduled Rides
    String scheduledContext = "No upcoming scheduled rides.";
    try {
      final scheduledRes = await GetScheduledRidesCall.call(userId: userId, token: token);
      if (scheduledRes.succeeded) {
        final rides = GetScheduledRidesCall.rides(scheduledRes.jsonBody);
        if (rides != null && rides.isNotEmpty) {
          scheduledContext = "Scheduled rides:\n" + rides.take(2).map((r) => "Date: ${r['scheduled_at']}, To: ${r['drop_location_address']}").join("\n");
        }
      }
    } catch (_) {}

    // 4. Fetch Active Vouchers
    String voucherContext = "No active vouchers available.";
    try {
      final vouchersRes = await GetAllVouchersCall.call(token: token);
      if (vouchersRes.succeeded) {
        final data = GetAllVouchersCall.data(vouchersRes.jsonBody);
        if (data != null && data.isNotEmpty) {
          voucherContext = "Available Promo Codes: " + data.take(3).map((v) => v['promo_code']).join(", ");
        }
      }
    } catch (_) {}

    // 3. App State Context
    final currentRideId = appState.currentRideId;
    final walletBalance = appState.walletBalance;
    final currentRideInfo = currentRideId != null ? "Currently in a ride (ID: $currentRideId)." : "No active ride.";

    return """
You are UGO AI Support, a highly capable and intelligent assistant for the UGO Taxi & Parcel app.
You have access to the user's real-time data and knowledge of the system's full API capabilities.

USER CONTEXT:
- Name: $userName
- User ID: $userId
- Wallet Balance: ₹$walletBalance
- Current Ride Status: $currentRideInfo
- History Context: $rideContext
- Scheduled Context: $scheduledContext
- Voucher Context: $voucherContext

SYSTEM CAPABILITIES (What you can facilitate via instructions):
1. RIDE MANAGEMENT:
   - Create rides (Automated booking flow)
   - Cancel rides (Use CancelRide API - requires ride ID and reason)
   - Rebook rides (Use RebookRideCall - for previously cancelled trips)
   - Estimate fares (Google Directions based)
2. SUPPORT & SAFETY:
   - Emergency SOS (Immediate response via EmergencySosCall)
   - Support Tickets (CreateSupportTicketCall for formal complaints)
   - Item Recovery (Help with "Lost item" logic)
3. PAYMENTS & FEEDBACK:
   - Add Tips (AddTipToRideCall for completed trips)
   - Submit Ratings (SubmitRideRatingCall for drivers)
   - Promo Codes (GetAllVouchersCall to see active discounts)

GUIDELINES:
- Be empathetic, premium, and concise. Your goal is instant resolution.
- If a user has a specific ride issue, always mention the Ride ID (e.g., #76).
- For safety issues, prioritize SOS instructions immediately.
- If you cannot resolve something automatically, tell the user you are "raising a support ticket" (referencing CreateSupportTicketCall).
- Use the provided context to answer precisely. Do not hallucinate data.
""";
  }
}
