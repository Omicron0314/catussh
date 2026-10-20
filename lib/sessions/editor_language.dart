// Which language a remote file is in: EditorLanguage of the Swift app, with
// the same names, extensions and shebang rules. Highlighting is re_highlight
// (highlight.js grammars) instead of tree-sitter.

import 'package:re_highlight/languages/bash.dart';
import 'package:re_highlight/languages/c.dart';
import 'package:re_highlight/languages/cpp.dart';
import 'package:re_highlight/languages/css.dart';
import 'package:re_highlight/languages/go.dart';
import 'package:re_highlight/languages/ini.dart';
import 'package:re_highlight/languages/java.dart';
import 'package:re_highlight/languages/javascript.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/languages/lua.dart';
import 'package:re_highlight/languages/markdown.dart';
import 'package:re_highlight/languages/perl.dart';
import 'package:re_highlight/languages/php.dart';
import 'package:re_highlight/languages/python.dart';
import 'package:re_highlight/languages/ruby.dart';
import 'package:re_highlight/languages/rust.dart';
import 'package:re_highlight/languages/sql.dart';
import 'package:re_highlight/languages/swift.dart';
import 'package:re_highlight/languages/typescript.dart';
import 'package:re_highlight/languages/xml.dart';
import 'package:re_highlight/languages/yaml.dart';
import 'package:re_highlight/re_highlight.dart';

enum EditorLanguage {
  plain('Plain Text'),
  bash('Shell'),
  c('C'),
  cpp('C++'),
  css('CSS'),
  go('Go'),
  html('HTML'),
  java('Java'),
  javaScript('JavaScript'),
  json('JSON'),
  lua('Lua'),
  markdown('Markdown'),
  perl('Perl'),
  php('PHP'),
  python('Python'),
  ruby('Ruby'),
  rust('Rust'),
  sql('SQL'),
  swift('Swift'),
  toml('TOML'),
  typeScript('TypeScript'),
  yaml('YAML');

  const EditorLanguage(this.title);
  final String title;

  Mode? get mode => switch (this) {
        plain => null,
        bash => langBash,
        c => langC,
        cpp => langCpp,
        css => langCss,
        go => langGo,
        html => langXml,
        java => langJava,
        javaScript => langJavascript,
        json => langJson,
        lua => langLua,
        markdown => langMarkdown,
        perl => langPerl,
        php => langPhp,
        python => langPython,
        ruby => langRuby,
        rust => langRust,
        sql => langSql,
        swift => langSwift,
        toml => langIni,
        typeScript => langTypescript,
        yaml => langYaml,
      };

  static const _byExtension = {
    'sh': bash, 'bash': bash, 'zsh': bash, 'ksh': bash, 'env': bash,
    'c': c, 'h': c,
    'cc': cpp, 'cpp': cpp, 'cxx': cpp, 'hpp': cpp, 'hh': cpp,
    'css': css, 'scss': css,
    'go': go,
    'html': html, 'htm': html, 'xml': html, 'svg': html, 'plist': html,
    'java': java, 'kt': java,
    'js': javaScript, 'mjs': javaScript, 'cjs': javaScript, 'jsx': javaScript,
    'json': json, 'jsonc': json, 'json5': json,
    'lua': lua,
    'md': markdown, 'markdown': markdown,
    'pl': perl, 'pm': perl,
    'php': php,
    'py': python, 'pyw': python,
    'rb': ruby,
    'rs': rust,
    'sql': sql,
    'swift': swift,
    'toml': toml,
    'ts': typeScript, 'tsx': typeScript,
    'yml': yaml, 'yaml': yaml,
  };

  static const _byName = {
    '.bashrc': bash, '.bash_profile': bash, '.bash_logout': bash, '.profile': bash,
    '.zshrc': bash, '.zprofile': bash, '.zshenv': bash, '.env': bash,
    'Gemfile': ruby, 'Rakefile': ruby, 'Cargo.lock': toml, 'Pipfile': toml,
    'docker-compose.yml': yaml, 'docker-compose.yaml': yaml,
  };

  static EditorLanguage detect(String fileName, [String? firstLine]) {
    final named = _byName[fileName];
    if (named != null) return named;
    final dot = fileName.lastIndexOf('.');
    if (dot > 0 && dot < fileName.length - 1) {
      final language = _byExtension[fileName.substring(dot + 1).toLowerCase()];
      if (language != null) return language;
    }
    if (firstLine != null && firstLine.startsWith('#!')) {
      final line = firstLine.toLowerCase();
      if (line.contains('python')) return python;
      if (line.contains('node')) return javaScript;
      if (line.contains('ruby')) return ruby;
      if (line.contains('perl')) return perl;
      if (line.contains('php')) return php;
      if (line.contains('lua')) return lua;
      if (line.contains('sh')) return bash;
    }
    return plain;
  }
}
