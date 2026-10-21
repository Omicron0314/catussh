import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L10n
/// returned by `L10n.of(context)`.
///
/// Applications need to include `L10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L10n.localizationsDelegates,
///   supportedLocales: L10n.supportedLocales,
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
/// be consistent with the languages listed in the L10n.supportedLocales
/// property.
abstract class L10n {
  L10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L10n of(BuildContext context) {
    return Localizations.of<L10n>(context, L10n)!;
  }

  static const LocalizationsDelegate<L10n> delegate = _L10nDelegate();

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
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutVersionLine.
  ///
  /// In en, this message translates to:
  /// **'{version} (Flutter) · Linux'**
  String aboutVersionLine(String version);

  /// No description provided for @absolutePathRequired.
  ///
  /// In en, this message translates to:
  /// **'Use an absolute path starting with /.'**
  String get absolutePathRequired;

  /// No description provided for @accentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get accentColor;

  /// No description provided for @accentColorHelp.
  ///
  /// In en, this message translates to:
  /// **'Used when the desktop accent is off or unavailable.'**
  String get accentColorHelp;

  /// No description provided for @acknowledgements.
  ///
  /// In en, this message translates to:
  /// **'Acknowledgements'**
  String get acknowledgements;

  /// No description provided for @addAndConnect.
  ///
  /// In en, this message translates to:
  /// **'Add and Connect'**
  String get addAndConnect;

  /// No description provided for @addServer.
  ///
  /// In en, this message translates to:
  /// **'Add a server'**
  String get addServer;

  /// No description provided for @addServerAction.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addServerAction;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @addressesHidden.
  ///
  /// In en, this message translates to:
  /// **'Addresses hidden'**
  String get addressesHidden;

  /// No description provided for @agreementEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Agreement…'**
  String get agreementEllipsis;

  /// No description provided for @allGroups.
  ///
  /// In en, this message translates to:
  /// **'All Groups'**
  String get allGroups;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'catussh'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'SSH terminal, files and monitor for your servers.'**
  String get appTagline;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @askBeforeClosing.
  ///
  /// In en, this message translates to:
  /// **'Ask before closing a session'**
  String get askBeforeClosing;

  /// No description provided for @askBeforeClosingHelp.
  ///
  /// In en, this message translates to:
  /// **'Confirm before closing a connected terminal or deleting.'**
  String get askBeforeClosingHelp;

  /// No description provided for @authenticateAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Authenticate automatically'**
  String get authenticateAutomatically;

  /// No description provided for @authenticateAutomaticallyHelp.
  ///
  /// In en, this message translates to:
  /// **'Required for Quick Connect.'**
  String get authenticateAutomaticallyHelp;

  /// No description provided for @authentication.
  ///
  /// In en, this message translates to:
  /// **'Authentication'**
  String get authentication;

  /// No description provided for @automatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get automatic;

  /// No description provided for @basedOn.
  ///
  /// In en, this message translates to:
  /// **'Based on'**
  String get basedOn;

  /// No description provided for @basedOnText.
  ///
  /// In en, this message translates to:
  /// **'catussh by mizorewww, the continuation of Rayon by Lakr Aream (@Lakr233) and contributors. This version is not affiliated with or endorsed by them.'**
  String get basedOnText;

  /// No description provided for @bind.
  ///
  /// In en, this message translates to:
  /// **'Bind'**
  String get bind;

  /// No description provided for @bindPort.
  ///
  /// In en, this message translates to:
  /// **'Bind port'**
  String get bindPort;

  /// No description provided for @cache.
  ///
  /// In en, this message translates to:
  /// **'Cache'**
  String get cache;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @cannotConnect.
  ///
  /// In en, this message translates to:
  /// **'Can\'t connect'**
  String get cannotConnect;

  /// No description provided for @cannotOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Can\'t open {name}'**
  String cannotOpenFile(String name);

  /// No description provided for @caretPosition.
  ///
  /// In en, this message translates to:
  /// **'Ln {line}, Col {column}'**
  String caretPosition(int line, int column);

  /// No description provided for @changesReplaced.
  ///
  /// In en, this message translates to:
  /// **'Your changes are replaced by the file on the server.'**
  String get changesReplaced;

  /// No description provided for @checkThenSave.
  ///
  /// In en, this message translates to:
  /// **'Check the connection, then save the server'**
  String get checkThenSave;

  /// No description provided for @chineseSimplified.
  ///
  /// In en, this message translates to:
  /// **'简体中文'**
  String get chineseSimplified;

  /// No description provided for @chineseTraditional.
  ///
  /// In en, this message translates to:
  /// **'繁體中文'**
  String get chineseTraditional;

  /// No description provided for @choose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get choose;

  /// No description provided for @chooseExistingGroup.
  ///
  /// In en, this message translates to:
  /// **'Choose an existing group'**
  String get chooseExistingGroup;

  /// No description provided for @chooseIdentity.
  ///
  /// In en, this message translates to:
  /// **'Choose Identity'**
  String get chooseIdentity;

  /// No description provided for @chooseServer.
  ///
  /// In en, this message translates to:
  /// **'Choose a server'**
  String get chooseServer;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @clearScrollback.
  ///
  /// In en, this message translates to:
  /// **'Clear Scrollback'**
  String get clearScrollback;

  /// No description provided for @clickToOpenTerminal.
  ///
  /// In en, this message translates to:
  /// **'Click to open a terminal'**
  String get clickToOpenTerminal;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @closeAll.
  ///
  /// In en, this message translates to:
  /// **'Close All'**
  String get closeAll;

  /// No description provided for @closeEditor.
  ///
  /// In en, this message translates to:
  /// **'Close Editor'**
  String get closeEditor;

  /// No description provided for @closeEditorOn.
  ///
  /// In en, this message translates to:
  /// **'Close the editor on {name}?'**
  String closeEditorOn(String name);

  /// No description provided for @closeEverythingOn.
  ///
  /// In en, this message translates to:
  /// **'Close everything open on {name}?'**
  String closeEverythingOn(String name);

  /// No description provided for @closeFileName.
  ///
  /// In en, this message translates to:
  /// **'Close {name}'**
  String closeFileName(String name);

  /// No description provided for @closeFileWithoutSaving.
  ///
  /// In en, this message translates to:
  /// **'Close {name} without saving?'**
  String closeFileWithoutSaving(String name);

  /// No description provided for @closeFiles.
  ///
  /// In en, this message translates to:
  /// **'Close Files'**
  String get closeFiles;

  /// No description provided for @closeMonitor.
  ///
  /// In en, this message translates to:
  /// **'Close Monitor'**
  String get closeMonitor;

  /// No description provided for @closeSession.
  ///
  /// In en, this message translates to:
  /// **'Close Session'**
  String get closeSession;

  /// No description provided for @closeSessionOn.
  ///
  /// In en, this message translates to:
  /// **'Close the session on {name}?'**
  String closeSessionOn(String name);

  /// No description provided for @closeTerminal.
  ///
  /// In en, this message translates to:
  /// **'Close Terminal'**
  String get closeTerminal;

  /// No description provided for @closeTitle.
  ///
  /// In en, this message translates to:
  /// **'Close {title}'**
  String closeTitle(String title);

  /// No description provided for @closeTransfer.
  ///
  /// In en, this message translates to:
  /// **'Close the file transfer on {name}?'**
  String closeTransfer(String name);

  /// No description provided for @closeWindow.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeWindow;

  /// No description provided for @codeHint.
  ///
  /// In en, this message translates to:
  /// **'sudo systemctl restart nginx'**
  String get codeHint;

  /// No description provided for @colors.
  ///
  /// In en, this message translates to:
  /// **'Colors'**
  String get colors;

  /// No description provided for @command.
  ///
  /// In en, this message translates to:
  /// **'Command'**
  String get command;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @connectEnter.
  ///
  /// In en, this message translates to:
  /// **'Connect (Enter)'**
  String get connectEnter;

  /// No description provided for @connectFailedReason.
  ///
  /// In en, this message translates to:
  /// **'Could not reach {host} on port {port}.'**
  String connectFailedReason(String host, int port);

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connecting;

  /// No description provided for @connectingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connectingEllipsis;

  /// No description provided for @connection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get connection;

  /// No description provided for @connectionClosed.
  ///
  /// In en, this message translates to:
  /// **'Connection closed'**
  String get connectionClosed;

  /// No description provided for @connectionClosedBanner.
  ///
  /// In en, this message translates to:
  /// **'[*] Connection Closed'**
  String get connectionClosedBanner;

  /// No description provided for @connectionTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection timeout'**
  String get connectionTimeout;

  /// No description provided for @connectionTimeoutHelp.
  ///
  /// In en, this message translates to:
  /// **'How long to wait for a server before giving up.'**
  String get connectionTimeoutHelp;

  /// No description provided for @continue_.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continue_;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'{what} copied'**
  String copied(Object what);

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copyAddress.
  ///
  /// In en, this message translates to:
  /// **'Copy Address'**
  String get copyAddress;

  /// No description provided for @copyCommand.
  ///
  /// In en, this message translates to:
  /// **'Copy SSH Command'**
  String get copyCommand;

  /// No description provided for @copyName.
  ///
  /// In en, this message translates to:
  /// **'Copy Name'**
  String get copyName;

  /// No description provided for @copyPath.
  ///
  /// In en, this message translates to:
  /// **'Copy Path'**
  String get copyPath;

  /// No description provided for @copyPublicKey.
  ///
  /// In en, this message translates to:
  /// **'Copy Public Key'**
  String get copyPublicKey;

  /// No description provided for @cores.
  ///
  /// In en, this message translates to:
  /// **'Cores'**
  String get cores;

  /// No description provided for @couldNotSave.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save {name}. {error}'**
  String couldNotSave(String name, String error);

  /// No description provided for @cpu.
  ///
  /// In en, this message translates to:
  /// **'CPU'**
  String get cpu;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @creatingConnection.
  ///
  /// In en, this message translates to:
  /// **'[*] Creating Connection'**
  String get creatingConnection;

  /// No description provided for @creatingFolderPath.
  ///
  /// In en, this message translates to:
  /// **'Creating Folder {path}...'**
  String creatingFolderPath(String path);

  /// No description provided for @cudaVersion.
  ///
  /// In en, this message translates to:
  /// **'CUDA {version}'**
  String cudaVersion(String version);

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{yesterday} other{{count} days ago}}'**
  String daysAgo(int count);

  /// No description provided for @defaultGroup.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultGroup;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Delete…'**
  String get deleteEllipsis;

  /// No description provided for @deleteFile.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteFile(String name);

  /// No description provided for @deleteFileWarning.
  ///
  /// In en, this message translates to:
  /// **'The file is deleted from the server. This cannot be undone.'**
  String get deleteFileWarning;

  /// No description provided for @deleteFolderWarning.
  ///
  /// In en, this message translates to:
  /// **'The folder and everything in it is deleted from the server. This cannot be undone.'**
  String get deleteFolderWarning;

  /// No description provided for @deleteForward.
  ///
  /// In en, this message translates to:
  /// **'Delete the forward on port {port}?'**
  String deleteForward(int port);

  /// No description provided for @deleteIdentity.
  ///
  /// In en, this message translates to:
  /// **'Delete identity {username}?'**
  String deleteIdentity(String username);

  /// No description provided for @deleteServer.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteServer(String name);

  /// No description provided for @deleteServers.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} servers?'**
  String deleteServers(int count);

  /// No description provided for @deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteTitle(String name);

  /// No description provided for @deletedServer.
  ///
  /// In en, this message translates to:
  /// **'Deleted server'**
  String get deletedServer;

  /// No description provided for @deletingFile.
  ///
  /// In en, this message translates to:
  /// **'Deleting {name}...'**
  String deletingFile(String name);

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselectAll;

  /// No description provided for @discardAndClose.
  ///
  /// In en, this message translates to:
  /// **'Discard Changes and Close'**
  String get discardAndClose;

  /// No description provided for @discardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard Changes'**
  String get discardChanges;

  /// No description provided for @disks.
  ///
  /// In en, this message translates to:
  /// **'Disks'**
  String get disks;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @downloadCancelled.
  ///
  /// In en, this message translates to:
  /// **'Download cancelled'**
  String get downloadCancelled;

  /// No description provided for @downloadComplete.
  ///
  /// In en, this message translates to:
  /// **'Download complete'**
  String get downloadComplete;

  /// No description provided for @downloadEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Download…'**
  String get downloadEllipsis;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String downloadFailed(String error);

  /// No description provided for @downloadHere.
  ///
  /// In en, this message translates to:
  /// **'Download Here'**
  String get downloadHere;

  /// No description provided for @dropToUpload.
  ///
  /// In en, this message translates to:
  /// **'Drop to upload to {path}'**
  String dropToUpload(String path);

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @duplicateServer.
  ///
  /// In en, this message translates to:
  /// **'Duplicate {name}?'**
  String duplicateServer(String name);

  /// No description provided for @durationDaysHours.
  ///
  /// In en, this message translates to:
  /// **'{days}d {hours}h'**
  String durationDaysHours(int days, int hours);

  /// No description provided for @durationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String durationHoursMinutes(int hours, int minutes);

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String durationMinutes(int minutes);

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit…'**
  String get edit;

  /// No description provided for @editAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editAction;

  /// No description provided for @editPortForward.
  ///
  /// In en, this message translates to:
  /// **'Edit Port Forward'**
  String get editPortForward;

  /// No description provided for @editServer.
  ///
  /// In en, this message translates to:
  /// **'Edit Server'**
  String get editServer;

  /// No description provided for @editSnippet.
  ///
  /// In en, this message translates to:
  /// **'Edit Snippet'**
  String get editSnippet;

  /// No description provided for @edited.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get edited;

  /// No description provided for @emptyFolder.
  ///
  /// In en, this message translates to:
  /// **'Empty folder'**
  String get emptyFolder;

  /// No description provided for @emptyServersMessage.
  ///
  /// In en, this message translates to:
  /// **'Saved servers keep their address, port and identity, and open a terminal, files or a monitor.'**
  String get emptyServersMessage;

  /// No description provided for @emptyServersTitle.
  ///
  /// In en, this message translates to:
  /// **'Save a server to reach it in one click'**
  String get emptyServersTitle;

  /// No description provided for @enclosingFolder.
  ///
  /// In en, this message translates to:
  /// **'Enclosing Folder (Alt+Up)'**
  String get enclosingFolder;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @equivalentCommand.
  ///
  /// In en, this message translates to:
  /// **'Equivalent command'**
  String get equivalentCommand;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @eula.
  ///
  /// In en, this message translates to:
  /// **'End User License Agreement'**
  String get eula;

  /// No description provided for @everySeconds.
  ///
  /// In en, this message translates to:
  /// **'Every {seconds} s'**
  String everySeconds(int seconds);

  /// No description provided for @execBegin.
  ///
  /// In en, this message translates to:
  /// **'[*] Execute Begin'**
  String get execBegin;

  /// No description provided for @execCannotConnect.
  ///
  /// In en, this message translates to:
  /// **'[E] Could not connect to the server'**
  String get execCannotConnect;

  /// No description provided for @execCannotSignIn.
  ///
  /// In en, this message translates to:
  /// **'[E] The identity could not sign in'**
  String get execCannotSignIn;

  /// No description provided for @execCompleted.
  ///
  /// In en, this message translates to:
  /// **'[*] Execution completed'**
  String get execCompleted;

  /// No description provided for @execStopped.
  ///
  /// In en, this message translates to:
  /// **'[*] Stopped'**
  String get execStopped;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @failedSftpSetup.
  ///
  /// In en, this message translates to:
  /// **'Failed to setup file transfer protocol'**
  String get failedSftpSetup;

  /// No description provided for @failedToAuthenticate.
  ///
  /// In en, this message translates to:
  /// **'Failed to authenticate connection. Did you forget to add identity or enable auto authentication?'**
  String get failedToAuthenticate;

  /// No description provided for @failedToLoadPath.
  ///
  /// In en, this message translates to:
  /// **'Failed to load {path}: {error}'**
  String failedToLoadPath(String path, String error);

  /// No description provided for @fanSpeed.
  ///
  /// In en, this message translates to:
  /// **'Fan {speed}'**
  String fanSpeed(String speed);

  /// No description provided for @fieldAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get fieldAddress;

  /// No description provided for @fieldComment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get fieldComment;

  /// No description provided for @fieldGroup.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get fieldGroup;

  /// No description provided for @fieldIdentity.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get fieldIdentity;

  /// No description provided for @fieldLastBanner.
  ///
  /// In en, this message translates to:
  /// **'Last banner'**
  String get fieldLastBanner;

  /// No description provided for @fieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fieldName;

  /// No description provided for @fieldPort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get fieldPort;

  /// No description provided for @fieldStartFolder.
  ///
  /// In en, this message translates to:
  /// **'SFTP start folder'**
  String get fieldStartFolder;

  /// No description provided for @fieldUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get fieldUsername;

  /// No description provided for @fifteenMinutes.
  ///
  /// In en, this message translates to:
  /// **'15 min'**
  String get fifteenMinutes;

  /// No description provided for @fileNotReadable.
  ///
  /// In en, this message translates to:
  /// **'The file could not be read as text.'**
  String get fileNotReadable;

  /// No description provided for @fileSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get fileSize;

  /// No description provided for @fileTransfer.
  ///
  /// In en, this message translates to:
  /// **'File Transfer'**
  String get fileTransfer;

  /// No description provided for @filterByGroup.
  ///
  /// In en, this message translates to:
  /// **'Filter by group'**
  String get filterByGroup;

  /// No description provided for @filterThisFolder.
  ///
  /// In en, this message translates to:
  /// **'Filter this folder'**
  String get filterThisFolder;

  /// No description provided for @finishedOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} finished'**
  String finishedOfTotal(int done, int total);

  /// No description provided for @fiveMinutes.
  ///
  /// In en, this message translates to:
  /// **'5 min'**
  String get fiveMinutes;

  /// No description provided for @followSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow System'**
  String get followSystem;

  /// No description provided for @font.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get font;

  /// No description provided for @fontHelp.
  ///
  /// In en, this message translates to:
  /// **'Installed monospace fonts.'**
  String get fontHelp;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get fontSize;

  /// No description provided for @fontSizeHelp.
  ///
  /// In en, this message translates to:
  /// **'Ctrl+= and Ctrl+- change it in a terminal.'**
  String get fontSizeHelp;

  /// No description provided for @forget.
  ///
  /// In en, this message translates to:
  /// **'Forget'**
  String get forget;

  /// No description provided for @forgetAll.
  ///
  /// In en, this message translates to:
  /// **'Forget All…'**
  String get forgetAll;

  /// No description provided for @forgetAllAction.
  ///
  /// In en, this message translates to:
  /// **'Forget All'**
  String get forgetAllAction;

  /// No description provided for @forgetAllHostKeys.
  ///
  /// In en, this message translates to:
  /// **'Forget all saved host keys?'**
  String get forgetAllHostKeys;

  /// No description provided for @forgetAllHostKeysHelp.
  ///
  /// In en, this message translates to:
  /// **'The key each server presents on its next connection is saved as its key.'**
  String get forgetAllHostKeysHelp;

  /// No description provided for @forgetHostKey.
  ///
  /// In en, this message translates to:
  /// **'Forget Host Key…'**
  String get forgetHostKey;

  /// No description provided for @forgetHostKeyExplain.
  ///
  /// In en, this message translates to:
  /// **'The key the server presents on the next connection is saved as its key. Do this only when you know its keys were replaced.'**
  String get forgetHostKeyExplain;

  /// No description provided for @forgetHostKeyOf.
  ///
  /// In en, this message translates to:
  /// **'Forget the host key of {name}?'**
  String forgetHostKeyOf(String name);

  /// No description provided for @forwardFailedAuth.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in, retrying'**
  String get forwardFailedAuth;

  /// No description provided for @forwardFailedConnect.
  ///
  /// In en, this message translates to:
  /// **'Could not connect, retrying'**
  String get forwardFailedConnect;

  /// No description provided for @forwardRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get forwardRunning;

  /// No description provided for @forwardStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped, retrying'**
  String get forwardStopped;

  /// No description provided for @forwardThrough.
  ///
  /// In en, this message translates to:
  /// **'Forward through'**
  String get forwardThrough;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @goAction.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get goAction;

  /// No description provided for @goToFolder.
  ///
  /// In en, this message translates to:
  /// **'Go to Folder'**
  String get goToFolder;

  /// No description provided for @goToFolderShortcut.
  ///
  /// In en, this message translates to:
  /// **'Go to Folder (Ctrl+Shift+G)'**
  String get goToFolderShortcut;

  /// No description provided for @gpu.
  ///
  /// In en, this message translates to:
  /// **'GPU'**
  String get gpu;

  /// No description provided for @gpuCount.
  ///
  /// In en, this message translates to:
  /// **'Graphics · {count, plural, =1{1 GPU} other{{count} GPUs}}'**
  String gpuCount(int count);

  /// No description provided for @graphics.
  ///
  /// In en, this message translates to:
  /// **'Graphics'**
  String get graphics;

  /// No description provided for @groupDefaultHint.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get groupDefaultHint;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @hideAddresses.
  ///
  /// In en, this message translates to:
  /// **'Hide Addresses'**
  String get hideAddresses;

  /// No description provided for @hideNamesAndAddresses.
  ///
  /// In en, this message translates to:
  /// **'Hide Names and Addresses'**
  String get hideNamesAndAddresses;

  /// No description provided for @hideSidebar.
  ///
  /// In en, this message translates to:
  /// **'Hide Sidebar (Ctrl+\\)'**
  String get hideSidebar;

  /// No description provided for @host.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get host;

  /// No description provided for @hostKeyChanged.
  ///
  /// In en, this message translates to:
  /// **'The host key of {host}:{port} has changed, so the connection was refused.'**
  String hostKeyChanged(String host, int port);

  /// No description provided for @hostKeyChangedHelp.
  ///
  /// In en, this message translates to:
  /// **'If the server was reinstalled or its keys were replaced, choose Forget Host Key for it and connect again. If not, something may be intercepting the connection.'**
  String get hostKeyChangedHelp;

  /// No description provided for @hostKeyOffered.
  ///
  /// In en, this message translates to:
  /// **'Offered: {type} {fingerprint}'**
  String hostKeyOffered(String type, String fingerprint);

  /// No description provided for @hostKeySaved.
  ///
  /// In en, this message translates to:
  /// **'Saved: {type} {fingerprint}'**
  String hostKeySaved(String type, String fingerprint);

  /// No description provided for @hostKeysSaved.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No keys saved yet} =1{1 key saved} other{{count} keys saved}}'**
  String hostKeysSaved(int count);

  /// No description provided for @hostPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Host name or IP address'**
  String get hostPlaceholder;

  /// No description provided for @hostname.
  ///
  /// In en, this message translates to:
  /// **'Hostname'**
  String get hostname;

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String hoursAgo(int count);

  /// No description provided for @iAgree.
  ///
  /// In en, this message translates to:
  /// **'I have read and agree to the license'**
  String get iAgree;

  /// No description provided for @iconLabel.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get iconLabel;

  /// No description provided for @identitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Identities'**
  String get identitiesTitle;

  /// No description provided for @identityCouldNotSignIn.
  ///
  /// In en, this message translates to:
  /// **'The selected identity could not sign in to {host}. ({error})'**
  String identityCouldNotSignIn(String host, String error);

  /// No description provided for @identityEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'A username with a password or key.'**
  String get identityEmptyMessage;

  /// No description provided for @identityGroup.
  ///
  /// In en, this message translates to:
  /// **'Group<{group}>'**
  String identityGroup(String group);

  /// No description provided for @identityInUse.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 server uses it and will try automatic identities instead.} other{{count} servers use it and will try automatic identities instead.}}'**
  String identityInUse(int count);

  /// No description provided for @identityLabel.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get identityLabel;

  /// No description provided for @identityRemoved.
  ///
  /// In en, this message translates to:
  /// **'Its password and keys are removed from catussh.'**
  String get identityRemoved;

  /// No description provided for @identityShort.
  ///
  /// In en, this message translates to:
  /// **'User {username} with {type}'**
  String identityShort(String username, String type);

  /// No description provided for @inDays.
  ///
  /// In en, this message translates to:
  /// **'in {count} days'**
  String inDays(int count);

  /// No description provided for @inHours.
  ///
  /// In en, this message translates to:
  /// **'in {count} hours'**
  String inHours(int count);

  /// No description provided for @inMinutes.
  ///
  /// In en, this message translates to:
  /// **'in {count} minutes'**
  String inMinutes(int count);

  /// No description provided for @includeQuickConnect.
  ///
  /// In en, this message translates to:
  /// **'Include Quick Connect commands'**
  String get includeQuickConnect;

  /// No description provided for @includeQuickConnectHelp.
  ///
  /// In en, this message translates to:
  /// **'Also remember user@host commands typed on Home.'**
  String get includeQuickConnectHelp;

  /// No description provided for @incomplete.
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get incomplete;

  /// No description provided for @invalidForward.
  ///
  /// In en, this message translates to:
  /// **'Invalid Forward'**
  String get invalidForward;

  /// No description provided for @invalidName.
  ///
  /// In en, this message translates to:
  /// **'That name contains characters a file name cannot have.'**
  String get invalidName;

  /// No description provided for @ioWait.
  ///
  /// In en, this message translates to:
  /// **'IO wait'**
  String get ioWait;

  /// No description provided for @issues.
  ///
  /// In en, this message translates to:
  /// **'Issues'**
  String get issues;

  /// No description provided for @issuesHelp.
  ///
  /// In en, this message translates to:
  /// **'Bugs and ideas go to the project\'s issue tracker.'**
  String get issuesHelp;

  /// No description provided for @keyPair.
  ///
  /// In en, this message translates to:
  /// **'Key pair'**
  String get keyPair;

  /// No description provided for @keyTypeKeyPair.
  ///
  /// In en, this message translates to:
  /// **'Key Pair'**
  String get keyTypeKeyPair;

  /// No description provided for @keyTypePlainKeyPair.
  ///
  /// In en, this message translates to:
  /// **'Plain Key Pair'**
  String get keyTypePlainKeyPair;

  /// No description provided for @keyTypePlainPrivateKey.
  ///
  /// In en, this message translates to:
  /// **'Plain Private Key'**
  String get keyTypePlainPrivateKey;

  /// No description provided for @keyTypePrivateKey.
  ///
  /// In en, this message translates to:
  /// **'Private Key'**
  String get keyTypePrivateKey;

  /// No description provided for @keyboard.
  ///
  /// In en, this message translates to:
  /// **'Keyboard'**
  String get keyboard;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageHelp.
  ///
  /// In en, this message translates to:
  /// **'Menus and messages. Dates follow too; server names and terminal output stay as they are.'**
  String get languageHelp;

  /// No description provided for @largerText.
  ///
  /// In en, this message translates to:
  /// **'Larger Text (Ctrl+=)'**
  String get largerText;

  /// No description provided for @lastErrorFromBackend.
  ///
  /// In en, this message translates to:
  /// **'[i] Last Error Provided By Backend'**
  String get lastErrorFromBackend;

  /// No description provided for @lastUsed.
  ///
  /// In en, this message translates to:
  /// **'Last used'**
  String get lastUsed;

  /// No description provided for @legal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legal;

  /// No description provided for @libraries.
  ///
  /// In en, this message translates to:
  /// **'Libraries'**
  String get libraries;

  /// No description provided for @librariesText.
  ///
  /// In en, this message translates to:
  /// **'Flutter · dartssh2 · xterm.dart · re_editor · dynamic_color · tray_manager · cryptography'**
  String get librariesText;

  /// No description provided for @license.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get license;

  /// No description provided for @licenseEllipsis.
  ///
  /// In en, this message translates to:
  /// **'License…'**
  String get licenseEllipsis;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @lightOrDark.
  ///
  /// In en, this message translates to:
  /// **'Light or dark'**
  String get lightOrDark;

  /// No description provided for @listenLocal.
  ///
  /// In en, this message translates to:
  /// **'Listen local'**
  String get listenLocal;

  /// No description provided for @listenRemote.
  ///
  /// In en, this message translates to:
  /// **'Listen remote'**
  String get listenRemote;

  /// No description provided for @liveFigures.
  ///
  /// In en, this message translates to:
  /// **'CPU {cpu}%    Mem {memory}%    ↓ {receive} ↑ {transmit}'**
  String liveFigures(
    String cpu,
    String memory,
    String receive,
    String transmit,
  );

  /// No description provided for @load.
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get load;

  /// No description provided for @loadComplete.
  ///
  /// In en, this message translates to:
  /// **'Load Complete'**
  String get loadComplete;

  /// No description provided for @loadItAnyway.
  ///
  /// In en, this message translates to:
  /// **'Load it anyway?'**
  String get loadItAnyway;

  /// No description provided for @loadPrivateKey.
  ///
  /// In en, this message translates to:
  /// **'Load Private Key…'**
  String get loadPrivateKey;

  /// No description provided for @loadPublicKey.
  ///
  /// In en, this message translates to:
  /// **'Load Public Key…'**
  String get loadPublicKey;

  /// No description provided for @loadingPath.
  ///
  /// In en, this message translates to:
  /// **'Loading... {path}'**
  String loadingPath(String path);

  /// No description provided for @localForwardExplain.
  ///
  /// In en, this message translates to:
  /// **'This computer :port → server → target'**
  String get localForwardExplain;

  /// No description provided for @localForwardShort.
  ///
  /// In en, this message translates to:
  /// **'localhost:{bind} -{server}-> {host}:{port}'**
  String localForwardShort(int bind, String server, String host, int port);

  /// No description provided for @malformedMachine.
  ///
  /// In en, this message translates to:
  /// **'Malformed machine or identity data'**
  String get malformedMachine;

  /// No description provided for @malformedMachineInfo.
  ///
  /// In en, this message translates to:
  /// **'[*] Malformed Machine Info'**
  String get malformedMachineInfo;

  /// No description provided for @materialYou.
  ///
  /// In en, this message translates to:
  /// **'Material You'**
  String get materialYou;

  /// No description provided for @maximizeWindow.
  ///
  /// In en, this message translates to:
  /// **'Maximize'**
  String get maximizeWindow;

  /// No description provided for @memory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get memory;

  /// No description provided for @memoryWithTotal.
  ///
  /// In en, this message translates to:
  /// **'Memory · {total}'**
  String memoryWithTotal(String total);

  /// No description provided for @minimizeWindow.
  ///
  /// In en, this message translates to:
  /// **'Minimize'**
  String get minimizeWindow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute ago} other{{count} minutes ago}}'**
  String minutesAgo(int count);

  /// No description provided for @missing.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get missing;

  /// No description provided for @modified.
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get modified;

  /// No description provided for @monitor.
  ///
  /// In en, this message translates to:
  /// **'Monitor'**
  String get monitor;

  /// No description provided for @monitorClosed.
  ///
  /// In en, this message translates to:
  /// **'Monitor closed'**
  String get monitorClosed;

  /// No description provided for @monthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{last month} other{{count} months ago}}'**
  String monthsAgo(int count);

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @moreActions.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get moreActions;

  /// No description provided for @namePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'prod-web-01'**
  String get namePlaceholder;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'A name is required.'**
  String get nameRequired;

  /// No description provided for @namesAndAddressesHidden.
  ///
  /// In en, this message translates to:
  /// **'Names and addresses hidden'**
  String get namesAndAddressesHidden;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navIdentities.
  ///
  /// In en, this message translates to:
  /// **'Identities'**
  String get navIdentities;

  /// No description provided for @navManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get navManage;

  /// No description provided for @navPortForward.
  ///
  /// In en, this message translates to:
  /// **'Port Forward'**
  String get navPortForward;

  /// No description provided for @navServers.
  ///
  /// In en, this message translates to:
  /// **'Servers'**
  String get navServers;

  /// No description provided for @navSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get navSessions;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navSnippets.
  ///
  /// In en, this message translates to:
  /// **'Snippets'**
  String get navSnippets;

  /// No description provided for @network.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get network;

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// No description provided for @newFolder.
  ///
  /// In en, this message translates to:
  /// **'New Folder'**
  String get newFolder;

  /// No description provided for @newIdentity.
  ///
  /// In en, this message translates to:
  /// **'New Identity'**
  String get newIdentity;

  /// No description provided for @newPortForward.
  ///
  /// In en, this message translates to:
  /// **'New Port Forward'**
  String get newPortForward;

  /// No description provided for @newServer.
  ///
  /// In en, this message translates to:
  /// **'New Server'**
  String get newServer;

  /// No description provided for @newSnippet.
  ///
  /// In en, this message translates to:
  /// **'New Snippet'**
  String get newSnippet;

  /// No description provided for @newTerminal.
  ///
  /// In en, this message translates to:
  /// **'New Terminal'**
  String get newTerminal;

  /// No description provided for @newTerminalShortcut.
  ///
  /// In en, this message translates to:
  /// **'New Terminal (Ctrl+Shift+T)'**
  String get newTerminalShortcut;

  /// No description provided for @nice.
  ///
  /// In en, this message translates to:
  /// **'Nice'**
  String get nice;

  /// No description provided for @noAutoIdentity.
  ///
  /// In en, this message translates to:
  /// **'No identity is set to authenticate automatically. Choose an identity for this server.'**
  String get noAutoIdentity;

  /// No description provided for @noCredentials.
  ///
  /// In en, this message translates to:
  /// **'No credentials'**
  String get noCredentials;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @noFileOpen.
  ///
  /// In en, this message translates to:
  /// **'No file open'**
  String get noFileOpen;

  /// No description provided for @noFileOpenHelp.
  ///
  /// In en, this message translates to:
  /// **'Double-click a text file in Files, or open one by its path.'**
  String get noFileOpenHelp;

  /// No description provided for @noIdentitiesYet.
  ///
  /// In en, this message translates to:
  /// **'No identities yet'**
  String get noIdentitiesYet;

  /// No description provided for @noIdentityForUser.
  ///
  /// In en, this message translates to:
  /// **'No identity for {username} authenticates automatically. Add one under Identities.'**
  String noIdentityForUser(String username);

  /// No description provided for @noMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get noMatches;

  /// No description provided for @noPortForwards.
  ///
  /// In en, this message translates to:
  /// **'No port forwards'**
  String get noPortForwards;

  /// No description provided for @noPrivateKeyLoaded.
  ///
  /// In en, this message translates to:
  /// **'No private key loaded'**
  String get noPrivateKeyLoaded;

  /// No description provided for @noPublicKeyLoaded.
  ///
  /// In en, this message translates to:
  /// **'No public key loaded'**
  String get noPublicKeyLoaded;

  /// No description provided for @noServer.
  ///
  /// In en, this message translates to:
  /// **'No server'**
  String get noServer;

  /// No description provided for @noServersYet.
  ///
  /// In en, this message translates to:
  /// **'No servers yet'**
  String get noServersYet;

  /// No description provided for @noSnippetsYet.
  ///
  /// In en, this message translates to:
  /// **'No snippets yet'**
  String get noSnippetsYet;

  /// No description provided for @noSwap.
  ///
  /// In en, this message translates to:
  /// **'No swap'**
  String get noSwap;

  /// No description provided for @noUsername.
  ///
  /// In en, this message translates to:
  /// **'No username'**
  String get noUsername;

  /// No description provided for @noWrapLines.
  ///
  /// In en, this message translates to:
  /// **'Don\'t Wrap Lines'**
  String get noWrapLines;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @notAKeyFile.
  ///
  /// In en, this message translates to:
  /// **'This file does not look like a {kind} key'**
  String notAKeyFile(String kind);

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get notConnected;

  /// No description provided for @notUsedByAnyServer.
  ///
  /// In en, this message translates to:
  /// **'Not used by any server'**
  String get notUsedByAnyServer;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// No description provided for @numberToKeep.
  ///
  /// In en, this message translates to:
  /// **'Number to keep'**
  String get numberToKeep;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @oneMinute.
  ///
  /// In en, this message translates to:
  /// **'1 min'**
  String get oneMinute;

  /// No description provided for @openAction.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openAction;

  /// No description provided for @openAnother.
  ///
  /// In en, this message translates to:
  /// **'Open Another'**
  String get openAnother;

  /// No description provided for @openEditor.
  ///
  /// In en, this message translates to:
  /// **'Open Editor'**
  String get openEditor;

  /// No description provided for @openFile.
  ///
  /// In en, this message translates to:
  /// **'Open File'**
  String get openFile;

  /// No description provided for @openFileEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Open File…'**
  String get openFileEllipsis;

  /// No description provided for @openFileShortcut.
  ///
  /// In en, this message translates to:
  /// **'Open File… (Ctrl+O)'**
  String get openFileShortcut;

  /// No description provided for @openFiles.
  ///
  /// In en, this message translates to:
  /// **'Open Files'**
  String get openFiles;

  /// No description provided for @openIdentities.
  ///
  /// In en, this message translates to:
  /// **'Open Identities'**
  String get openIdentities;

  /// No description provided for @openMonitor.
  ///
  /// In en, this message translates to:
  /// **'Open Monitor'**
  String get openMonitor;

  /// No description provided for @openTerminal.
  ///
  /// In en, this message translates to:
  /// **'Open Terminal'**
  String get openTerminal;

  /// No description provided for @openTerminals.
  ///
  /// In en, this message translates to:
  /// **'Open Terminals…'**
  String get openTerminals;

  /// No description provided for @openTerminalsHelp.
  ///
  /// In en, this message translates to:
  /// **'Pick several servers and open a terminal on each'**
  String get openTerminalsHelp;

  /// No description provided for @openTerminalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Open Terminals'**
  String get openTerminalsTitle;

  /// No description provided for @openingFile.
  ///
  /// In en, this message translates to:
  /// **'Opening {name}…'**
  String openingFile(String name);

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @orientation.
  ///
  /// In en, this message translates to:
  /// **'Orientation'**
  String get orientation;

  /// No description provided for @os.
  ///
  /// In en, this message translates to:
  /// **'OS'**
  String get os;

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// No description provided for @passphrase.
  ///
  /// In en, this message translates to:
  /// **'Passphrase'**
  String get passphrase;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @paste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// No description provided for @pathExample.
  ///
  /// In en, this message translates to:
  /// **'/etc/hosts'**
  String get pathExample;

  /// No description provided for @pathLabel.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get pathLabel;

  /// No description provided for @peakRate.
  ///
  /// In en, this message translates to:
  /// **'peak {rate}'**
  String peakRate(String rate);

  /// No description provided for @permissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissions;

  /// No description provided for @plainKeyPair.
  ///
  /// In en, this message translates to:
  /// **'Plain Key Pair'**
  String get plainKeyPair;

  /// No description provided for @plainPrivateKey.
  ///
  /// In en, this message translates to:
  /// **'Plain Private Key'**
  String get plainPrivateKey;

  /// No description provided for @port.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get port;

  /// No description provided for @portForwardTitle.
  ///
  /// In en, this message translates to:
  /// **'Port Forward'**
  String get portForwardTitle;

  /// No description provided for @portForwardsStop.
  ///
  /// In en, this message translates to:
  /// **'Port forwards through it stop working.'**
  String get portForwardsStop;

  /// No description provided for @portRange.
  ///
  /// In en, this message translates to:
  /// **'1–65535'**
  String get portRange;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @privateKey.
  ///
  /// In en, this message translates to:
  /// **'Private key'**
  String get privateKey;

  /// No description provided for @privateKeyLower.
  ///
  /// In en, this message translates to:
  /// **'private'**
  String get privateKeyLower;

  /// No description provided for @processes.
  ///
  /// In en, this message translates to:
  /// **'Processes'**
  String get processes;

  /// No description provided for @processor.
  ///
  /// In en, this message translates to:
  /// **'Processor'**
  String get processor;

  /// No description provided for @processorCores.
  ///
  /// In en, this message translates to:
  /// **'Processor · {count, plural, =1{1 core} other{{count} cores}}'**
  String processorCores(int count);

  /// No description provided for @publicKey.
  ///
  /// In en, this message translates to:
  /// **'Public key'**
  String get publicKey;

  /// No description provided for @publicKeyLower.
  ///
  /// In en, this message translates to:
  /// **'public'**
  String get publicKeyLower;

  /// No description provided for @publicKeyOptional.
  ///
  /// In en, this message translates to:
  /// **'Public key (optional)'**
  String get publicKeyOptional;

  /// No description provided for @quickConnectHelp.
  ///
  /// In en, this message translates to:
  /// **'Type user@host, user@host:port or a full ssh command.'**
  String get quickConnectHelp;

  /// No description provided for @quickConnectHint.
  ///
  /// In en, this message translates to:
  /// **'user@host:22'**
  String get quickConnectHint;

  /// No description provided for @quickConnectNoAutoIdentity.
  ///
  /// In en, this message translates to:
  /// **'Quick Connect signs in with identities set to “Authenticate automatically”. You have none yet.'**
  String get quickConnectNoAutoIdentity;

  /// No description provided for @quit.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get quit;

  /// No description provided for @ram.
  ///
  /// In en, this message translates to:
  /// **'RAM'**
  String get ram;

  /// No description provided for @receive.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get receive;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @recentSection.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recentSection;

  /// No description provided for @reconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get reconnect;

  /// No description provided for @reconnectTerminal.
  ///
  /// In en, this message translates to:
  /// **'Reconnect Terminal'**
  String get reconnectTerminal;

  /// No description provided for @reconnectingNote.
  ///
  /// In en, this message translates to:
  /// **'[i] Reconnecting with the details from when this session started.'**
  String get reconnectingNote;

  /// No description provided for @reconnectingNoteHelp.
  ///
  /// In en, this message translates to:
  /// **'    If the server was edited, open a new terminal instead.'**
  String get reconnectingNoteHelp;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @refreshHelp.
  ///
  /// In en, this message translates to:
  /// **'How often an open monitor reads the server.'**
  String get refreshHelp;

  /// No description provided for @reload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get reload;

  /// No description provided for @reloadFromServer.
  ///
  /// In en, this message translates to:
  /// **'Reload {name} from the server?'**
  String reloadFromServer(String name);

  /// No description provided for @reloadFromServerAction.
  ///
  /// In en, this message translates to:
  /// **'Reload from Server'**
  String get reloadFromServerAction;

  /// No description provided for @reloadShortcut.
  ///
  /// In en, this message translates to:
  /// **'Reload (Ctrl+R)'**
  String get reloadShortcut;

  /// No description provided for @rememberRecentServers.
  ///
  /// In en, this message translates to:
  /// **'Remember recent servers'**
  String get rememberRecentServers;

  /// No description provided for @rememberRecentServersHelp.
  ///
  /// In en, this message translates to:
  /// **'Listed under Quick Connect on Home.'**
  String get rememberRecentServersHelp;

  /// No description provided for @remoteForwardExplain.
  ///
  /// In en, this message translates to:
  /// **'Server :port → this computer → target'**
  String get remoteForwardExplain;

  /// No description provided for @remoteForwardShort.
  ///
  /// In en, this message translates to:
  /// **'{server}:{bind} -localhost-> {host}:{port}'**
  String remoteForwardShort(int bind, String server, String host, int port);

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @removeFromRecent.
  ///
  /// In en, this message translates to:
  /// **'Remove from Recent'**
  String get removeFromRecent;

  /// No description provided for @removeFromTray.
  ///
  /// In en, this message translates to:
  /// **'Remove from Tray'**
  String get removeFromTray;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @renameEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Rename…'**
  String get renameEllipsis;

  /// No description provided for @renamingFile.
  ///
  /// In en, this message translates to:
  /// **'Renaming {name}...'**
  String renamingFile(String name);

  /// No description provided for @reportProblem.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get reportProblem;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @restoreWindow.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreWindow;

  /// No description provided for @revert.
  ///
  /// In en, this message translates to:
  /// **'Revert'**
  String get revert;

  /// No description provided for @run.
  ///
  /// In en, this message translates to:
  /// **'Run…'**
  String get run;

  /// No description provided for @runAction.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get runAction;

  /// No description provided for @runName.
  ///
  /// In en, this message translates to:
  /// **'Run {name}'**
  String runName(String name);

  /// No description provided for @runningOfTotal.
  ///
  /// In en, this message translates to:
  /// **'/ {total} running'**
  String runningOfTotal(int total);

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saveAndStart.
  ///
  /// In en, this message translates to:
  /// **'Save and Start'**
  String get saveAndStart;

  /// No description provided for @saveShortcut.
  ///
  /// In en, this message translates to:
  /// **'Save (Ctrl+S)'**
  String get saveShortcut;

  /// No description provided for @saveWithoutConnecting.
  ///
  /// In en, this message translates to:
  /// **'Save the server without connecting'**
  String get saveWithoutConnecting;

  /// No description provided for @savedHostKeys.
  ///
  /// In en, this message translates to:
  /// **'Saved host keys'**
  String get savedHostKeys;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchForwards.
  ///
  /// In en, this message translates to:
  /// **'Search forwards'**
  String get searchForwards;

  /// No description provided for @searchIdentities.
  ///
  /// In en, this message translates to:
  /// **'Search identities'**
  String get searchIdentities;

  /// No description provided for @searchServers.
  ///
  /// In en, this message translates to:
  /// **'Search servers'**
  String get searchServers;

  /// No description provided for @searchSnippets.
  ///
  /// In en, this message translates to:
  /// **'Search snippets'**
  String get searchSnippets;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @selectAllText.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAllText;

  /// No description provided for @selectIdentity.
  ///
  /// In en, this message translates to:
  /// **'Select an identity'**
  String get selectIdentity;

  /// No description provided for @selectIdentityFirst.
  ///
  /// In en, this message translates to:
  /// **'No identity that authenticates automatically could sign in. Choose an identity.'**
  String get selectIdentityFirst;

  /// No description provided for @serverFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get serverFallbackName;

  /// No description provided for @serverRefusedListen.
  ///
  /// In en, this message translates to:
  /// **'The server refused to listen on port {port}.'**
  String serverRefusedListen(int port);

  /// No description provided for @serversNeedIdentity.
  ///
  /// In en, this message translates to:
  /// **'Servers need an identity set.'**
  String get serversNeedIdentity;

  /// No description provided for @serversSection.
  ///
  /// In en, this message translates to:
  /// **'Servers'**
  String get serversSection;

  /// No description provided for @serversUsingCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 server} other{{count} servers}}'**
  String serversUsingCount(int count);

  /// No description provided for @sessionToolsOpen.
  ///
  /// In en, this message translates to:
  /// **'{tools} open'**
  String sessionToolsOpen(String tools);

  /// No description provided for @sessionsSection.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessionsSection;

  /// No description provided for @settingsShortcut.
  ///
  /// In en, this message translates to:
  /// **'Settings (Ctrl+,)'**
  String get settingsShortcut;

  /// No description provided for @sftpNotConnected.
  ///
  /// In en, this message translates to:
  /// **'The file transfer session is not connected.'**
  String get sftpNotConnected;

  /// No description provided for @shortcutCloseTerminal.
  ///
  /// In en, this message translates to:
  /// **'Close terminal'**
  String get shortcutCloseTerminal;

  /// No description provided for @shortcutCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get shortcutCopy;

  /// No description provided for @shortcutNewServer.
  ///
  /// In en, this message translates to:
  /// **'New server'**
  String get shortcutNewServer;

  /// No description provided for @shortcutNewTerminal.
  ///
  /// In en, this message translates to:
  /// **'New terminal on this server'**
  String get shortcutNewTerminal;

  /// No description provided for @shortcutPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get shortcutPaste;

  /// No description provided for @shortcutSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get shortcutSettings;

  /// No description provided for @shortcutSidebar.
  ///
  /// In en, this message translates to:
  /// **'Show or hide the sidebar'**
  String get shortcutSidebar;

  /// No description provided for @show.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get show;

  /// No description provided for @showAll.
  ///
  /// In en, this message translates to:
  /// **'Show All'**
  String get showAll;

  /// No description provided for @showEverything.
  ///
  /// In en, this message translates to:
  /// **'Show Everything'**
  String get showEverything;

  /// No description provided for @showInTray.
  ///
  /// In en, this message translates to:
  /// **'Show in Tray'**
  String get showInTray;

  /// No description provided for @showSessionOnConnect.
  ///
  /// In en, this message translates to:
  /// **'Show a session when it connects'**
  String get showSessionOnConnect;

  /// No description provided for @showSessionOnConnectHelp.
  ///
  /// In en, this message translates to:
  /// **'Switch to a terminal as soon as it opens.'**
  String get showSessionOnConnectHelp;

  /// No description provided for @showSidebar.
  ///
  /// In en, this message translates to:
  /// **'Show Sidebar (Ctrl+\\)'**
  String get showSidebar;

  /// No description provided for @smallerText.
  ///
  /// In en, this message translates to:
  /// **'Smaller Text (Ctrl+-)'**
  String get smallerText;

  /// No description provided for @snippetNameHint.
  ///
  /// In en, this message translates to:
  /// **'Restart nginx'**
  String get snippetNameHint;

  /// No description provided for @snippetNoCommand.
  ///
  /// In en, this message translates to:
  /// **'This snippet has no command to run.'**
  String get snippetNoCommand;

  /// No description provided for @snippetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Snippets'**
  String get snippetsTitle;

  /// No description provided for @sourceCode.
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get sourceCode;

  /// No description provided for @sourceOnGitHub.
  ///
  /// In en, this message translates to:
  /// **'Omicron0314/catussh on GitHub'**
  String get sourceOnGitHub;

  /// No description provided for @ssh.
  ///
  /// In en, this message translates to:
  /// **'SSH'**
  String get ssh;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @stopAll.
  ///
  /// In en, this message translates to:
  /// **'Stop All'**
  String get stopAll;

  /// No description provided for @stopAndClose.
  ///
  /// In en, this message translates to:
  /// **'Stop and Close'**
  String get stopAndClose;

  /// No description provided for @stopRunning.
  ///
  /// In en, this message translates to:
  /// **'Stop running {name}?'**
  String stopRunning(String name);

  /// No description provided for @storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage;

  /// No description provided for @storageEncrypted.
  ///
  /// In en, this message translates to:
  /// **'Servers, identities and snippets are encrypted (AES-256-GCM) in {path}; the key is kept in the system keyring.'**
  String storageEncrypted(String path);

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @swap.
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get swap;

  /// No description provided for @syntaxHighlighting.
  ///
  /// In en, this message translates to:
  /// **'Syntax highlighting'**
  String get syntaxHighlighting;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @target.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get target;

  /// No description provided for @targetHost.
  ///
  /// In en, this message translates to:
  /// **'Target host'**
  String get targetHost;

  /// No description provided for @targetPort.
  ///
  /// In en, this message translates to:
  /// **'Target port'**
  String get targetPort;

  /// No description provided for @terminalAlreadyOpen.
  ///
  /// In en, this message translates to:
  /// **'{name} already has a terminal open'**
  String terminalAlreadyOpen(String name);

  /// No description provided for @terminalColorsUnder.
  ///
  /// In en, this message translates to:
  /// **'Terminal colors are set under Terminal.'**
  String get terminalColorsUnder;

  /// No description provided for @terminalFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get terminalFallbackTitle;

  /// No description provided for @terminalOpen.
  ///
  /// In en, this message translates to:
  /// **'A terminal is open'**
  String get terminalOpen;

  /// No description provided for @terminalTab.
  ///
  /// In en, this message translates to:
  /// **'Terminal {number}'**
  String terminalTab(int number);

  /// No description provided for @text.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get text;

  /// No description provided for @textNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'The text could not be loaded.'**
  String get textNotLoaded;

  /// No description provided for @thisSnippet.
  ///
  /// In en, this message translates to:
  /// **'this snippet'**
  String get thisSnippet;

  /// No description provided for @through.
  ///
  /// In en, this message translates to:
  /// **'Through'**
  String get through;

  /// No description provided for @toolEditor.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get toolEditor;

  /// No description provided for @toolEditorHelp.
  ///
  /// In en, this message translates to:
  /// **'Edit text files on this server'**
  String get toolEditorHelp;

  /// No description provided for @toolFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get toolFiles;

  /// No description provided for @toolFilesHelp.
  ///
  /// In en, this message translates to:
  /// **'Browse, upload and download files over SFTP'**
  String get toolFilesHelp;

  /// No description provided for @toolMonitor.
  ///
  /// In en, this message translates to:
  /// **'Monitor'**
  String get toolMonitor;

  /// No description provided for @toolMonitorHelp.
  ///
  /// In en, this message translates to:
  /// **'Watch CPU, memory, disk and network usage'**
  String get toolMonitorHelp;

  /// No description provided for @toolTerminal.
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get toolTerminal;

  /// No description provided for @toolTerminalHelp.
  ///
  /// In en, this message translates to:
  /// **'Open an SSH terminal on this server'**
  String get toolTerminalHelp;

  /// No description provided for @transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @transferRunningWarning.
  ///
  /// In en, this message translates to:
  /// **'A transfer is still running and will be interrupted.'**
  String get transferRunningWarning;

  /// No description provided for @transmit.
  ///
  /// In en, this message translates to:
  /// **'Transmit'**
  String get transmit;

  /// No description provided for @trayTooltipFigures.
  ///
  /// In en, this message translates to:
  /// **'CPU {cpu}%  Mem {memory}%'**
  String trayTooltipFigures(String cpu, String memory);

  /// No description provided for @trayTooltipRates.
  ///
  /// In en, this message translates to:
  /// **'↑ {transmit}  ↓ {receive}'**
  String trayTooltipRates(String transmit, String receive);

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @tryingIdentity.
  ///
  /// In en, this message translates to:
  /// **'[i] trying to authenticate with {identity}'**
  String tryingIdentity(String identity);

  /// No description provided for @unableToConnectOrAuth.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect or authenticate ({error})'**
  String unableToConnectOrAuth(String error);

  /// No description provided for @unableToConnectShort.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect for {host}:{port}'**
  String unableToConnectShort(String host, int port);

  /// No description provided for @unableToConnectTo.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect for {host}:{port} ({error})'**
  String unableToConnectTo(String host, int port, String error);

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown Error'**
  String get unknownError;

  /// No description provided for @unknownKey.
  ///
  /// In en, this message translates to:
  /// **'Unknown Key'**
  String get unknownKey;

  /// No description provided for @unknownServer.
  ///
  /// In en, this message translates to:
  /// **'Unknown server'**
  String get unknownServer;

  /// No description provided for @unsavedChangesLost.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes are lost.'**
  String get unsavedChangesLost;

  /// No description provided for @unsavedFilesWarning.
  ///
  /// In en, this message translates to:
  /// **'Files open in the editor have changes that are not saved. They are lost if you close.'**
  String get unsavedFilesWarning;

  /// No description provided for @unsavedInEditor.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes in the editor will be lost.'**
  String get unsavedInEditor;

  /// No description provided for @untitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitled;

  /// No description provided for @untitledFolder.
  ///
  /// In en, this message translates to:
  /// **'untitled folder'**
  String get untitledFolder;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @uploadCancelled.
  ///
  /// In en, this message translates to:
  /// **'Upload cancelled'**
  String get uploadCancelled;

  /// No description provided for @uploadComplete.
  ///
  /// In en, this message translates to:
  /// **'Upload complete'**
  String get uploadComplete;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String uploadFailed(String error);

  /// No description provided for @uptime.
  ///
  /// In en, this message translates to:
  /// **'Uptime'**
  String get uptime;

  /// No description provided for @useDesktopAccent.
  ///
  /// In en, this message translates to:
  /// **'Use the desktop accent color'**
  String get useDesktopAccent;

  /// No description provided for @useDesktopAccentHelp.
  ///
  /// In en, this message translates to:
  /// **'Material You: colors follow your desktop theme when it provides an accent.'**
  String get useDesktopAccentHelp;

  /// No description provided for @used.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get used;

  /// No description provided for @usedBy.
  ///
  /// In en, this message translates to:
  /// **'Used by {names}'**
  String usedBy(String names);

  /// No description provided for @usedByMore.
  ///
  /// In en, this message translates to:
  /// **'Used by {names} and {count} more'**
  String usedByMore(String names, int count);

  /// No description provided for @usedOfSize.
  ///
  /// In en, this message translates to:
  /// **'{used} of {size}'**
  String usedOfSize(String used, String size);

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @usernameOnly.
  ///
  /// In en, this message translates to:
  /// **'Username Only'**
  String get usernameOnly;

  /// No description provided for @usernamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'root'**
  String get usernamePlaceholder;

  /// No description provided for @vaultKeyMissing.
  ///
  /// In en, this message translates to:
  /// **'The key that opens your saved servers is missing from the system keyring.'**
  String get vaultKeyMissing;

  /// No description provided for @vaultKeyringUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The system keyring (Secret Service) could not be reached, so servers and identities are kept for this run only.'**
  String get vaultKeyringUnavailable;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @versionLine.
  ///
  /// In en, this message translates to:
  /// **'{version} ({build}) · Linux'**
  String versionLine(String version, String build);

  /// No description provided for @vram.
  ///
  /// In en, this message translates to:
  /// **'VRAM'**
  String get vram;

  /// No description provided for @weeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{last week} other{{count} weeks ago}}'**
  String weeksAgo(int count);

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to catussh'**
  String get welcome;

  /// No description provided for @whereKept.
  ///
  /// In en, this message translates to:
  /// **'Where your servers are kept'**
  String get whereKept;

  /// No description provided for @wrapLines.
  ///
  /// In en, this message translates to:
  /// **'Wrap Lines'**
  String get wrapLines;

  /// No description provided for @yearsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{last year} other{{count} years ago}}'**
  String yearsAgo(int count);

  /// No description provided for @yourChangesLost.
  ///
  /// In en, this message translates to:
  /// **'Your changes are lost if you don\'t save them.'**
  String get yourChangesLost;
}

class _L10nDelegate extends LocalizationsDelegate<L10n> {
  const _L10nDelegate();

  @override
  Future<L10n> load(Locale locale) {
    return SynchronousFuture<L10n>(lookupL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_L10nDelegate old) => false;
}

L10n lookupL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return L10nEn();
    case 'zh':
      return L10nZh();
  }

  throw FlutterError(
    'L10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
