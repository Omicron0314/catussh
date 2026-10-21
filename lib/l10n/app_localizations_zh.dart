// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class L10nZh extends L10n {
  L10nZh([String locale = 'zh']) : super(locale);

  @override
  String get about => '关于';

  @override
  String aboutVersionLine(String version) {
    return '$version（Flutter）· Linux';
  }

  @override
  String get absolutePathRequired => '请输入以 / 开头的绝对路径。';

  @override
  String get accentColor => '强调色';

  @override
  String get accentColorHelp => '桌面强调色关闭或不可用时使用。';

  @override
  String get acknowledgements => '致谢';

  @override
  String get addAndConnect => '添加并连接';

  @override
  String get addServer => '添加服务器';

  @override
  String get addServerAction => '添加';

  @override
  String get address => '地址';

  @override
  String get addressesHidden => '地址已隐藏';

  @override
  String get agreementEllipsis => '用户协议…';

  @override
  String get allGroups => '全部分组';

  @override
  String get appName => 'catussh';

  @override
  String get appTagline => '为你的服务器提供终端、文件和监控。';

  @override
  String get appearance => '外观';

  @override
  String get askBeforeClosing => '关闭会话前确认';

  @override
  String get askBeforeClosingHelp => '关闭已连接的终端或删除前先确认。';

  @override
  String get authenticateAutomatically => '自动认证';

  @override
  String get authenticateAutomaticallyHelp => '快速连接需要它。';

  @override
  String get authentication => '认证方式';

  @override
  String get automatic => '自动';

  @override
  String get basedOn => '基于';

  @override
  String get basedOnText =>
      'mizorewww 的 catussh，它延续自 Lakr Aream（@Lakr233）和贡献者们的 Rayon。本版本与原作者无隶属关系，也未获其背书。';

  @override
  String get bind => '监听';

  @override
  String get bindPort => '监听端口';

  @override
  String get cache => '缓存';

  @override
  String get cancel => '取消';

  @override
  String get cannotConnect => '无法连接';

  @override
  String cannotOpenFile(String name) {
    return '无法打开 $name';
  }

  @override
  String caretPosition(int line, int column) {
    return '第 $line 行，第 $column 列';
  }

  @override
  String get changesReplaced => '服务器上的文件会覆盖你的修改。';

  @override
  String get checkThenSave => '先检查连接，再保存服务器';

  @override
  String get chineseSimplified => '简体中文';

  @override
  String get chineseTraditional => '繁體中文';

  @override
  String get choose => '选择';

  @override
  String get chooseExistingGroup => '选择已有分组';

  @override
  String get chooseIdentity => '选择身份';

  @override
  String get chooseServer => '选择服务器';

  @override
  String get clear => '清除';

  @override
  String get clearScrollback => '清空回滚';

  @override
  String get clickToOpenTerminal => '点击打开终端';

  @override
  String get close => '关闭';

  @override
  String get closeAll => '全部关闭';

  @override
  String get closeEditor => '关闭编辑器';

  @override
  String closeEditorOn(String name) {
    return '要关闭 $name 上的编辑器吗？';
  }

  @override
  String closeEverythingOn(String name) {
    return '要关闭 $name 上打开的所有内容吗？';
  }

  @override
  String closeFileName(String name) {
    return '关闭 $name';
  }

  @override
  String closeFileWithoutSaving(String name) {
    return '不保存就关闭 $name？';
  }

  @override
  String get closeFiles => '关闭文件';

  @override
  String get closeMonitor => '关闭监控';

  @override
  String get closeSession => '关闭会话';

  @override
  String closeSessionOn(String name) {
    return '要关闭 $name 上的会话吗？';
  }

  @override
  String get closeTerminal => '关闭终端';

  @override
  String closeTitle(String title) {
    return '关闭 $title';
  }

  @override
  String closeTransfer(String name) {
    return '要关闭 $name 上的文件传输吗？';
  }

  @override
  String get closeWindow => '关闭';

  @override
  String get codeHint => 'sudo systemctl restart nginx';

  @override
  String get colors => '配色';

  @override
  String get command => '命令';

  @override
  String get connect => '连接';

  @override
  String get connectEnter => '连接（回车）';

  @override
  String connectFailedReason(String host, int port) {
    return '无法访问 $host 的 $port 端口。';
  }

  @override
  String get connecting => '正在连接…';

  @override
  String get connectingEllipsis => '正在连接…';

  @override
  String get connection => '连接';

  @override
  String get connectionClosed => '连接已关闭';

  @override
  String get connectionClosedBanner => '[*] 连接已关闭';

  @override
  String get connectionTimeout => '连接超时';

  @override
  String get connectionTimeoutHelp => '等待服务器响应的最长时间。';

  @override
  String get continue_ => '继续';

  @override
  String copied(Object what) {
    return '已复制$what';
  }

  @override
  String get copy => '复制';

  @override
  String get copyAddress => '复制地址';

  @override
  String get copyCommand => '复制 SSH 命令';

  @override
  String get copyName => '复制名称';

  @override
  String get copyPath => '复制路径';

  @override
  String get copyPublicKey => '复制公钥';

  @override
  String get cores => '每核';

  @override
  String couldNotSave(String name, String error) {
    return '无法保存 $name。$error';
  }

  @override
  String get cpu => 'CPU';

  @override
  String get create => '创建';

  @override
  String get creatingConnection => '[*] 正在建立连接';

  @override
  String creatingFolderPath(String path) {
    return '正在创建文件夹 $path…';
  }

  @override
  String cudaVersion(String version) {
    return 'CUDA $version';
  }

  @override
  String get dark => '深色';

  @override
  String daysAgo(int count) {
    return '$count 天前';
  }

  @override
  String get defaultGroup => '默认';

  @override
  String get delete => '删除';

  @override
  String get deleteEllipsis => '删除…';

  @override
  String deleteFile(String name) {
    return '删除 $name？';
  }

  @override
  String get deleteFileWarning => '这个文件会从服务器上删除，无法撤销。';

  @override
  String get deleteFolderWarning => '这个文件夹及其中的所有内容会从服务器上删除，无法撤销。';

  @override
  String deleteForward(int port) {
    return '删除 $port 端口的转发？';
  }

  @override
  String deleteIdentity(String username) {
    return '删除身份 $username？';
  }

  @override
  String deleteServer(String name) {
    return '删除 $name？';
  }

  @override
  String deleteServers(int count) {
    return '删除 $count 台服务器？';
  }

  @override
  String deleteTitle(String name) {
    return '删除 $name？';
  }

  @override
  String get deletedServer => '已删除的服务器';

  @override
  String deletingFile(String name) {
    return '正在删除 $name…';
  }

  @override
  String get deselectAll => '取消全选';

  @override
  String get discardAndClose => '放弃更改并关闭';

  @override
  String get discardChanges => '放弃更改';

  @override
  String get disks => '磁盘';

  @override
  String get done => '完成';

  @override
  String get download => '下载';

  @override
  String get downloadCancelled => '下载已取消';

  @override
  String get downloadComplete => '下载完成';

  @override
  String get downloadEllipsis => '下载…';

  @override
  String downloadFailed(String error) {
    return '下载失败：$error';
  }

  @override
  String get downloadHere => '下载到这里';

  @override
  String dropToUpload(String path) {
    return '拖放到此处，上传到 $path';
  }

  @override
  String get duplicate => '复制一份';

  @override
  String duplicateServer(String name) {
    return '复制 $name？';
  }

  @override
  String durationDaysHours(int days, int hours) {
    return '$days天 $hours小时';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours小时 $minutes分';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes分';
  }

  @override
  String get edit => '编辑…';

  @override
  String get editAction => '编辑';

  @override
  String get editPortForward => '编辑端口转发';

  @override
  String get editServer => '编辑服务器';

  @override
  String get editSnippet => '编辑片段';

  @override
  String get edited => '已修改';

  @override
  String get emptyFolder => '空文件夹';

  @override
  String get emptyServersMessage => '保存的服务器会记住地址、端口和身份，可以一键打开终端、文件或监控。';

  @override
  String get emptyServersTitle => '保存一台服务器，以后一键就能连上';

  @override
  String get enclosingFolder => '上一级文件夹（Alt+↑）';

  @override
  String get english => 'English';

  @override
  String get equivalentCommand => '等效命令';

  @override
  String get error => '错误';

  @override
  String get eula => '最终用户许可协议';

  @override
  String everySeconds(int seconds) {
    return '每 $seconds 秒';
  }

  @override
  String get execBegin => '[*] 开始执行';

  @override
  String get execCannotConnect => '[E] 无法连接到服务器';

  @override
  String get execCannotSignIn => '[E] 身份无法登录';

  @override
  String get execCompleted => '[*] 执行完成';

  @override
  String get execStopped => '[*] 已停止';

  @override
  String get failed => '失败';

  @override
  String get failedSftpSetup => '无法建立文件传输协议';

  @override
  String get failedToAuthenticate => '认证失败。是不是忘了添加身份，或者没有开启自动认证？';

  @override
  String failedToLoadPath(String path, String error) {
    return '无法载入 $path：$error';
  }

  @override
  String fanSpeed(String speed) {
    return '风扇 $speed';
  }

  @override
  String get fieldAddress => '地址';

  @override
  String get fieldComment => '备注';

  @override
  String get fieldGroup => '分组';

  @override
  String get fieldIdentity => '身份';

  @override
  String get fieldLastBanner => '上次服务器信息';

  @override
  String get fieldName => '名称';

  @override
  String get fieldPort => '端口';

  @override
  String get fieldStartFolder => 'SFTP 起始目录';

  @override
  String get fieldUsername => '用户名';

  @override
  String get fifteenMinutes => '15 分钟';

  @override
  String get fileNotReadable => '无法把这个文件当作文本读取。';

  @override
  String get fileSize => '大小';

  @override
  String get fileTransfer => '文件传输';

  @override
  String get filterByGroup => '按分组筛选';

  @override
  String get filterThisFolder => '筛选当前文件夹';

  @override
  String finishedOfTotal(int done, int total) {
    return '已完成 $done/$total';
  }

  @override
  String get fiveMinutes => '5 分钟';

  @override
  String get followSystem => '跟随系统';

  @override
  String get font => '字体';

  @override
  String get fontHelp => '已安装的等宽字体。';

  @override
  String get fontSize => '字号';

  @override
  String get fontSizeHelp => '在终端里用 Ctrl+= 和 Ctrl+- 调整。';

  @override
  String get forget => '忘记';

  @override
  String get forgetAll => '全部忘记…';

  @override
  String get forgetAllAction => '全部忘记';

  @override
  String get forgetAllHostKeys => '忘记所有已保存的主机密钥？';

  @override
  String get forgetAllHostKeysHelp => '下次连接时，每台服务器提供的密钥会被保存为它的密钥。';

  @override
  String get forgetHostKey => '忘记主机密钥…';

  @override
  String get forgetHostKeyExplain =>
      '下一次连接时，服务器提供的密钥会被保存为它的密钥。只有在你确定它的密钥被更换过时才这么做。';

  @override
  String forgetHostKeyOf(String name) {
    return '忘记 $name 的主机密钥？';
  }

  @override
  String get forwardFailedAuth => '无法登录，正在重试';

  @override
  String get forwardFailedConnect => '无法连接，正在重试';

  @override
  String get forwardRunning => '运行中';

  @override
  String get forwardStopped => '已停止，正在重试';

  @override
  String get forwardThrough => '经由服务器';

  @override
  String get free => '空闲';

  @override
  String get general => '通用';

  @override
  String get goAction => '前往';

  @override
  String get goToFolder => '前往文件夹';

  @override
  String get goToFolderShortcut => '前往文件夹（Ctrl+Shift+G）';

  @override
  String get gpu => '占用';

  @override
  String gpuCount(int count) {
    return '显卡 · $count 块';
  }

  @override
  String get graphics => '显卡';

  @override
  String get groupDefaultHint => '默认';

  @override
  String get hide => '隐藏';

  @override
  String get hideAddresses => '隐藏地址';

  @override
  String get hideNamesAndAddresses => '隐藏名称和地址';

  @override
  String get hideSidebar => '隐藏侧栏（Ctrl+\\）';

  @override
  String get host => '主机';

  @override
  String hostKeyChanged(String host, int port) {
    return '$host:$port 的主机密钥已经改变，因此拒绝连接。';
  }

  @override
  String get hostKeyChangedHelp =>
      '如果服务器重装过或更换了密钥，对它选择“忘记主机密钥”后重新连接。否则可能有第三方在拦截连接。';

  @override
  String hostKeyOffered(String type, String fingerprint) {
    return '对方提供：$type $fingerprint';
  }

  @override
  String hostKeySaved(String type, String fingerprint) {
    return '已保存：$type $fingerprint';
  }

  @override
  String hostKeysSaved(int count) {
    return '已保存 $count 个';
  }

  @override
  String get hostPlaceholder => '主机名或 IP 地址';

  @override
  String get hostname => '主机名';

  @override
  String hoursAgo(int count) {
    return '$count 小时前';
  }

  @override
  String get iAgree => '我已阅读并同意该许可协议';

  @override
  String get iconLabel => '图标';

  @override
  String get identitiesTitle => '身份';

  @override
  String identityCouldNotSignIn(String host, String error) {
    return '所选身份无法登录 $host。（$error）';
  }

  @override
  String get identityEmptyMessage => '一个用户名，加上密码或密钥。';

  @override
  String identityGroup(String group) {
    return '分组<$group>';
  }

  @override
  String identityInUse(int count) {
    return '$count 台服务器正在使用它，删除后会改用自动身份。';
  }

  @override
  String get identityLabel => '身份';

  @override
  String get identityRemoved => '它的密码和密钥会从 catussh 中移除。';

  @override
  String identityShort(String username, String type) {
    return '用户 $username，$type';
  }

  @override
  String inDays(int count) {
    return '$count 天后';
  }

  @override
  String inHours(int count) {
    return '$count 小时后';
  }

  @override
  String inMinutes(int count) {
    return '$count 分钟后';
  }

  @override
  String get includeQuickConnect => '包含快速连接命令';

  @override
  String get includeQuickConnectHelp => '也记住在主页输入的 user@host 命令。';

  @override
  String get incomplete => '信息不完整';

  @override
  String get invalidForward => '无效的转发';

  @override
  String get invalidName => '这个名称包含文件名不允许的字符。';

  @override
  String get ioWait => 'IO 等待';

  @override
  String get issues => '问题反馈';

  @override
  String get issuesHelp => '问题和建议请提到项目的 issue 里。';

  @override
  String get keyPair => '密钥对';

  @override
  String get keyTypeKeyPair => '密钥对';

  @override
  String get keyTypePlainKeyPair => '无密码密钥对';

  @override
  String get keyTypePlainPrivateKey => '无密码私钥';

  @override
  String get keyTypePrivateKey => '私钥';

  @override
  String get keyboard => '快捷键';

  @override
  String get language => '语言';

  @override
  String get languageHelp => '界面和提示文字，日期也会跟着变；服务器名称和终端内容保持不变。';

  @override
  String get largerText => '放大文字（Ctrl+=）';

  @override
  String get lastErrorFromBackend => '[i] 后端返回的最后一个错误';

  @override
  String get lastUsed => '上次使用';

  @override
  String get legal => '法律信息';

  @override
  String get libraries => '使用的库';

  @override
  String get librariesText =>
      'Flutter · dartssh2 · xterm.dart · re_editor · dynamic_color · tray_manager · cryptography';

  @override
  String get license => '许可证';

  @override
  String get licenseEllipsis => '许可证…';

  @override
  String get light => '浅色';

  @override
  String get lightOrDark => '浅色或深色';

  @override
  String get listenLocal => '本地监听';

  @override
  String get listenRemote => '远程监听';

  @override
  String liveFigures(
    String cpu,
    String memory,
    String receive,
    String transmit,
  ) {
    return 'CPU $cpu%    内存 $memory%    ↓ $receive ↑ $transmit';
  }

  @override
  String get load => '负载';

  @override
  String get loadComplete => '载入完成';

  @override
  String get loadItAnyway => '仍要载入吗？';

  @override
  String get loadPrivateKey => '载入私钥…';

  @override
  String get loadPublicKey => '载入公钥…';

  @override
  String loadingPath(String path) {
    return '正在载入… $path';
  }

  @override
  String get localForwardExplain => '本机 :端口 → 服务器 → 目标';

  @override
  String localForwardShort(int bind, String server, String host, int port) {
    return 'localhost:$bind -$server-> $host:$port';
  }

  @override
  String get malformedMachine => '服务器或身份的数据不完整';

  @override
  String get malformedMachineInfo => '[*] 服务器信息不完整';

  @override
  String get materialYou => 'Material You';

  @override
  String get maximizeWindow => '最大化';

  @override
  String get memory => '内存';

  @override
  String memoryWithTotal(String total) {
    return '内存 · $total';
  }

  @override
  String get minimizeWindow => '最小化';

  @override
  String minutesAgo(int count) {
    return '$count 分钟前';
  }

  @override
  String get missing => '缺失';

  @override
  String get modified => '修改时间';

  @override
  String get monitor => '监控';

  @override
  String get monitorClosed => '监控已关闭';

  @override
  String monthsAgo(int count) {
    return '$count 个月前';
  }

  @override
  String get more => '更多';

  @override
  String get moreActions => '更多操作';

  @override
  String get namePlaceholder => 'prod-web-01';

  @override
  String get nameRequired => '名称不能为空。';

  @override
  String get namesAndAddressesHidden => '名称和地址已隐藏';

  @override
  String get navHome => '主页';

  @override
  String get navIdentities => '身份';

  @override
  String get navManage => '管理';

  @override
  String get navPortForward => '端口转发';

  @override
  String get navServers => '服务器';

  @override
  String get navSessions => '会话';

  @override
  String get navSettings => '设置';

  @override
  String get navSnippets => '片段';

  @override
  String get network => '网络';

  @override
  String get never => '从未';

  @override
  String get newFolder => '新建文件夹';

  @override
  String get newIdentity => '新建身份';

  @override
  String get newPortForward => '新建端口转发';

  @override
  String get newServer => '新建服务器';

  @override
  String get newSnippet => '新建片段';

  @override
  String get newTerminal => '新建终端';

  @override
  String get newTerminalShortcut => '新建终端（Ctrl+Shift+T）';

  @override
  String get nice => 'Nice';

  @override
  String get noAutoIdentity => '没有设置自动认证的身份。请为这台服务器选择一个身份。';

  @override
  String get noCredentials => '没有凭据';

  @override
  String get noData => '没有数据';

  @override
  String get noFileOpen => '没有打开的文件';

  @override
  String get noFileOpenHelp => '在文件页双击一个文本文件，或按路径打开。';

  @override
  String get noIdentitiesYet => '还没有身份';

  @override
  String noIdentityForUser(String username) {
    return '没有 $username 的自动认证身份。请在“身份”里添加。';
  }

  @override
  String get noMatches => '没有匹配项';

  @override
  String get noPortForwards => '还没有端口转发';

  @override
  String get noPrivateKeyLoaded => '未载入私钥';

  @override
  String get noPublicKeyLoaded => '未载入公钥';

  @override
  String get noServer => '没有服务器';

  @override
  String get noServersYet => '还没有服务器';

  @override
  String get noSnippetsYet => '还没有片段';

  @override
  String get noSwap => '没有交换分区';

  @override
  String get noUsername => '没有用户名';

  @override
  String get noWrapLines => '不自动换行';

  @override
  String get none => '无';

  @override
  String notAKeyFile(String kind) {
    return '这个文件看起来不像$kind密钥';
  }

  @override
  String get notConnected => '未连接';

  @override
  String get notUsedByAnyServer => '没有被任何服务器使用';

  @override
  String get now => '刚刚';

  @override
  String get numberToKeep => '保留数量';

  @override
  String get ok => '好';

  @override
  String get oneMinute => '1 分钟';

  @override
  String get openAction => '打开';

  @override
  String get openAnother => '再开一个';

  @override
  String get openEditor => '打开编辑器';

  @override
  String get openFile => '打开文件';

  @override
  String get openFileEllipsis => '打开文件…';

  @override
  String get openFileShortcut => '打开文件…（Ctrl+O）';

  @override
  String get openFiles => '打开文件';

  @override
  String get openIdentities => '打开身份';

  @override
  String get openMonitor => '打开监控';

  @override
  String get openTerminal => '打开终端';

  @override
  String get openTerminals => '批量打开终端…';

  @override
  String get openTerminalsHelp => '选择多台服务器，各打开一个终端';

  @override
  String get openTerminalsTitle => '批量打开终端';

  @override
  String openingFile(String name) {
    return '正在打开 $name…';
  }

  @override
  String get optional => '可选';

  @override
  String get orientation => '方向';

  @override
  String get os => '系统';

  @override
  String get owner => '所有者';

  @override
  String get passphrase => '私钥密码';

  @override
  String get password => '密码';

  @override
  String get paste => '粘贴';

  @override
  String get pathExample => '/etc/hosts';

  @override
  String get pathLabel => '路径';

  @override
  String peakRate(String rate) {
    return '峰值 $rate';
  }

  @override
  String get permissions => '权限';

  @override
  String get plainKeyPair => '无密码密钥对';

  @override
  String get plainPrivateKey => '无密码私钥';

  @override
  String get port => '端口';

  @override
  String get portForwardTitle => '端口转发';

  @override
  String get portForwardsStop => '经由它的端口转发会停止工作。';

  @override
  String get portRange => '1–65535';

  @override
  String get privacy => '隐私';

  @override
  String get privateKey => '私钥';

  @override
  String get privateKeyLower => '私钥';

  @override
  String get processes => '进程';

  @override
  String get processor => '处理器';

  @override
  String processorCores(int count) {
    return '处理器 · $count 核';
  }

  @override
  String get publicKey => '公钥';

  @override
  String get publicKeyLower => '公钥';

  @override
  String get publicKeyOptional => '公钥（可选）';

  @override
  String get quickConnectHelp => '输入 user@host、user@host:端口，或完整的 ssh 命令。';

  @override
  String get quickConnectHint => 'user@host:22';

  @override
  String get quickConnectNoAutoIdentity => '快速连接使用“自动认证”的身份登录。你还没有这样的身份。';

  @override
  String get quit => '退出';

  @override
  String get ram => '内存';

  @override
  String get receive => '接收';

  @override
  String get recent => '最近';

  @override
  String get recentSection => '最近记录';

  @override
  String get reconnect => '重新连接';

  @override
  String get reconnectTerminal => '重新连接终端';

  @override
  String get reconnectingNote => '[i] 用会话开始时的信息重新连接。';

  @override
  String get reconnectingNoteHelp => '    如果服务器被修改过，请改为新开一个终端。';

  @override
  String get refresh => '刷新频率';

  @override
  String get refreshHelp => '打开监控时读取服务器的间隔。';

  @override
  String get reload => '重新加载';

  @override
  String reloadFromServer(String name) {
    return '从服务器重新载入 $name？';
  }

  @override
  String get reloadFromServerAction => '从服务器重新载入';

  @override
  String get reloadShortcut => '重新加载（Ctrl+R）';

  @override
  String get rememberRecentServers => '记住最近使用的服务器';

  @override
  String get rememberRecentServersHelp => '列在主页快速连接下方。';

  @override
  String get remoteForwardExplain => '服务器 :端口 → 本机 → 目标';

  @override
  String remoteForwardShort(int bind, String server, String host, int port) {
    return '$server:$bind -localhost-> $host:$port';
  }

  @override
  String get remove => '移除';

  @override
  String get removeFromRecent => '从最近记录中移除';

  @override
  String get removeFromTray => '从托盘移除';

  @override
  String get rename => '重命名';

  @override
  String get renameEllipsis => '重命名…';

  @override
  String renamingFile(String name) {
    return '正在重命名 $name…';
  }

  @override
  String get reportProblem => '报告问题';

  @override
  String get required => '必填';

  @override
  String get restoreWindow => '还原';

  @override
  String get revert => '还原';

  @override
  String get run => '运行…';

  @override
  String get runAction => '运行';

  @override
  String runName(String name) {
    return '运行 $name';
  }

  @override
  String runningOfTotal(int total) {
    return '/ $total 个运行';
  }

  @override
  String get save => '保存';

  @override
  String get saveAndStart => '保存并启动';

  @override
  String get saveShortcut => '保存（Ctrl+S）';

  @override
  String get saveWithoutConnecting => '保存服务器但不连接';

  @override
  String get savedHostKeys => '已保存的主机密钥';

  @override
  String get saving => '正在保存…';

  @override
  String get search => '搜索';

  @override
  String get searchForwards => '搜索转发';

  @override
  String get searchIdentities => '搜索身份';

  @override
  String get searchServers => '搜索服务器';

  @override
  String get searchSnippets => '搜索片段';

  @override
  String get selectAll => '全选';

  @override
  String get selectAllText => '全选';

  @override
  String get selectIdentity => '选择一个身份';

  @override
  String get selectIdentityFirst => '没有能自动认证的身份登录成功，请选择一个身份。';

  @override
  String get serverFallbackName => '服务器';

  @override
  String serverRefusedListen(int port) {
    return '服务器拒绝在 $port 端口监听。';
  }

  @override
  String get serversNeedIdentity => '服务器需要先设置身份。';

  @override
  String get serversSection => '服务器';

  @override
  String serversUsingCount(int count) {
    return '$count 台服务器';
  }

  @override
  String sessionToolsOpen(String tools) {
    return '$tools已打开';
  }

  @override
  String get sessionsSection => '会话';

  @override
  String get settingsShortcut => '设置（Ctrl+,）';

  @override
  String get sftpNotConnected => '文件传输会话尚未连接。';

  @override
  String get shortcutCloseTerminal => '关闭终端';

  @override
  String get shortcutCopy => '复制';

  @override
  String get shortcutNewServer => '新建服务器';

  @override
  String get shortcutNewTerminal => '在这台服务器上新开终端';

  @override
  String get shortcutPaste => '粘贴';

  @override
  String get shortcutSettings => '设置';

  @override
  String get shortcutSidebar => '显示或隐藏侧栏';

  @override
  String get show => '显示';

  @override
  String get showAll => '查看全部';

  @override
  String get showEverything => '全部显示';

  @override
  String get showInTray => '显示在托盘';

  @override
  String get showSessionOnConnect => '连接后自动切换到会话';

  @override
  String get showSessionOnConnectHelp => '终端一打开就切换过去。';

  @override
  String get showSidebar => '显示侧栏（Ctrl+\\）';

  @override
  String get smallerText => '缩小文字（Ctrl+-）';

  @override
  String get snippetNameHint => '重启 nginx';

  @override
  String get snippetNoCommand => '这个片段没有可以运行的命令。';

  @override
  String get snippetsTitle => '片段';

  @override
  String get sourceCode => '源代码';

  @override
  String get sourceOnGitHub => 'GitHub 上的 Omicron0314/catussh';

  @override
  String get ssh => 'SSH';

  @override
  String get start => '启动';

  @override
  String get stop => '停止';

  @override
  String get stopAll => '全部停止';

  @override
  String get stopAndClose => '停止并关闭';

  @override
  String stopRunning(String name) {
    return '要停止运行 $name 吗？';
  }

  @override
  String get storage => '存储';

  @override
  String storageEncrypted(String path) {
    return '服务器、身份和片段以 AES-256-GCM 加密存放在 $path，密钥保存在系统密钥环里。';
  }

  @override
  String get summary => '汇总';

  @override
  String get swap => '交换';

  @override
  String get syntaxHighlighting => '语法高亮';

  @override
  String get system => '跟随系统';

  @override
  String get target => '目标';

  @override
  String get targetHost => '目标主机';

  @override
  String get targetPort => '目标端口';

  @override
  String terminalAlreadyOpen(String name) {
    return '$name 已经打开了一个终端';
  }

  @override
  String get terminalColorsUnder => '终端配色在“终端”里设置。';

  @override
  String get terminalFallbackTitle => '终端';

  @override
  String get terminalOpen => '已打开终端';

  @override
  String terminalTab(int number) {
    return '终端 $number';
  }

  @override
  String get text => '文字';

  @override
  String get textNotLoaded => '无法载入文本。';

  @override
  String get thisSnippet => '这个片段';

  @override
  String get through => '经由';

  @override
  String get toolEditor => '编辑器';

  @override
  String get toolEditorHelp => '编辑这台服务器上的文本文件';

  @override
  String get toolFiles => '文件';

  @override
  String get toolFilesHelp => '通过 SFTP 浏览、上传和下载文件';

  @override
  String get toolMonitor => '监控';

  @override
  String get toolMonitorHelp => '查看 CPU、内存、磁盘和网络占用';

  @override
  String get toolTerminal => '终端';

  @override
  String get toolTerminalHelp => '在这台服务器上打开 SSH 终端';

  @override
  String get transfer => '传输';

  @override
  String get transferRunningWarning => '还有传输正在进行，会被中断。';

  @override
  String get transmit => '发送';

  @override
  String trayTooltipFigures(String cpu, String memory) {
    return 'CPU $cpu%  内存 $memory%';
  }

  @override
  String trayTooltipRates(String transmit, String receive) {
    return '↑ $transmit  ↓ $receive';
  }

  @override
  String get tryAgain => '重试';

  @override
  String tryingIdentity(String identity) {
    return '[i] 正在尝试用 $identity 认证';
  }

  @override
  String unableToConnectOrAuth(String error) {
    return '无法连接或认证（$error）';
  }

  @override
  String unableToConnectShort(String host, int port) {
    return '无法连接到 $host:$port';
  }

  @override
  String unableToConnectTo(String host, int port, String error) {
    return '无法连接到 $host:$port（$error）';
  }

  @override
  String get unknown => '未知';

  @override
  String get unknownError => '未知错误';

  @override
  String get unknownKey => '未知密钥';

  @override
  String get unknownServer => '未知服务器';

  @override
  String get unsavedChangesLost => '未保存的修改将会丢失。';

  @override
  String get unsavedFilesWarning => '编辑器里打开的文件有未保存的修改，关闭后会丢失。';

  @override
  String get unsavedInEditor => '编辑器中未保存的修改将会丢失。';

  @override
  String get untitled => '未命名';

  @override
  String get untitledFolder => '未命名文件夹';

  @override
  String get upload => '上传';

  @override
  String get uploadCancelled => '上传已取消';

  @override
  String get uploadComplete => '上传完成';

  @override
  String uploadFailed(String error) {
    return '上传失败：$error';
  }

  @override
  String get uptime => '运行时间';

  @override
  String get useDesktopAccent => '使用桌面强调色';

  @override
  String get useDesktopAccentHelp => 'Material You：桌面主题提供强调色时，配色跟随桌面。';

  @override
  String get used => '已用';

  @override
  String usedBy(String names) {
    return '被 $names 使用';
  }

  @override
  String usedByMore(String names, int count) {
    return '被 $names 等 $count 台服务器使用';
  }

  @override
  String usedOfSize(String used, String size) {
    return '$used / $size';
  }

  @override
  String get user => '用户';

  @override
  String get usernameOnly => '仅用户名';

  @override
  String get usernamePlaceholder => 'root';

  @override
  String get vaultKeyMissing => '系统密钥环里找不到用于解密已保存服务器的密钥。';

  @override
  String get vaultKeyringUnavailable =>
      '无法访问系统密钥环（Secret Service），服务器和身份只在本次运行期间保留。';

  @override
  String get version => '版本';

  @override
  String versionLine(String version, String build) {
    return '$version（$build）· Linux';
  }

  @override
  String get vram => '显存';

  @override
  String weeksAgo(int count) {
    return '$count 周前';
  }

  @override
  String get welcome => '欢迎使用 catussh';

  @override
  String get whereKept => '服务器数据的存放位置';

  @override
  String get wrapLines => '自动换行';

  @override
  String yearsAgo(int count) {
    return '$count 年前';
  }

  @override
  String get yourChangesLost => '不保存的话修改会丢失。';
}
