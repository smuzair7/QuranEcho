import 'dart:io';
import 'dart:convert';

void main() async {
  // Determine the Flutter SDK path
  final result = await Process.run('flutter', ['--version']);
  if (result.exitCode != 0) {
    print('Error: Flutter SDK not found. Make sure Flutter is installed and in your PATH.');
    return;
  }
  
  print('Creating project configuration directories...');
  
  // Create .idea directory if it doesn't exist
  final ideaDir = Directory('.idea');
  if (!await ideaDir.exists()) {
    await ideaDir.create();
  }
  
  // Create libraries directory if it doesn't exist
  final librariesDir = Directory('.idea/libraries');
  if (!await librariesDir.exists()) {
    await librariesDir.create(recursive: true);
  }
  
  // Get Flutter SDK path
  final processResult = await Process.run('flutter', ['config', '--machine']);
  if (processResult.exitCode != 0) {
    print('Error getting Flutter config');
    return;
  }
  
  final Map<String, dynamic> config = jsonDecode(processResult.stdout);
  final flutterSdkPath = config['flutterRoot'] as String;
  final dartSdkPath = '$flutterSdkPath/bin/cache/dart-sdk';
  
  print('Flutter SDK detected at: $flutterSdkPath');
  print('Dart SDK should be at: $dartSdkPath');
  
  // Create Dart SDK configuration file
  final dartSdkXml = '''
<component name="libraryTable">
  <library name="Dart SDK">
    <CLASSES>
      <root url="file://$dartSdkPath/lib/async" />
      <root url="file://$dartSdkPath/lib/cli" />
      <root url="file://$dartSdkPath/lib/collection" />
      <root url="file://$dartSdkPath/lib/convert" />
      <root url="file://$dartSdkPath/lib/core" />
      <root url="file://$dartSdkPath/lib/developer" />
      <root url="file://$dartSdkPath/lib/ffi" />
      <root url="file://$dartSdkPath/lib/html" />
      <root url="file://$dartSdkPath/lib/io" />
      <root url="file://$dartSdkPath/lib/isolate" />
      <root url="file://$dartSdkPath/lib/js" />
      <root url="file://$dartSdkPath/lib/js_interop" />
      <root url="file://$dartSdkPath/lib/js_util" />
      <root url="file://$dartSdkPath/lib/math" />
      <root url="file://$dartSdkPath/lib/mirrors" />
      <root url="file://$dartSdkPath/lib/typed_data" />
    </CLASSES>
    <JAVADOC />
    <SOURCES />
  </library>
</component>
''';

  await File('.idea/libraries/Dart_SDK.xml').writeAsString(dartSdkXml);
  
  // Create workspace configuration
  final workspaceXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<project version="4">
  <component name="FileEditorManager">
    <leaf>
      <file leaf-file-name="main.dart" pinned="false" current="true" current-in-tab="true">
        <entry file="file://\$PROJECT_DIR\$/lib/main.dart">
          <provider selected="true" editor-type-id="text-editor">
            <state line="0" column="0" selection-start="0" selection-end="0" vertical-scroll-proportion="0.0">
              <folding />
            </state>
          </provider>
        </entry>
      </file>
    </leaf>
  </component>
  <component name="ProjectView">
    <navigator currentView="ProjectPane" proportions="" version="1" />
    <panes>
      <pane id="ProjectPane">
        <subPane>
          <PATH>
            <PATH_ELEMENT>
              <option name="myItemId" value="quran_echo" />
              <option name="myItemType" value="com.intellij.ide.projectView.impl.nodes.ProjectViewProjectNode" />
            </PATH_ELEMENT>
          </PATH>
          <PATH>
            <PATH_ELEMENT>
              <option name="myItemId" value="quran_echo" />
              <option name="myItemType" value="com.intellij.ide.projectView.impl.nodes.ProjectViewProjectNode" />
            </PATH_ELEMENT>
            <PATH_ELEMENT>
              <option name="myItemId" value="quran_echo" />
              <option name="myItemType" value="com.intellij.ide.projectView.impl.nodes.PsiDirectoryNode" />
            </PATH_ELEMENT>
          </PATH>
        </subPane>
      </pane>
    </panes>
  </component>
  <component name="FlutterView" splitter-proportion="0.75" />
</project>
''';

  await File('.idea/workspace.xml').writeAsString(workspaceXml);
  
  print('SDK configuration complete. Try reopening the project in Android Studio.');
}
