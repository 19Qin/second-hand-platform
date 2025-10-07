import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('en', 'US'),
    Locale('zh', 'CN'),
  ];

  // Common
  String get appName => _localizedValues[locale.languageCode]?['appName'] ?? 'Fliliy';
  String get ok => _localizedValues[locale.languageCode]?['ok'] ?? 'OK';
  String get cancel => _localizedValues[locale.languageCode]?['cancel'] ?? 'Cancel';
  String get save => _localizedValues[locale.languageCode]?['save'] ?? 'Save';
  String get edit => _localizedValues[locale.languageCode]?['edit'] ?? 'Edit';
  String get delete => _localizedValues[locale.languageCode]?['delete'] ?? 'Delete';
  String get confirm => _localizedValues[locale.languageCode]?['confirm'] ?? 'Confirm';
  String get back => _localizedValues[locale.languageCode]?['back'] ?? 'Back';
  String get next => _localizedValues[locale.languageCode]?['next'] ?? 'Next';
  String get loading => _localizedValues[locale.languageCode]?['loading'] ?? 'Loading...';
  String get error => _localizedValues[locale.languageCode]?['error'] ?? 'Error';
  String get success => _localizedValues[locale.languageCode]?['success'] ?? 'Success';
  String get warning => _localizedValues[locale.languageCode]?['warning'] ?? 'Warning';
  String get maintenance => _localizedValues[locale.languageCode]?['maintenance'] ?? 'Under Maintenance';
  String get maintenanceMessage => _localizedValues[locale.languageCode]?['maintenanceMessage'] ?? 'This feature is under maintenance, please try again later.';

  // Auth
  String get login => _localizedValues[locale.languageCode]?['login'] ?? 'Login';
  String get register => _localizedValues[locale.languageCode]?['register'] ?? 'Register';
  String get logout => _localizedValues[locale.languageCode]?['logout'] ?? 'Logout';
  String get mobileNumber => _localizedValues[locale.languageCode]?['mobileNumber'] ?? 'Mobile Number';
  String get password => _localizedValues[locale.languageCode]?['password'] ?? 'Password';
  String get confirmPassword => _localizedValues[locale.languageCode]?['confirmPassword'] ?? 'Confirm Password';
  String get verificationCode => _localizedValues[locale.languageCode]?['verificationCode'] ?? 'Verification Code';
  String get send => _localizedValues[locale.languageCode]?['send'] ?? 'Send';
  String get resend => _localizedValues[locale.languageCode]?['resend'] ?? 'Resend';
  String get username => _localizedValues[locale.languageCode]?['username'] ?? 'Username';
  String get email => _localizedValues[locale.languageCode]?['email'] ?? 'Email';
  String get agreeTerms => _localizedValues[locale.languageCode]?['agreeTerms'] ?? 'I agree with Terms & Conditions';
  String get termsAndConditions => _localizedValues[locale.languageCode]?['termsAndConditions'] ?? 'Terms & Conditions';
  String get userAgreement => _localizedValues[locale.languageCode]?['userAgreement'] ?? 'User Agreement';

  // Profile
  String get profile => _localizedValues[locale.languageCode]?['profile'] ?? 'Profile';
  String get editProfile => _localizedValues[locale.languageCode]?['editProfile'] ?? 'Edit Profile';
  String get settings => _localizedValues[locale.languageCode]?['settings'] ?? 'Settings';
  String get language => _localizedValues[locale.languageCode]?['language'] ?? 'Language';
  String get english => _localizedValues[locale.languageCode]?['english'] ?? 'English';
  String get chinese => _localizedValues[locale.languageCode]?['chinese'] ?? '中文';
  String get gender => _localizedValues[locale.languageCode]?['gender'] ?? 'Gender';
  String get male => _localizedValues[locale.languageCode]?['male'] ?? 'Male';
  String get female => _localizedValues[locale.languageCode]?['female'] ?? 'Female';
  String get unknown => _localizedValues[locale.languageCode]?['unknown'] ?? 'Unknown';
  String get birthday => _localizedValues[locale.languageCode]?['birthday'] ?? 'Birthday';
  String get location => _localizedValues[locale.languageCode]?['location'] ?? 'Location';
  String get bio => _localizedValues[locale.languageCode]?['bio'] ?? 'Bio';
  String get changeAvatar => _localizedValues[locale.languageCode]?['changeAvatar'] ?? 'Change Avatar';
  String get takePhoto => _localizedValues[locale.languageCode]?['takePhoto'] ?? 'Take Photo';
  String get chooseFromGallery => _localizedValues[locale.languageCode]?['chooseFromGallery'] ?? 'Choose from Gallery';

  // Products
  String get products => _localizedValues[locale.languageCode]?['products'] ?? 'Products';
  String get myProducts => _localizedValues[locale.languageCode]?['myProducts'] ?? 'My Products';
  String get published => _localizedValues[locale.languageCode]?['published'] ?? 'Published';
  String get active => _localizedValues[locale.languageCode]?['active'] ?? 'Active';
  String get sold => _localizedValues[locale.languageCode]?['sold'] ?? 'Sold';
  String get favorites => _localizedValues[locale.languageCode]?['favorites'] ?? 'Favorites';
  String get price => _localizedValues[locale.languageCode]?['price'] ?? 'Price';
  String get condition => _localizedValues[locale.languageCode]?['condition'] ?? 'Condition';
  String get likeNew => _localizedValues[locale.languageCode]?['likeNew'] ?? 'Like New';
  String get good => _localizedValues[locale.languageCode]?['good'] ?? 'Good';
  String get fair => _localizedValues[locale.languageCode]?['fair'] ?? 'Fair';

  // Chat
  String get chat => _localizedValues[locale.languageCode]?['chat'] ?? 'Chat';
  String get messages => _localizedValues[locale.languageCode]?['messages'] ?? 'Messages';
  String get sendMessage => _localizedValues[locale.languageCode]?['sendMessage'] ?? 'Send Message';

  // Navigation
  String get home => _localizedValues[locale.languageCode]?['home'] ?? 'Home';
  String get search => _localizedValues[locale.languageCode]?['search'] ?? 'Search';
  String get publish => _localizedValues[locale.languageCode]?['publish'] ?? 'Publish';
  String get chatTab => _localizedValues[locale.languageCode]?['chatTab'] ?? 'Chat';
  String get profileTab => _localizedValues[locale.languageCode]?['profileTab'] ?? 'Profile';

  // User Agreement
  String get agreementOverview => _localizedValues[locale.languageCode]?['agreementOverview'] ?? 'I. Agreement Overview';
  String get agreementOverviewContent => _localizedValues[locale.languageCode]?['agreementOverviewContent'] ?? 'This Agreement is a legal agreement between you ("User") and [Platform Name] ("Platform") regarding the use of Platform services. By registering, logging in, or using the Platform services, you agree to all terms and conditions of this Agreement. If you do not agree with any part of this Agreement, please do not register or use the Platform services.';

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appName': 'Fliliy',
      'ok': 'OK',
      'cancel': 'Cancel',
      'save': 'Save',
      'edit': 'Edit',
      'delete': 'Delete',
      'confirm': 'Confirm',
      'back': 'Back',
      'next': 'Next',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'warning': 'Warning',
      'maintenance': 'Under Maintenance',
      'maintenanceMessage': 'This feature is under maintenance, please try again later.',
      'login': 'Login',
      'register': 'Register',
      'logout': 'Logout',
      'mobileNumber': 'Mobile Number',
      'password': 'Password',
      'confirmPassword': 'Confirm Password',
      'verificationCode': 'Verification Code',
      'send': 'Send',
      'resend': 'Resend',
      'username': 'Username',
      'email': 'Email',
      'agreeTerms': 'I agree with Terms & Conditions',
      'termsAndConditions': 'Terms & Conditions',
      'userAgreement': 'User Agreement',
      'profile': 'Profile',
      'editProfile': 'Edit Profile',
      'settings': 'Settings',
      'language': 'Language',
      'english': 'English',
      'chinese': '中文',
      'gender': 'Gender',
      'male': 'Male',
      'female': 'Female',
      'unknown': 'Unknown',
      'birthday': 'Birthday',
      'location': 'Location',
      'bio': 'Bio',
      'changeAvatar': 'Change Avatar',
      'takePhoto': 'Take Photo',
      'chooseFromGallery': 'Choose from Gallery',
      'products': 'Products',
      'myProducts': 'My Products',
      'published': 'Published',
      'active': 'Active',
      'sold': 'Sold',
      'favorites': 'Favorites',
      'price': 'Price',
      'condition': 'Condition',
      'likeNew': 'Like New',
      'good': 'Good',
      'fair': 'Fair',
      'chat': 'Chat',
      'messages': 'Messages',
      'sendMessage': 'Send Message',
      'home': 'Home',
      'search': 'Search',
      'publish': 'Publish',
      'chatTab': 'Chat',
      'profileTab': 'Profile',
      'agreementOverview': 'I. Agreement Overview',
      'agreementOverviewContent': 'This Agreement is a legal agreement between you ("User") and [Platform Name] ("Platform") regarding the use of Platform services. By registering, logging in, or using the Platform services, you agree to all terms and conditions of this Agreement. If you do not agree with any part of this Agreement, please do not register or use the Platform services.',
    },
    'zh': {
      'appName': 'Fliliy',
      'ok': '确定',
      'cancel': '取消',
      'save': '保存',
      'edit': '编辑',
      'delete': '删除',
      'confirm': '确认',
      'back': '返回',
      'next': '下一步',
      'loading': '加载中...',
      'error': '错误',
      'success': '成功',
      'warning': '警告',
      'maintenance': '功能维护中',
      'maintenanceMessage': '该功能正在维护中，请稍后再试。',
      'login': '登录',
      'register': '注册',
      'logout': '退出登录',
      'mobileNumber': '手机号码',
      'password': '密码',
      'confirmPassword': '确认密码',
      'verificationCode': '验证码',
      'send': '发送',
      'resend': '重新发送',
      'username': '用户名',
      'email': '邮箱',
      'agreeTerms': '我同意条款和条件',
      'termsAndConditions': '条款和条件',
      'userAgreement': '用户协议',
      'profile': '个人资料',
      'editProfile': '编辑资料',
      'settings': '设置',
      'language': '语言',
      'english': 'English',
      'chinese': '中文',
      'gender': '性别',
      'male': '男',
      'female': '女',
      'unknown': '未知',
      'birthday': '生日',
      'location': '位置',
      'bio': '个人简介',
      'changeAvatar': '更换头像',
      'takePhoto': '拍照',
      'chooseFromGallery': '从相册选择',
      'products': '商品',
      'myProducts': '我的商品',
      'published': '已发布',
      'active': '在售中',
      'sold': '已售出',
      'favorites': '收藏',
      'price': '价格',
      'condition': '成色',
      'likeNew': '几乎全新',
      'good': '轻微使用痕迹',
      'fair': '明显使用痕迹',
      'chat': '聊天',
      'messages': '消息',
      'sendMessage': '发送消息',
      'home': '首页',
      'search': '搜索',
      'publish': '发布',
      'chatTab': '聊天',
      'profileTab': '个人',
      'agreementOverview': 'I. 协议概述',
      'agreementOverviewContent': '本协议是您（"用户"）与[平台名称]（"平台"）之间关于使用平台服务的法律协议。通过注册、登录或使用平台服务，您同意本协议的所有条款和条件。如果您不同意本协议的任何部分，请不要注册或使用平台服务。',
    },
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
