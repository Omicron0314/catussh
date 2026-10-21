// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class L10nEn extends L10n {
  L10nEn([String locale = 'en']) : super(locale);

  @override
  String get about => 'About';

  @override
  String aboutVersionLine(String version) {
    return '$version (Flutter) · Linux';
  }

  @override
  String get absolutePathRequired => 'Use an absolute path starting with /.';

  @override
  String get accentColor => 'Accent color';

  @override
  String get accentColorHelp =>
      'Used when the desktop accent is off or unavailable.';

  @override
  String get acknowledgements => 'Acknowledgements';

  @override
  String get addAndConnect => 'Add and Connect';

  @override
  String get addServer => 'Add a server';

  @override
  String get addServerAction => 'Add';

  @override
  String get address => 'Address';

  @override
  String get addressesHidden => 'Addresses hidden';

  @override
  String get agreementEllipsis => 'Agreement…';

  @override
  String get allGroups => 'All Groups';

  @override
  String get appName => 'catussh';

  @override
  String get appTagline => 'SSH terminal, files and monitor for your servers.';

  @override
  String get appearance => 'Appearance';

  @override
  String get askBeforeClosing => 'Ask before closing a session';

  @override
  String get askBeforeClosingHelp =>
      'Confirm before closing a connected terminal or deleting.';

  @override
  String get authenticateAutomatically => 'Authenticate automatically';

  @override
  String get authenticateAutomaticallyHelp => 'Required for Quick Connect.';

  @override
  String get authentication => 'Authentication';

  @override
  String get automatic => 'Automatic';

  @override
  String get basedOn => 'Based on';

  @override
  String get basedOnText =>
      'catussh by mizorewww, the continuation of Rayon by Lakr Aream (@Lakr233) and contributors. This version is not affiliated with or endorsed by them.';

  @override
  String get bind => 'Bind';

  @override
  String get bindPort => 'Bind port';

  @override
  String get cache => 'Cache';

  @override
  String get cancel => 'Cancel';

  @override
  String get cannotConnect => 'Can\'t connect';

  @override
  String cannotOpenFile(String name) {
    return 'Can\'t open $name';
  }

  @override
  String caretPosition(int line, int column) {
    return 'Ln $line, Col $column';
  }

  @override
  String get changesReplaced =>
      'Your changes are replaced by the file on the server.';

  @override
  String get checkThenSave => 'Check the connection, then save the server';

  @override
  String get chineseSimplified => '简体中文';

  @override
  String get chineseTraditional => '繁體中文';

  @override
  String get choose => 'Choose';

  @override
  String get chooseExistingGroup => 'Choose an existing group';

  @override
  String get chooseIdentity => 'Choose Identity';

  @override
  String get chooseServer => 'Choose a server';

  @override
  String get clear => 'Clear';

  @override
  String get clearScrollback => 'Clear Scrollback';

  @override
  String get clickToOpenTerminal => 'Click to open a terminal';

  @override
  String get close => 'Close';

  @override
  String get closeAll => 'Close All';

  @override
  String get closeEditor => 'Close Editor';

  @override
  String closeEditorOn(String name) {
    return 'Close the editor on $name?';
  }

  @override
  String closeEverythingOn(String name) {
    return 'Close everything open on $name?';
  }

  @override
  String closeFileName(String name) {
    return 'Close $name';
  }

  @override
  String closeFileWithoutSaving(String name) {
    return 'Close $name without saving?';
  }

  @override
  String get closeFiles => 'Close Files';

  @override
  String get closeMonitor => 'Close Monitor';

  @override
  String get closeSession => 'Close Session';

  @override
  String closeSessionOn(String name) {
    return 'Close the session on $name?';
  }

  @override
  String get closeTerminal => 'Close Terminal';

  @override
  String closeTitle(String title) {
    return 'Close $title';
  }

  @override
  String closeTransfer(String name) {
    return 'Close the file transfer on $name?';
  }

  @override
  String get closeWindow => 'Close';

  @override
  String get codeHint => 'sudo systemctl restart nginx';

  @override
  String get colors => 'Colors';

  @override
  String get command => 'Command';

  @override
  String get connect => 'Connect';

  @override
  String get connectEnter => 'Connect (Enter)';

  @override
  String connectFailedReason(String host, int port) {
    return 'Could not reach $host on port $port.';
  }

  @override
  String get connecting => 'Connecting…';

  @override
  String get connectingEllipsis => 'Connecting...';

  @override
  String get connection => 'Connection';

  @override
  String get connectionClosed => 'Connection closed';

  @override
  String get connectionClosedBanner => '[*] Connection Closed';

  @override
  String get connectionTimeout => 'Connection timeout';

  @override
  String get connectionTimeoutHelp =>
      'How long to wait for a server before giving up.';

  @override
  String get continue_ => 'Continue';

  @override
  String copied(Object what) {
    return '$what copied';
  }

  @override
  String get copy => 'Copy';

  @override
  String get copyAddress => 'Copy Address';

  @override
  String get copyCommand => 'Copy SSH Command';

  @override
  String get copyName => 'Copy Name';

  @override
  String get copyPath => 'Copy Path';

  @override
  String get copyPublicKey => 'Copy Public Key';

  @override
  String get cores => 'Cores';

  @override
  String couldNotSave(String name, String error) {
    return 'Couldn\'t save $name. $error';
  }

  @override
  String get cpu => 'CPU';

  @override
  String get create => 'Create';

  @override
  String get creatingConnection => '[*] Creating Connection';

  @override
  String creatingFolderPath(String path) {
    return 'Creating Folder $path...';
  }

  @override
  String cudaVersion(String version) {
    return 'CUDA $version';
  }

  @override
  String get dark => 'Dark';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: 'yesterday',
    );
    return '$_temp0';
  }

  @override
  String get defaultGroup => 'Default';

  @override
  String get delete => 'Delete';

  @override
  String get deleteEllipsis => 'Delete…';

  @override
  String deleteFile(String name) {
    return 'Delete $name?';
  }

  @override
  String get deleteFileWarning =>
      'The file is deleted from the server. This cannot be undone.';

  @override
  String get deleteFolderWarning =>
      'The folder and everything in it is deleted from the server. This cannot be undone.';

  @override
  String deleteForward(int port) {
    return 'Delete the forward on port $port?';
  }

  @override
  String deleteIdentity(String username) {
    return 'Delete identity $username?';
  }

  @override
  String deleteServer(String name) {
    return 'Delete $name?';
  }

  @override
  String deleteServers(int count) {
    return 'Delete $count servers?';
  }

  @override
  String deleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get deletedServer => 'Deleted server';

  @override
  String deletingFile(String name) {
    return 'Deleting $name...';
  }

  @override
  String get deselectAll => 'Deselect All';

  @override
  String get discardAndClose => 'Discard Changes and Close';

  @override
  String get discardChanges => 'Discard Changes';

  @override
  String get disks => 'Disks';

  @override
  String get done => 'Done';

  @override
  String get download => 'Download';

  @override
  String get downloadCancelled => 'Download cancelled';

  @override
  String get downloadComplete => 'Download complete';

  @override
  String get downloadEllipsis => 'Download…';

  @override
  String downloadFailed(String error) {
    return 'Download failed: $error';
  }

  @override
  String get downloadHere => 'Download Here';

  @override
  String dropToUpload(String path) {
    return 'Drop to upload to $path';
  }

  @override
  String get duplicate => 'Duplicate';

  @override
  String duplicateServer(String name) {
    return 'Duplicate $name?';
  }

  @override
  String durationDaysHours(int days, int hours) {
    return '${days}d ${hours}h';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String durationMinutes(int minutes) {
    return '${minutes}m';
  }

  @override
  String get edit => 'Edit…';

  @override
  String get editAction => 'Edit';

  @override
  String get editPortForward => 'Edit Port Forward';

  @override
  String get editServer => 'Edit Server';

  @override
  String get editSnippet => 'Edit Snippet';

  @override
  String get edited => 'Edited';

  @override
  String get emptyFolder => 'Empty folder';

  @override
  String get emptyServersMessage =>
      'Saved servers keep their address, port and identity, and open a terminal, files or a monitor.';

  @override
  String get emptyServersTitle => 'Save a server to reach it in one click';

  @override
  String get enclosingFolder => 'Enclosing Folder (Alt+Up)';

  @override
  String get english => 'English';

  @override
  String get equivalentCommand => 'Equivalent command';

  @override
  String get error => 'Error';

  @override
  String get eula => 'End User License Agreement';

  @override
  String everySeconds(int seconds) {
    return 'Every $seconds s';
  }

  @override
  String get execBegin => '[*] Execute Begin';

  @override
  String get execCannotConnect => '[E] Could not connect to the server';

  @override
  String get execCannotSignIn => '[E] The identity could not sign in';

  @override
  String get execCompleted => '[*] Execution completed';

  @override
  String get execStopped => '[*] Stopped';

  @override
  String get failed => 'Failed';

  @override
  String get failedSftpSetup => 'Failed to setup file transfer protocol';

  @override
  String get failedToAuthenticate =>
      'Failed to authenticate connection. Did you forget to add identity or enable auto authentication?';

  @override
  String failedToLoadPath(String path, String error) {
    return 'Failed to load $path: $error';
  }

  @override
  String fanSpeed(String speed) {
    return 'Fan $speed';
  }

  @override
  String get fieldAddress => 'Address';

  @override
  String get fieldComment => 'Comment';

  @override
  String get fieldGroup => 'Group';

  @override
  String get fieldIdentity => 'Identity';

  @override
  String get fieldLastBanner => 'Last banner';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldPort => 'Port';

  @override
  String get fieldStartFolder => 'SFTP start folder';

  @override
  String get fieldUsername => 'Username';

  @override
  String get fifteenMinutes => '15 min';

  @override
  String get fileNotReadable => 'The file could not be read as text.';

  @override
  String get fileSize => 'Size';

  @override
  String get fileTransfer => 'File Transfer';

  @override
  String get filterByGroup => 'Filter by group';

  @override
  String get filterThisFolder => 'Filter this folder';

  @override
  String finishedOfTotal(int done, int total) {
    return '$done of $total finished';
  }

  @override
  String get fiveMinutes => '5 min';

  @override
  String get followSystem => 'Follow System';

  @override
  String get font => 'Font';

  @override
  String get fontHelp => 'Installed monospace fonts.';

  @override
  String get fontSize => 'Size';

  @override
  String get fontSizeHelp => 'Ctrl+= and Ctrl+- change it in a terminal.';

  @override
  String get forget => 'Forget';

  @override
  String get forgetAll => 'Forget All…';

  @override
  String get forgetAllAction => 'Forget All';

  @override
  String get forgetAllHostKeys => 'Forget all saved host keys?';

  @override
  String get forgetAllHostKeysHelp =>
      'The key each server presents on its next connection is saved as its key.';

  @override
  String get forgetHostKey => 'Forget Host Key…';

  @override
  String get forgetHostKeyExplain =>
      'The key the server presents on the next connection is saved as its key. Do this only when you know its keys were replaced.';

  @override
  String forgetHostKeyOf(String name) {
    return 'Forget the host key of $name?';
  }

  @override
  String get forwardFailedAuth => 'Could not sign in, retrying';

  @override
  String get forwardFailedConnect => 'Could not connect, retrying';

  @override
  String get forwardRunning => 'Running';

  @override
  String get forwardStopped => 'Stopped, retrying';

  @override
  String get forwardThrough => 'Forward through';

  @override
  String get free => 'Free';

  @override
  String get general => 'General';

  @override
  String get goAction => 'Go';

  @override
  String get goToFolder => 'Go to Folder';

  @override
  String get goToFolderShortcut => 'Go to Folder (Ctrl+Shift+G)';

  @override
  String get gpu => 'GPU';

  @override
  String gpuCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count GPUs',
      one: '1 GPU',
    );
    return 'Graphics · $_temp0';
  }

  @override
  String get graphics => 'Graphics';

  @override
  String get groupDefaultHint => 'Default';

  @override
  String get hide => 'Hide';

  @override
  String get hideAddresses => 'Hide Addresses';

  @override
  String get hideNamesAndAddresses => 'Hide Names and Addresses';

  @override
  String get hideSidebar => 'Hide Sidebar (Ctrl+\\)';

  @override
  String get host => 'Host';

  @override
  String hostKeyChanged(String host, int port) {
    return 'The host key of $host:$port has changed, so the connection was refused.';
  }

  @override
  String get hostKeyChangedHelp =>
      'If the server was reinstalled or its keys were replaced, choose Forget Host Key for it and connect again. If not, something may be intercepting the connection.';

  @override
  String hostKeyOffered(String type, String fingerprint) {
    return 'Offered: $type $fingerprint';
  }

  @override
  String hostKeySaved(String type, String fingerprint) {
    return 'Saved: $type $fingerprint';
  }

  @override
  String hostKeysSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count keys saved',
      one: '1 key saved',
      zero: 'No keys saved yet',
    );
    return '$_temp0';
  }

  @override
  String get hostPlaceholder => 'Host name or IP address';

  @override
  String get hostname => 'Hostname';

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String get iAgree => 'I have read and agree to the license';

  @override
  String get iconLabel => 'Icon';

  @override
  String get identitiesTitle => 'Identities';

  @override
  String identityCouldNotSignIn(String host, String error) {
    return 'The selected identity could not sign in to $host. ($error)';
  }

  @override
  String get identityEmptyMessage => 'A username with a password or key.';

  @override
  String identityGroup(String group) {
    return 'Group<$group>';
  }

  @override
  String identityInUse(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count servers use it and will try automatic identities instead.',
      one: '1 server uses it and will try automatic identities instead.',
    );
    return '$_temp0';
  }

  @override
  String get identityLabel => 'Identity';

  @override
  String get identityRemoved =>
      'Its password and keys are removed from catussh.';

  @override
  String identityShort(String username, String type) {
    return 'User $username with $type';
  }

  @override
  String inDays(int count) {
    return 'in $count days';
  }

  @override
  String inHours(int count) {
    return 'in $count hours';
  }

  @override
  String inMinutes(int count) {
    return 'in $count minutes';
  }

  @override
  String get includeQuickConnect => 'Include Quick Connect commands';

  @override
  String get includeQuickConnectHelp =>
      'Also remember user@host commands typed on Home.';

  @override
  String get incomplete => 'Incomplete';

  @override
  String get invalidForward => 'Invalid Forward';

  @override
  String get invalidName =>
      'That name contains characters a file name cannot have.';

  @override
  String get ioWait => 'IO wait';

  @override
  String get issues => 'Issues';

  @override
  String get issuesHelp => 'Bugs and ideas go to the project\'s issue tracker.';

  @override
  String get keyPair => 'Key pair';

  @override
  String get keyTypeKeyPair => 'Key Pair';

  @override
  String get keyTypePlainKeyPair => 'Plain Key Pair';

  @override
  String get keyTypePlainPrivateKey => 'Plain Private Key';

  @override
  String get keyTypePrivateKey => 'Private Key';

  @override
  String get keyboard => 'Keyboard';

  @override
  String get language => 'Language';

  @override
  String get languageHelp =>
      'Menus and messages. Dates follow too; server names and terminal output stay as they are.';

  @override
  String get largerText => 'Larger Text (Ctrl+=)';

  @override
  String get lastErrorFromBackend => '[i] Last Error Provided By Backend';

  @override
  String get lastUsed => 'Last used';

  @override
  String get legal => 'Legal';

  @override
  String get libraries => 'Libraries';

  @override
  String get librariesText =>
      'Flutter · dartssh2 · xterm.dart · re_editor · dynamic_color · tray_manager · cryptography';

  @override
  String get license => 'License';

  @override
  String get licenseEllipsis => 'License…';

  @override
  String get light => 'Light';

  @override
  String get lightOrDark => 'Light or dark';

  @override
  String get listenLocal => 'Listen local';

  @override
  String get listenRemote => 'Listen remote';

  @override
  String liveFigures(
    String cpu,
    String memory,
    String receive,
    String transmit,
  ) {
    return 'CPU $cpu%    Mem $memory%    ↓ $receive ↑ $transmit';
  }

  @override
  String get load => 'Load';

  @override
  String get loadComplete => 'Load Complete';

  @override
  String get loadItAnyway => 'Load it anyway?';

  @override
  String get loadPrivateKey => 'Load Private Key…';

  @override
  String get loadPublicKey => 'Load Public Key…';

  @override
  String loadingPath(String path) {
    return 'Loading... $path';
  }

  @override
  String get localForwardExplain => 'This computer :port → server → target';

  @override
  String localForwardShort(int bind, String server, String host, int port) {
    return 'localhost:$bind -$server-> $host:$port';
  }

  @override
  String get malformedMachine => 'Malformed machine or identity data';

  @override
  String get malformedMachineInfo => '[*] Malformed Machine Info';

  @override
  String get materialYou => 'Material You';

  @override
  String get maximizeWindow => 'Maximize';

  @override
  String get memory => 'Memory';

  @override
  String memoryWithTotal(String total) {
    return 'Memory · $total';
  }

  @override
  String get minimizeWindow => 'Minimize';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String get missing => 'Missing';

  @override
  String get modified => 'Modified';

  @override
  String get monitor => 'Monitor';

  @override
  String get monitorClosed => 'Monitor closed';

  @override
  String monthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months ago',
      one: 'last month',
    );
    return '$_temp0';
  }

  @override
  String get more => 'More';

  @override
  String get moreActions => 'More actions';

  @override
  String get namePlaceholder => 'prod-web-01';

  @override
  String get nameRequired => 'A name is required.';

  @override
  String get namesAndAddressesHidden => 'Names and addresses hidden';

  @override
  String get navHome => 'Home';

  @override
  String get navIdentities => 'Identities';

  @override
  String get navManage => 'Manage';

  @override
  String get navPortForward => 'Port Forward';

  @override
  String get navServers => 'Servers';

  @override
  String get navSessions => 'Sessions';

  @override
  String get navSettings => 'Settings';

  @override
  String get navSnippets => 'Snippets';

  @override
  String get network => 'Network';

  @override
  String get never => 'Never';

  @override
  String get newFolder => 'New Folder';

  @override
  String get newIdentity => 'New Identity';

  @override
  String get newPortForward => 'New Port Forward';

  @override
  String get newServer => 'New Server';

  @override
  String get newSnippet => 'New Snippet';

  @override
  String get newTerminal => 'New Terminal';

  @override
  String get newTerminalShortcut => 'New Terminal (Ctrl+Shift+T)';

  @override
  String get nice => 'Nice';

  @override
  String get noAutoIdentity =>
      'No identity is set to authenticate automatically. Choose an identity for this server.';

  @override
  String get noCredentials => 'No credentials';

  @override
  String get noData => 'No data';

  @override
  String get noFileOpen => 'No file open';

  @override
  String get noFileOpenHelp =>
      'Double-click a text file in Files, or open one by its path.';

  @override
  String get noIdentitiesYet => 'No identities yet';

  @override
  String noIdentityForUser(String username) {
    return 'No identity for $username authenticates automatically. Add one under Identities.';
  }

  @override
  String get noMatches => 'No matches';

  @override
  String get noPortForwards => 'No port forwards';

  @override
  String get noPrivateKeyLoaded => 'No private key loaded';

  @override
  String get noPublicKeyLoaded => 'No public key loaded';

  @override
  String get noServer => 'No server';

  @override
  String get noServersYet => 'No servers yet';

  @override
  String get noSnippetsYet => 'No snippets yet';

  @override
  String get noSwap => 'No swap';

  @override
  String get noUsername => 'No username';

  @override
  String get noWrapLines => 'Don\'t Wrap Lines';

  @override
  String get none => 'None';

  @override
  String notAKeyFile(String kind) {
    return 'This file does not look like a $kind key';
  }

  @override
  String get notConnected => 'Not connected';

  @override
  String get notUsedByAnyServer => 'Not used by any server';

  @override
  String get now => 'Now';

  @override
  String get numberToKeep => 'Number to keep';

  @override
  String get ok => 'OK';

  @override
  String get oneMinute => '1 min';

  @override
  String get openAction => 'Open';

  @override
  String get openAnother => 'Open Another';

  @override
  String get openEditor => 'Open Editor';

  @override
  String get openFile => 'Open File';

  @override
  String get openFileEllipsis => 'Open File…';

  @override
  String get openFileShortcut => 'Open File… (Ctrl+O)';

  @override
  String get openFiles => 'Open Files';

  @override
  String get openIdentities => 'Open Identities';

  @override
  String get openMonitor => 'Open Monitor';

  @override
  String get openTerminal => 'Open Terminal';

  @override
  String get openTerminals => 'Open Terminals…';

  @override
  String get openTerminalsHelp =>
      'Pick several servers and open a terminal on each';

  @override
  String get openTerminalsTitle => 'Open Terminals';

  @override
  String openingFile(String name) {
    return 'Opening $name…';
  }

  @override
  String get optional => 'Optional';

  @override
  String get orientation => 'Orientation';

  @override
  String get os => 'OS';

  @override
  String get owner => 'Owner';

  @override
  String get passphrase => 'Passphrase';

  @override
  String get password => 'Password';

  @override
  String get paste => 'Paste';

  @override
  String get pathExample => '/etc/hosts';

  @override
  String get pathLabel => 'Path';

  @override
  String peakRate(String rate) {
    return 'peak $rate';
  }

  @override
  String get permissions => 'Permissions';

  @override
  String get plainKeyPair => 'Plain Key Pair';

  @override
  String get plainPrivateKey => 'Plain Private Key';

  @override
  String get port => 'Port';

  @override
  String get portForwardTitle => 'Port Forward';

  @override
  String get portForwardsStop => 'Port forwards through it stop working.';

  @override
  String get portRange => '1–65535';

  @override
  String get privacy => 'Privacy';

  @override
  String get privateKey => 'Private key';

  @override
  String get privateKeyLower => 'private';

  @override
  String get processes => 'Processes';

  @override
  String get processor => 'Processor';

  @override
  String processorCores(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cores',
      one: '1 core',
    );
    return 'Processor · $_temp0';
  }

  @override
  String get publicKey => 'Public key';

  @override
  String get publicKeyLower => 'public';

  @override
  String get publicKeyOptional => 'Public key (optional)';

  @override
  String get quickConnectHelp =>
      'Type user@host, user@host:port or a full ssh command.';

  @override
  String get quickConnectHint => 'user@host:22';

  @override
  String get quickConnectNoAutoIdentity =>
      'Quick Connect signs in with identities set to “Authenticate automatically”. You have none yet.';

  @override
  String get quit => 'Quit';

  @override
  String get ram => 'RAM';

  @override
  String get receive => 'Receive';

  @override
  String get recent => 'Recent';

  @override
  String get recentSection => 'Recent';

  @override
  String get reconnect => 'Reconnect';

  @override
  String get reconnectTerminal => 'Reconnect Terminal';

  @override
  String get reconnectingNote =>
      '[i] Reconnecting with the details from when this session started.';

  @override
  String get reconnectingNoteHelp =>
      '    If the server was edited, open a new terminal instead.';

  @override
  String get refresh => 'Refresh';

  @override
  String get refreshHelp => 'How often an open monitor reads the server.';

  @override
  String get reload => 'Reload';

  @override
  String reloadFromServer(String name) {
    return 'Reload $name from the server?';
  }

  @override
  String get reloadFromServerAction => 'Reload from Server';

  @override
  String get reloadShortcut => 'Reload (Ctrl+R)';

  @override
  String get rememberRecentServers => 'Remember recent servers';

  @override
  String get rememberRecentServersHelp => 'Listed under Quick Connect on Home.';

  @override
  String get remoteForwardExplain => 'Server :port → this computer → target';

  @override
  String remoteForwardShort(int bind, String server, String host, int port) {
    return '$server:$bind -localhost-> $host:$port';
  }

  @override
  String get remove => 'Remove';

  @override
  String get removeFromRecent => 'Remove from Recent';

  @override
  String get removeFromTray => 'Remove from Tray';

  @override
  String get rename => 'Rename';

  @override
  String get renameEllipsis => 'Rename…';

  @override
  String renamingFile(String name) {
    return 'Renaming $name...';
  }

  @override
  String get reportProblem => 'Report a problem';

  @override
  String get required => 'Required';

  @override
  String get restoreWindow => 'Restore';

  @override
  String get revert => 'Revert';

  @override
  String get run => 'Run…';

  @override
  String get runAction => 'Run';

  @override
  String runName(String name) {
    return 'Run $name';
  }

  @override
  String runningOfTotal(int total) {
    return '/ $total running';
  }

  @override
  String get save => 'Save';

  @override
  String get saveAndStart => 'Save and Start';

  @override
  String get saveShortcut => 'Save (Ctrl+S)';

  @override
  String get saveWithoutConnecting => 'Save the server without connecting';

  @override
  String get savedHostKeys => 'Saved host keys';

  @override
  String get saving => 'Saving…';

  @override
  String get search => 'Search';

  @override
  String get searchForwards => 'Search forwards';

  @override
  String get searchIdentities => 'Search identities';

  @override
  String get searchServers => 'Search servers';

  @override
  String get searchSnippets => 'Search snippets';

  @override
  String get selectAll => 'Select All';

  @override
  String get selectAllText => 'Select All';

  @override
  String get selectIdentity => 'Select an identity';

  @override
  String get selectIdentityFirst =>
      'No identity that authenticates automatically could sign in. Choose an identity.';

  @override
  String get serverFallbackName => 'Server';

  @override
  String serverRefusedListen(int port) {
    return 'The server refused to listen on port $port.';
  }

  @override
  String get serversNeedIdentity => 'Servers need an identity set.';

  @override
  String get serversSection => 'Servers';

  @override
  String serversUsingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count servers',
      one: '1 server',
    );
    return '$_temp0';
  }

  @override
  String sessionToolsOpen(String tools) {
    return '$tools open';
  }

  @override
  String get sessionsSection => 'Sessions';

  @override
  String get settingsShortcut => 'Settings (Ctrl+,)';

  @override
  String get sftpNotConnected => 'The file transfer session is not connected.';

  @override
  String get shortcutCloseTerminal => 'Close terminal';

  @override
  String get shortcutCopy => 'Copy';

  @override
  String get shortcutNewServer => 'New server';

  @override
  String get shortcutNewTerminal => 'New terminal on this server';

  @override
  String get shortcutPaste => 'Paste';

  @override
  String get shortcutSettings => 'Settings';

  @override
  String get shortcutSidebar => 'Show or hide the sidebar';

  @override
  String get show => 'Show';

  @override
  String get showAll => 'Show All';

  @override
  String get showEverything => 'Show Everything';

  @override
  String get showInTray => 'Show in Tray';

  @override
  String get showSessionOnConnect => 'Show a session when it connects';

  @override
  String get showSessionOnConnectHelp =>
      'Switch to a terminal as soon as it opens.';

  @override
  String get showSidebar => 'Show Sidebar (Ctrl+\\)';

  @override
  String get smallerText => 'Smaller Text (Ctrl+-)';

  @override
  String get snippetNameHint => 'Restart nginx';

  @override
  String get snippetNoCommand => 'This snippet has no command to run.';

  @override
  String get snippetsTitle => 'Snippets';

  @override
  String get sourceCode => 'Source code';

  @override
  String get sourceOnGitHub => 'Omicron0314/catussh on GitHub';

  @override
  String get ssh => 'SSH';

  @override
  String get start => 'Start';

  @override
  String get stop => 'Stop';

  @override
  String get stopAll => 'Stop All';

  @override
  String get stopAndClose => 'Stop and Close';

  @override
  String stopRunning(String name) {
    return 'Stop running $name?';
  }

  @override
  String get storage => 'Storage';

  @override
  String storageEncrypted(String path) {
    return 'Servers, identities and snippets are encrypted (AES-256-GCM) in $path; the key is kept in the system keyring.';
  }

  @override
  String get summary => 'Summary';

  @override
  String get swap => 'Swap';

  @override
  String get syntaxHighlighting => 'Syntax highlighting';

  @override
  String get system => 'System';

  @override
  String get target => 'Target';

  @override
  String get targetHost => 'Target host';

  @override
  String get targetPort => 'Target port';

  @override
  String terminalAlreadyOpen(String name) {
    return '$name already has a terminal open';
  }

  @override
  String get terminalColorsUnder => 'Terminal colors are set under Terminal.';

  @override
  String get terminalFallbackTitle => 'Terminal';

  @override
  String get terminalOpen => 'A terminal is open';

  @override
  String terminalTab(int number) {
    return 'Terminal $number';
  }

  @override
  String get text => 'Text';

  @override
  String get textNotLoaded => 'The text could not be loaded.';

  @override
  String get thisSnippet => 'this snippet';

  @override
  String get through => 'Through';

  @override
  String get toolEditor => 'Editor';

  @override
  String get toolEditorHelp => 'Edit text files on this server';

  @override
  String get toolFiles => 'Files';

  @override
  String get toolFilesHelp => 'Browse, upload and download files over SFTP';

  @override
  String get toolMonitor => 'Monitor';

  @override
  String get toolMonitorHelp => 'Watch CPU, memory, disk and network usage';

  @override
  String get toolTerminal => 'Terminal';

  @override
  String get toolTerminalHelp => 'Open an SSH terminal on this server';

  @override
  String get transfer => 'Transfer';

  @override
  String get transferRunningWarning =>
      'A transfer is still running and will be interrupted.';

  @override
  String get transmit => 'Transmit';

  @override
  String trayTooltipFigures(String cpu, String memory) {
    return 'CPU $cpu%  Mem $memory%';
  }

  @override
  String trayTooltipRates(String transmit, String receive) {
    return '↑ $transmit  ↓ $receive';
  }

  @override
  String get tryAgain => 'Try Again';

  @override
  String tryingIdentity(String identity) {
    return '[i] trying to authenticate with $identity';
  }

  @override
  String unableToConnectOrAuth(String error) {
    return 'Unable to connect or authenticate ($error)';
  }

  @override
  String unableToConnectShort(String host, int port) {
    return 'Unable to connect for $host:$port';
  }

  @override
  String unableToConnectTo(String host, int port, String error) {
    return 'Unable to connect for $host:$port ($error)';
  }

  @override
  String get unknown => 'Unknown';

  @override
  String get unknownError => 'Unknown Error';

  @override
  String get unknownKey => 'Unknown Key';

  @override
  String get unknownServer => 'Unknown server';

  @override
  String get unsavedChangesLost => 'Unsaved changes are lost.';

  @override
  String get unsavedFilesWarning =>
      'Files open in the editor have changes that are not saved. They are lost if you close.';

  @override
  String get unsavedInEditor => 'Unsaved changes in the editor will be lost.';

  @override
  String get untitled => 'Untitled';

  @override
  String get untitledFolder => 'untitled folder';

  @override
  String get upload => 'Upload';

  @override
  String get uploadCancelled => 'Upload cancelled';

  @override
  String get uploadComplete => 'Upload complete';

  @override
  String uploadFailed(String error) {
    return 'Upload failed: $error';
  }

  @override
  String get uptime => 'Uptime';

  @override
  String get useDesktopAccent => 'Use the desktop accent color';

  @override
  String get useDesktopAccentHelp =>
      'Material You: colors follow your desktop theme when it provides an accent.';

  @override
  String get used => 'Used';

  @override
  String usedBy(String names) {
    return 'Used by $names';
  }

  @override
  String usedByMore(String names, int count) {
    return 'Used by $names and $count more';
  }

  @override
  String usedOfSize(String used, String size) {
    return '$used of $size';
  }

  @override
  String get user => 'User';

  @override
  String get usernameOnly => 'Username Only';

  @override
  String get usernamePlaceholder => 'root';

  @override
  String get vaultKeyMissing =>
      'The key that opens your saved servers is missing from the system keyring.';

  @override
  String get vaultKeyringUnavailable =>
      'The system keyring (Secret Service) could not be reached, so servers and identities are kept for this run only.';

  @override
  String get version => 'Version';

  @override
  String versionLine(String version, String build) {
    return '$version ($build) · Linux';
  }

  @override
  String get vram => 'VRAM';

  @override
  String weeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks ago',
      one: 'last week',
    );
    return '$_temp0';
  }

  @override
  String get welcome => 'Welcome to catussh';

  @override
  String get whereKept => 'Where your servers are kept';

  @override
  String get wrapLines => 'Wrap Lines';

  @override
  String yearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years ago',
      one: 'last year',
    );
    return '$_temp0';
  }

  @override
  String get yourChangesLost =>
      'Your changes are lost if you don\'t save them.';
}
