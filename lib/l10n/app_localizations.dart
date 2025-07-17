import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_cs.dart';
import 'app_localizations_de.dart';
import 'app_localizations_el.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fa.dart';
import 'app_localizations_fi.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ha.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_hu.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pa.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ro.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_sv.dart';
import 'app_localizations_th.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_uk.dart';
import 'app_localizations_ur.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('bn'),
    Locale('cs'),
    Locale('de'),
    Locale('el'),
    Locale('en'),
    Locale('es'),
    Locale('fa'),
    Locale('fi'),
    Locale('fr'),
    Locale('ha'),
    Locale('hi'),
    Locale('hu'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('nl'),
    Locale('pa'),
    Locale('pl'),
    Locale('pt'),
    Locale('ro'),
    Locale('ru'),
    Locale('sv'),
    Locale('th'),
    Locale('tr'),
    Locale('uk'),
    Locale('ur'),
    Locale('vi'),
    Locale('zh')
  ];

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @multiParamHelp.
  ///
  /// In en, this message translates to:
  /// **'Multi-parameter Function Help'**
  String get multiParamHelp;

  /// No description provided for @aiDesigner.
  ///
  /// In en, this message translates to:
  /// **'AI Designer'**
  String get aiDesigner;

  /// No description provided for @imageWorkshop.
  ///
  /// In en, this message translates to:
  /// **'Image Generation Workshop'**
  String get imageWorkshop;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Queee Calculator (English)'**
  String get appTitle;

  /// No description provided for @aiDesignerScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Designer'**
  String get aiDesignerScreenTitle;

  /// No description provided for @aiDesignerTextFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your calculator design needs...'**
  String get aiDesignerTextFieldHint;

  /// No description provided for @imageGeneration.
  ///
  /// In en, this message translates to:
  /// **'Image Generation Workshop'**
  String get imageGeneration;

  /// No description provided for @themeSettings.
  ///
  /// In en, this message translates to:
  /// **'Theme Settings'**
  String get themeSettings;

  /// No description provided for @welcomeMessage1.
  ///
  /// In en, this message translates to:
  /// **'👋 Hello! I\'m your exclusive calculator function designer'**
  String get welcomeMessage1;

  /// No description provided for @welcomeMessage2.
  ///
  /// In en, this message translates to:
  /// **'✨ I\'m a professional calculator function design master! I specialize in designing and extending calculator function logic for you!\n\n🚀 I\'m specifically responsible for:\n• Function extension (scientific calculation, financial tools, unit conversion)\n• Smart calculation (equation solving, data analysis, statistical calculation)\n• Practical tools (exchange rate conversion, discount calculation, loan calculation)\n• Button function definition (adding new calculation buttons and functions)\n\n⚠️ Note: I\'m only responsible for function design, not appearance styling (background images, colors, fonts, etc.). For appearance modifications, please use the \"Image Generation Workshop\"!'**
  String get welcomeMessage2;

  /// No description provided for @welcomeMessage3.
  ///
  /// In en, this message translates to:
  /// **'💡 **Quick Start Examples**:\n\n🏦 **Financial Calculation**:\n\"3.5% interest rate, 30-year loan, input loan amount, output monthly mortgage\"\n\"4% annual interest compound calculation, 10-year investment period\"\n\"USD to CNY exchange rate 7.2, currency conversion\"\n\n🔬 **Scientific Calculation**:\n\"Add power operations, logarithms, trigonometric functions\"\n\"Add statistical functions: mean, standard deviation, variance\"\n\"Add combination and permutation calculations\"\n\n💼 **Practical Tools**:\n\"10% off, 15% off, 30% off discount calculator\"\n\"BMI calculator, input height and weight to calculate health index\"\n\"Unit conversion: cm to inches, kg to pounds\"\n\n🎯 **Usage Tips**:\n• Describe specific needs, I\'ll automatically generate corresponding buttons\n• Specify parameter ranges, such as \"3.5% interest rate\" will preset parameters\n• Mention usage scenarios, I\'ll optimize the operation process'**
  String get welcomeMessage3;

  /// No description provided for @aiDesignerWorking.
  ///
  /// In en, this message translates to:
  /// **'🎯 AI Designer is working'**
  String get aiDesignerWorking;

  /// No description provided for @aiDesignerWorkingDesc.
  ///
  /// In en, this message translates to:
  /// **'Designing exclusive calculator functions for you...'**
  String get aiDesignerWorkingDesc;

  /// No description provided for @designComplete.
  ///
  /// In en, this message translates to:
  /// **'✅ Function design completed! Automatically applied to calculator.'**
  String get designComplete;

  /// No description provided for @designCompleteWithName.
  ///
  /// In en, this message translates to:
  /// **'🎉 {name} successfully applied!'**
  String designCompleteWithName(Object name);

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @sorryDifficulty.
  ///
  /// In en, this message translates to:
  /// **'😅 Sorry, I encountered some difficulties. Can you describe your idea in a different way?'**
  String get sorryDifficulty;

  /// No description provided for @smallProblem.
  ///
  /// In en, this message translates to:
  /// **'😓 There was a small problem: {error}\n\nDon\'t worry, let\'s try again!'**
  String smallProblem(Object error);

  /// No description provided for @networkTest.
  ///
  /// In en, this message translates to:
  /// **'Network Connection Test'**
  String get networkTest;

  /// No description provided for @testingConnection.
  ///
  /// In en, this message translates to:
  /// **'Testing AI service connection...'**
  String get testingConnection;

  /// No description provided for @connectionSuccess.
  ///
  /// In en, this message translates to:
  /// **'Connection Successful'**
  String get connectionSuccess;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection Failed'**
  String get connectionFailed;

  /// No description provided for @connectionSuccessDesc.
  ///
  /// In en, this message translates to:
  /// **'✅ AI service connection is normal, you can use AI customization features normally.'**
  String get connectionSuccessDesc;

  /// No description provided for @connectionFailedDesc.
  ///
  /// In en, this message translates to:
  /// **'❌ Unable to connect to AI service. Please check network connection or try again later.\n\nPossible reasons:\n• Network connection issues\n• Firewall blocking\n• Service temporarily unavailable'**
  String get connectionFailedDesc;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @testFailed.
  ///
  /// In en, this message translates to:
  /// **'Test Failed'**
  String get testFailed;

  /// No description provided for @testFailedDesc.
  ///
  /// In en, this message translates to:
  /// **'An error occurred during testing:\n{error}'**
  String testFailedDesc(Object error);

  /// No description provided for @quickRepliesTitle.
  ///
  /// In en, this message translates to:
  /// **'🎯 Practical Personalized Case Library'**
  String get quickRepliesTitle;

  /// No description provided for @quickRepliesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Simple and practical, but full of personalized calculation functions'**
  String get quickRepliesSubtitle;

  /// No description provided for @progressiveDesign.
  ///
  /// In en, this message translates to:
  /// **'💡 Progressive Design Philosophy'**
  String get progressiveDesign;

  /// No description provided for @progressiveDesignDesc.
  ///
  /// In en, this message translates to:
  /// **'Each level adds new functions based on the previous level, Level 1→Level 20 gradually builds a complete professional calculator'**
  String get progressiveDesignDesc;

  /// No description provided for @startNewConversation.
  ///
  /// In en, this message translates to:
  /// **'Start New Conversation'**
  String get startNewConversation;

  /// No description provided for @startNewConversationDesc.
  ///
  /// In en, this message translates to:
  /// **'Start a completely new design conversation?\n\nThe calculator will be reset to default style.'**
  String get startNewConversationDesc;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @resetSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Reset to default calculator functions, background images from image workshop preserved!'**
  String get resetSuccess;

  /// No description provided for @messageOptions.
  ///
  /// In en, this message translates to:
  /// **'Message Options'**
  String get messageOptions;

  /// No description provided for @copyMessage.
  ///
  /// In en, this message translates to:
  /// **'Copy Message'**
  String get copyMessage;

  /// No description provided for @editMessage.
  ///
  /// In en, this message translates to:
  /// **'Edit Message'**
  String get editMessage;

  /// No description provided for @deleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete Message'**
  String get deleteMessage;

  /// No description provided for @messageCopied.
  ///
  /// In en, this message translates to:
  /// **'Message copied to clipboard'**
  String get messageCopied;

  /// No description provided for @editMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Message'**
  String get editMessageTitle;

  /// No description provided for @editMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Enter new message content...'**
  String get editMessageHint;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @messageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Message updated'**
  String get messageUpdated;

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed: {error}'**
  String updateFailed(Object error);

  /// No description provided for @deleteMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Message'**
  String get deleteMessageTitle;

  /// No description provided for @deleteMessageDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this message? This action cannot be undone.'**
  String get deleteMessageDesc;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @messageDeleted.
  ///
  /// In en, this message translates to:
  /// **'Message deleted'**
  String get messageDeleted;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String deleteFailed(Object error);

  /// No description provided for @designing.
  ///
  /// In en, this message translates to:
  /// **'Designing...'**
  String get designing;

  /// No description provided for @quickIdeas.
  ///
  /// In en, this message translates to:
  /// **'Quick Ideas'**
  String get quickIdeas;

  /// No description provided for @newConversation.
  ///
  /// In en, this message translates to:
  /// **'New Conversation'**
  String get newConversation;

  /// No description provided for @describeCalculator.
  ///
  /// In en, this message translates to:
  /// **'Describe your calculator...'**
  String get describeCalculator;

  /// No description provided for @testNetworkConnection.
  ///
  /// In en, this message translates to:
  /// **'Test Network Connection'**
  String get testNetworkConnection;

  /// No description provided for @buttonBackground.
  ///
  /// In en, this message translates to:
  /// **'Button'**
  String get buttonBackground;

  /// No description provided for @appBackground.
  ///
  /// In en, this message translates to:
  /// **'APP Background'**
  String get appBackground;

  /// No description provided for @displayArea.
  ///
  /// In en, this message translates to:
  /// **'Display Area'**
  String get displayArea;

  /// No description provided for @opacityControl.
  ///
  /// In en, this message translates to:
  /// **'Opacity Control'**
  String get opacityControl;

  /// No description provided for @buttonOpacity.
  ///
  /// In en, this message translates to:
  /// **'Button Opacity'**
  String get buttonOpacity;

  /// No description provided for @displayOpacity.
  ///
  /// In en, this message translates to:
  /// **'Display Opacity'**
  String get displayOpacity;

  /// No description provided for @appBackgroundOpacity.
  ///
  /// In en, this message translates to:
  /// **'APP Background Opacity'**
  String get appBackgroundOpacity;

  /// No description provided for @customGeneration.
  ///
  /// In en, this message translates to:
  /// **'Custom Generation'**
  String get customGeneration;

  /// No description provided for @appBackgroundPrompt.
  ///
  /// In en, this message translates to:
  /// **'Describe the APP background you want...'**
  String get appBackgroundPrompt;

  /// No description provided for @generateAppBackground.
  ///
  /// In en, this message translates to:
  /// **'Generate APP Background'**
  String get generateAppBackground;

  /// No description provided for @quickSelection.
  ///
  /// In en, this message translates to:
  /// **'Quick Selection'**
  String get quickSelection;

  /// No description provided for @appBackgroundQuickExamples.
  ///
  /// In en, this message translates to:
  /// **'APP Background Quick Examples'**
  String get appBackgroundQuickExamples;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @resetToDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset to Default'**
  String get resetToDefault;

  /// No description provided for @resetToDefaultDesc.
  ///
  /// In en, this message translates to:
  /// **'Reset all background images and opacity settings to default?'**
  String get resetToDefaultDesc;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @buttonBackgroundPrompt.
  ///
  /// In en, this message translates to:
  /// **'Describe the button background you want...'**
  String get buttonBackgroundPrompt;

  /// No description provided for @generateButtonBackground.
  ///
  /// In en, this message translates to:
  /// **'Generate Button Background'**
  String get generateButtonBackground;

  /// No description provided for @selectButtons.
  ///
  /// In en, this message translates to:
  /// **'Select Buttons'**
  String get selectButtons;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselectAll;

  /// No description provided for @buttonPatternPrompt.
  ///
  /// In en, this message translates to:
  /// **'Describe the button pattern you want...'**
  String get buttonPatternPrompt;

  /// No description provided for @generateButtonPattern.
  ///
  /// In en, this message translates to:
  /// **'Generate Button Pattern'**
  String get generateButtonPattern;

  /// No description provided for @displayBackgroundPrompt.
  ///
  /// In en, this message translates to:
  /// **'Describe the display area background you want...'**
  String get displayBackgroundPrompt;

  /// No description provided for @generateDisplayBackground.
  ///
  /// In en, this message translates to:
  /// **'Generate Display Background'**
  String get generateDisplayBackground;

  /// No description provided for @displayBackgroundQuickExamples.
  ///
  /// In en, this message translates to:
  /// **'Display Background Quick Examples'**
  String get displayBackgroundQuickExamples;

  /// No description provided for @thinkingProcess.
  ///
  /// In en, this message translates to:
  /// **'View Thinking Process'**
  String get thinkingProcess;

  /// No description provided for @appliedToCalculator.
  ///
  /// In en, this message translates to:
  /// **'Applied to Calculator'**
  String get appliedToCalculator;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @aiAssistant.
  ///
  /// In en, this message translates to:
  /// **'🤖 AI Assistant'**
  String get aiAssistant;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'bn',
        'cs',
        'de',
        'el',
        'en',
        'es',
        'fa',
        'fi',
        'fr',
        'ha',
        'hi',
        'hu',
        'id',
        'it',
        'ja',
        'ko',
        'nl',
        'pa',
        'pl',
        'pt',
        'ro',
        'ru',
        'sv',
        'th',
        'tr',
        'uk',
        'ur',
        'vi',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'bn':
      return AppLocalizationsBn();
    case 'cs':
      return AppLocalizationsCs();
    case 'de':
      return AppLocalizationsDe();
    case 'el':
      return AppLocalizationsEl();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fa':
      return AppLocalizationsFa();
    case 'fi':
      return AppLocalizationsFi();
    case 'fr':
      return AppLocalizationsFr();
    case 'ha':
      return AppLocalizationsHa();
    case 'hi':
      return AppLocalizationsHi();
    case 'hu':
      return AppLocalizationsHu();
    case 'id':
      return AppLocalizationsId();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'nl':
      return AppLocalizationsNl();
    case 'pa':
      return AppLocalizationsPa();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ro':
      return AppLocalizationsRo();
    case 'ru':
      return AppLocalizationsRu();
    case 'sv':
      return AppLocalizationsSv();
    case 'th':
      return AppLocalizationsTh();
    case 'tr':
      return AppLocalizationsTr();
    case 'uk':
      return AppLocalizationsUk();
    case 'ur':
      return AppLocalizationsUr();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
