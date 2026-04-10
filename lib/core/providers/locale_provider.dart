import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Locale provider matching React app's i18n exactly
/// Persists to SharedPreferences with key 'app_language'
/// Supports 'en' and 'hi'
class LocaleProvider extends ChangeNotifier {
  String _lang = 'en';
  String get lang => _lang;
  bool get isEnglish => _lang == 'en';
  bool get isHindi => _lang == 'hi';

  LocaleProvider() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('app_language');
      if (saved == 'hi' || saved == 'en') {
        _lang = saved!;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setLang(String lang) async {
    if (lang != 'en' && lang != 'hi') return;
    _lang = lang;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', lang);
    } catch (_) {}
  }

  /// Translate a key into current language.
  /// Falls back to English, then to the key itself.
  String t(String key) {
    return _translations[_lang]?[key] ?? _translations['en']?[key] ?? key;
  }

  // ===== TRANSLATIONS (matches React i18n.tsx exactly) =====
  static const Map<String, Map<String, String>> _translations = {
    'en': {
      // Navigation
      'dashboard': 'Dashboard',
      'students': 'Students',
      'attendance': 'Attendance',
      'buses': 'Buses',
      'live_tracking': 'Live Tracking',
      'payments': 'Payments',
      'notifications': 'Notifications',
      'settings': 'Settings',
      'support': 'Support',
      'profile': 'Profile',
      'logout': 'Logout',
      'bus_admins': 'Bus Admins',
      'documentation': 'Documentation',
      'routes': 'Routes',
      'reports': 'Reports',
      'student_profile': 'Student Profile',
      'attendance_history': 'Attendance History',
      'bus_camera': 'Bus Camera',

      // Auth
      'login': 'Login',
      'register': 'Register',
      'email': 'Email',
      'password': 'Password',
      'phone': 'Phone',
      'submit': 'Submit',
      'cancel': 'Cancel',
      'save': 'Save',
      'search': 'Search',
      'loading': 'Loading',
      'parent_terminal': 'Parent Terminal',
      'admin_terminal': 'Bus Admin Terminal',
      'admission_number': 'Admission Number',
      'forgot_password': 'Forgot Password',
      'new_user': 'New User?',
      'register_account': 'Register Account',
      'access_admin': 'Access Bus Admin Terminal',
      'back_to_parent': 'Back to Parent Portal',

      // Fees
      'fee_history': 'Fee History',
      'pay_now': 'Pay Now',
      'download_receipt': 'Download Receipt',
      'pending': 'Pending',
      'paid': 'Paid',
      'overdue': 'Overdue',
      'partial': 'Partial',
      'total_due': 'Total Due',
      'base_fee': 'Base Fee',
      'late_fee': 'Late Fee',
      'discount': 'Discount',
      'amount': 'Amount',
      'month': 'Month',
      'year': 'Year',
      'fee_ledger': 'Fee Ledger',
      'payment_history': 'Payment History',
      'total_cleared': 'Total Cleared',
      'outstanding': 'Outstanding',
      'overdue_months': 'Overdue Months',
      'billing_period': 'Billing Period',
      'pay_previous': 'Pay previous month first',
      'future_scheduled': 'Future Scheduled',

      // Support
      'support_center': 'Support Center',
      'submit_ticket': 'Submit Ticket',
      'call_support': 'Call Support',
      'email_us': 'Email Us',
      'faq': 'FAQ',
      'chat_support': 'Chat Support',
      'type_message': 'Type a message...',
      'we_help': "We're here to help you 24/7",
      'ticket_submitted': 'Ticket Submitted Successfully',
      'respond_24h': 'Our team will respond within 24 hours.',

      // Language
      'language': 'Language',
      'english': 'English',
      'hindi': 'Hindi',
      'select_language': 'Select Language',

      // Status
      'no_data': 'No Data Found',
      'error': 'Error',
      'success': 'Success',
      'warning': 'Warning',
      'active': 'Active',
      'inactive': 'Inactive',

      // Dashboard
      'school_bus_mgmt': 'School Bus Fee Management',
      'realtime_tracking': 'Real-time Tracking',
      'secure_payments': 'Secure Payments',
      'total_students': 'Total Students',
      'total_buses': 'Total Buses',
      'active_routes': 'Active Routes',
      'pending_fees': 'Pending Fees',
      'monthly_revenue': 'Monthly Revenue',
      'family_hub': 'Family Hub',

      // Form fields
      'full_name': 'Full Name',
      'phone_number': 'Phone Number',
      'grade': 'Grade',
      'section': 'Section',
      'boarding_point': 'Boarding Point',
      'route': 'Route',
      'bus_number': 'Bus Number',
      'status': 'Status',
      'date': 'Date',

      // Topbar
      'mark_all_read': 'Mark All Read',
      'alert_center': 'Alert Center',
      'no_alerts': 'No Alerts',
      'global_fleet': 'Global Fleet Link',
      'online': 'Online',
      'enterprise_fleet': 'Enterprise Fleet',
      'main_portal': 'Main Portal',

      // Misc
      'confirm_logout': 'Are you sure you want to logout?',
      'yes': 'Yes',
      'no': 'No',
      'subject': 'Subject',
      'priority': 'Priority',
      'description': 'Description',
      'send': 'Send',
      'close': 'Close',
      'back': 'Back',
      'next': 'Next',
      'view_all': 'View All',
      'filter': 'Filter',
      'clear': 'Clear',
      'today': 'Today',
      'yesterday': 'Yesterday',
      'this_month': 'This Month',
      'pickup': 'Pickup',
      'drop': 'Drop',
      'present': 'Present',
      'absent': 'Absent',
      'user_manual': 'User Manual',
      'safety_policy': 'Safety Policy',
      'terms_of_service': 'Terms of Service',
      'privacy_policy': 'Privacy Policy',

      // Profile
      'edit_profile': 'Edit Profile',
      'password_reset': 'Password Reset',
      'update_info': 'Update your personal information',
      'change_password': 'Change your account password',
      'choose_language': 'Choose your preferred language',

      // Routes/Children
      'child_route_details': 'Child Route Details',
      'only_routes_shown': 'Only routes assigned to your children are shown',
      'no_child_routes': 'No child routes found',
      'contact_admin': 'Contact bus admin to assign routes',
      'route_name': 'Route Name',
      'start': 'Start',
      'end': 'End',
      'plate': 'Plate',
      'all_years': 'All Years',
      'all_months': 'All Months',
      'clear_all': 'Clear All',
      'filter_year_month': 'Filter by Year & Month',
      'overall_attendance': 'Overall Attendance Rate',
      'no_records': 'No Records Found',
      'no_attendance_data': 'No attendance data available',
      'no_students': 'No Students Found',
      'link_child': 'Contact admin to link your child',
      'student_name': 'Student Name',
      'actions': 'Actions',
      'receipts': 'Receipts',
      'digital_archive': 'Digital Receipt Archive',
      'submit_a_ticket': 'Submit a Ticket',
      'find_answers': 'Find answers to common questions',
      'support_active': 'Support Active',
      'open_ticket': 'Open Ticket',
      'call_now': 'Call Now',
      'send_email': 'Send Email',
      'all_caught_up': 'All Caught Up',
      'sign_out': 'Sign Out',
      'confirm_sign_out': 'Are you sure you want to sign out?',
    },
    'hi': {
      // Navigation
      'dashboard': 'डैशबोर्ड',
      'students': 'छात्र',
      'attendance': 'उपस्थिति',
      'buses': 'बसें',
      'live_tracking': 'लाइव ट्रैकिंग',
      'payments': 'भुगतान',
      'notifications': 'सूचनाएं',
      'settings': 'सेटिंग्स',
      'support': 'सहायता',
      'profile': 'प्रोफाइल',
      'logout': 'लॉगआउट',
      'bus_admins': 'बस एडमिन',
      'documentation': 'दस्तावेज़',
      'routes': 'मार्ग',
      'reports': 'रिपोर्ट',
      'student_profile': 'छात्र प्रोफाइल',
      'attendance_history': 'उपस्थिति इतिहास',
      'bus_camera': 'बस कैमरा',

      // Auth
      'login': 'लॉगिन',
      'register': 'रजिस्टर',
      'email': 'ईमेल',
      'password': 'पासवर्ड',
      'phone': 'फ़ोन',
      'submit': 'जमा करें',
      'cancel': 'रद्द करें',
      'save': 'सहेजें',
      'search': 'खोजें',
      'loading': 'लोड हो रहा है',
      'parent_terminal': 'अभिभावक पोर्टल',
      'admin_terminal': 'बस एडमिन पोर्टल',
      'admission_number': 'प्रवेश संख्या',
      'forgot_password': 'पासवर्ड भूल गए?',
      'new_user': 'नए उपयोगकर्ता?',
      'register_account': 'खाता बनाएं',
      'access_admin': 'बस एडमिन पोर्टल खोलें',
      'back_to_parent': 'अभिभावक पोर्टल पर वापस',

      // Fees
      'fee_history': 'शुल्क इतिहास',
      'pay_now': 'अभी भुगतान करें',
      'download_receipt': 'रसीद डाउनलोड करें',
      'pending': 'लंबित',
      'paid': 'भुगतान किया',
      'overdue': 'बकाया',
      'partial': 'आंशिक',
      'total_due': 'कुल देय',
      'base_fee': 'मूल शुल्क',
      'late_fee': 'विलंब शुल्क',
      'discount': 'छूट',
      'amount': 'राशि',
      'month': 'महीना',
      'year': 'वर्ष',
      'fee_ledger': 'शुल्क खाता',
      'payment_history': 'भुगतान इतिहास',
      'total_cleared': 'कुल भुगतान',
      'outstanding': 'बकाया',
      'overdue_months': 'बकाया महीने',
      'billing_period': 'बिलिंग अवधि',
      'pay_previous': 'पहले पिछले महीने का भुगतान करें',
      'future_scheduled': 'भविष्य निर्धारित',

      // Support
      'support_center': 'सहायता केंद्र',
      'submit_ticket': 'टिकट जमा करें',
      'call_support': 'कॉल करें',
      'email_us': 'ईमेल करें',
      'faq': 'सामान्य प्रश्न',
      'chat_support': 'चैट सहायता',
      'type_message': 'संदेश लिखें...',
      'we_help': 'हम आपकी 24/7 मदद के लिए यहाँ हैं',
      'ticket_submitted': 'टिकट सफलतापूर्वक जमा हुआ',
      'respond_24h': 'हमारी टीम 24 घंटे में जवाब देगी।',

      // Language
      'language': 'भाषा',
      'english': 'अंग्रेज़ी',
      'hindi': 'हिन्दी',
      'select_language': 'भाषा चुनें',

      // Status
      'no_data': 'कोई डेटा नहीं मिला',
      'error': 'त्रुटि',
      'success': 'सफल',
      'warning': 'चेतावनी',
      'active': 'सक्रिय',
      'inactive': 'निष्क्रिय',

      // Dashboard
      'school_bus_mgmt': 'स्कूल बस शुल्क प्रबंधन',
      'realtime_tracking': 'रियल-टाइम ट्रैकिंग',
      'secure_payments': 'सुरक्षित भुगतान',
      'total_students': 'कुल छात्र',
      'total_buses': 'कुल बसें',
      'active_routes': 'सक्रिय मार्ग',
      'pending_fees': 'लंबित शुल्क',
      'monthly_revenue': 'मासिक राजस्व',
      'family_hub': 'परिवार हब',

      // Form fields
      'full_name': 'पूरा नाम',
      'phone_number': 'फ़ोन नंबर',
      'grade': 'कक्षा',
      'section': 'सेक्शन',
      'boarding_point': 'बोर्डिंग पॉइंट',
      'route': 'मार्ग',
      'bus_number': 'बस नंबर',
      'status': 'स्थिति',
      'date': 'तारीख',

      // Topbar
      'mark_all_read': 'सभी पढ़ा हुआ करें',
      'alert_center': 'अलर्ट सेंटर',
      'no_alerts': 'कोई अलर्ट नहीं',
      'global_fleet': 'ग्लोबल फ्लीट लिंक',
      'online': 'ऑनलाइन',
      'enterprise_fleet': 'एंटरप्राइज फ्लीट',
      'main_portal': 'मुख्य पोर्टल',

      // Misc
      'confirm_logout': 'क्या आप लॉगआउट करना चाहते हैं?',
      'yes': 'हाँ',
      'no': 'नहीं',
      'subject': 'विषय',
      'priority': 'प्राथमिकता',
      'description': 'विवरण',
      'send': 'भेजें',
      'close': 'बंद करें',
      'back': 'पीछे',
      'next': 'आगे',
      'view_all': 'सभी देखें',
      'filter': 'फ़िल्टर',
      'clear': 'साफ करें',
      'today': 'आज',
      'yesterday': 'कल',
      'this_month': 'इस महीने',
      'pickup': 'पिकअप',
      'drop': 'ड्रॉप',
      'present': 'उपस्थित',
      'absent': 'अनुपस्थित',
      'user_manual': 'उपयोगकर्ता पुस्तिका',
      'safety_policy': 'सुरक्षा नीति',
      'terms_of_service': 'सेवा की शर्तें',
      'privacy_policy': 'गोपनीयता नीति',

      // Profile
      'edit_profile': 'प्रोफाइल संपादित करें',
      'password_reset': 'पासवर्ड रीसेट',
      'update_info': 'अपनी व्यक्तिगत जानकारी अपडेट करें',
      'change_password': 'अपना पासवर्ड बदलें',
      'choose_language': 'अपनी पसंदीदा भाषा चुनें',

      // Routes/Children
      'child_route_details': 'बच्चे के मार्ग विवरण',
      'only_routes_shown': 'केवल आपके बच्चों के मार्ग दिखाए गए हैं',
      'no_child_routes': 'कोई मार्ग नहीं मिला',
      'contact_admin': 'मार्ग जोड़ने के लिए बस व्यवस्थापक से संपर्क करें',
      'route_name': 'मार्ग का नाम',
      'start': 'शुरू',
      'end': 'अंत',
      'plate': 'नंबर प्लेट',
      'all_years': 'सभी वर्ष',
      'all_months': 'सभी महीने',
      'clear_all': 'सब साफ करें',
      'filter_year_month': 'वर्ष और महीने से फ़िल्टर करें',
      'overall_attendance': 'कुल उपस्थिति दर',
      'no_records': 'कोई रिकॉर्ड नहीं',
      'no_attendance_data': 'इस छात्र के लिए कोई उपस्थिति डेटा नहीं',
      'no_students': 'कोई छात्र नहीं मिला',
      'link_child': 'अपने बच्चे को जोड़ने के लिए व्यवस्थापक से संपर्क करें',
      'student_name': 'छात्र का नाम',
      'actions': 'कार्रवाई',
      'receipts': 'रसीदें',
      'digital_archive': 'डिजिटल रसीद संग्रह',
      'submit_a_ticket': 'टिकट जमा करें',
      'find_answers': 'सामान्य प्रश्नों के उत्तर खोजें',
      'support_active': 'सहायता सक्रिय',
      'open_ticket': 'टिकट खोलें',
      'call_now': 'अभी कॉल करें',
      'send_email': 'ईमेल भेजें',
      'all_caught_up': 'सब कुछ पढ़ लिया',
      'sign_out': 'साइन आउट',
      'confirm_sign_out': 'क्या आप साइन आउट करना चाहते हैं?',
    },
  };
}
