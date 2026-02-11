import 'package:ugouser/backend/api_requests/api_calls.dart';

import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'wallet_model.dart';
export 'wallet_model.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
/// Wallet Management Interface
class WalletWidget extends StatefulWidget {
  const WalletWidget({super.key});

  static String routeName = 'Wallet';
  static String routePath = '/wallet';

  @override
  State<WalletWidget> createState() => _WalletWidgetState();
}

class _WalletWidgetState extends State<WalletWidget> {
  late WalletModel _model;
  final TextEditingController _amountController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();


  final scaffoldKey = GlobalKey<ScaffoldState>();
late Razorpay _razorpay;


  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => WalletModel());
      _razorpay = Razorpay();

    _razorpay.on(
      Razorpay.EVENT_PAYMENT_SUCCESS,
      _handlePaymentSuccess,
    );

    _razorpay.on(
      Razorpay.EVENT_PAYMENT_ERROR,
      _handlePaymentError,
    );
    _loadWallet(); 

  }

  
  Future<void> _loadWallet() async {
  final response = await GetwalletCall.call(
    userId: FFAppState().userid,
    token: FFAppState().accessToken,
  );

  if (response.succeeded) {
    final balanceString =
        GetwalletCall.walletBalance(response.jsonBody);

    final double balance =
        double.tryParse(balanceString ?? "0") ?? 0.0;

    setState(() {
      FFAppState().walletBalance = balance;
    });
  }
}

void _openRazorpay(double amount) {
    var options = {
      'key': 'rzp_test_SAvHgTPEoPnNo7',
      'amount': (amount * 100).toInt(), // in paise
      'name': 'Ugo App',
      'description': 'Wallet Recharge',
      'prefill': {
        'contact': '9885881832',
        'email': 'test@email.com',
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint("Razorpay Error: $e");
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response)async {
   
  final amount = double.tryParse(_amountController.text.trim());
  if (amount == null) return;

  final apiResponse = await AddMoneyToWalletCall.call(
    userId: FFAppState().userid,
    amount: amount,
    token: FFAppState().accessToken,
  );

  if (AddMoneyToWalletCall.success(apiResponse.jsonBody) == true) {
    final balanceString =
    AddMoneyToWalletCall.walletBalance(apiResponse.jsonBody);

final double balance =
    double.tryParse(balanceString ?? "0") ?? 0.0;


    setState(() {
      FFAppState().walletBalance = balance;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Wallet Updated: ₹$balance")),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Wallet update failed")),
    );
  }


    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Successful")),
    );

    // TODO: Update Wallet Balance in Firestore
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Failed")),
    );
  }
  @override
  void dispose() {
      _razorpay.clear();
      _amountController.dispose();
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primary,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 60.0,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 30.0,
            ),
            onPressed: () async {
              context.pop();
            },
          ),
          title: Text(
            FFLocalizations.of(context).getText(
              '8bs46fqf' /* Wallet */,
            ),
            style: FlutterFlowTheme.of(context).titleLarge.override(
                  font: GoogleFonts.interTight(
                    fontWeight: FontWeight.w500,
                    fontStyle:
                        FlutterFlowTheme.of(context).titleLarge.fontStyle,
                  ),
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  fontSize: 16.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w500,
                  fontStyle: FlutterFlowTheme.of(context).titleLarge.fontStyle,
                ),
          ),
          actions: [],
          centerTitle: true,
          elevation: 2.0,
        ),
        body: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: InkWell(
                    splashColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () async {
                      context.pushNamed(BalanceWidget.routeName);
                    },
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: Color(0xFFFF7B10),
                          width: 2.0,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  FFLocalizations.of(context).getText(
                                    '7idwe1xc' /* Ugo cash */,
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .titleLarge
                                      .override(
                                        font: GoogleFonts.interTight(
                                          fontWeight: FontWeight.w500,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleLarge
                                                  .fontStyle,
                                        ),
                                        color: FlutterFlowTheme.of(context)
                                            .accent1,
                                        fontSize: 20.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleLarge
                                            .fontStyle,
                                      ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Text(
                                      "₹ ${FFAppState().walletBalance.toStringAsFixed(2)}",
                                      style: FlutterFlowTheme.of(context)
                                          .titleLarge
                                          .override(
                                            font: GoogleFonts.interTight(
                                              fontWeight: FontWeight.w500,
                                            ),
                                            color: FlutterFlowTheme.of(context).accent1,
                                            fontSize: 20.0,
                                          ),
                                    ),

                                    // InkWell(
                                    //   splashColor: Colors.transparent,
                                    //   focusColor: Colors.transparent,
                                    //   hoverColor: Colors.transparent,
                                    //   highlightColor: Colors.transparent,
                                    //   onTap: () async {
                                    //     context
                                    //         .pushNamed(BalanceWidget.routeName);
                                    //   },
                                    //   child: Icon(
                                    //     Icons.chevron_right,
                                    //     color: FlutterFlowTheme.of(context)
                                    //         .accent1,
                                    //     size: 20.0,
                                    //   ),
                                    // ),
                                  ].divide(SizedBox(width: 8.0)),
                                ),
                              ],
                            ),
                            Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _amountController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: "Enter Amount",
                                    prefixIcon: Icon(Icons.currency_rupee),
                                    filled: true,
                                    fillColor: Color(0xFFF5F5F5),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please enter amount";
                                    }
                                    final amount = double.tryParse(value);
                                    if (amount == null || amount <= 0) {
                                      return "Enter valid amount";
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 12),

                                /// ADD AMOUNT BUTTON
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: FlutterFlowTheme.of(context).primary,
                                    minimumSize: Size(double.infinity, 48),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () async {
                                    if (_formKey.currentState!.validate()) {
                                      double amount =
                                          double.parse(_amountController.text.trim());

                                      _openRazorpay(amount);
                                    }
                                  },
                                  child: Text(
                                    "Add Amount",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          ].divide(SizedBox(height: 16.0)),
                        ),
                      ),
                    ),
                  ),
                ),
                // Column(
                //   mainAxisSize: MainAxisSize.max,
                //   crossAxisAlignment: CrossAxisAlignment.start,
                //   children: [
                //     Text(
                //       FFLocalizations.of(context).getText(
                //         'ktxa402r' /* Payment methods */,
                //       ),
                //       style: FlutterFlowTheme.of(context).titleMedium.override(
                //             font: GoogleFonts.interTight(
                //               fontWeight: FontWeight.w500,
                //               fontStyle: FlutterFlowTheme.of(context)
                //                   .titleMedium
                //                   .fontStyle,
                //             ),
                //             color: FlutterFlowTheme.of(context).accent1,
                //             fontSize: 16.0,
                //             letterSpacing: 0.0,
                //             fontWeight: FontWeight.w500,
                //             fontStyle: FlutterFlowTheme.of(context)
                //                 .titleMedium
                //                 .fontStyle,
                //           ),
                //     ),
                //     Column(
                //       mainAxisSize: MainAxisSize.max,
                //       children: [
                //         Row(
                //           mainAxisSize: MainAxisSize.max,
                //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //           crossAxisAlignment: CrossAxisAlignment.center,
                //           children: [
                //             Row(
                //               mainAxisSize: MainAxisSize.max,
                //               children: [
                //                 Icon(
                //                   Icons.qr_code_scanner,
                //                   color: Color(0xFF756F6F),
                //                   size: 20.0,
                //                 ),
                //                 Text(
                //                   FFLocalizations.of(context).getText(
                //                     'oao5dvnw' /* Upi scan and pay */,
                //                   ),
                //                   style: FlutterFlowTheme.of(context)
                //                       .bodyMedium
                //                       .override(
                //                         font: GoogleFonts.inter(
                //                           fontWeight: FontWeight.normal,
                //                           fontStyle:
                //                               FlutterFlowTheme.of(context)
                //                                   .bodyMedium
                //                                   .fontStyle,
                //                         ),
                //                         color: Color(0xFF756F6F),
                //                         fontSize: 14.0,
                //                         letterSpacing: 0.0,
                //                         fontWeight: FontWeight.normal,
                //                         fontStyle: FlutterFlowTheme.of(context)
                //                             .bodyMedium
                //                             .fontStyle,
                //                       ),
                //                 ),
                //               ].divide(SizedBox(width: 12.0)),
                //             ),
                //             Icon(
                //               Icons.chevron_right,
                //               color: FlutterFlowTheme.of(context).accent1,
                //               size: 20.0,
                //             ),
                //           ],
                //         ),
                //         Divider(
                //           height: 1.0,
                //           thickness: 1.0,
                //           color: Color(0xFFD9D9D9),
                //         ),
                //         Row(
                //           mainAxisSize: MainAxisSize.max,
                //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //           crossAxisAlignment: CrossAxisAlignment.center,
                //           children: [
                //             Row(
                //               mainAxisSize: MainAxisSize.max,
                //               children: [
                //                 Icon(
                //                   Icons.attach_money,
                //                   color: Color(0xFF756F6F),
                //                   size: 20.0,
                //                 ),
                //                 Text(
                //                   FFLocalizations.of(context).getText(
                //                     'mcje350w' /* Cash */,
                //                   ),
                //                   style: FlutterFlowTheme.of(context)
                //                       .bodyMedium
                //                       .override(
                //                         font: GoogleFonts.inter(
                //                           fontWeight: FontWeight.normal,
                //                           fontStyle:
                //                               FlutterFlowTheme.of(context)
                //                                   .bodyMedium
                //                                   .fontStyle,
                //                         ),
                //                         color: Color(0xFF756F6F),
                //                         fontSize: 16.0,
                //                         letterSpacing: 0.0,
                //                         fontWeight: FontWeight.normal,
                //                         fontStyle: FlutterFlowTheme.of(context)
                //                             .bodyMedium
                //                             .fontStyle,
                //                       ),
                //                 ),
                //               ].divide(SizedBox(width: 12.0)),
                //             ),
                //             Icon(
                //               Icons.chevron_right,
                //               color: FlutterFlowTheme.of(context).accent1,
                //               size: 20.0,
                //             ),
                //           ],
                //         ),
                //         Divider(
                //           height: 1.0,
                //           thickness: 1.0,
                //           color: Color(0xFFD9D9D9),
                //         ),
                //         Row(
                //           mainAxisSize: MainAxisSize.max,
                //           crossAxisAlignment: CrossAxisAlignment.center,
                //           children: [
                //             Icon(
                //               Icons.add,
                //               color: FlutterFlowTheme.of(context).accent1,
                //               size: 20.0,
                //             ),
                //             Padding(
                //               padding: EdgeInsetsDirectional.fromSTEB(
                //                   12.0, 0.0, 12.0, 0.0),
                //               child: Text(
                //                 FFLocalizations.of(context).getText(
                //                   'zsnn2w5x' /* Add payment method */,
                //                 ),
                //                 style: FlutterFlowTheme.of(context)
                //                     .bodyMedium
                //                     .override(
                //                       font: GoogleFonts.inter(
                //                         fontWeight: FontWeight.normal,
                //                         fontStyle: FlutterFlowTheme.of(context)
                //                             .bodyMedium
                //                             .fontStyle,
                //                       ),
                //                       color:
                //                           FlutterFlowTheme.of(context).accent1,
                //                       fontSize: 14.0,
                //                       letterSpacing: 0.0,
                //                       fontWeight: FontWeight.normal,
                //                       fontStyle: FlutterFlowTheme.of(context)
                //                           .bodyMedium
                //                           .fontStyle,
                //                     ),
                //               ),
                //             ),
                //           ],
                //         ),
                //       ].divide(SizedBox(height: 8.0)),
                //     ),
                //   ].divide(SizedBox(height: 16.0)),
                // ),
                // Column(
                //   mainAxisSize: MainAxisSize.max,
                //   crossAxisAlignment: CrossAxisAlignment.start,
                //   children: [
                //     Text(
                //       FFLocalizations.of(context).getText(
                //         'vo9mscox' /* Rides profiles */,
                //       ),
                //       style: FlutterFlowTheme.of(context).titleMedium.override(
                //             font: GoogleFonts.interTight(
                //               fontWeight: FontWeight.w500,
                //               fontStyle: FlutterFlowTheme.of(context)
                //                   .titleMedium
                //                   .fontStyle,
                //             ),
                //             color: FlutterFlowTheme.of(context).accent1,
                //             fontSize: 16.0,
                //             letterSpacing: 0.0,
                //             fontWeight: FontWeight.w500,
                //             fontStyle: FlutterFlowTheme.of(context)
                //                 .titleMedium
                //                 .fontStyle,
                //           ),
                //     ),
                //     Column(
                //       mainAxisSize: MainAxisSize.max,
                //       children: [
                //         Row(
                //           mainAxisSize: MainAxisSize.max,
                //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //           crossAxisAlignment: CrossAxisAlignment.center,
                //           children: [
                //             Row(
                //               mainAxisSize: MainAxisSize.max,
                //               children: [
                //                 Icon(
                //                   Icons.person,
                //                   color: Color(0xFF948C8C),
                //                   size: 20.0,
                //                 ),
                //                 Text(
                //                   FFLocalizations.of(context).getText(
                //                     'ksdpgb8i' /* Personal */,
                //                   ),
                //                   style: FlutterFlowTheme.of(context)
                //                       .bodyMedium
                //                       .override(
                //                         font: GoogleFonts.inter(
                //                           fontWeight: FontWeight.normal,
                //                           fontStyle:
                //                               FlutterFlowTheme.of(context)
                //                                   .bodyMedium
                //                                   .fontStyle,
                //                         ),
                //                         color: Color(0xFF948C8C),
                //                         fontSize: 14.0,
                //                         letterSpacing: 0.0,
                //                         fontWeight: FontWeight.normal,
                //                         fontStyle: FlutterFlowTheme.of(context)
                //                             .bodyMedium
                //                             .fontStyle,
                //                       ),
                //                 ),
                //               ].divide(SizedBox(width: 12.0)),
                //             ),
                //             Icon(
                //               Icons.chevron_right,
                //               color: FlutterFlowTheme.of(context).accent1,
                //               size: 20.0,
                //             ),
                //           ],
                //         ),
                //         Divider(
                //           height: 1.0,
                //           thickness: 1.0,
                //           color: Color(0xFFD9D9D9),
                //         ),
                //         Row(
                //           mainAxisSize: MainAxisSize.max,
                //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //           crossAxisAlignment: CrossAxisAlignment.center,
                //           children: [
                //             Row(
                //               mainAxisSize: MainAxisSize.max,
                //               children: [
                //                 Icon(
                //                   Icons.business,
                //                   color: Color(0xFF948C8C),
                //                   size: 20.0,
                //                 ),
                //                 Text(
                //                   FFLocalizations.of(context).getText(
                //                     'qnqo8992' /* Starting using Ugo for busines... */,
                //                   ),
                //                   style: FlutterFlowTheme.of(context)
                //                       .bodyMedium
                //                       .override(
                //                         font: GoogleFonts.inter(
                //                           fontWeight: FontWeight.normal,
                //                           fontStyle:
                //                               FlutterFlowTheme.of(context)
                //                                   .bodyMedium
                //                                   .fontStyle,
                //                         ),
                //                         color: Color(0xFF948C8C),
                //                         fontSize: 14.0,
                //                         letterSpacing: 0.0,
                //                         fontWeight: FontWeight.normal,
                //                         fontStyle: FlutterFlowTheme.of(context)
                //                             .bodyMedium
                //                             .fontStyle,
                //                       ),
                //                 ),
                //               ].divide(SizedBox(width: 12.0)),
                //             ),
                //             Icon(
                //               Icons.chevron_right,
                //               color: FlutterFlowTheme.of(context).accent1,
                //               size: 20.0,
                //             ),
                //           ],
                //         ),
                //       ].divide(SizedBox(height: 8.0)),
                //     ),
                //   ].divide(SizedBox(height: 16.0)),
                // ),
                // Column(
                //   mainAxisSize: MainAxisSize.max,
                //   crossAxisAlignment: CrossAxisAlignment.start,
                //   children: [
                //     Text(
                //       FFLocalizations.of(context).getText(
                //         'hk03dlx6' /* Shared with you */,
                //       ),
                //       style: FlutterFlowTheme.of(context).titleMedium.override(
                //             font: GoogleFonts.interTight(
                //               fontWeight: FontWeight.w500,
                //               fontStyle: FlutterFlowTheme.of(context)
                //                   .titleMedium
                //                   .fontStyle,
                //             ),
                //             color: FlutterFlowTheme.of(context).accent1,
                //             fontSize: 16.0,
                //             letterSpacing: 0.0,
                //             fontWeight: FontWeight.w500,
                //             fontStyle: FlutterFlowTheme.of(context)
                //                 .titleMedium
                //                 .fontStyle,
                //           ),
                //     ),
                //     Row(
                //       mainAxisSize: MainAxisSize.max,
                //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //       crossAxisAlignment: CrossAxisAlignment.center,
                //       children: [
                //         Row(
                //           mainAxisSize: MainAxisSize.max,
                //           children: [
                //             Icon(
                //               Icons.people,
                //               color: Color(0xFF948C8C),
                //               size: 20.0,
                //             ),
                //             Text(
                //               FFLocalizations.of(context).getText(
                //                 '5iatkiuw' /* Manage business rides for othe... */,
                //               ),
                //               style: FlutterFlowTheme.of(context)
                //                   .bodyMedium
                //                   .override(
                //                     font: GoogleFonts.inter(
                //                       fontWeight: FontWeight.normal,
                //                       fontStyle: FlutterFlowTheme.of(context)
                //                           .bodyMedium
                //                           .fontStyle,
                //                     ),
                //                     color: Color(0xFF948C8C),
                //                     fontSize: 14.0,
                //                     letterSpacing: 0.0,
                //                     fontWeight: FontWeight.normal,
                //                     fontStyle: FlutterFlowTheme.of(context)
                //                         .bodyMedium
                //                         .fontStyle,
                //                   ),
                //             ),
                //           ].divide(SizedBox(width: 12.0)),
                //         ),
                //         Icon(
                //           Icons.chevron_right,
                //           color: FlutterFlowTheme.of(context).accent1,
                //           size: 20.0,
                //         ),
                //       ],
                //     ),
                //   ].divide(SizedBox(height: 16.0)),
                // ),
                // Column(
                //   mainAxisSize: MainAxisSize.max,
                //   crossAxisAlignment: CrossAxisAlignment.start,
                //   children: [
                //     Text(
                //       FFLocalizations.of(context).getText(
                //         'ijvyfwt8' /* Vouchers */,
                //       ),
                //       style: FlutterFlowTheme.of(context).titleMedium.override(
                //             font: GoogleFonts.interTight(
                //               fontWeight: FontWeight.w500,
                //               fontStyle: FlutterFlowTheme.of(context)
                //                   .titleMedium
                //                   .fontStyle,
                //             ),
                //             color: FlutterFlowTheme.of(context).accent1,
                //             fontSize: 16.0,
                //             letterSpacing: 0.0,
                //             fontWeight: FontWeight.w500,
                //             fontStyle: FlutterFlowTheme.of(context)
                //                 .titleMedium
                //                 .fontStyle,
                //           ),
                //     ),
                //     Column(
                //       mainAxisSize: MainAxisSize.max,
                //       children: [
                //         Row(
                //           mainAxisSize: MainAxisSize.max,
                //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //           crossAxisAlignment: CrossAxisAlignment.center,
                //           children: [
                //             Row(
                //               mainAxisSize: MainAxisSize.max,
                //               children: [
                //                 Icon(
                //                   Icons.card_giftcard,
                //                   color: Color(0xFF948C8C),
                //                   size: 20.0,
                //                 ),
                //                 Text(
                //                   FFLocalizations.of(context).getText(
                //                     'uy42yrs1' /* Vouchers */,
                //                   ),
                //                   style: FlutterFlowTheme.of(context)
                //                       .bodyMedium
                //                       .override(
                //                         font: GoogleFonts.inter(
                //                           fontWeight: FontWeight.normal,
                //                           fontStyle:
                //                               FlutterFlowTheme.of(context)
                //                                   .bodyMedium
                //                                   .fontStyle,
                //                         ),
                //                         color: Color(0xFF948C8C),
                //                         fontSize: 14.0,
                //                         letterSpacing: 0.0,
                //                         fontWeight: FontWeight.normal,
                //                         fontStyle: FlutterFlowTheme.of(context)
                //                             .bodyMedium
                //                             .fontStyle,
                //                       ),
                //                 ),
                //               ].divide(SizedBox(width: 12.0)),
                //             ),
                //             Row(
                //               mainAxisSize: MainAxisSize.max,
                //               children: [
                //                 Text(
                //                   FFLocalizations.of(context).getText(
                //                     '6sj8408l' /* 0 */,
                //                   ),
                //                   style: FlutterFlowTheme.of(context)
                //                       .bodyMedium
                //                       .override(
                //                         font: GoogleFonts.inter(
                //                           fontWeight: FontWeight.normal,
                //                           fontStyle:
                //                               FlutterFlowTheme.of(context)
                //                                   .bodyMedium
                //                                   .fontStyle,
                //                         ),
                //                         color: FlutterFlowTheme.of(context)
                //                             .accent1,
                //                         fontSize: 14.0,
                //                         letterSpacing: 0.0,
                //                         fontWeight: FontWeight.normal,
                //                         fontStyle: FlutterFlowTheme.of(context)
                //                             .bodyMedium
                //                             .fontStyle,
                //                       ),
                //                 ),
                //                 Icon(
                //                   Icons.chevron_right,
                //                   color: FlutterFlowTheme.of(context).accent1,
                //                   size: 20.0,
                //                 ),
                //               ].divide(SizedBox(width: 8.0)),
                //             ),
                //           ],
                //         ),
                //         Divider(
                //           height: 1.0,
                //           thickness: 1.0,
                //           color: Color(0xFFD9D9D9),
                //         ),
                //         Row(
                //           mainAxisSize: MainAxisSize.max,
                //           crossAxisAlignment: CrossAxisAlignment.center,
                //           children: [
                //             Icon(
                //               Icons.add,
                //               color: Color(0xFF948C8C),
                //               size: 20.0,
                //             ),
                //             Padding(
                //               padding: EdgeInsetsDirectional.fromSTEB(
                //                   12.0, 0.0, 12.0, 0.0),
                //               child: Text(
                //                 FFLocalizations.of(context).getText(
                //                   'i796wiq8' /* Add vouchers code */,
                //                 ),
                //                 style: FlutterFlowTheme.of(context)
                //                     .bodyMedium
                //                     .override(
                //                       font: GoogleFonts.inter(
                //                         fontWeight: FontWeight.normal,
                //                         fontStyle: FlutterFlowTheme.of(context)
                //                             .bodyMedium
                //                             .fontStyle,
                //                       ),
                //                       color: Color(0xFF948C8C),
                //                       fontSize: 14.0,
                //                       letterSpacing: 0.0,
                //                       fontWeight: FontWeight.normal,
                //                       fontStyle: FlutterFlowTheme.of(context)
                //                           .bodyMedium
                //                           .fontStyle,
                //                     ),
                //               ),
                //             ),
                //           ],
                //         ),
                //       ].divide(SizedBox(height: 8.0)),
                //     ),
                //   ].divide(SizedBox(height: 16.0)),
                // ),
                // Column(
                //   mainAxisSize: MainAxisSize.max,
                //   crossAxisAlignment: CrossAxisAlignment.start,
                //   children: [
                //     Text(
                //       FFLocalizations.of(context).getText(
                //         '9n8ry32v' /* Promotions */,
                //       ),
                //       style: FlutterFlowTheme.of(context).titleMedium.override(
                //             font: GoogleFonts.interTight(
                //               fontWeight: FontWeight.w500,
                //               fontStyle: FlutterFlowTheme.of(context)
                //                   .titleMedium
                //                   .fontStyle,
                //             ),
                //             color: FlutterFlowTheme.of(context).accent1,
                //             fontSize: 16.0,
                //             letterSpacing: 0.0,
                //             fontWeight: FontWeight.w500,
                //             fontStyle: FlutterFlowTheme.of(context)
                //                 .titleMedium
                //                 .fontStyle,
                //           ),
                //     ),
                //     Column(
                //       mainAxisSize: MainAxisSize.max,
                //       children: [
                //         Row(
                //           mainAxisSize: MainAxisSize.max,
                //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //           crossAxisAlignment: CrossAxisAlignment.center,
                //           children: [
                //             Row(
                //               mainAxisSize: MainAxisSize.max,
                //               children: [
                //                 Icon(
                //                   Icons.local_offer,
                //                   color: Color(0xFF948C8C),
                //                   size: 20.0,
                //                 ),
                //                 Text(
                //                   FFLocalizations.of(context).getText(
                //                     'gb7bjv1c' /* Promotions */,
                //                   ),
                //                   style: FlutterFlowTheme.of(context)
                //                       .bodyMedium
                //                       .override(
                //                         font: GoogleFonts.inter(
                //                           fontWeight: FontWeight.normal,
                //                           fontStyle:
                //                               FlutterFlowTheme.of(context)
                //                                   .bodyMedium
                //                                   .fontStyle,
                //                         ),
                //                         color: Color(0xFF948C8C),
                //                         fontSize: 14.0,
                //                         letterSpacing: 0.0,
                //                         fontWeight: FontWeight.normal,
                //                         fontStyle: FlutterFlowTheme.of(context)
                //                             .bodyMedium
                //                             .fontStyle,
                //                       ),
                //                 ),
                //               ].divide(SizedBox(width: 12.0)),
                //             ),
                //             Icon(
                //               Icons.chevron_right,
                //               color: FlutterFlowTheme.of(context).accent1,
                //               size: 20.0,
                //             ),
                //           ],
                //         ),
                //         Divider(
                //           height: 1.0,
                //           thickness: 1.0,
                //           color: Color(0xFFD9D9D9),
                //         ),
                //         Row(
                //           mainAxisSize: MainAxisSize.max,
                //           crossAxisAlignment: CrossAxisAlignment.center,
                //           children: [
                //             Icon(
                //               Icons.add,
                //               color: Color(0xFF948C8C),
                //               size: 20.0,
                //             ),
                //             Padding(
                //               padding: EdgeInsetsDirectional.fromSTEB(
                //                   12.0, 0.0, 12.0, 0.0),
                //               child: Text(
                //                 FFLocalizations.of(context).getText(
                //                   'ae6qnm0p' /* Add promo code */,
                //                 ),
                //                 style: FlutterFlowTheme.of(context)
                //                     .bodyMedium
                //                     .override(
                //                       font: GoogleFonts.inter(
                //                         fontWeight: FontWeight.normal,
                //                         fontStyle: FlutterFlowTheme.of(context)
                //                             .bodyMedium
                //                             .fontStyle,
                //                       ),
                //                       color: Color(0xFF948C8C),
                //                       fontSize: 14.0,
                //                       letterSpacing: 0.0,
                //                       fontWeight: FontWeight.normal,
                //                       fontStyle: FlutterFlowTheme.of(context)
                //                           .bodyMedium
                //                           .fontStyle,
                //                     ),
                //               ),
                //             ),
                //           ],
                //         ),
                //       ].divide(SizedBox(height: 8.0)),
                //     ),
                //   ].divide(SizedBox(height: 16.0)),
                // ),
                // Column(
                //   mainAxisSize: MainAxisSize.max,
                //   crossAxisAlignment: CrossAxisAlignment.start,
                //   children: [
                //     Text(
                //       FFLocalizations.of(context).getText(
                //         'gtwmsvor' /* Referrals */,
                //       ),
                //       style: FlutterFlowTheme.of(context).titleMedium.override(
                //             font: GoogleFonts.interTight(
                //               fontWeight: FontWeight.w500,
                //               fontStyle: FlutterFlowTheme.of(context)
                //                   .titleMedium
                //                   .fontStyle,
                //             ),
                //             color: FlutterFlowTheme.of(context).accent1,
                //             fontSize: 16.0,
                //             letterSpacing: 0.0,
                //             fontWeight: FontWeight.w500,
                //             fontStyle: FlutterFlowTheme.of(context)
                //                 .titleMedium
                //                 .fontStyle,
                //           ),
                //     ),
                //     Row(
                //       mainAxisSize: MainAxisSize.max,
                //       crossAxisAlignment: CrossAxisAlignment.center,
                //       children: [
                //         Icon(
                //           Icons.add,
                //           color: Color(0xFF948C8C),
                //           size: 20.0,
                //         ),
                //         Padding(
                //           padding: EdgeInsetsDirectional.fromSTEB(
                //               12.0, 0.0, 12.0, 0.0),
                //           child: Text(
                //             FFLocalizations.of(context).getText(
                //               'bqk65ixo' /* Add referral code */,
                //             ),
                //             style: FlutterFlowTheme.of(context)
                //                 .bodyMedium
                //                 .override(
                //                   font: GoogleFonts.inter(
                //                     fontWeight: FontWeight.normal,
                //                     fontStyle: FlutterFlowTheme.of(context)
                //                         .bodyMedium
                //                         .fontStyle,
                //                   ),
                //                   color: Color(0xFF948C8C),
                //                   fontSize: 14.0,
                //                   letterSpacing: 0.0,
                //                   fontWeight: FontWeight.normal,
                //                   fontStyle: FlutterFlowTheme.of(context)
                //                       .bodyMedium
                //                       .fontStyle,
                //                 ),
                //           ),
                //         ),
                //       ],
                //     ),
                //   ].divide(SizedBox(height: 16.0)),
                // ),
              ]
                  .divide(SizedBox(height: 24.0))
                  .addToStart(SizedBox(height: 16.0))
                  .addToEnd(SizedBox(height: 24.0)),
            ),
          ),
        ),
      ),
    );
  }
}