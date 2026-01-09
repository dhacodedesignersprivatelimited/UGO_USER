import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocaleStorageKey = '__locale_key__';

class FFLocalizations {
  FFLocalizations(this.locale);

  final Locale locale;

  static FFLocalizations of(BuildContext context) =>
      Localizations.of<FFLocalizations>(context, FFLocalizations)!;

  static List<String> languages() => ['en', 'te', 'hi'];

  static late SharedPreferences _prefs;
  static Future initialize() async =>
      _prefs = await SharedPreferences.getInstance();
  static Future storeLocale(String locale) =>
      _prefs.setString(_kLocaleStorageKey, locale);
  static Locale? getStoredLocale() {
    final locale = _prefs.getString(_kLocaleStorageKey);
    return locale != null && locale.isNotEmpty ? createLocale(locale) : null;
  }

  String get languageCode => locale.toString();
  String? get languageShortCode =>
      _languagesWithShortCode.contains(locale.toString())
          ? '${locale.toString()}_short'
          : null;
  int get languageIndex => languages().contains(languageCode)
      ? languages().indexOf(languageCode)
      : 0;

  String getText(String key) =>
      (kTranslationsMap[key] ?? {})[locale.toString()] ?? '';

  String getVariableText({
    String? enText = '',
    String? teText = '',
    String? hiText = '',
  }) =>
      [enText, teText, hiText][languageIndex] ?? '';

  static const Set<String> _languagesWithShortCode = {
    'ar',
    'az',
    'ca',
    'cs',
    'da',
    'de',
    'dv',
    'en',
    'es',
    'et',
    'fi',
    'fr',
    'gr',
    'he',
    'hi',
    'hu',
    'it',
    'km',
    'ku',
    'mn',
    'ms',
    'no',
    'pt',
    'ro',
    'ru',
    'rw',
    'sv',
    'th',
    'uk',
    'vi',
  };
}

/// Used if the locale is not supported by GlobalMaterialLocalizations.
class FallbackMaterialLocalizationDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const FallbackMaterialLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => _isSupportedLocale(locale);

  @override
  Future<MaterialLocalizations> load(Locale locale) async =>
      SynchronousFuture<MaterialLocalizations>(
        const DefaultMaterialLocalizations(),
      );

  @override
  bool shouldReload(FallbackMaterialLocalizationDelegate old) => false;
}

/// Used if the locale is not supported by GlobalCupertinoLocalizations.
class FallbackCupertinoLocalizationDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => _isSupportedLocale(locale);

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      SynchronousFuture<CupertinoLocalizations>(
        const DefaultCupertinoLocalizations(),
      );

  @override
  bool shouldReload(FallbackCupertinoLocalizationDelegate old) => false;
}

class FFLocalizationsDelegate extends LocalizationsDelegate<FFLocalizations> {
  const FFLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => _isSupportedLocale(locale);

  @override
  Future<FFLocalizations> load(Locale locale) =>
      SynchronousFuture<FFLocalizations>(FFLocalizations(locale));

  @override
  bool shouldReload(FFLocalizationsDelegate old) => false;
}

Locale createLocale(String language) => language.contains('_')
    ? Locale.fromSubtags(
        languageCode: language.split('_').first,
        scriptCode: language.split('_').last,
      )
    : Locale(language);

bool _isSupportedLocale(Locale locale) {
  final language = locale.toString();
  return FFLocalizations.languages().contains(
    language.endsWith('_')
        ? language.substring(0, language.length - 1)
        : language,
  );
}

final kTranslationsMap = <Map<String, Map<String, String>>>[
  // UgIntro
  {
    'c2vapqgd': {
      'en': 'Your ride is just minutes away.',
      'hi': 'आपकी सवारी बस कुछ ही मिनटों की दूरी पर है।',
      'te': 'మీ రైడ్ కేవలం నిమిషాల దూరంలో ఉంది.',
    },
    'x61mmd2b': {
      'en': 'Request. Ride. Relax. Go anywhere in your city.',
      'hi': 'अनुरोध करें। सवारी करें। आराम करें। अपने शहर में कहीं भी जाएँ।',
      'te':
          'అభ్యర్థించండి. ప్రయాణించండి. విశ్రాంతి తీసుకోండి. మీ నగరంలో ఎక్కడికైనా వెళ్లండి.',
    },
    'euc38vm7': {
      'en': 'Get started',
      'hi': 'शुरू हो जाओ',
      'te': 'ప్రారంభించండి',
    },
    'ur7fzwga': {
      'en': 'Already have an account ? Sign up',
      'hi': 'क्या आपके पास पहले से खाता है? साइन अप करें',
      'te': 'ఇప్పటికే ఖాతా ఉందా? సైన్ అప్ చేయండి',
    },
    '88h4vryl': {
      'en': 'hjvkjbj',
      'hi': '',
      'te': '',
    },
  },
  // login
  {
    '0wqdgogt': {
      'en': 'Start your journey – enter your phone number',
      'hi': 'अपनी यात्रा शुरू करें - अपना फ़ोन नंबर दर्ज करें',
      'te': 'మీ ప్రయాణాన్ని ప్రారంభించండి - మీ ఫోన్ నంబర్‌ను నమోదు చేయండి',
    },
    'lu0ku0g6': {
      'en': 'We\'ll send you a code to verify your number',
      'hi': 'हम आपको आपका नंबर सत्यापित करने के लिए एक कोड भेजेंगे',
      'te': 'మీ నంబర్‌ను ధృవీకరించడానికి మేము మీకు ఒక కోడ్‌ను పంపుతాము.',
    },
    'kd9srmop': {
      'en': 'Phone number',
      'hi': 'फ़ोन नंबर',
      'te': 'ఫోన్ నంబర్',
    },
    '398um26d': {
      'en': 'ENTER YOUR NUMBER',
      'hi': 'अपना नंबर दर्ज करें',
      'te': 'మీ నంబర్‌ను నమోదు చేయండి',
    },
    'm21mv0lk': {
      'en': 'SEND OTP',
      'hi': 'ओटीपी भेजें',
      'te': 'OTP పంపండి',
    },
    'hczr77o0': {
      'en': 'or connect with',
      'hi': 'या से जुड़ें',
      'te': 'లేదా కనెక్ట్ అవ్వండి',
    },
    'mc86snxk': {
      'en': 'LOGIN',
      'hi': 'लॉग इन करें',
      'te': 'లాగిన్',
    },
  },
  // otpverification
  {
    'ujhimmtb': {
      'en': 'Enter the OTP to continue.',
      'hi': 'जारी रखने के लिए OTP दर्ज करें.',
      'te': 'కొనసాగించడానికి OTP ని నమోదు చేయండి.',
    },
    'xupvugn4': {
      'en': 'We\'ve sent you a 6-digit code – check your messages',
      'hi': 'हमने आपको एक 6-अंकीय कोड भेजा है - अपने संदेश देखें',
      'te': 'మేము మీకు 6-అంకెల కోడ్‌ను పంపాము – మీ సందేశాలను తనిఖీ చేయండి',
    },
    'f9214evl': {
      'en': 'RESEND OTP',
      'hi': 'OTP पुनः भेजें',
      'te': 'OTP ని మళ్ళీ పంపండి',
    },
    'k9o36d8i': {
      'en': 'VERIFY',
      'hi': 'सत्यापित करें',
      'te': 'ధృవీకరించండి',
    },
    'duko62qy': {
      'en': 'Verification',
      'hi': 'सत्यापन',
      'te': 'ధృవీకరణ',
    },
  },
  // detailspage
  {
    '690d37j0': {
      'en': 'Please enter your full name',
      'hi': 'कृपया अपना पूरा नाम दर्ज करें',
      'te': 'దయచేసి మీ పూర్తి పేరును నమోదు చేయండి.',
    },
    'vte8wcmh': {
      'en': 'First name',
      'hi': 'पहला नाम',
      'te': 'మొదటి పేరు',
    },
    '7bnk9lgl': {
      'en': '*',
      'hi': '*',
      'te': '*',
    },
    '49wr7pqt': {
      'en': 'Last name (optional)',
      'hi': 'अंतिम नाम (वैकल्पिक)',
      'te': 'ఇంటిపేరు (ఐచ్ఛికం)',
    },
    'wrm1qdfp': {
      'en': 'Email',
      'hi': 'पहला नाम',
      'te': 'మొదటి పేరు',
    },
    '2l4iyk5b': {
      'en': '*',
      'hi': '*',
      'te': '*',
    },
    'qn0zg6xk': {
      'en': 'Continue',
      'hi': 'जारी रखना',
      'te': 'కొనసాగించు',
    },
  },
  // privacypolicy
  {
    'xmkcjp48': {
      'en': 'Accept Terms & Review Privacy Notice',
      'hi': 'शर्तें स्वीकार करें और गोपनीयता सूचना की समीक्षा करें',
      'te': 'నిబంధనలను అంగీకరించి, గోప్యతా నోటీసును సమీక్షించండి',
    },
    '1hdp8y0l': {
      'en': 'By selecting \\\"I Agree\\\" below, I confirm that:',
      'hi':
          'नीचे \\\"मैं सहमत हूँ\\\" का चयन करके, मैं पुष्टि करता/करती हूँ कि:',
      'te':
          'కింద \\\"నేను అంగీకరిస్తున్నాను\\\" ఎంచుకోవడం ద్వారా, నేను వీటిని నిర్ధారిస్తున్నాను:',
    },
    'xsmpe8lc': {
      'en': 'I have read and agree to the Terms of Use',
      'hi': 'मैंने उपयोग की शर्तें पढ़ ली हैं और उनसे सहमत हूँ',
      'te': 'నేను ఉపయోగ నిబంధనలను చదివి అంగీకరిస్తున్నాను.',
    },
    'zt7g0lt1': {
      'en': 'I acknowledge the Privacy Notice',
      'hi': 'मैं गोपनीयता सूचना को स्वीकार करता/करती हूँ',
      'te': 'నేను గోప్యతా నోటీసును అంగీకరిస్తున్నాను',
    },
    'esk52694': {
      'en': 'I am at least 18 years of age',
      'hi': 'मैं कम से कम 18 साल का हूँ',
      'te': 'నాకు కనీసం 18 సంవత్సరాలు నిండి ఉండాలి.',
    },
    'i1uu17n2': {
      'en': 'Agree terms and conditions',
      'hi': 'नियम और शर्तों से सहमत हों',
      'te': 'నిబంధనలు మరియు షరతులను అంగీకరించండి',
    },
    'xxge13d3': {
      'en': 'Additional Information',
      'hi': 'अतिरिक्त जानकारी',
      'te': 'అదనపు సమాచారం',
    },
    'ma5k2a5l': {
      'en':
          '• Your data will be processed in accordance with our Privacy Policy',
      'hi': '• आपका डेटा हमारी गोपनीयता नीति के अनुसार संसाधित किया जाएगा',
      'te': '• మీ డేటా మా గోప్యతా విధానానికి అనుగుణంగా ప్రాసెస్ చేయబడుతుంది.',
    },
    'ap3gdbuv': {
      'en': '• You can withdraw consent at any time by contacting support',
      'hi': '• आप किसी भी समय सहायता टीम से संपर्क करके सहमति वापस ले सकते हैं',
      'te':
          '• మీరు మద్దతును సంప్రదించడం ద్వారా ఎప్పుడైనా సమ్మతిని ఉపసంహరించుకోవచ్చు',
    },
    'i0augwch': {
      'en': '• Terms may be updated periodically with notice',
      'hi': '• शर्तों को समय-समय पर सूचना के साथ अद्यतन किया जा सकता है',
      'te': '• నిబంధనలు కాలానుగుణంగా నోటీసుతో నవీకరించబడవచ్చు.',
    },
    '8bd4c5yq': {
      'en': 'Need help?',
      'hi': 'मदद की ज़रूरत है?',
      'te': 'సహాయం కావాలి?',
    },
    'gzvrni3c': {
      'en': 'Contact Support',
      'hi': 'समर्थन से संपर्क करें',
      'te': 'మద్దతును సంప్రదించండి',
    },
    'x4yfngl0': {
      'en': 'Continue',
      'hi': 'जारी रखना',
      'te': 'కొనసాగించు',
    },
  },
  // notification_allow
  {
    'ozvadmk6': {
      'en': 'Allow notifications to get exclusive U Go offers and updates!',
      'hi': 'अनन्य यू गो ऑफर और अपडेट प्राप्त करने के लिए सूचनाएं अनुमति दें!',
      'te':
          'ప్రత్యేకమైన U Go ఆఫర్‌లు మరియు నవీకరణలను పొందడానికి నోటిఫికేషన్‌లను అనుమతించండి!',
    },
    'la6cvp94': {
      'en': 'Allow',
      'hi': 'अनुमति दें',
      'te': 'అనుమతించు',
    },
    'v47crzl8': {
      'en': 'Skip',
      'hi': 'छोडना',
      'te': 'దాటవేయి',
    },
    '9ppvufp9': {
      'en': 'Allow notifications',
      'hi': '',
      'te': '',
    },
  },
  // location
  {
    'r0jmuvmm': {
      'en': 'Allow Location',
      'hi': 'स्थान की अनुमति दें',
      'te': 'స్థానాన్ని అనుమతించు',
    },
    'nqodqk44': {
      'en': 'Allow location to book your ride faster',
      'hi': 'स्थान को अपनी सवारी तेज़ी से बुक करने की अनुमति दें',
      'te': 'మీ రైడ్‌ను వేగంగా బుక్ చేసుకోవడానికి లొకేషన్‌ను అనుమతించండి',
    },
    'nk8owetj': {
      'en': 'Allow',
      'hi': 'अनुमति दें',
      'te': 'అనుమతించు',
    },
    'uskmg48m': {
      'en': 'Skip',
      'hi': 'छोडना',
      'te': 'దాటవేయి',
    },
  },
  // serviceoptions
  {
    'xlfqyvqa': {
      'en': 'Comfortable Rides, Anytime',
      'hi': 'आरामदायक सवारी, कभी भी',
      'te': 'సౌకర్యవంతమైన రైడ్‌లు, ఎప్పుడైనా',
    },
    'o76sscog': {
      'en': 'Book a bike',
      'hi': 'बाइक बुक करें',
      'te': 'బైక్ బుక్ చేసుకోండి',
    },
    'p3js2d3q': {
      'en': 'Book a auto',
      'hi': 'ऑटो बुक करें',
      'te': 'ఆటో బుక్ చేసుకోండి',
    },
    'a1vegvac': {
      'en': 'Book a Cab',
      'hi': 'कैब बुक करें',
      'te': 'క్యాబ్ బుక్ చేసుకోండి',
    },
    'rnwdwckb': {
      'en': 'Services',
      'hi': 'सेवाएं',
      'te': 'సేవలు',
    },
    'bi51z7ga': {
      'en': 'Home',
      'hi': 'घर',
      'te': 'హొమ్ పేజ్',
    },
    'ebo27o5n': {
      'en': 'Services',
      'hi': 'सेवाएं',
      'te': 'సేవలు',
    },
    '7d51nyn6': {
      'en': 'History',
      'hi': 'इतिहास',
      'te': 'చరిత్ర',
    },
    'av1fdhh2': {
      'en': 'Account',
      'hi': 'खाता',
      'te': 'ఖాతా',
    },
    'g8fj5flo': {
      'en': 'Rideoptions',
      'hi': 'सवारी विकल्प',
      'te': 'రైడ్‌ఆప్షన్‌లు',
    },
  },
  // home
  {
    'h1w2v3fi': {
      'en': 'Where to go ?',
      'hi': 'कहाँ जाए ?',
      'te': 'ఎక్కడికి వెళ్ళాలి?',
    },
    'en8fyguh': {
      'en': 'Your Ride Awaits',
      'hi': 'आपकी सवारी का इंतज़ार है',
      'te': 'మీ రైడ్ వేచి ఉంది',
    },
    '76yoeddl': {
      'en': 'See all',
      'hi': 'सभी देखें',
      'te': 'అన్నీ చూడండి',
    },
    'dtkvc9rl': {
      'en': 'Scan Qr and book the ride',
      'hi': 'QR स्कैन करें और सवारी बुक करें',
      'te': 'Qr స్కాన్ చేసి రైడ్ బుక్ చేసుకోండి',
    },
    'b01q6jhz': {
      'en': 'Cancel',
      'hi': '',
      'te': '',
    },
    'jbh9xjpf': {
      'en': 'Save every day',
      'hi': 'हर दिन बचत करें',
      'te': 'ప్రతి రోజు ఆదా చేయండి',
    },
    '96ev15d0': {
      'en': 'Auto rides',
      'hi': 'ऑटो सवारी',
      'te': 'ఆటో రైడ్స్',
    },
    '39myr84r': {
      'en': 'Upfront fares doorstep pickupd',
      'hi': 'अग्रिम किराया, दरवाजे से पिकअप',
      'te': 'ముందస్తు ఛార్జీలు ఇంటి వద్దకే తీసుకోబడతాయి',
    },
    'imvzfpcd': {
      'en': 'Enjoy 10% off on first booking',
      'hi': 'पहली बुकिंग पर 10% छूट का आनंद लें',
      'te': 'మొదటి బుకింగ్‌పై 10% తగ్గింపు పొందండి',
    },
    'w3p04fqe': {
      'en': 'home',
      'hi': 'घर',
      'te': 'హోమ్',
    },
  },
  // bookinghistory
  {
    'spkaimq0': {
      'en': 'Past',
      'hi': 'अतीत',
      'te': 'గతం',
    },
    'h6ish31y': {
      'en': 'Moosarambagh',
      'hi': 'मूसारामबाग',
      'te': 'మూసారంబాగ్',
    },
    '4d7qlt6t': {
      'en': 'Nov 17. 5:20 PM',
      'hi': '17 नवंबर, शाम 5:20 बजे',
      'te': 'నవంబర్ 17. సాయంత్రం 5:20',
    },
    'j57t1b2p': {
      'en': '₹ 30.00',
      'hi': '₹ 30.00',
      'te': '₹ 30.00',
    },
    'g0fpm7hn': {
      'en': 'Rebook',
      'hi': 'पुनः बुक करें',
      'te': 'రీబుక్',
    },
    'h73p5v1n': {
      'en': 'Dilsukhnagar',
      'hi': 'दिलसुखनगर',
      'te': 'దిల్ సుఖ్ నగర్',
    },
    '6c34anxj': {
      'en': 'Nov 12. 2:20 PM',
      'hi': '12 नवंबर, दोपहर 2:20 बजे',
      'te': 'నవంబర్ 12. మధ్యాహ్నం 2:20',
    },
    'mwrzb0z2': {
      'en': '₹ 40.00',
      'hi': '₹ 40.00',
      'te': '₹ 40.00',
    },
    'idns9o6q': {
      'en': 'Rebook',
      'hi': 'पुनः बुक करें',
      'te': 'రీబుక్',
    },
    '6k36le2b': {
      'en': 'Moosarambagh',
      'hi': 'मूसारामबाग',
      'te': 'మూసారంబాగ్',
    },
    '2tyqui90': {
      'en': 'Nov 17. 5:20 PM',
      'hi': '17 नवंबर, शाम 5:20 बजे',
      'te': 'నవంబర్ 17. సాయంత్రం 5:20',
    },
    'xkey942k': {
      'en': '₹ 30.00',
      'hi': '₹ 30.00',
      'te': '₹ 30.00',
    },
    'tjmrsbr9': {
      'en': 'Rebook',
      'hi': 'पुनः बुक करें',
      'te': 'రీబుక్',
    },
    'j468hhv1': {
      'en': 'Dilsukhnagar',
      'hi': 'दिलसुखनगर',
      'te': 'దిల్ సుఖ్ నగర్',
    },
    '6kmu14r2': {
      'en': 'Nov 12. 2:20 PM',
      'hi': '12 नवंबर, दोपहर 2:20 बजे',
      'te': 'నవంబర్ 12. మధ్యాహ్నం 2:20',
    },
    'l07h6q1e': {
      'en': '₹ 40.00',
      'hi': '₹ 40.00',
      'te': '₹ 40.00',
    },
    'f0ouuyx4': {
      'en': 'Rebook',
      'hi': 'पुनः बुक करें',
      'te': 'రీబుక్',
    },
    'i8smb2ll': {
      'en': 'Dilsukhnagar',
      'hi': 'दिलसुखनगर',
      'te': 'దిల్ సుఖ్ నగర్',
    },
    'vktzh9gn': {
      'en': 'Nov 12. 2:20 PM',
      'hi': '12 नवंबर, दोपहर 2:20 बजे',
      'te': 'నవంబర్ 12. మధ్యాహ్నం 2:20',
    },
    'kjz7brc9': {
      'en': '₹ 40.00',
      'hi': '₹ 40.00',
      'te': '₹ 40.00',
    },
    '5rck6cm4': {
      'en': 'Rebook',
      'hi': 'पुनः बुक करें',
      'te': 'రీబుక్',
    },
    'br7x3500': {
      'en': 'History',
      'hi': 'इतिहास',
      'te': 'చరిత్ర',
    },
    'l5j83shi': {
      'en': 'Booking history',
      'hi': 'बुकिंग इतिहास',
      'te': 'బుకింగ్ చరిత్ర',
    },
  },
  // AccountManagement
  {
    'xr4zc3rw': {
      'en': 'GO CODE DESIGNERS',
      'hi': 'गो कोड डिज़ाइनर्स',
      'te': 'గో కోడ్ డిజైనర్లు',
    },
    'oc8ggcgd': {
      'en': 'Support',
      'hi': 'सहायता',
      'te': 'మద్దతు',
    },
    '6ghijs7n': {
      'en': 'Wallet',
      'hi': 'बटुआ',
      'te': 'వాలెట్',
    },
    'p32bt3aj': {
      'en': 'History',
      'hi': 'इतिहास',
      'te': 'చరిత్ర',
    },
    'uwwd4cw4': {
      'en': 'Settings',
      'hi': 'सेटिंग्स',
      'te': 'సెట్టింగులు',
    },
    'mc9wnk6s': {
      'en': 'Languages',
      'hi': 'सेटिंग्स',
      'te': 'సెట్టింగులు',
    },
    'u3u05cev': {
      'en': 'Insurance',
      'hi': 'बीमा',
      'te': 'భీమా',
    },
    'kf80lpgb': {
      'en': 'Messages',
      'hi': 'संदेशों',
      'te': 'సందేశాలు',
    },
    'gw6i4s9e': {
      'en': 'Legal',
      'hi': 'कानूनी',
      'te': 'చట్టపరమైన',
    },
    '87zx8uve': {
      'en': 'Account',
      'hi': 'खाता',
      'te': 'ఖాతా',
    },
    'luv589l7': {
      'en': 'My Account',
      'hi': 'मेरा खाता',
      'te': 'నా ఖాతా',
    },
  },
  // support
  {
    'ilu9a857': {
      'en': 'All topics',
      'hi': 'सभी विषय',
      'te': 'అన్ని అంశాలు',
    },
    'l5axm4k6': {
      'en': 'Help with a trip',
      'hi': 'यात्रा में सहायता',
      'te': 'యాత్రకు సహాయం చేయండి',
    },
    '1x4bvc77': {
      'en': 'Account',
      'hi': 'खाता',
      'te': 'ఖాతా',
    },
    'mltafgrv': {
      'en': 'Accessibility',
      'hi': 'सरल उपयोग',
      'te': 'యాక్సెసిబిలిటీ',
    },
    'sftkxprc': {
      'en': 'Cancellation policy',
      'hi': 'शटल',
      'te': 'షటిల్',
    },
    '0bntvzxa': {
      'en': 'Support',
      'hi': '',
      'te': '',
    },
  },
  // Wallet
  {
    '7idwe1xc': {
      'en': 'Ugo cash',
      'hi': 'उगो कैश',
      'te': 'ఉగో నగదు',
    },
    'o5o4i3gu': {
      'en': '₹0.00',
      'hi': '₹0.00',
      'te': '₹0.00',
    },
    'a6u6d0sq': {
      'en': 'Gift card',
      'hi': 'उपहार कार्ड',
      'te': 'బహుమతి కార్డు',
    },
    'ktxa402r': {
      'en': 'Payment methods',
      'hi': 'भुगतान विधियाँ',
      'te': 'చెల్లింపు పద్ధతులు',
    },
    'oao5dvnw': {
      'en': 'Upi scan and pay',
      'hi': 'Upi स्कैन और भुगतान',
      'te': 'UPI స్కాన్ చేసి చెల్లించండి',
    },
    'mcje350w': {
      'en': 'Cash',
      'hi': 'नकद',
      'te': 'నగదు',
    },
    'zsnn2w5x': {
      'en': 'Add payment method',
      'hi': 'भुगतान विधि जोड़ें',
      'te': 'చెల్లింపు పద్ధతిని జోడించండి',
    },
    'vo9mscox': {
      'en': 'Rides profiles',
      'hi': 'सवारी प्रोफाइल',
      'te': 'రైడ్ ప్రొఫైల్స్',
    },
    'ksdpgb8i': {
      'en': 'Personal',
      'hi': 'निजी',
      'te': 'వ్యక్తిగత',
    },
    'qnqo8992': {
      'en': 'Starting using Ugo for business',
      'hi': 'व्यवसाय के लिए Ugo का उपयोग शुरू करना',
      'te': 'వ్యాపారం కోసం Ugoని ఉపయోగించడం ప్రారంభించడం',
    },
    'hk03dlx6': {
      'en': 'Shared with you',
      'hi': 'आपके साथ साझा',
      'te': 'మీతో పంచుకున్నారు',
    },
    '5iatkiuw': {
      'en': 'Manage business rides for others',
      'hi': 'दूसरों के लिए व्यावसायिक यात्राओं का प्रबंधन करें',
      'te': 'ఇతరుల కోసం వ్యాపార సవారీలను నిర్వహించండి',
    },
    'ijvyfwt8': {
      'en': 'Vouchers',
      'hi': 'वाउचर',
      'te': 'వోచర్లు',
    },
    'uy42yrs1': {
      'en': 'Vouchers',
      'hi': 'वाउचर',
      'te': 'వోచర్లు',
    },
    '6sj8408l': {
      'en': '0',
      'hi': '0',
      'te': '0',
    },
    'i796wiq8': {
      'en': 'Add vouchers code',
      'hi': 'वाउचर कोड जोड़ें',
      'te': 'వోచర్ల కోడ్‌ను జోడించండి',
    },
    '9n8ry32v': {
      'en': 'Promotions',
      'hi': 'प्रचार',
      'te': 'ప్రమోషన్లు',
    },
    'gb7bjv1c': {
      'en': 'Promotions',
      'hi': 'प्रचार',
      'te': 'ప్రమోషన్లు',
    },
    'ae6qnm0p': {
      'en': 'Add promo code',
      'hi': 'प्रोमो कोड जोड़ें',
      'te': 'ప్రోమో కోడ్‌ను జోడించండి',
    },
    'gtwmsvor': {
      'en': 'Referrals',
      'hi': 'रेफरल',
      'te': 'సిఫార్సులు',
    },
    'bqk65ixo': {
      'en': 'Add referral code',
      'hi': 'रेफरल कोड जोड़ें',
      'te': 'రిఫెరల్ కోడ్‌ను జోడించండి',
    },
    '8bs46fqf': {
      'en': 'Wallet',
      'hi': '',
      'te': '',
    },
  },
  // Balance
  {
    'a8iy3nqi': {
      'en': '₹0.00',
      'hi': '₹0.00',
      'te': '₹0.00',
    },
    '8fo1zywz': {
      'en': 'Monthly activity',
      'hi': 'मासिक गतिविधि',
      'te': 'నెలవారీ కార్యాచరణ',
    },
    'hsnf3c9h': {
      'en': 'Ugo cash added',
      'hi': 'उगो नकद जोड़ा गया',
      'te': 'Ugo నగదు జోడించబడింది',
    },
    '0ewa2jk5': {
      'en': '0.00',
      'hi': '0.00',
      'te': '0.00 అంటే ఏమిటి?',
    },
    '9hrlimpg': {
      'en': 'Ugo cash spent',
      'hi': 'उगो नकद खर्च',
      'te': 'ఉగో నగదు ఖర్చు చేయబడింది',
    },
    'qtg8aa3s': {
      'en': '0.00',
      'hi': '0.00',
      'te': '0.00 అంటే ఏమిటి?',
    },
    'cw8x5cg4': {
      'en': 'Ugo balance',
      'hi': 'उगो बैलेंस',
      'te': 'యుగో బ్యాలెన్స్',
    },
  },
  // auto-book
  {
    'lqrebzzn': {
      'en': 'Moto',
      'hi': 'मोटो',
      'te': 'మోటో',
    },
    'bi8twbdw': {
      'en': 'Pick up : dilsukhnagar drop location : Ameerpet',
      'hi': 'पिक-अप: दिलसुखनगर ड्रॉप स्थान: अमीरपेट',
      'te': 'పికప్: దిల్‌సుఖ్‌నగర్ డ్రాప్ లొకేషన్: అమీర్‌పేట్',
    },
    '5kmx6fh5': {
      'en': '₹34.22',
      'hi': '₹34.22',
      'te': '₹34.22',
    },
    'xwgtg5ie': {
      'en': 'Cancel',
      'hi': 'रद्द करना',
      'te': 'రద్దు చేయి',
    },
    '077w129n': {
      'en': 'UGO-AUTO',
      'hi': 'यूगो-ऑटो',
      'te': 'యుజిఓ-ఆటో',
    },
  },
  // bikebook
  {
    'angmdohs': {
      'en': 'Moto',
      'hi': 'मोटो',
      'te': 'మోటో',
    },
    'qgovjqli': {
      'en': 'Pick up : dilsukhnagar drop location : /nAmeerpet',
      'hi': 'पिक अप: दिलसुखनगर ड्रॉप स्थान: /nअमीरपेट',
      'te': 'పికప్: దిల్‌సుఖ్‌నగర్ డ్రాప్ లొకేషన్: /nఅమీర్‌పేట్',
    },
    'vd3706rt': {
      'en': '₹34.22',
      'hi': '₹34.22',
      'te': '₹34.22',
    },
    'j1rgj21x': {
      'en': 'Cancel',
      'hi': 'रद्द करना',
      'te': 'రద్దు చేయి',
    },
    'kqqm8wfu': {
      'en': 'UGO BIKE',
      'hi': 'यूगो बाइक',
      'te': 'యుగో బైక్',
    },
  },
  // avaliable-options
  {
    'sss1lv7l': {
      'en': 'Choose a ride',
      'hi': 'एक सवारी चुनें',
      'te': 'రైడ్‌ను ఎంచుకోండి',
    },
    '9i8wvtyx': {
      'en': 'Cash',
      'hi': 'नकद',
      'te': 'నగదు',
    },
    'wkk5mvrs': {
      'en': 'Scan',
      'hi': 'स्कैन',
      'te': 'స్కాన్ చేయండి',
    },
    'd9gp7e0g': {
      'en': 'Book ride',
      'hi': 'सवारी बुक करें',
      'te': 'బుక్ రైడ్',
    },
    'm2899lty': {
      'en': 'Add Stops',
      'hi': 'स्टॉप जोड़ें',
      'te': 'స్టాప్‌లను జోడించండి',
    },
  },
  // conform_location
  {
    'imzt8cr8': {
      'en': 'Add stops',
      'hi': 'स्टॉप जोड़ें',
      'te': 'స్టాప్‌లను జోడించండి',
    },
    'albhijj1': {
      'en': '•',
      'hi': '•',
      'te': '•',
    },
    'u6x3lohi': {
      'en': 'Enter pickup location',
      'hi': 'पिकअप स्थान दर्ज करें',
      'te': 'పికప్ స్థానాన్ని నమోదు చేయండి',
    },
    '8qw8lcxh': {
      'en': '1',
      'hi': '1',
      'te': '1. 1.',
    },
    'i3kf70rh': {
      'en': 'Add stop',
      'hi': 'स्टॉप जोड़ें',
      'te': 'స్టాప్‌ను జోడించండి',
    },
    '8ysdsq60': {
      'en': '2',
      'hi': '2',
      'te': '2',
    },
    'akzfkkd2': {
      'en': 'Add stop',
      'hi': 'स्टॉप जोड़ें',
      'te': 'స్టాప్‌ను జోడించండి',
    },
    'qh4iq3du': {
      'en': 'Pickup now',
      'hi': 'अभी उठाओ',
      'te': 'ఇప్పుడే తీసుకోండి',
    },
    'ymq0ndnp': {
      'en': 'For me',
      'hi': 'मेरे लिए',
      'te': 'నా కోసం',
    },
    'tioigdzn': {
      'en': 'Done',
      'hi': 'हो गया',
      'te': 'పూర్తయింది',
    },
    '83kqrbgp': {
      'en': 'Add Stops',
      'hi': 'स्टॉप जोड़ें',
      'te': 'స్టాప్‌లను జోడించండి',
    },
  },
  // plan_your_ride
  {
    'rs74x0qu': {
      'en': 'Pickup Location',
      'hi': '',
      'te': '',
    },
    'ty6xjj16': {
      'en': 'Drop Location',
      'hi': '',
      'te': '',
    },
    'q0khx6fp': {
      'en': 'Rajiv Gandhi airport',
      'hi': 'राजीव गांधी हवाई अड्डा',
      'te': 'రాజీవ్ గాంధీ విమానాశ్రయం',
    },
    'g9qt7ukz': {
      'en': 'Shamshad Hyderabad, airport',
      'hi': 'शमशाद हैदराबाद, हवाई अड्डा',
      'te': 'షంషాద్ హైదరాబాద్ విమానాశ్రయం',
    },
    '67xegy76': {
      'en': '12km',
      'hi': '12 किमी',
      'te': '12 కి.మీ',
    },
    'weu9g17h': {
      'en': 'Search in different city',
      'hi': 'अलग शहर में खोजें',
      'te': 'వేరే నగరంలో శోధించండి',
    },
    '5sz8c1ks': {
      'en': 'Set location on map',
      'hi': 'मानचित्र पर स्थान सेट करें',
      'te': 'మ్యాప్‌లో స్థానాన్ని సెట్ చేయండి',
    },
    'mcmrbcak': {
      'en': 'Saved places',
      'hi': 'सहेजे गए स्थान',
      'te': 'సేవ్ చేసిన స్థలాలు',
    },
    '3xxzi81u': {
      'en': 'Plan your ride',
      'hi': 'अपनी यात्रा की योजना बनाएं',
      'te': 'మీ రైడ్‌ని ప్లాన్ చేసుకోండి',
    },
  },
  // choose_destination
  {
    'z6wk5pln': {
      'en': 'Where to go ?',
      'hi': 'कहाँ जाए ?',
      'te': 'ఎక్కడికి వెళ్ళాలి?',
    },
    't7pi31fn': {
      'en': 'Rajiv Gandhi airport',
      'hi': 'राजीव गांधी हवाई अड्डा',
      'te': 'రాజీవ్ గాంధీ విమానాశ్రయం',
    },
    'zkms4ufc': {
      'en': 'Shamshad Hyderabad, airport',
      'hi': 'शमशाद हैदराबाद, हवाई अड्डा',
      'te': 'షంషాద్ హైదరాబాద్ విమానాశ్రయం',
    },
    'vuql4wxz': {
      'en': '12km',
      'hi': '12 किमी',
      'te': '12 కి.మీ',
    },
    'lvyzepw0': {
      'en': 'Search in different city',
      'hi': 'अलग शहर में खोजें',
      'te': 'వేరే నగరంలో శోధించండి',
    },
    'pnfms2qb': {
      'en': 'Set location on map',
      'hi': 'मानचित्र पर स्थान सेट करें',
      'te': 'మ్యాప్‌లో స్థానాన్ని సెట్ చేయండి',
    },
    'fvjjwsyx': {
      'en': 'Saved places',
      'hi': 'सहेजे गए स्थान',
      'te': 'సేవ్ చేసిన స్థలాలు',
    },
    'm9rf4tbo': {
      'en': 'Choose the destination',
      'hi': 'गंतव्य चुनें',
      'te': 'గమ్యస్థానాన్ని ఎంచుకోండి',
    },
  },
  // scan_to_book
  {
    'd5nsxfra': {
      'en': 'Scan the QR Code to Book Your Ride',
      'hi': 'अपनी सवारी बुक करने के लिए QR कोड स्कैन करें',
      'te': 'మీ రైడ్ బుక్ చేసుకోవడానికి QR కోడ్‌ను స్కాన్ చేయండి.',
    },
    't346q4kk': {
      'en': 'Scan Qr',
      'hi': 'क्यूआर स्कैन करें',
      'te': 'Qr స్కాన్ చేయండి',
    },
  },
  // History
  {
    'c0vu40lh': {
      'en': 'Past',
      'hi': 'अतीत',
      'te': 'గతం',
    },
    '0gut0jmn': {
      'en': 'Moosarambagh',
      'hi': 'मूसारामबाग',
      'te': 'మూసారంబాగ్',
    },
    'lxpk8m0l': {
      'en': 'Nov 17. 5:20 PM',
      'hi': '17 नवंबर, शाम 5:20 बजे',
      'te': 'నవంబర్ 17. సాయంత్రం 5:20',
    },
    'oxsoi771': {
      'en': '₹ 30.00',
      'hi': '₹ 30.00',
      'te': '₹ 30.00',
    },
    '8rlnckeh': {
      'en': 'Rebook',
      'hi': 'पुनः बुक करें',
      'te': 'రీబుక్',
    },
    'it4iktrs': {
      'en': 'Dilsukhnagar',
      'hi': 'दिलसुखनगर',
      'te': 'దిల్ సుఖ్ నగర్',
    },
    'wy0c9zr0': {
      'en': 'Nov 12. 2:20 PM',
      'hi': '12 नवंबर, दोपहर 2:20 बजे',
      'te': 'నవంబర్ 12. మధ్యాహ్నం 2:20',
    },
    '4vux8ze9': {
      'en': '₹ 40.00',
      'hi': '₹ 40.00',
      'te': '₹ 40.00',
    },
    'zy4irrh0': {
      'en': 'Rebook',
      'hi': 'पुनः बुक करें',
      'te': 'రీబుక్',
    },
    'puj2e3gd': {
      'en': 'Moosarambagh',
      'hi': 'मूसारामबाग',
      'te': 'మూసారంబాగ్',
    },
    'b0vj804q': {
      'en': 'Nov 17. 5:20 PM',
      'hi': '17 नवंबर, शाम 5:20 बजे',
      'te': 'నవంబర్ 17. సాయంత్రం 5:20',
    },
    'tric25j6': {
      'en': '₹ 30.00',
      'hi': '₹ 30.00',
      'te': '₹ 30.00',
    },
    'z6wnb9dz': {
      'en': 'Rebook',
      'hi': 'पुनः बुक करें',
      'te': 'రీబుక్',
    },
    '0dy2vanb': {
      'en': 'Dilsukhnagar',
      'hi': 'दिलसुखनगर',
      'te': 'దిల్ సుఖ్ నగర్',
    },
    'ob0fb5ve': {
      'en': 'Nov 12. 2:20 PM',
      'hi': '12 नवंबर, दोपहर 2:20 बजे',
      'te': 'నవంబర్ 12. మధ్యాహ్నం 2:20',
    },
    'qinmxv0b': {
      'en': '₹ 40.00',
      'hi': '₹ 40.00',
      'te': '₹ 40.00',
    },
    'pt5eqqo4': {
      'en': 'Rebook',
      'hi': 'पुनः बुक करें',
      'te': 'రీబుక్',
    },
    'd1xoho5t': {
      'en': 'Dilsukhnagar',
      'hi': 'दिलसुखनगर',
      'te': 'దిల్ సుఖ్ నగర్',
    },
    'exychc9j': {
      'en': 'Nov 12. 2:20 PM',
      'hi': '12 नवंबर, दोपहर 2:20 बजे',
      'te': 'నవంబర్ 12. మధ్యాహ్నం 2:20',
    },
    'hw807j6y': {
      'en': '₹ 40.00',
      'hi': '₹ 40.00',
      'te': '₹ 40.00',
    },
    'w9nepd8d': {
      'en': 'Rebook',
      'hi': 'पुनः बुक करें',
      'te': 'రీబుక్',
    },
    'b5u7cma8': {
      'en': 'History',
      'hi': 'इतिहास',
      'te': 'చరిత్ర',
    },
  },
  // settings_page
  {
    'vd2ymh90': {
      'en': 'Add Home',
      'hi': 'होम जोड़ें',
      'te': 'ఇంటిని జోడించండి',
    },
    'rw4zfx8g': {
      'en': 'Add Work',
      'hi': 'कार्य जोड़ें',
      'te': 'కార్యాలయాన్ని జోడించండి',
    },
    'xth2lr6p': {
      'en': 'Shortcuts',
      'hi': 'शॉर्टकट',
      'te': 'సత్వరమార్గాలు',
    },
    '78rilzrv': {
      'en': 'Accessibility',
      'hi': 'सरल उपयोग',
      'te': 'యాక్సెసిబిలిటీ',
    },
    'jmqxj8q4': {
      'en': 'Manage your accessibility settings',
      'hi': 'अपनी पहुँच-योग्यता सेटिंग प्रबंधित करें',
      'te': 'మీ యాక్సెసిబిలిటీ సెట్టింగ్‌లను నిర్వహించండి',
    },
    'xkgf70lf': {
      'en': 'Communication',
      'hi': 'संचार',
      'te': 'కమ్యూనికేషన్',
    },
    '9o8esdqp': {
      'en': 'Manage contact and notification settings',
      'hi': 'संपर्क और सूचना सेटिंग प्रबंधित करें',
      'te': 'కాంటాక్ట్ మరియు నోటిఫికేషన్ సెట్టింగ్‌లను నిర్వహించండి',
    },
    'u9kk66zb': {
      'en': 'Safety',
      'hi': 'सुरक्षा',
      'te': 'భద్రత',
    },
    'qv71xhj1': {
      'en': 'Safety preferences',
      'hi': 'सुरक्षा प्राथमिकताएँ',
      'te': 'భద్రతా ప్రాధాన్యతలు',
    },
    'p7wpg8kg': {
      'en': 'Choose and schedule your favorite safety tools',
      'hi': 'अपने पसंदीदा सुरक्षा उपकरण चुनें और शेड्यूल करें',
      'te': 'మీకు ఇష్టమైన భద్రతా సాధనాలను ఎంచుకోండి మరియు షెడ్యూల్ చేయండి',
    },
    '4851qjtq': {
      'en': 'Manage Trusted Contacts',
      'hi': 'विश्वसनीय संपर्क प्रबंधित करें',
      'te': 'విశ్వసనీయ పరిచయాలను నిర్వహించండి',
    },
    '5dgmooor': {
      'en': 'Share your trip status with family and friends in a single tap',
      'hi':
          'एक ही टैप में अपने परिवार और दोस्तों के साथ अपनी यात्रा की स्थिति साझा करें',
      'te':
          'మీ ట్రిప్ స్థితిని కుటుంబం మరియు స్నేహితులతో ఒకే ట్యాప్‌లో పంచుకోండి',
    },
    'fcbrfwi5': {
      'en': 'RideCheck',
      'hi': 'राइडचेक',
      'te': 'రైడ్‌చెక్',
    },
    'fd9npakg': {
      'en': 'Manage your RideCheck notifications',
      'hi': 'अपनी राइडचेक सूचनाएं प्रबंधित करें',
      'te': 'మీ RideCheck నోటిఫికేషన్‌లను నిర్వహించండి',
    },
    '8hfqx5dx': {
      'en': 'Ride Preferences',
      'hi': 'सवारी प्राथमिकताएँ',
      'te': 'రైడ్ ప్రాధాన్యతలు',
    },
    'p4jioty0': {
      'en': 'Tip automatically',
      'hi': 'स्वचालित रूप से टिप',
      'te': 'ఆటోమేటిక్‌గా చిట్కా',
    },
    'qw85ltwj': {
      'en': 'Set a default tip amount for every ride',
      'hi': 'प्रत्येक सवारी के लिए एक डिफ़ॉल्ट टिप राशि निर्धारित करें',
      'te': 'ప్రతి రైడ్ కి డిఫాల్ట్ టిప్ మొత్తాన్ని సెట్ చేయండి',
    },
    'n2gf5xso': {
      'en': 'Reserve',
      'hi': 'संरक्षित',
      'te': 'రిజర్వ్',
    },
    'iqv3vgu0': {
      'en': 'Manage booking match preferences',
      'hi': 'बुकिंग मिलान प्राथमिकताएं प्रबंधित करें',
      'te': 'బుకింగ్ మ్యాచ్ ప్రాధాన్యతలను నిర్వహించండి',
    },
    'nfvd0da4': {
      'en': 'Driver Nearby Alert',
      'hi': 'ड्राइवर के पास अलर्ट',
      'te': 'డ్రైవర్ సమీపంలోని హెచ్చరిక',
    },
    'n2cz2j8u': {
      'en': 'Notify me during long waits',
      'hi': 'लंबे इंतजार के दौरान मुझे सूचित करें',
      'te': 'ఎక్కువసేపు వేచి ఉన్నప్పుడు నాకు తెలియజేయి',
    },
    'chhlv2fh': {
      'en': 'Commute alerts',
      'hi': 'आवागमन अलर्ट',
      'te': 'ప్రయాణ హెచ్చరికలు',
    },
    'g7zw1t8g': {
      'en': 'Plan commute with traffic alerts',
      'hi': 'ट्रैफ़िक अलर्ट के साथ यात्रा की योजना बनाएं',
      'te': 'ట్రాఫిక్ హెచ్చరికలతో ప్రయాణాన్ని ప్లాన్ చేసుకోండి',
    },
    'jwua7y6v': {
      'en': 'Switch account',
      'hi': 'खाता स्थानांतरित करें',
      'te': 'ఖాతాను మార్చు',
    },
    'i3g6i1zo': {
      'en': 'Sign out',
      'hi': 'साइन आउट',
      'te': 'సైన్ అవుట్ చేయండి',
    },
    'rotnxdvl': {
      'en': 'App Settings',
      'hi': 'ऐप सेटिंग्स',
      'te': 'యాప్ సెట్టింగ్‌లు',
    },
  },
  // Profile_setting
  {
    'strai6nr': {
      'en': 'GO CODE DESIGNERS',
      'hi': 'गो कोड डिज़ाइनर्स',
      'te': 'గో కోడ్ డిజైనర్లు',
    },
    'gpjsbapw': {
      'en': 'Name',
      'hi': 'नाम',
      'te': 'పేరు',
    },
    'nzougsbz': {
      'en': 'Go CODE DESIGNERS',
      'hi': 'गो कोड डिज़ाइनर्स',
      'te': 'కోడ్ డిజైనర్లకు వెళ్లండి',
    },
    'bub0e7tg': {
      'en': 'Phone number',
      'hi': 'फ़ोन नंबर',
      'te': 'ఫోన్ నంబర్',
    },
    '99l2lyka': {
      'en': '9885881832',
      'hi': '9885881832',
      'te': '9885881832 ద్వారా www.mc.gov.in',
    },
    'uj2qqhvh': {
      'en': 'Gender',
      'hi': 'लिंग',
      'te': 'లింగం',
    },
    '3yx1101c': {
      'en': 'Man',
      'hi': 'आदमी',
      'te': 'మనిషి',
    },
    '1za01ujf': {
      'en': 'Email',
      'hi': 'ईमेल',
      'te': 'ఇ-మెయిల్',
    },
    'cqz2gscf': {
      'en': 'Duggiralanaresh1@gmail.com',
      'hi': 'Duggiralanaresh1@gmail.com',
      'te': 'దుగ్గిరలనరేష్1@gmail.com',
    },
    '383johu2': {
      'en': 'Language',
      'hi': 'भाषा',
      'te': 'భాష',
    },
    'h5ox1a3d': {
      'en': 'English',
      'hi': 'अंग्रेज़ी',
      'te': 'ఇంగ్లీష్',
    },
    '6uptrs2q': {
      'en': 'Save',
      'hi': 'बचाना',
      'te': 'సేవ్ చేయండి',
    },
    'l6xp81l6': {
      'en': 'App Settings',
      'hi': 'ऐप सेटिंग्स',
      'te': 'యాప్ సెట్టింగ్‌లు',
    },
  },
  // Add_home
  {
    'de0gbmr2': {
      'en': 'Rajiv Gandhi airport',
      'hi': 'राजीव गांधी हवाई अड्डा',
      'te': 'రాజీవ్ గాంధీ విమానాశ్రయం',
    },
    'bmqca3jq': {
      'en': 'Shamshad Hyderabad, airport',
      'hi': 'शमशाद हैदराबाद, हवाई अड्डा',
      'te': 'షంషాద్ హైదరాబాద్ విమానాశ్రయం',
    },
    'yk89c7oh': {
      'en': '12km',
      'hi': '12 किमी',
      'te': '12 కి.మీ',
    },
    '5awp706u': {
      'en': 'Search in different city',
      'hi': 'अलग शहर में खोजें',
      'te': 'వేరే నగరంలో శోధించండి',
    },
    'qlzex98e': {
      'en': 'Set location on map',
      'hi': 'मानचित्र पर स्थान सेट करें',
      'te': 'మ్యాప్‌లో స్థానాన్ని సెట్ చేయండి',
    },
    'cw7vnuxs': {
      'en': 'Saved places',
      'hi': 'सहेजे गए स्थान',
      'te': 'సేవ్ చేసిన స్థలాలు',
    },
    'unxbdrt3': {
      'en': 'Add home',
      'hi': 'घर जोड़ें',
      'te': 'ఇంటిని జోడించండి',
    },
  },
  // Add_office
  {
    'ma10493c': {
      'en': 'Rajiv Gandhi airport',
      'hi': 'राजीव गांधी हवाई अड्डा',
      'te': 'రాజీవ్ గాంధీ విమానాశ్రయం',
    },
    '7dwgh835': {
      'en': 'Shamshad Hyderabad, airport',
      'hi': 'शमशाद हैदराबाद, हवाई अड्डा',
      'te': 'షంషాద్ హైదరాబాద్ విమానాశ్రయం',
    },
    'olo2j5pf': {
      'en': '12km',
      'hi': '12 किमी',
      'te': '12 కి.మీ',
    },
    'c0fm547s': {
      'en': 'Search in different city',
      'hi': 'अलग शहर में खोजें',
      'te': 'వేరే నగరంలో శోధించండి',
    },
    'juv5dgq8': {
      'en': 'Set location on map',
      'hi': 'मानचित्र पर स्थान सेट करें',
      'te': 'మ్యాప్‌లో స్థానాన్ని సెట్ చేయండి',
    },
    'l8rl8ngc': {
      'en': 'Saved places',
      'hi': 'सहेजे गए स्थान',
      'te': 'సేవ్ చేసిన స్థలాలు',
    },
    '0990b83s': {
      'en': 'Add office',
      'hi': 'कार्यालय जोड़ें',
      'te': 'కార్యాలయాన్ని జోడించండి',
    },
  },
  // saved_add
  {
    'hfosrynq': {
      'en': 'Saved places',
      'hi': 'सहेजे गए स्थान',
      'te': 'సేవ్ చేసిన స్థలాలు',
    },
    'wsx3v4m0': {
      'en': 'Add Home',
      'hi': 'होम जोड़ें',
      'te': 'ఇంటిని జోడించండి',
    },
    'o6pkmpcm': {
      'en': 'Add Work',
      'hi': 'कार्य जोड़ें',
      'te': 'కార్యాలయాన్ని జోడించండి',
    },
    '354dyfpp': {
      'en': 'Add a new place',
      'hi': 'नया स्थान जोड़ें',
      'te': 'కొత్త స్థలాన్ని జోడించండి',
    },
  },
  // Accessibility_settings
  {
    'txczm026': {
      'en': 'Hearing',
      'hi': 'सुनवाई',
      'te': 'వినికిడి',
    },
    'mt067xu4': {
      'en': 'Indicate hearing preference',
      'hi': 'श्रवण वरीयता इंगित करें',
      'te': 'వినికిడి ప్రాధాన్యతను సూచించండి',
    },
    '5vt79gun': {
      'en': 'Vision',
      'hi': 'दृष्टि',
      'te': 'దృష్టి',
    },
    'nu22iv2u': {
      'en': 'Choose to disclose whether you\'re blind or low vision',
      'hi': 'यह बताना चुनें कि आप अंधे हैं या कम दृष्टि वाले हैं',
      'te':
          'మీరు అంధులా లేదా తక్కువ దృష్టి ఉన్నారా అని వెల్లడించడానికి ఎంచుకోండి',
    },
    'hji1iy90': {
      'en': 'Communication settings',
      'hi': 'संचार सेटिंग्स',
      'te': 'కమ్యూనికేషన్ సెట్టింగ్‌లు',
    },
    't70apkmo': {
      'en': 'Let others know how you need to or prefer to communicate.',
      'hi':
          'दूसरों को बताएं कि आपको किस प्रकार संवाद करना चाहिए या आप किस प्रकार संवाद करना पसंद करते हैं।',
      'te':
          'మీరు ఎలా కమ్యూనికేట్ చేయాలో లేదా ఎలా కమ్యూనికేట్ చేయాలనుకుంటున్నారో ఇతరులకు తెలియజేయండి.',
    },
    '69386x4e': {
      'en': 'Accessibility',
      'hi': 'सरल उपयोग',
      'te': 'యాక్సెసిబిలిటీ',
    },
  },
  // Hearing
  {
    'q7ai65o0': {
      'en': 'Let drivers and couriers know if you\'re deaf or hard of hearing',
      'hi': 'यदि आप बहरे हैं या कम सुनते हैं तो ड्राइवरों और कूरियर को बताएं',
      'te':
          'మీరు చెవిటివారో లేదా వినికిడి లోపం ఉన్నారో లేదో డ్రైవర్లు మరియు కొరియర్‌లకు తెలియజేయండి.',
    },
    '2bir0a8h': {
      'en': 'I;m deaf',
      'hi': 'मैं बहरा हूँ',
      'te': 'నేను చెవిటివాడిని.',
    },
    'j0nd9ppv': {
      'en': 'I;m hard of hearing',
      'hi': 'मुझे सुनने में दिक्कत है',
      'te': 'నాకు వినికిడి కష్టంగా ఉంది.',
    },
    '19pk9vwp': {
      'en': 'I;m not deaf or hard of hearing',
      'hi': 'मैं बहरा या कम सुनने वाला नहीं हूँ',
      'te': 'నేను చెవిటివాడిని లేదా వినికిడి లోపం ఉన్నవాడిని కాదు.',
    },
    '0vz47ig4': {
      'en': 'Hearing',
      'hi': 'सुनवाई',
      'te': 'వినికిడి',
    },
  },
  // Vision
  {
    'l7hiz6yp': {
      'en': 'Let drivers and couriers know if you\'re deaf or hard of hearing',
      'hi': 'यदि आप बहरे हैं या कम सुनते हैं तो ड्राइवरों और कूरियर को बताएं',
      'te':
          'మీరు చెవిటివారో లేదా వినికిడి లోపం ఉన్నారో లేదో డ్రైవర్లు మరియు కొరియర్‌లకు తెలియజేయండి.',
    },
    '3zrdl7j9': {
      'en': 'I;m blind',
      'hi': 'मैं अंधा हुँ',
      'te': 'నేను అంధుడిని;',
    },
    'rdyxxwt6': {
      'en': 'I;m low vision',
      'hi': 'मेरी दृष्टि कमज़ोर है',
      'te': 'నాకు దృష్టి తక్కువగా ఉంది.',
    },
    'kx5zxhf5': {
      'en': 'I;m not blind or low vision',
      'hi': 'मैं अंधा या कम दृष्टि वाला नहीं हूँ',
      'te': 'నేను అంధుడిని లేదా తక్కువ దృష్టిని కలిగి లేను.',
    },
    'tmb60xz8': {
      'en': 'Vision',
      'hi': 'दृष्टि',
      'te': 'దృష్టి',
    },
  },
  // Communication
  {
    'ko3qsi6f': {
      'en': 'Contact preference',
      'hi': 'संपर्क वरीयता',
      'te': 'పరిచయ ప్రాధాన్యత',
    },
    'uljo7or2': {
      'en': 'Choose how you want drivers o reach you',
      'hi': 'चुनें कि आप ड्राइवरों को कैसे अपने पास लाना चाहते हैं',
      'te': 'డ్రైవర్లు మిమ్మల్ని ఎలా చేరుకోవాలనుకుంటున్నారో ఎంచుకోండి.',
    },
    '7i72kvzn': {
      'en': 'Call or chat',
      'hi': 'कॉल या चैट करें',
      'te': 'కాల్ చేయండి లేదా చాట్ చేయండి',
    },
    'zwm558z1': {
      'en': 'Call',
      'hi': 'पुकारना',
      'te': 'కాల్ చేయండి',
    },
    'yzqtmt8w': {
      'en': 'Chat',
      'hi': 'बात करना',
      'te': 'చాట్',
    },
    'tt2phkev': {
      'en': 'Marketing preference',
      'hi': 'विपणन वरीयता',
      'te': 'మార్కెటింగ్ ప్రాధాన్యత',
    },
    'kj82qg6d': {
      'en':
          'Choose how to get special offers promos personalized suggestions and more',
      'hi':
          'विशेष ऑफ़र, प्रोमो, व्यक्तिगत सुझाव और अन्य चीज़ें पाने का तरीका चुनें',
      'te':
          'ప్రత్యేక ఆఫర్‌లు, ప్రోమోలు, వ్యక్తిగతీకరించిన సూచనలు మరియు మరిన్నింటిని ఎలా పొందాలో ఎంచుకోండి',
    },
    'r5nko7za': {
      'en': 'Push notifications',
      'hi': 'सूचनाएं धक्का',
      'te': 'పుష్ నోటిఫికేషన్లు',
    },
    'rw956aib': {
      'en': 'Save changes',
      'hi': 'परिवर्तनों को सुरक्षित करें',
      'te': 'మార్పులను సేవ్ చేయి',
    },
    'n7e8f01i': {
      'en': 'Communication',
      'hi': 'संचार',
      'te': 'కమ్యూనికేషన్',
    },
  },
  // Pushnotifications
  {
    'gaeok22h': {
      'en': 'Categories',
      'hi': 'श्रेणियाँ',
      'te': 'వర్గం',
    },
    'fe2109ti': {
      'en': 'Promotional offers',
      'hi': 'प्रचारात्मक प्रस्ताव',
      'te': 'ప్రమోషనల్ ఆఫర్లు',
    },
    '0sx5can7': {
      'en': 'Promotional offers, discounts and referral bonus',
      'hi': 'प्रचारात्मक ऑफ़र, छूट और रेफरल बोनस',
      'te': 'ప్రమోషనల్ ఆఫర్లు, డిస్కౌంట్లు మరియు రిఫెరల్ బోనస్',
    },
    'd3vf20um': {
      'en': 'Membership',
      'hi': 'सदस्यता',
      'te': 'సభ్యత్వం',
    },
    '8768rwio': {
      'en': 'Ugo One membership benefits and loyalty rewards',
      'hi': 'उगो वन सदस्यता लाभ और वफादारी पुरस्कार',
      'te': 'Ugo One సభ్యత్వ ప్రయోజనాలు మరియు లాయల్టీ రివార్డులు',
    },
    'ijpmysvu': {
      'en': 'Product updates & news',
      'hi': 'उत्पाद अपडेट और समाचार',
      'te': 'ఉత్పత్తి నవీకరణలు & వార్తలు',
    },
    '98202sfo': {
      'en': 'New product updates and interesting news',
      'hi': 'नए उत्पाद अपडेट और दिलचस्प समाचार',
      'te': 'కొత్త ఉత్పత్తి నవీకరణలు మరియు ఆసక్తికరమైన వార్తలు',
    },
    'd2h0rkrw': {
      'en': 'Recommendations',
      'hi': 'सिफारिशों',
      'te': 'సిఫార్సులు',
    },
    'msr0xh2v': {
      'en': 'Personalized trip suggestions',
      'hi': 'व्यक्तिगत यात्रा सुझाव',
      'te': 'వ్యక్తిగతీకరించిన ట్రిప్ సూచనలు',
    },
    '7sdy4gcc': {
      'en': 'Feedback',
      'hi': 'प्रतिक्रिया',
      'te': 'అభిప్రాయం',
    },
    '73qwhbgg': {
      'en': 'User research and marketing surveys',
      'hi': 'उपयोगकर्ता अनुसंधान और विपणन सर्वेक्षण',
      'te': 'వినియోగదారు పరిశోధన మరియు మార్కెటింగ్ సర్వేలు',
    },
    'gystp015': {
      'en': 'Push notifications',
      'hi': 'सूचनाएं धक्का',
      'te': 'పుష్ నోటిఫికేషన్లు',
    },
  },
  // Safetypreferences
  {
    'ixe1axt7': {
      'en': 'These will turn on when you use your preference',
      'hi': 'जब आप अपनी प्राथमिकता का उपयोग करेंगे तो ये चालू हो जाएंगे',
      'te': 'మీరు మీ ప్రాధాన్యతను ఉపయోగించినప్పుడు ఇవి ఆన్ అవుతాయి.',
    },
    '6uu87tpc': {
      'en': 'Get more safety check-ins',
      'hi': 'अधिक सुरक्षा जांच प्राप्त करें',
      'te': 'మరిన్ని భద్రతా తనిఖీలను పొందండి',
    },
    'ezx2ad7g': {
      'en': 'Monitor ride for route or time issues',
      'hi': 'मार्ग या समय संबंधी समस्याओं के लिए सवारी की निगरानी करें',
      'te': 'మార్గం లేదా సమయ సమస్యల కోసం రైడ్‌ను పర్యవేక్షించండి',
    },
    'yjlrlal7': {
      'en': 'Record audio',
      'hi': 'ऑडियो रिकॉर्ड करें',
      'te': 'ఆడియోను రికార్డ్ చేయండి',
    },
    'alme3h8l': {
      'en': 'Send a recording with your safety report',
      'hi': 'अपनी सुरक्षा रिपोर्ट के साथ एक रिकॉर्डिंग भेजें',
      'te': 'మీ భద్రతా నివేదికతో రికార్డింగ్‌ను పంపండి',
    },
    'gk9cnj7m': {
      'en': 'Share trip status',
      'hi': 'यात्रा की स्थिति साझा करें',
      'te': 'ట్రిప్ స్థితిని షేర్ చేయండి',
    },
    'b4blepbz': {
      'en': 'Share live trip with friends or family',
      'hi': 'दोस्तों या परिवार के साथ लाइव यात्रा साझा करें',
      'te': 'స్నేహితులు లేదా కుటుంబ సభ్యులతో ప్రత్యక్ష యాత్రను పంచుకోండి',
    },
    'woxk3510': {
      'en': 'Schedule',
      'hi': 'अनुसूची',
      'te': 'షెడ్యూల్',
    },
    'cyjugduq': {
      'en': 'This is how and when your preferences will turn on',
      'hi': 'आपकी प्राथमिकताएँ इस प्रकार और कब चालू होंगी',
      'te': 'మీ ప్రాధాన్యతలు ఎలా మరియు ఎప్పుడు ఆన్ అవుతాయి అనేది ఇక్కడ ఉంది',
    },
    'ue8ium3r': {
      'en': 'All rides',
      'hi': 'सभी सवारी',
      'te': 'అన్ని రైడ్‌లు',
    },
    'w7emc38a': {
      'en': 'on during every ride',
      'hi': 'हर सवारी के दौरान चालू',
      'te': 'ప్రతి రైడ్ సమయంలో ఆన్',
    },
    'lbu77i6m': {
      'en': 'Some rides',
      'hi': 'कुछ सवारी',
      'te': 'కొన్ని రైడ్‌లు',
    },
    '284tu9bw': {
      'en': 'Choose ride types',
      'hi': 'सवारी के प्रकार चुनें',
      'te': 'రైడ్ రకాలను ఎంచుకోండి',
    },
    'ugclg4l8': {
      'en': 'No rides',
      'hi': 'कोई सवारी नहीं',
      'te': 'రైడ్‌లు లేవు',
    },
    'a3btvneb': {
      'en': 'only turn on manually',
      'hi': 'केवल मैन्युअल रूप से चालू करें',
      'te': 'మాన్యువల్‌గా మాత్రమే ఆన్ చేయండి',
    },
    'j4u6mh08': {
      'en': 'Done',
      'hi': 'हो गया',
      'te': 'పూర్తయింది',
    },
    'to0i86k9': {
      'en': 'Safety preferences',
      'hi': 'सुरक्षा प्राथमिकताएँ',
      'te': 'భద్రతా ప్రాధాన్యతలు',
    },
  },
  // Trustedcontacts
  {
    'g6m134u2': {
      'en': 'Share your trip status',
      'hi': 'अपनी यात्रा की स्थिति साझा करें',
      'te': 'మీ ట్రిప్ స్టేటస్‌ను షేర్ చేయండి',
    },
    'ic5f70x5': {
      'en': 'Share your live location with contacts during any Ugo trip',
      'hi':
          'किसी भी उगो यात्रा के दौरान अपने संपर्कों के साथ अपना लाइव स्थान साझा करें',
      'te':
          'ఏదైనా Ugo ట్రిప్ సమయంలో మీ ప్రత్యక్ష స్థానాన్ని కాంటాక్ట్‌లతో పంచుకోండి',
    },
    '243jdoch': {
      'en': 'Set your emergency contact',
      'hi': 'अपना आपातकालीन संपर्क सेट करें',
      'te': 'మీ అత్యవసర పరిచయాన్ని సెట్ చేయండి',
    },
    'vmbbzyy4': {
      'en': 'Share your live location with contacts during any Ugo trip',
      'hi':
          'किसी भी उगो यात्रा के दौरान अपने संपर्कों के साथ अपना लाइव स्थान साझा करें',
      'te':
          'ఏదైనా Ugo ట్రిప్ సమయంలో మీ ప్రత్యక్ష స్థానాన్ని కాంటాక్ట్‌లతో పంచుకోండి',
    },
    '8kdg92mk': {
      'en': 'Add contact',
      'hi': 'संपर्क जोड़ें',
      'te': 'పరిచయాన్ని జోడించండి',
    },
    'i7r9ws1o': {
      'en': 'Trusted contacts',
      'hi': 'विश्वसनीय संपर्क',
      'te': 'విశ్వసనీయ పరిచయాలు',
    },
  },
  // Ridecheck
  {
    '6l4gljqb': {
      'en':
          'RideCheck helps in unexpected situations by offering quick access to safety tools, so you can get help fast',
      'hi':
          'राइडचेक अप्रत्याशित परिस्थितियों में सुरक्षा उपकरणों तक त्वरित पहुंच प्रदान करके मदद करता है, ताकि आपको तुरंत सहायता मिल सके',
      'te':
          'RideCheck భద్రతా సాధనాలకు త్వరిత ప్రాప్యతను అందించడం ద్వారా ఊహించని పరిస్థితుల్లో సహాయపడుతుంది, కాబట్టి మీరు త్వరగా సహాయం పొందవచ్చు.',
    },
    'qz96lcn7': {
      'en': 'Ridecheck Notification',
      'hi': 'राइडचेक अधिसूचना',
      'te': 'రైడ్‌చెక్ నోటిఫికేషన్',
    },
    'shl1sb1b': {
      'en':
          'When enabled, we\'ll notify you with a RideCheck if your trip seems off course',
      'hi':
          'सक्षम होने पर, यदि आपकी यात्रा मार्ग से भटकती हुई प्रतीत होती है, तो हम आपको राइडचेक के माध्यम से सूचित करेंगे',
      'te':
          'ప్రారంభించబడినప్పుడు, మీ ప్రయాణం తప్పుగా అనిపిస్తే మేము RideCheck ద్వారా మీకు తెలియజేస్తాము.',
    },
    'm5hml2iz': {
      'en': 'Ride check',
      'hi': 'सवारी जांच',
      'te': 'రైడ్ చెక్',
    },
  },
  // Tipautomatically
  {
    'ocvw6zj4': {
      'en':
          'Make tipping easy by setting a default tip for each ride. You can adjust it within an hour, and 100% goes to your driver.',
      'hi':
          'हर सवारी के लिए एक डिफ़ॉल्ट टिप सेट करके टिप देना आसान बनाएँ। आप इसे एक घंटे के अंदर एडजस्ट कर सकते हैं, और 100% आपके ड्राइवर को जाता है।',
      'te':
          'ప్రతి రైడ్‌కు డిఫాల్ట్ చిట్కాను సెట్ చేయడం ద్వారా టిప్పింగ్‌ను సులభతరం చేయండి. మీరు దానిని ఒక గంటలోపు సర్దుబాటు చేయవచ్చు మరియు 100% మీ డ్రైవర్‌కు వెళ్తుంది.',
    },
    'njyvr94a': {
      'en': 'Turn on auto tipping',
      'hi': 'ऑटो टिपिंग चालू करें',
      'te': 'ఆటో టిప్పింగ్‌ను ఆన్ చేయండి',
    },
    'bktuvk3x': {
      'en': 'Tip amount',
      'hi': 'टिप राशि',
      'te': 'టిప్ మొత్తం',
    },
    'ixm84wqm': {
      'en': '10',
      'hi': '10',
      'te': '10',
    },
    '7l694w2k': {
      'en': '20',
      'hi': '20',
      'te': '20',
    },
    '7q63yu0x': {
      'en': 'Custom',
      'hi': 'रिवाज़',
      'te': 'కస్టమ్',
    },
    'q7rhig4g': {
      'en': 'Tip automatically',
      'hi': 'स्वचालित रूप से टिप',
      'te': 'ఆటోమేటిక్‌గా చిట్కా',
    },
  },
  // Reservematching
  {
    'tv934q4t': {
      'en': 'Reserve matching',
      'hi': 'आरक्षित मिलान',
      'te': 'రిజర్వ్ మ్యాచింగ్',
    },
    'dipozvy7': {
      'en': 'Choose how you\'re matched with drivers when you book ahead',
      'hi':
          'पहले से बुकिंग करते समय ड्राइवरों से आपका मिलान कैसे किया जाए, यह चुनें',
      'te':
          'మీరు ముందుగా బుక్ చేసుకునేటప్పుడు డ్రైవర్లతో ఎలా సరిపోలాలో ఎంచుకోండి',
    },
    'l67s2hr8': {
      'en': 'Auto rematch',
      'hi': 'ऑटो रीमैच',
      'te': 'ఆటో రీమ్యాచ్',
    },
    'yi2dd18f': {
      'en':
          'Match with a new drivers if yours will be late due to slow progress',
      'hi':
          'यदि आपकी गाड़ी धीमी प्रगति के कारण देर से पहुंचेगी तो नए ड्राइवर से मिलान करें',
      'te':
          'మీ డ్రైవర్ నెమ్మదిగా ఉండటం వల్ల ఆలస్యం అవుతుంటే కొత్త డ్రైవర్లతో మ్యాచ్ చేయండి.',
    },
    'dx2c7h8q': {
      'en': 'Reserve matching',
      'hi': 'आरक्षित मिलान',
      'te': 'రిజర్వ్ మ్యాచింగ్',
    },
  },
  // Driversnearbyalerts
  {
    'zyozfavt': {
      'en': 'Get alert when driver\'s near',
      'hi': 'ड्राइवर के पास होने पर अलर्ट प्राप्त करें',
      'te': 'డ్రైవర్ దగ్గరగా ఉన్నప్పుడు హెచ్చరిక పొందండి',
    },
    'zdvom7o3': {
      'en':
          'We\'ll buzz your phone when your driver is nearby, so you don\'t miss their arrival',
      'hi':
          'जब आपका ड्राइवर आस-पास होगा, तो हम आपके फ़ोन पर कॉल करेंगे, ताकि आप उनके आगमन से न चूकें',
      'te':
          'మీ డ్రైవర్ సమీపంలో ఉన్నప్పుడు మేము మీ ఫోన్‌ను బజ్ చేస్తాము, కాబట్టి మీరు వారి రాకను కోల్పోరు.',
    },
    'i8hy6zbf': {
      'en': 'Drivers near by alerts',
      'hi': 'आस-पास के ड्राइवरों के लिए अलर्ट',
      'te': 'సమీపంలోని డ్రైవర్లకు హెచ్చరికలు',
    },
  },
  // chooseride
  {
    'tprxoefz': {
      'en': 'Late nights',
      'hi': 'देर रात तक',
      'te': 'అర్థరాత్రులు',
    },
    'kk4nvssl': {
      'en': 'Between 10PM to 6AM',
      'hi': 'रात 10 बजे से सुबह 6 बजे के बीच',
      'te': 'రాత్రి 10 గంటల నుండి ఉదయం 6 గంటల మధ్య',
    },
    'a2xf8mbz': {
      'en': 'Bar and restaurants',
      'hi': 'बार और रेस्तरां',
      'te': 'బార్ మరియు రెస్టారెంట్లు',
    },
    'gc3skc6j': {
      'en': 'Within 50 meters',
      'hi': '50 मीटर के भीतर',
      'te': '50 మీటర్ల లోపల',
    },
    '7g3bpi7m': {
      'en': 'Weekends',
      'hi': 'सप्ताहांत',
      'te': 'వారాంతాలు',
    },
    'vnc3rpu5': {
      'en': 'Friday through sunday',
      'hi': 'शुक्रवार से रविवार तक',
      'te': 'శుక్రవారం నుండి ఆదివారం వరకు',
    },
    '1a5usrvr': {
      'en': 'Confirm',
      'hi': 'पुष्टि करना',
      'te': 'నిర్ధారించండి',
    },
    '13agxu8t': {
      'en': 'Cancel',
      'hi': 'रद्द करना',
      'te': 'రద్దు చేయి',
    },
    'lj1iagwe': {
      'en': 'Choose ride types',
      'hi': 'सवारी के प्रकार चुनें',
      'te': 'రైడ్ రకాలను ఎంచుకోండి',
    },
    'z9v6iqjj': {
      'en': 'Home',
      'hi': 'घर',
      'te': 'హొమ్ పేజ్',
    },
  },
  // Commute_alerts
  {
    'u20mk24x': {
      'en': 'We\'re here to help make your commute more predictable.',
      'hi':
          'हम आपकी यात्रा को अधिक पूर्वानुमानित बनाने में सहायता के लिए यहां हैं।',
      'te':
          'మీ ప్రయాణాన్ని మరింత ఊహించదగినదిగా చేయడంలో సహాయపడటానికి మేము ఇక్కడ ఉన్నాము.',
    },
    'wzg5jc2w': {
      'en': 'Add a commute for the trips you take routinely',
      'hi': 'अपनी नियमित यात्राओं के लिए आवागमन जोड़ें',
      'te': 'మీరు రోజూ చేసే ప్రయాణాలకు ప్రయాణ మార్గాన్ని జోడించండి',
    },
    '076xy4r4': {
      'en':
          'Receive personalised commute notifications with traffic and waiting time',
      'hi':
          'ट्रैफ़िक और प्रतीक्षा समय के साथ व्यक्तिगत आवागमन सूचनाएं प्राप्त करें',
      'te':
          'ట్రాఫిక్ మరియు వేచి ఉండే సమయంతో వ్యక్తిగతీకరించిన ప్రయాణ నోటిఫికేషన్‌లను స్వీకరించండి',
    },
    'hyug15zy': {
      'en': 'Get suggestions on when to request a trip for a timely arrival',
      'hi':
          'समय पर आगमन के लिए यात्रा का अनुरोध कब करें, इस पर सुझाव प्राप्त करें',
      'te':
          'సకాలంలో చేరుకోవడానికి ఎప్పుడు ట్రిప్‌ని అభ్యర్థించాలో సూచనలను పొందండి',
    },
    'vziqnf97': {
      'en': 'Get started',
      'hi': 'शुरू हो जाओ',
      'te': 'ప్రారంభించండి',
    },
    'fu7p71gq': {
      'en': 'Commute alerts',
      'hi': 'आवागमन अलर्ट',
      'te': 'ప్రయాణ హెచ్చరికలు',
    },
  },
  // Payment_options
  {
    'q5l67j5j': {
      'en': 'Personal',
      'hi': 'निजी',
      'te': 'వ్యక్తిగత',
    },
    'l9hbshk7': {
      'en': 'Business',
      'hi': 'व्यापार',
      'te': 'బిజినెస్‌',
    },
    'ck9jlsm2': {
      'en': 'Ugo balance ₹0.00',
      'hi': 'उगो बैलेंस ₹0.00',
      'te': 'యుగో బ్యాలెన్స్ ₹0.00',
    },
    '3n2ljdag': {
      'en': 'Ugo cash : ₹0.00',
      'hi': 'उगो कैश : ₹0.00',
      'te': 'ఉగో నగదు : ₹0.00',
    },
    '53zufytw': {
      'en': 'Payment methods',
      'hi': 'भुगतान विधियाँ',
      'te': 'చెల్లింపు పద్ధతులు',
    },
    'tv7rlhvh': {
      'en': '\$',
      'hi': '\$',
      'te': '\$',
    },
    'm786q92q': {
      'en': 'Cash',
      'hi': 'नकद',
      'te': 'నగదు',
    },
    'nb2o49pw': {
      'en': 'Add payment method',
      'hi': 'भुगतान विधि जोड़ें',
      'te': 'చెల్లింపు పద్ధతిని జోడించండి',
    },
    'xt4t3gpw': {
      'en': 'Vouchers',
      'hi': 'वाउचर',
      'te': 'వోచర్లు',
    },
    'w3uwmx1x': {
      'en': 'Add Vouchers code',
      'hi': 'वाउचर कोड जोड़ें',
      'te': 'వోచర్‌ల కోడ్‌ను జోడించండి',
    },
    'vuudjeki': {
      'en': 'Payment options',
      'hi': 'भुगतान विकल्प',
      'te': 'చెల్లింపు ఎంపికలు',
    },
  },
  // add_payment
  {
    'zt4zn1bv': {
      'en': 'Credit or debit',
      'hi': 'क्रेडिट या डेबिट',
      'te': 'క్రెడిట్ లేదా డెబిట్',
    },
    'zii9uz3g': {
      'en': 'Gift card',
      'hi': 'उपहार कार्ड',
      'te': 'బహుమతి కార్డు',
    },
    'j27860pt': {
      'en': 'Add Payment',
      'hi': 'भुगतान जोड़ें',
      'te': 'చెల్లింపును జోడించండి',
    },
  },
  // voucher
  {
    'vwnvxe7z': {
      'en': 'Enter voucher code',
      'hi': 'वाउचर कोड दर्ज करें',
      'te': 'వోచర్ కోడ్‌ను నమోదు చేయండి',
    },
    '2qlkdmuh': {
      'en': 'Enter the code in order to claim and use you voucher',
      'hi': 'अपने वाउचर का दावा करने और उसका उपयोग करने के लिए कोड दर्ज करें',
      'te': 'మీ వోచర్‌ను క్లెయిమ్ చేసి ఉపయోగించడానికి కోడ్‌ను నమోదు చేయండి.',
    },
    'zflfzuy8': {
      'en': 'Continue',
      'hi': 'जारी रखना',
      'te': 'కొనసాగించు',
    },
    'an1a9ec8': {
      'en': 'Add vocher code',
      'hi': 'वाउचर कोड जोड़ें',
      'te': 'వోచర్ కోడ్‌ను జోడించండి',
    },
  },
  // wallet_password
  {
    '6j592fk4': {
      'en': 'To add a new payment method create a password for you Ugo account',
      'hi': 'नई भुगतान विधि जोड़ने के लिए अपने Ugo खाते के लिए पासवर्ड बनाएँ',
      'te':
          'కొత్త చెల్లింపు పద్ధతిని జోడించడానికి మీ Ugo ఖాతా కోసం పాస్‌వర్డ్‌ను సృష్టించండి',
    },
    'w08xsjta': {
      'en': 'Minimum 8 characters',
      'hi': 'न्यूनतम 8 अक्षर',
      'te': 'కనీసం 8 అక్షరాలు',
    },
    '3tili4xw': {
      'en': 'Next',
      'hi': 'अगला',
      'te': 'తరువాతి',
    },
    'q11nxck4': {
      'en': 'Add Password',
      'hi': 'पासवर्ड जोड़ें',
      'te': 'పాస్‌వర్డ్‌ను జోడించండి',
    },
  },
  // add_cards
  {
    '0l9bisnd': {
      'en': 'Card Number',
      'hi': 'कार्ड संख्या',
      'te': 'కార్డ్ నంబర్',
    },
    '0ypc14yn': {
      'en': 'Card Holder Name',
      'hi': 'कार्डधारक का नाम',
      'te': 'కార్డ్ హోల్డర్ పేరు',
    },
    'gcrvhofg': {
      'en': 'Expiry Date',
      'hi': 'समाप्ति तिथि',
      'te': 'గడువు తేదీ',
    },
    'e2ibb4t7': {
      'en': 'CVV',
      'hi': 'सीवीवी',
      'te': 'సివివి',
    },
    'jl60dts6': {
      'en': 'Add Card',
      'hi': 'कार्ड जोड़ें',
      'te': 'కార్డ్‌ను జోడించండి',
    },
    '8p1xngfs': {
      'en': 'Add Card',
      'hi': 'कार्ड जोड़ें',
      'te': 'కార్డ్‌ను జోడించండి',
    },
  },
  // Driver_details
  {
    'ekfej241': {
      'en': 'UGO TAXI',
      'hi': 'यूगो टैक्सी',
      'te': 'యుజిఓ టాక్సీ',
    },
    '14hhszp0': {
      'en': 'Driver details',
      'hi': 'ड्राइवर विवरण',
      'te': 'డ్రైవర్ వివరాలు',
    },
    'gepq9jh1': {
      'en': 'Driver name: Sharath',
      'hi': 'ड्राइवर का नाम: शरत',
      'te': 'డ్రైవర్ పేరు: శరత్',
    },
    'f87kknso': {
      'en': 'vehicle number : 1287737738',
      'hi': 'वाहन संख्या : 1287737738',
      'te': 'వాహనం నంబర్: 1287737738',
    },
    'u8ny24ht': {
      'en': 'Rating :',
      'hi': 'रेटिंग :',
      'te': 'రేటింగ్ :',
    },
    '5wyvvbo9': {
      'en': '4.7',
      'hi': '4.7',
      'te': '4.7 समानिक समानी',
    },
    '5cshm3od': {
      'en': 'Drop location : Ameerpet',
      'hi': 'ड्रॉप स्थान: अमीरपेट',
      'te': 'డ్రాప్ లొకేషన్: అమీర్‌పేట',
    },
    'sq2q0aex': {
      'en': 'Drop distance : 15km',
      'hi': 'ड्रॉप दूरी : 15 किमी',
      'te': 'డ్రాప్ దూరం: 15 కి.మీ.',
    },
    'e2qayho8': {
      'en': 'Trip amount : ₹100.00',
      'hi': 'यात्रा राशि : ₹100.00',
      'te': 'ట్రిప్ మొత్తం: ₹100.00',
    },
    'tvvu7856': {
      'en': 'TIP AMOUNT',
      'hi': 'टिप राशि',
      'te': 'చిట్కా మొత్తం',
    },
    '3eeo73fo': {
      'en': '10',
      'hi': '10',
      'te': '10',
    },
    'qp9ckf7f': {
      'en': '20',
      'hi': '20',
      'te': '20',
    },
    'gvv3ine5': {
      'en': '30',
      'hi': '30',
      'te': '30 లు',
    },
    'fvj1to8q': {
      'en': 'Total amount',
      'hi': 'कुल राशि',
      'te': 'మొత్తం మొత్తం',
    },
    'm7v44mwf': {
      'en': '₹100.00',
      'hi': '₹100.00',
      'te': '₹100.00',
    },
    '3iah97vf': {
      'en': 'Cancel',
      'hi': 'रद्द करना',
      'te': 'రద్దు చేయి',
    },
    'bd8wulws': {
      'en': 'Continue',
      'hi': 'जारी रखना',
      'te': 'కొనసాగించు',
    },
  },
  // Messages
  {
    '0rdq2ugn': {
      'en': 'No new messages right now. Check back soon for the latest offers!',
      'hi': 'अभी कोई नया संदेश नहीं है। नवीनतम ऑफ़र के लिए जल्द ही वापस देखें!',
      'te':
          'ప్రస్తుతం కొత్త సందేశాలు లేవు. తాజా ఆఫర్‌ల కోసం త్వరలో తిరిగి తనిఖీ చేయండి!',
    },
    'lpprsepq': {
      'en': 'Messages',
      'hi': 'संदेशों',
      'te': 'సందేశాలు',
    },
  },
  // Language
  {
    'bh670gmz': {
      'en': 'English',
      'hi': 'अंग्रेज़ी',
      'te': 'ఇంగ్లీష్',
    },
    'iih23n2v': {
      'en': 'Telugu',
      'hi': 'तेलुगू',
      'te': 'తెలుగు',
    },
    '6craqhm0': {
      'en': 'Hindi',
      'hi': 'हिंदी',
      'te': 'హిందీ',
    },
    'fmwribbv': {
      'en': 'Languages',
      'hi': 'बोली',
      'te': 'భాషలు',
    },
  },
  // Account_support
  {
    'tfzrtoij': {
      'en': 'Can\'t sign in or request a trip',
      'hi': '',
      'te': '',
    },
    'biryh5h6': {
      'en': 'Account settings',
      'hi': '',
      'te': '',
    },
    'zobguivi': {
      'en': 'Payment methods',
      'hi': '',
      'te': '',
    },
    'y2rtjpsw': {
      'en': 'Gift cards and vouchers',
      'hi': '',
      'te': '',
    },
    '7dkzfeve': {
      'en': 'Promos and partnerships',
      'hi': '',
      'te': '',
    },
    'ipz98pti': {
      'en': 'Uber Cash',
      'hi': '',
      'te': '',
    },
    'eujhm8po': {
      'en': 'Receipts and invoices',
      'hi': '',
      'te': '',
    },
    'm1vu6je7': {
      'en': 'Other payment support',
      'hi': '',
      'te': '',
    },
    '9c264lwa': {
      'en': 'Duplicate or unknown charges',
      'hi': '',
      'te': '',
    },
    '6ezjtt01': {
      'en': 'Rider insurance',
      'hi': '',
      'te': '',
    },
    'hy81sb07': {
      'en': 'I lost my phone in Uber',
      'hi': '',
      'te': '',
    },
    'ysdtmrd0': {
      'en': 'Account',
      'hi': '',
      'te': '',
    },
  },
  // support_ride
  {
    'gnde4jfz': {
      'en': 'Choose a trip',
      'hi': '',
      'te': '',
    },
  },
  // ride_overview
  {
    'hc5zvngx': {
      'en': 'Having an issue with a different\ndriver?',
      'hi': '',
      'te': '',
    },
    'y2ttgl8h': {
      'en': 'Get help',
      'hi': '',
      'te': '',
    },
    'ljppe8um': {
      'en': 'Moto ride with JILLA\nRAJENDRA PRASAD',
      'hi': '',
      'te': '',
    },
    'ehqd5nb0': {
      'en': 'Jan 18 11:12AM',
      'hi': '',
      'te': '',
    },
    'ygqiactr': {
      'en': '₹103.00',
      'hi': '',
      'te': '',
    },
    't13nqnia': {
      'en': 'Receipt',
      'hi': '',
      'te': '',
    },
    '858a9u1g': {
      'en': 'Invoice',
      'hi': '',
      'te': '',
    },
    '3g341fjq': {
      'en': 'Secunderabad, Telangana 500003,\nIndia',
      'hi': '',
      'te': '',
    },
    'gvct7vaz': {
      'en': '11:23 AM',
      'hi': '',
      'te': '',
    },
    'wj0fb88l': {
      'en':
          '16-11-477/1, Shashi Hospital Ln, Indira\nNagar, Dilsukhnagar, Hyderabad, Tela...',
      'hi': '',
      'te': '',
    },
    'v96p81tf': {
      'en': '11:59 AM',
      'hi': '',
      'te': '',
    },
    'xtwustmq': {
      'en': 'No tip added',
      'hi': '',
      'te': '',
    },
    'zfv9e386': {
      'en': 'No rating',
      'hi': '',
      'te': '',
    },
    'e3d5d8wp': {
      'en': 'Help & safety',
      'hi': '',
      'te': '',
    },
    'fii1tu3m': {
      'en': 'Find lost item',
      'hi': '',
      'te': '',
    },
    '8hzyd342': {
      'en': 'We can help you get in touch with your\ndriver',
      'hi': '',
      'te': '',
    },
    'w778vvv7': {
      'en': 'Report safety issue',
      'hi': '',
      'te': '',
    },
    '8jdx0bd7': {
      'en': 'Report any safety related issues to us',
      'hi': '',
      'te': '',
    },
    '2627acjm': {
      'en': 'Customer support',
      'hi': '',
      'te': '',
    },
    '6b25o08x': {
      'en': 'Ride details',
      'hi': '',
      'te': '',
    },
  },
  // Find_lost_items
  {
    'hkyqoi9u': {
      'en': 'Completed trip, 103.00 INR',
      'hi': '',
      'te': '',
    },
    'uc1f6erh': {
      'en': 'Wed, Aug 13, 3:48 PM',
      'hi': '',
      'te': '',
    },
    's54ixuvs': {
      'en': 'Hi Naresh, I\'m here to help. Please choose an option below.',
      'hi': '',
      'te': '',
    },
    'ih19prky': {
      'en': 'My friend/relative lost their phone in an Ugo',
      'hi': '',
      'te': '',
    },
    '0aiojzj1': {
      'en': 'I need to contact my driver about a lost item',
      'hi': '',
      'te': '',
    },
    'citxykqp': {
      'en': 'Something else',
      'hi': '',
      'te': '',
    },
    'xyc9hgu9': {
      'en': 'Ugo',
      'hi': '',
      'te': '',
    },
    'df0w2cmm': {
      'en': 'Find lost items',
      'hi': '',
      'te': '',
    },
  },
  // Report_issues
  {
    'leew4lf2': {
      'en': 'Safety',
      'hi': '',
      'te': '',
    },
    'kje7no8j': {
      'en': 'My driver didn\'t match the profile in my app',
      'hi': '',
      'te': '',
    },
    'ua7essc9': {
      'en': 'My driver\'s vehicle was different',
      'hi': '',
      'te': '',
    },
    'ni50t98o': {
      'en': 'Report inappropriate driver behaviour',
      'hi': '',
      'te': '',
    },
    '95bcajt9': {
      'en': 'I was involved in an accident',
      'hi': '',
      'te': '',
    },
    'yi3xzmc0': {
      'en': 'My driver\'s vehicle was unsafe or broke down',
      'hi': '',
      'te': '',
    },
    'a1507nfa': {
      'en': 'Report safety issue',
      'hi': '',
      'te': '',
    },
  },
  // Customer_suport
  {
    'bj4b2zwh': {
      'en': 'Wed, Aug 13, 3:50 PM',
      'hi': '',
      'te': '',
    },
    'ajsw9xpw': {
      'en': 'Hi Naresh, welcome to customer support.',
      'hi': '',
      'te': '',
    },
    '1c03oj7k': {
      'en':
          'If you\'re reaching out about the price you paid for this ride, unfortunately it is too late to review it.',
      'hi': '',
      'te': '',
    },
    'ii0ixfby': {
      'en':
          'In the future, if you need support with a ride\'s price, please contact us as soon as possible so we can help. I can still help with the following options. If you\'d like to share feedback about the driver or vehicle, please select that option below.',
      'hi': '',
      'te': '',
    },
    'gopklq8z': {
      'en': 'Share feedback about the driver or vehicle',
      'hi': '',
      'te': '',
    },
    'kt5woz1j': {
      'en': 'That\'s all I need',
      'hi': '',
      'te': '',
    },
    'zpy3yojt': {
      'en': 'Help with something else',
      'hi': '',
      'te': '',
    },
    '7uibnal3': {
      'en': 'Customer support',
      'hi': '',
      'te': '',
    },
  },
  // Book_sucessfull
  {
    '88qi4lhh': {
      'en': 'Otp :',
      'hi': '',
      'te': '',
    },
    'n36b4xti': {
      'en': '2',
      'hi': '',
      'te': '',
    },
    'yb3qxw4x': {
      'en': '5',
      'hi': '',
      'te': '',
    },
    'xvghbrv2': {
      'en': '4',
      'hi': '',
      'te': '',
    },
    'pdplo6jz': {
      'en': '2',
      'hi': '',
      'te': '',
    },
    'z1rynwit': {
      'en': 'AP28TA',
      'hi': '',
      'te': '',
    },
    '2dgclytm': {
      'en': '2',
      'hi': '',
      'te': '',
    },
    's2ppwd0m': {
      'en': '5',
      'hi': '',
      'te': '',
    },
    'lnc7td6b': {
      'en': '4',
      'hi': '',
      'te': '',
    },
    'x84wnc38': {
      'en': '2',
      'hi': '',
      'te': '',
    },
    'zao712re': {
      'en': 'Name : Bharath',
      'hi': '',
      'te': '',
    },
    'k9ut8cez': {
      'en': 'Rating :',
      'hi': '',
      'te': '',
    },
    'xuero9r2': {
      'en': '4.6',
      'hi': '',
      'te': '',
    },
    '4vnlodv0': {
      'en': ': Dilsukhnagar',
      'hi': '',
      'te': '',
    },
    'xu50sls1': {
      'en': ': Ameerpet',
      'hi': '',
      'te': '',
    },
    's5ihqfjt': {
      'en': 'Amount',
      'hi': '',
      'te': '',
    },
    'y6tax9ap': {
      'en': '₹76.00',
      'hi': '',
      'te': '',
    },
    '4p03da39': {
      'en': 'Distance : 15km',
      'hi': '',
      'te': '',
    },
    'u0balwl6': {
      'en': 'Cancel',
      'hi': 'रद्द करना',
      'te': 'రద్దు చేయి',
    },
  },
  // cancel_ride
  {
    'ohc1zeqa': {
      'en': '🚕',
      'hi': '',
      'te': '',
    },
    'eyqf5dyn': {
      'en': 'Driver delayed too long',
      'hi': '',
      'te': '',
    },
    'nz6u65ls': {
      'en': '📞',
      'hi': '',
      'te': '',
    },
    'i2pyehba': {
      'en': 'Unable to contact driver',
      'hi': '',
      'te': '',
    },
    'bcer8eaw': {
      'en': '📍',
      'hi': '',
      'te': '',
    },
    '1j1jnqj4': {
      'en': 'Wrong pickup location',
      'hi': '',
      'te': '',
    },
    'vchg0nsl': {
      'en': '❌',
      'hi': '',
      'te': '',
    },
    'q43sw3j7': {
      'en': 'Change in travel plan',
      'hi': '',
      'te': '',
    },
    'g8a3tgmz': {
      'en': '💸',
      'hi': '',
      'te': '',
    },
    'adfjszay': {
      'en': 'Fare is too high',
      'hi': '',
      'te': '',
    },
    '6kdzzyh9': {
      'en': '👥',
      'hi': '',
      'te': '',
    },
    'djwquulj': {
      'en': 'Booked by mistake',
      'hi': '',
      'te': '',
    },
    'iyy10m4d': {
      'en': '🛑',
      'hi': '',
      'te': '',
    },
    'su8wk1sl': {
      'en': 'Safety concerns',
      'hi': '',
      'te': '',
    },
    'igi6n2xn': {
      'en': 'others',
      'hi': '',
      'te': '',
    },
    'qhfrthhl': {
      'en': 'Submit',
      'hi': '',
      'te': '',
    },
    '0bgtqxm5': {
      'en': 'Cancel Ride Options',
      'hi': '',
      'te': '',
    },
  },
  // Add_stop
  {
    '0b9t1w3t': {
      'en': 'Where to go ?',
      'hi': '',
      'te': '',
    },
    'x3o859jp': {
      'en': '',
      'hi': '',
      'te': '',
    },
    'p3hnvsn1': {
      'en': 'Where to go ?',
      'hi': '',
      'te': '',
    },
    'k8xb627q': {
      'en': 'Select Location',
      'hi': '',
      'te': '',
    },
    'kaxklmj0': {
      'en': 'Rajiv Gandhi airport',
      'hi': 'राजीव गांधी हवाई अड्डा',
      'te': 'రాజీవ్ గాంధీ విమానాశ్రయం',
    },
    '31o2lj63': {
      'en': 'Shamshad Hyderabad, airport',
      'hi': 'शमशाद हैदराबाद, हवाई अड्डा',
      'te': 'షంషాద్ హైదరాబాద్ విమానాశ్రయం',
    },
    'g3praj3e': {
      'en': '12km',
      'hi': '12 किमी',
      'te': '12 కి.మీ',
    },
    'eahltylj': {
      'en': 'Search in different city',
      'hi': 'अलग शहर में खोजें',
      'te': 'వేరే నగరంలో శోధించండి',
    },
    'ei0xn43w': {
      'en': 'Set location on map',
      'hi': 'मानचित्र पर स्थान सेट करें',
      'te': 'మ్యాప్‌లో స్థానాన్ని సెట్ చేయండి',
    },
    'bskvsj5n': {
      'en': 'Saved places',
      'hi': 'सहेजे गए स्थान',
      'te': 'సేవ్ చేసిన స్థలాలు',
    },
    'c4m6gzcd': {
      'en': 'Add a stop',
      'hi': '',
      'te': '',
    },
  },
  // Add_stops
  {
    'dxiixsbj': {
      'en': 'Add stops',
      'hi': '',
      'te': '',
    },
    'u6dhdrae': {
      'en': 'Enter pickup location',
      'hi': '',
      'te': '',
    },
    'hmfllz9a': {
      'en': 'Add stop',
      'hi': '',
      'te': '',
    },
    'wpxo5fgu': {
      'en': '',
      'hi': '',
      'te': '',
    },
    'c6uskffx': {
      'en': 'Add stop',
      'hi': '',
      'te': '',
    },
    'jclne6lk': {
      'en': 'Add stop',
      'hi': '',
      'te': '',
    },
    'tucm3v4b': {
      'en': '',
      'hi': '',
      'te': '',
    },
    'dstq4c18': {
      'en': 'Add stop',
      'hi': '',
      'te': '',
    },
    'rcrhulj3': {
      'en': 'Pick up',
      'hi': '',
      'te': '',
    },
    'c0kxfcc8': {
      'en': 'Search...',
      'hi': '',
      'te': '',
    },
    '272zv4j4': {
      'en': 'Now',
      'hi': '',
      'te': '',
    },
    'rlfi2nqi': {
      'en': 'Later',
      'hi': '',
      'te': '',
    },
    '4kpz5uqp': {
      'en': 'Pick Now',
      'hi': '',
      'te': '',
    },
    'yzmm26mn': {
      'en': 'Search...',
      'hi': '',
      'te': '',
    },
    'lceqk6wm': {
      'en': 'For Me',
      'hi': 'मेरे लिए',
      'te': 'నా కోసం',
    },
    't57dvmyq': {
      'en': 'Other',
      'hi': '',
      'te': '',
    },
    'i4m7v84d': {
      'en': 'Done',
      'hi': 'हो गया',
      'te': 'పూర్తయింది',
    },
  },
  // passwordcard
  {
    'kvffzs8j': {
      'en': 'Add Password',
      'hi': '',
      'te': '',
    },
    'zclr7bp0': {
      'en': 'Home',
      'hi': '',
      'te': '',
    },
  },
  // review
  {
    'q926b71g': {
      'en': 'Review',
      'hi': '',
      'te': '',
    },
    'khw5ycdw': {
      'en': 'Home',
      'hi': '',
      'te': '',
    },
  },
  // ridecomplete
  {
    'okj4gvo3': {
      'en': 'Ride Complete',
      'hi': '',
      'te': '',
    },
    'iag5ed1a': {
      'en': 'Home',
      'hi': '',
      'te': '',
    },
  },
  // Set_Location
  {
    'fu9b0xkt': {
      'en': 'Set your pickup spot',
      'hi': '',
      'te': '',
    },
    'oyq430f9': {
      'en': 'Drag map to move pin',
      'hi': '',
      'te': '',
    },
    '20avd2zk': {
      'en': 'Akshya Patra restaurant',
      'hi': '',
      'te': '',
    },
    'zjwcs591': {
      'en': 'Confirm pickup',
      'hi': '',
      'te': '',
    },
    'enofnqm4': {
      'en': 'Home',
      'hi': '',
      'te': '',
    },
  },
  // Menu
  {
    'dc4d2jzu': {
      'en': 'Home',
      'hi': 'घर',
      'te': 'హొమ్ పేజ్',
    },
    '7gtos5g5': {
      'en': 'Services',
      'hi': '',
      'te': '',
    },
    'b6qjqpkc': {
      'en': 'History',
      'hi': '',
      'te': '',
    },
    'yzazzu72': {
      'en': 'Account',
      'hi': '',
      'te': '',
    },
  },
  // ride_detais
  {
    'nqlh5yse': {
      'en': '1/18/25, 11:12 AM',
      'hi': '',
      'te': '',
    },
    'hpgy10eh': {
      'en': 'Hero Glamour',
      'hi': '',
      'te': '',
    },
    'dm3vkyld': {
      'en': '₹103.00',
      'hi': '',
      'te': '',
    },
    'e7sn691y': {
      'en': 'CASH',
      'hi': '',
      'te': '',
    },
  },
  // password
  {
    'k9faeq99': {
      'en': 'To add a new payment method create a password for you Ugo account',
      'hi': '',
      'te': '',
    },
    '2cht2a5x': {
      'en': 'Minimum 8 characters',
      'hi': '',
      'te': '',
    },
    'k5cfz5ok': {
      'en': 'Next',
      'hi': '',
      'te': '',
    },
  },
  // ridecomplet
  {
    'w7o09tep': {
      'en': 'Your trip with Bharath has ended',
      'hi': '',
      'te': '',
    },
    'e1pwahtk': {
      'en': 'Trip ID: 1234567890',
      'hi': '',
      'te': '',
    },
    'itezhxm9': {
      'en': 'Driver',
      'hi': '',
      'te': '',
    },
    'am6io75k': {
      'en': 'Bharath',
      'hi': '',
      'te': '',
    },
    'm6ib4mjg': {
      'en': '4.9 (123 rides)',
      'hi': '',
      'te': '',
    },
    'a11u60qp': {
      'en': 'Trip Summary',
      'hi': '',
      'te': '',
    },
    '95n45uj9': {
      'en': 'Pickup',
      'hi': '',
      'te': '',
    },
    'wdtk7l90': {
      'en': 'Dilsukhnagar',
      'hi': '',
      'te': '',
    },
    'pfia3mlm': {
      'en': 'Dropoff',
      'hi': '',
      'te': '',
    },
    'ral9tz6v': {
      'en': 'Ameerpet',
      'hi': '',
      'te': '',
    },
    'y91w3ryi': {
      'en': 'Distance',
      'hi': '',
      'te': '',
    },
    'bi5g3ho0': {
      'en': '15 Kms',
      'hi': '',
      'te': '',
    },
    'wc94wl6t': {
      'en': 'Duration',
      'hi': '',
      'te': '',
    },
    'a8zv4fsc': {
      'en': '15 minutes',
      'hi': '',
      'te': '',
    },
    '6qhaxbne': {
      'en': 'Fare Breakdown',
      'hi': '',
      'te': '',
    },
    '6wkr4vk8': {
      'en': 'Total Fare',
      'hi': '',
      'te': '',
    },
    'iz0zreln': {
      'en': '\$15.50',
      'hi': '',
      'te': '',
    },
    '7gyftq6y': {
      'en': 'Base Fare',
      'hi': '',
      'te': '',
    },
    'mjc0nu9q': {
      'en': '\$5.00',
      'hi': '',
      'te': '',
    },
    'vl0wuiqt': {
      'en': 'Payment Method',
      'hi': '',
      'te': '',
    },
    '48s55xcd': {
      'en': 'Credit Card',
      'hi': '',
      'te': '',
    },
    '2h4276ti': {
      'en': 'Status',
      'hi': '',
      'te': '',
    },
    'yzyd2xf0': {
      'en': 'Paid',
      'hi': '',
      'te': '',
    },
    '5nwjd2yc': {
      'en': 'Rate Your Ride',
      'hi': '',
      'te': '',
    },
    '6fi1td6j': {
      'en': 'Report a problem',
      'hi': '',
      'te': '',
    },
    'fq6hj164': {
      'en': ' | ',
      'hi': '',
      'te': '',
    },
    'wxncerht': {
      'en': 'Help & Support',
      'hi': '',
      'te': '',
    },
    '33zia1cf': {
      'en': ' | ',
      'hi': '',
      'te': '',
    },
    '7vl2zftg': {
      'en': 'Lost an item?',
      'hi': '',
      'te': '',
    },
    'mpvy88fi': {
      'en': ' | ',
      'hi': '',
      'te': '',
    },
    '7kp58c7y': {
      'en': 'Share trip details',
      'hi': '',
      'te': '',
    },
    'tpgp8z97': {
      'en': 'Tip Driver (Optional)',
      'hi': '',
      'te': '',
    },
    '2rzn0mym': {
      'en': '\$2',
      'hi': '',
      'te': '',
    },
    'kpvfp1xf': {
      'en': '\$5',
      'hi': '',
      'te': '',
    },
    '0fynk5u5': {
      'en': '\$10',
      'hi': '',
      'te': '',
    },
    'ew3x3tmk': {
      'en': 'Custom',
      'hi': '',
      'te': '',
    },
    '7331qu7u': {
      'en': 'Suggestions',
      'hi': '',
      'te': '',
    },
    '02dtdzvc': {
      'en': 'Rebook your last location',
      'hi': '',
      'te': '',
    },
    'smz87xjz': {
      'en': 'Save this drop location',
      'hi': '',
      'te': '',
    },
    'byt66rmt': {
      'en': 'Thanks for riding with us! · Safety is our priority',
      'hi': '',
      'te': '',
    },
  },
  // reviews
  {
    '0yhjk2c3': {
      'en': 'Trip Summary',
      'hi': '',
      'te': '',
    },
    '7482iwxb': {
      'en': 'Bharath',
      'hi': '',
      'te': '',
    },
    'jbyhqqg3': {
      'en': 'Fare: \$12.50',
      'hi': '',
      'te': '',
    },
    'rpt36sv1': {
      'en': 'Route: 123 Main St to 456 Oak Ave',
      'hi': '',
      'te': '',
    },
    'if0a8nrr': {
      'en': 'Rate Your Trip',
      'hi': '',
      'te': '',
    },
    'a00tj7z9': {
      'en': '1 Star\" \\ \"2 Stars\" \\ \"3 Stars\" \\ \"4 Stars',
      'hi': '',
      'te': '',
    },
    'd95i27h2': {
      'en': '5 Stars',
      'hi': '',
      'te': '',
    },
    'xy4is6yq': {
      'en': 'Optional Tags',
      'hi': '',
      'te': '',
    },
    'lg5on7em': {
      'en': 'Friendly\" \\ \"Safe\" \\ \"Worst\" \\ \"Fast',
      'hi': '',
      'te': '',
    },
    'lw2hpxv7': {
      'en': 'Affordable',
      'hi': '',
      'te': '',
    },
    'noto88qg': {
      'en': 'Optional Comments',
      'hi': '',
      'te': '',
    },
    'a2jbhg9r': {
      'en': 'Add your comments...',
      'hi': '',
      'te': '',
    },
    'wdtlzwwe': {
      'en': 'Add Photos',
      'hi': '',
      'te': '',
    },
    '87drjemk': {
      'en': 'Add photos',
      'hi': '',
      'te': '',
    },
    '8styiovi': {
      'en': 'Skip',
      'hi': '',
      'te': '',
    },
    '81smp27x': {
      'en': 'Submit Review',
      'hi': '',
      'te': '',
    },
  },
  // Miscellaneous
  {
    '1k7c97to': {
      'en': '',
      'hi': '',
      'te': '',
    },
    '3j8hsoyb': {
      'en': 'Allow Notification',
      'hi': '',
      'te': '',
    },
    'hl9sq5w1': {
      'en': 'Allow Location',
      'hi': '',
      'te': '',
    },
    'il0x470m': {
      'en': '',
      'hi': '',
      'te': '',
    },
    'grcdu80x': {
      'en': '',
      'hi': '',
      'te': '',
    },
    'zhnss238': {
      'en': '',
      'hi': '',
      'te': '',
    },
    '80d2q2of': {
      'en': '',
      'hi': '',
      'te': '',
    },
    'txqtzfi9': {
      'en': '',
      'hi': '',
      'te': '',
    },
    'km8s16pb': {
      'en': '',
      'hi': '',
      'te': '',
    },
    '3frlu4on': {
      'en': '',
      'hi': '',
      'te': '',
    },
    '2uvtdyx1': {
      'en': '',
      'hi': '',
      'te': '',
    },
    'ht806lil': {
      'en': '',
      'hi': '',
      'te': '',
    },
    'ebdkb0h2': {
      'en': '',
      'hi': '',
      'te': '',
    },
    'opg8t6we': {
      'en': '',
      'hi': '',
      'te': '',
    },
    'wns4o5pt': {
      'en': '',
      'hi': '',
      'te': '',
    },
    'y5wkpu4r': {
      'en': '',
      'hi': '',
      'te': '',
    },
    'gm5w49nn': {
      'en': '',
      'hi': '',
      'te': '',
    },
    '4pvkeeoe': {
      'en': '',
      'hi': '',
      'te': '',
    },
    '9j4ii7im': {
      'en': '',
      'hi': '',
      'te': '',
    },
    'tnl2vzl7': {
      'en': '',
      'hi': '',
      'te': '',
    },
    'bi921mey': {
      'en': '',
      'hi': '',
      'te': '',
    },
    'brsrxxpc': {
      'en': '',
      'hi': '',
      'te': '',
    },
    'jy1mqc03': {
      'en': '',
      'hi': '',
      'te': '',
    },
    'v98krr7z': {
      'en': '',
      'hi': '',
      'te': '',
    },
    'u745jhgp': {
      'en': '',
      'hi': '',
      'te': '',
    },
    '35v2nqx0': {
      'en': '',
      'hi': '',
      'te': '',
    },
    'jy9uagvs': {
      'en': '',
      'hi': '',
      'te': '',
    },
    'gr1avdi1': {
      'en': '',
      'hi': '',
      'te': '',
    },
  },
].reduce((a, b) => a..addAll(b));
