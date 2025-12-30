///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'translations.g.dart';

// Path: <root>
typedef TranslationsZh = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.zh,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  );

	/// Metadata for the translations of <zh>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final TranslationsAppZh app = TranslationsAppZh.internal(_root);
	late final TranslationsCommonZh common = TranslationsCommonZh.internal(_root);
	late final TranslationsWorkspaceZh workspace = TranslationsWorkspaceZh.internal(_root);
	late final TranslationsDocumentZh document = TranslationsDocumentZh.internal(_root);
	late final TranslationsSettingsZh settings = TranslationsSettingsZh.internal(_root);
	late final TranslationsAppearanceZh appearance = TranslationsAppearanceZh.internal(_root);
	late final TranslationsWelcomeZh welcome = TranslationsWelcomeZh.internal(_root);
	late final TranslationsTimeZh time = TranslationsTimeZh.internal(_root);
}

// Path: app
class TranslationsAppZh {
	TranslationsAppZh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '云笺妙笔'
	String get name => '云笺妙笔';

	/// zh: 'Enjoy writing with AI'
	String get slogan => 'Enjoy writing with AI';
}

// Path: common
class TranslationsCommonZh {
	TranslationsCommonZh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '确定'
	String get confirm => '确定';

	/// zh: '取消'
	String get cancel => '取消';

	/// zh: '保存'
	String get save => '保存';

	/// zh: '删除'
	String get delete => '删除';

	/// zh: '编辑'
	String get edit => '编辑';

	/// zh: '重命名'
	String get rename => '重命名';

	/// zh: '设置'
	String get settings => '设置';

	/// zh: '搜索'
	String get search => '搜索';

	/// zh: '加载中...'
	String get loading => '加载中...';

	/// zh: '错误'
	String get error => '错误';

	/// zh: '成功'
	String get success => '成功';

	/// zh: '警告'
	String get warning => '警告';

	/// zh: '提示'
	String get info => '提示';
}

// Path: workspace
class TranslationsWorkspaceZh {
	TranslationsWorkspaceZh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '工作空间'
	String get title => '工作空间';

	/// zh: '新建工作空间'
	String get create => '新建工作空间';

	/// zh: '选择一个工作空间开始'
	String get selectToStart => '选择一个工作空间开始';

	/// zh: '从左侧选择或点击 + 创建工作空间'
	String get selectHint => '从左侧选择或点击 + 创建工作空间';

	/// zh: '名称'
	String get name => '名称';

	/// zh: '输入工作空间名称'
	String get namePlaceholder => '输入工作空间名称';

	/// zh: '请输入工作空间名称'
	String get nameRequired => '请输入工作空间名称';

	/// zh: '描述（可选）'
	String get description => '描述（可选）';

	/// zh: '简要描述这个工作空间'
	String get descriptionPlaceholder => '简要描述这个工作空间';

	/// zh: '选择图标'
	String get selectIcon => '选择图标';

	/// zh: '主题色'
	String get themeColor => '主题色';

	/// zh: '置顶'
	String get pin => '置顶';

	/// zh: '取消置顶'
	String get unpin => '取消置顶';

	/// zh: '归档'
	String get archive => '归档';

	/// zh: '进入工作空间'
	String get enterWorkspace => '进入工作空间';
}

// Path: document
class TranslationsDocumentZh {
	TranslationsDocumentZh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '新建'
	String get kNew => '新建';

	/// zh: '新建文档'
	String get newDocument => '新建文档';

	/// zh: '导入文档'
	String get importDocument => '导入文档';

	/// zh: '输入文档名称'
	String get documentName => '输入文档名称';

	/// zh: '还没有文档'
	String get empty => '还没有文档';

	/// zh: '点击上方「新建」按钮创建第一个文档'
	String get emptyHint => '点击上方「新建」按钮创建第一个文档';

	/// zh: '$count 字'
	String wordCount({required Object count}) => '${count} 字';

	/// zh: '确定删除「$name」？'
	String deleteConfirm({required Object name}) => '确定删除「${name}」？';

	/// zh: '此操作不可撤销'
	String get deleteHint => '此操作不可撤销';

	/// zh: '文件夹内的所有内容也会被删除'
	String get folderDeleteHint => '文件夹内的所有内容也会被删除';

	/// zh: '导入失败: $error'
	String importFailed({required Object error}) => '导入失败: ${error}';

	/// zh: '创建失败: $error'
	String createFailed({required Object error}) => '创建失败: ${error}';
}

// Path: settings
class TranslationsSettingsZh {
	TranslationsSettingsZh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '设置'
	String get title => '设置';

	/// zh: '通用'
	String get general => '通用';

	/// zh: 'AI 模型'
	String get aiModel => 'AI 模型';

	/// zh: '外观'
	String get appearance => '外观';

	/// zh: '快捷键'
	String get shortcuts => '快捷键';

	/// zh: '导入/导出'
	String get importExport => '导入/导出';

	/// zh: '语言'
	String get language => '语言';

	/// zh: '选择应用界面显示的语言'
	String get languageDesc => '选择应用界面显示的语言';

	/// zh: '编辑器'
	String get editor => '编辑器';

	/// zh: '自动保存'
	String get autoSave => '自动保存';

	/// zh: '自动保存文档更改'
	String get autoSaveDesc => '自动保存文档更改';

	/// zh: '自动保存间隔'
	String get autoSaveInterval => '自动保存间隔';

	/// zh: '每 $seconds 秒自动保存一次'
	String autoSaveIntervalDesc({required Object seconds}) => '每 ${seconds} 秒自动保存一次';

	/// zh: '显示字数统计'
	String get showWordCount => '显示字数统计';

	/// zh: '在编辑器底部显示字数和字符数'
	String get showWordCountDesc => '在编辑器底部显示字数和字符数';

	/// zh: '拼写检查'
	String get spellCheck => '拼写检查';

	/// zh: '启用拼写检查功能'
	String get spellCheckDesc => '启用拼写检查功能';

	/// zh: 'AI 助手'
	String get aiAssistant => 'AI 助手';

	/// zh: '显示悬浮按钮'
	String get showFloatingButton => '显示悬浮按钮';

	/// zh: '在界面右下角显示 AI 助手快捷按钮'
	String get showFloatingButtonDesc => '在界面右下角显示 AI 助手快捷按钮';

	/// zh: '默认搜索范围'
	String get defaultSearchScope => '默认搜索范围';

	/// zh: '打开 AI 助手时的默认知识库搜索范围'
	String get defaultSearchScopeDesc => '打开 AI 助手时的默认知识库搜索范围';

	/// zh: '当前工作空间'
	String get currentWorkspace => '当前工作空间';

	/// zh: '所有工作空间'
	String get allWorkspaces => '所有工作空间';
}

// Path: appearance
class TranslationsAppearanceZh {
	TranslationsAppearanceZh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '主题'
	String get theme => '主题';

	/// zh: '主题模式'
	String get themeMode => '主题模式';

	/// zh: '选择应用的颜色主题'
	String get themeModeDesc => '选择应用的颜色主题';

	/// zh: '跟随系统'
	String get followSystem => '跟随系统';

	/// zh: '浅色'
	String get light => '浅色';

	/// zh: '深色'
	String get dark => '深色';

	/// zh: '字体'
	String get font => '字体';

	/// zh: '字体'
	String get fontFamily => '字体';

	/// zh: '选择编辑器使用的字体'
	String get fontFamilyDesc => '选择编辑器使用的字体';

	/// zh: '系统默认'
	String get systemDefault => '系统默认';

	/// zh: '字体大小'
	String get fontSize => '字体大小';

	/// zh: '调整编辑器的默认字体大小'
	String get fontSizeDesc => '调整编辑器的默认字体大小';

	/// zh: '行高'
	String get lineHeight => '行高';

	/// zh: '调整文本行之间的间距'
	String get lineHeightDesc => '调整文本行之间的间距';

	/// zh: '预览'
	String get preview => '预览';

	/// zh: '这是一段预览文本，用于展示当前的字体设置效果。 This is a preview text to demonstrate the current font settings. 你可以调整上方的设置来查看实时效果。'
	String get previewText => '这是一段预览文本，用于展示当前的字体设置效果。\n\nThis is a preview text to demonstrate the current font settings.\n\n你可以调整上方的设置来查看实时效果。';
}

// Path: welcome
class TranslationsWelcomeZh {
	TranslationsWelcomeZh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '今日热点'
	String get todayHotspot => '今日热点';

	/// zh: '暂无热点'
	String get noHotspot => '暂无热点';

	/// zh: '加载失败'
	String get loadFailed => '加载失败';
}

// Path: time
class TranslationsTimeZh {
	TranslationsTimeZh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '刚刚访问'
	String get justNow => '刚刚访问';

	/// zh: '$count 分钟前'
	String minutesAgo({required Object count}) => '${count} 分钟前';

	/// zh: '$count 小时前'
	String hoursAgo({required Object count}) => '${count} 小时前';

	/// zh: '$count 天前'
	String daysAgo({required Object count}) => '${count} 天前';
}
