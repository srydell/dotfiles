; Symbols already written with a namespace are exact lookup candidates.
(qualified_identifier) @symbol.qualified

; These two forms make unqualified names visible. Lua applies their lexical
; scope and source-order rules before resolving a candidate.
(using_declaration
  (identifier) @using.namespace)

(using_declaration
  (qualified_identifier) @using.symbol)

; Capture the whole definition because tree-sitter-cpp exposes the alias name
; as a field but represents the target as its second named child. Keeping the
; pairing intact avoids correlating independent captures by source position.
(namespace_alias_definition) @namespace.alias

; Type names and direct function calls are the two unqualified contexts that
; can be resolved with useful confidence from syntax alone. Member calls are
; deliberately excluded because their functions are field_expressions.
(type_identifier) @symbol.unqualified_type

(call_expression
  function: (identifier) @symbol.unqualified_function)
