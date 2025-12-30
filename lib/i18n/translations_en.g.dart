///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'translations.g.dart';

// Path: <root>
class TranslationsEn extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsEn({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver);

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	late final TranslationsEn _root = this; // ignore: unused_field

	@override 
	TranslationsEn $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsEn(meta: meta ?? this.$meta);

	// Translations
	@override late final TranslationsAppEn app = TranslationsAppEn._(_root);
	@override late final TranslationsCommonEn common = TranslationsCommonEn._(_root);
	@override late final TranslationsWorkspaceEn workspace = TranslationsWorkspaceEn._(_root);
	@override late final TranslationsDocumentEn document = TranslationsDocumentEn._(_root);
	@override late final TranslationsSettingsEn settings = TranslationsSettingsEn._(_root);
	@override late final TranslationsAppearanceEn appearance = TranslationsAppearanceEn._(_root);
	@override late final TranslationsWelcomeEn welcome = TranslationsWelcomeEn._(_root);
	@override late final TranslationsTimeEn time = TranslationsTimeEn._(_root);
}

// Path: app
class TranslationsAppEn extends TranslationsAppZh {
	TranslationsAppEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get name => 'AI Text Editor';
	@override String get slogan => 'Enjoy writing with AI';
}

// Path: common
class TranslationsCommonEn extends TranslationsCommonZh {
	TranslationsCommonEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get confirm => 'Confirm';
	@override String get cancel => 'Cancel';
	@override String get save => 'Save';
	@override String get delete => 'Delete';
	@override String get edit => 'Edit';
	@override String get rename => 'Rename';
	@override String get settings => 'Settings';
	@override String get search => 'Search';
	@override String get loading => 'Loading...';
	@override String get error => 'Error';
	@override String get success => 'Success';
	@override String get warning => 'Warning';
	@override String get info => 'Info';
}

// Path: workspace
class TranslationsWorkspaceEn extends TranslationsWorkspaceZh {
	TranslationsWorkspaceEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Workspaces';
	@override String get create => 'New Workspace';
	@override String get selectToStart => 'Select a workspace to start';
	@override String get selectHint => 'Select from the left or click + to create';
	@override String get name => 'Name';
	@override String get namePlaceholder => 'Enter workspace name';
	@override String get nameRequired => 'Please enter workspace name';
	@override String get description => 'Description (optional)';
	@override String get descriptionPlaceholder => 'Brief description of this workspace';
	@override String get selectIcon => 'Select Icon';
	@override String get themeColor => 'Theme Color';
	@override String get pin => 'Pin';
	@override String get unpin => 'Unpin';
	@override String get archive => 'Archive';
	@override String get enterWorkspace => 'Enter Workspace';
}

// Path: document
class TranslationsDocumentEn extends TranslationsDocumentZh {
	TranslationsDocumentEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get kNew => 'New';
	@override String get newDocument => 'New Document';
	@override String get importDocument => 'Import Document';
	@override String get documentName => 'Enter document name';
	@override String get empty => 'No documents yet';
	@override String get emptyHint => 'Click the "New" button above to create your first document';
	@override String wordCount({required Object count}) => '${count} words';
	@override String deleteConfirm({required Object name}) => 'Delete "${name}"?';
	@override String get deleteHint => 'This action cannot be undone';
	@override String get folderDeleteHint => 'All contents in the folder will also be deleted';
	@override String importFailed({required Object error}) => 'Import failed: ${error}';
	@override String createFailed({required Object error}) => 'Create failed: ${error}';
}

// Path: settings
class TranslationsSettingsEn extends TranslationsSettingsZh {
	TranslationsSettingsEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Settings';
	@override String get general => 'General';
	@override String get aiModel => 'AI Model';
	@override String get appearance => 'Appearance';
	@override String get shortcuts => 'Shortcuts';
	@override String get importExport => 'Import/Export';
	@override String get language => 'Language';
	@override String get languageDesc => 'Select the language for the app interface';
	@override String get editor => 'Editor';
	@override String get autoSave => 'Auto Save';
	@override String get autoSaveDesc => 'Automatically save document changes';
	@override String get autoSaveInterval => 'Auto Save Interval';
	@override String autoSaveIntervalDesc({required Object seconds}) => 'Auto save every ${seconds} seconds';
	@override String get showWordCount => 'Show Word Count';
	@override String get showWordCountDesc => 'Display word and character count at the bottom of the editor';
	@override String get spellCheck => 'Spell Check';
	@override String get spellCheckDesc => 'Enable spell check feature';
	@override String get aiAssistant => 'AI Assistant';
	@override String get showFloatingButton => 'Show Floating Button';
	@override String get showFloatingButtonDesc => 'Show AI assistant shortcut button at the bottom right';
	@override String get defaultSearchScope => 'Default Search Scope';
	@override String get defaultSearchScopeDesc => 'Default knowledge base search scope when opening AI assistant';
	@override String get currentWorkspace => 'Current Workspace';
	@override String get allWorkspaces => 'All Workspaces';
}

// Path: appearance
class TranslationsAppearanceEn extends TranslationsAppearanceZh {
	TranslationsAppearanceEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get theme => 'Theme';
	@override String get themeMode => 'Theme Mode';
	@override String get themeModeDesc => 'Select the color theme for the app';
	@override String get followSystem => 'Follow System';
	@override String get light => 'Light';
	@override String get dark => 'Dark';
	@override String get font => 'Font';
	@override String get fontFamily => 'Font Family';
	@override String get fontFamilyDesc => 'Select the font for the editor';
	@override String get systemDefault => 'System Default';
	@override String get fontSize => 'Font Size';
	@override String get fontSizeDesc => 'Adjust the default font size of the editor';
	@override String get lineHeight => 'Line Height';
	@override String get lineHeightDesc => 'Adjust the spacing between text lines';
	@override String get preview => 'Preview';
	@override String get previewText => 'This is a preview text to demonstrate the current font settings.\n\nThis is a preview text to demonstrate the current font settings.\n\nYou can adjust the settings above to see the real-time effect.';
}

// Path: welcome
class TranslationsWelcomeEn extends TranslationsWelcomeZh {
	TranslationsWelcomeEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get todayHotspot => 'Today\'s Hotspot';
	@override String get noHotspot => 'No hotspot';
	@override String get loadFailed => 'Load failed';
}

// Path: time
class TranslationsTimeEn extends TranslationsTimeZh {
	TranslationsTimeEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get justNow => 'Just now';
	@override String minutesAgo({required Object count}) => '${count} minutes ago';
	@override String hoursAgo({required Object count}) => '${count} hours ago';
	@override String daysAgo({required Object count}) => '${count} days ago';
}
