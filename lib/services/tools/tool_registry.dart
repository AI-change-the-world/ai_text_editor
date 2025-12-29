/// Tool registry for managing and accessing tools
///
/// This file defines the ToolRegistry class which serves as a central
/// repository for all available tools in the AI Agent system.
library;

import 'tool_interface.dart';

/// A registry for managing tools available to the AI Agent system.
///
/// The [ToolRegistry] provides a centralized way to:
/// - Register tools for use by the Agent
/// - Look up tools by name
/// - Get tool schemas for LLM function calling
/// - Generate tool descriptions for prompts
///
/// Example usage:
/// ```dart
/// final registry = ToolRegistry();
/// registry.register(FullTextSearchTool());
/// registry.register(VectorSearchTool());
///
/// // Get a tool by name
/// final tool = registry.getTool('full_text_search');
///
/// // Get all tool schemas for LLM
/// final schemas = registry.getToolSchemas();
/// ```
class ToolRegistry {
  /// Internal map of tool name to tool instance.
  final Map<String, ITool> _tools = {};

  /// Creates a new empty [ToolRegistry].
  ToolRegistry();

  /// Creates a [ToolRegistry] with the given tools pre-registered.
  factory ToolRegistry.withTools(List<ITool> tools) {
    final registry = ToolRegistry();
    for (final tool in tools) {
      registry.register(tool);
    }
    return registry;
  }

  /// Registers a tool in the registry.
  ///
  /// If a tool with the same name already exists, it will be replaced.
  ///
  /// [tool] - The tool to register.
  void register(ITool tool) {
    _tools[tool.name] = tool;
  }

  /// Unregisters a tool from the registry.
  ///
  /// [name] - The name of the tool to unregister.
  ///
  /// Returns true if the tool was found and removed, false otherwise.
  bool unregister(String name) {
    return _tools.remove(name) != null;
  }

  /// Gets a tool by name.
  ///
  /// [name] - The name of the tool to retrieve.
  ///
  /// Returns the tool if found, null otherwise.
  ITool? getTool(String name) => _tools[name];

  /// Checks if a tool with the given name is registered.
  ///
  /// [name] - The name of the tool to check.
  bool hasTool(String name) => _tools.containsKey(name);

  /// Gets all registered tool names.
  List<String> get toolNames => _tools.keys.toList();

  /// Gets all registered tools.
  List<ITool> get tools => _tools.values.toList();

  /// Gets the number of registered tools.
  int get count => _tools.length;

  /// Checks if the registry is empty.
  bool get isEmpty => _tools.isEmpty;

  /// Checks if the registry is not empty.
  bool get isNotEmpty => _tools.isNotEmpty;

  /// Gets tool schemas in the format expected by LLM function calling.
  ///
  /// Returns a list of tool definitions that can be passed to an LLM
  /// for function calling capabilities.
  ///
  /// Example output:
  /// ```json
  /// [
  ///   {
  ///     "type": "function",
  ///     "function": {
  ///       "name": "full_text_search",
  ///       "description": "Search the knowledge base...",
  ///       "parameters": { ... }
  ///     }
  ///   }
  /// ]
  /// ```
  List<Map<String, dynamic>> getToolSchemas() {
    return _tools.values
        .map((tool) => {
              'type': 'function',
              'function': {
                'name': tool.name,
                'description': tool.description,
                'parameters': tool.parametersSchema,
              },
            })
        .toList();
  }

  /// Gets tool schemas for specific tools only.
  ///
  /// [toolNames] - List of tool names to include.
  ///
  /// Returns schemas only for the specified tools that exist in the registry.
  List<Map<String, dynamic>> getToolSchemasFor(List<String> toolNames) {
    return toolNames.where((name) => _tools.containsKey(name)).map((name) {
      final tool = _tools[name]!;
      return <String, dynamic>{
        'type': 'function',
        'function': {
          'name': tool.name,
          'description': tool.description,
          'parameters': tool.parametersSchema,
        },
      };
    }).toList();
  }

  /// Gets a formatted string of tool descriptions.
  ///
  /// This is useful for including in system prompts to help the LLM
  /// understand what tools are available.
  ///
  /// Example output:
  /// ```
  /// - full_text_search: Search the knowledge base using keywords...
  /// - vector_search: Perform semantic search based on meaning...
  /// ```
  String getToolDescriptions() {
    return _tools.values
        .map((t) => '- ${t.name}: ${t.description.trim()}')
        .join('\n');
  }

  /// Gets tool descriptions for specific tools only.
  ///
  /// [toolNames] - List of tool names to include.
  String getToolDescriptionsFor(List<String> toolNames) {
    return toolNames.where((name) => _tools.containsKey(name)).map((name) {
      final tool = _tools[name]!;
      return '- ${tool.name}: ${tool.description.trim()}';
    }).join('\n');
  }

  /// Clears all registered tools.
  void clear() {
    _tools.clear();
  }

  @override
  String toString() {
    return 'ToolRegistry(tools: ${_tools.keys.join(', ')})';
  }
}
