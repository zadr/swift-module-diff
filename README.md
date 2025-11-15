### swift-module-diff
#### What should this do
Given a pair of Xcode apps (such as Xcode.app and Xcode-beta.app):
1. Scan through known SDKs (iOS, macOS, watchOS, tvOS, visionOS)
2. Compile a list of supported architectures and `swiftinterface` files for each architecture
3. For each `swiftinterface` file, parse it with [SwiftSyntax](https://github.com/apple/swift-syntax)
4. Repeat for the other copy of Xcode
5. Compare the two results, noting what frameworks are introduced, along with modifications to types, and members (additions, deprecations, etc)
6. Output some basic HTML to see all the frameworks with modifications on one page
7. Be able to click into a framework to see all modifications to types, and members (additions, deprecations, etc)

#### Things Left To Do
Swift is a big and evolving language, so it is likely that edge-cases are broken, or lesser-used features are missing. This tool is still under development.

All major Swift language features are now tracked! For a comprehensive list of supported features, see `MISSING_FEATURES.md`.

And there are some other features that could be nice to have, such as:

- [ ] Using a DSL to generate HTML
- [ ] Making HTML output more readable, such as by:
- Selectively hiding attributes, or parameters of attributes (i.e. macOS @availability parameter isn't helpful on iOS API diff)
- [ ] Making HTML interactable, such as by linking to more docs, or adding an option to expand all details with one click
- [ ] Filtering output by platform, architecture, or framework
- [ ] Extending CLI to expose diffing swiftmodule directories outside of Xcode.app bundles

#### But Why?
Having everything that changed one one page can be nice

If more information than base additions / deprecations / removals is needed, official documentation is always available

#### Inspiration
Code Workshop's [`objc-diff`](http://codeworkshop.net/objc-diff/)

#### Notes on development
As a hypothetical, consider adding support for a new `magic` keyword that can appear before `func` declarations in `class` contexts.

Starting with a new `Magic.swiftmodule` containing the following:

```
class C {
    magic func x(y: Int = 1) -> Int { 0 }
}
```

Running with `--single-file` flag set: `swift-module-diff --single-file=/path/to/Magic.swiftmodule` will parse a single file.

From there, breakpoints make for a quick way to the AST. For example, in `FunctionTracker.visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind`,
running `vo node` will produce something that looks like this:

```
(lldb) vo node
(SwiftSyntax.FunctionDeclSyntax) node = FunctionDeclSyntax
├─attributes: AttributeListSyntax
├─modifiers: DeclModifierListSyntax
│ ╰─[0]: DeclModifierSyntax
│   ╰─name: keyword(SwiftSyntax.Keyword.magic)
├─funcKeyword: keyword(SwiftSyntax.Keyword.func)
├─name: identifier("x")
├─signature: FunctionSignatureSyntax
│ ├─parameterClause: FunctionParameterClauseSyntax
│ │ ├─leftParen: leftParen
│ │ ├─parameters: FunctionParameterListSyntax
│ │ │ ╰─[0]: FunctionParameterSyntax
│ │ │   ├─attributes: AttributeListSyntax
│ │ │   ├─modifiers: DeclModifierListSyntax
│ │ │   ├─firstName: identifier("y")
│ │ │   ├─colon: colon
│ │ │   ├─type: IdentifierTypeSyntax
│ │ │   │ ╰─name: identifier("Int")
│ │ │   ╰─defaultValue: InitializerClauseSyntax
│ │ │     ├─equal: equal
│ │ │     ╰─value: IntegerLiteralExprSyntax
│ │ │       ╰─literal: integerLiteral("1")
│ │ ╰─rightParen: rightParen
│ ╰─returnClause: ReturnClauseSyntax
│   ├─arrow: arrow
│   ╰─type: IdentifierTypeSyntax
│     ╰─name: identifier("Int")
╰─body: CodeBlockSyntax
  ├─leftBrace: leftBrace
  ├─statements: CodeBlockItemListSyntax
  │ ╰─[0]: CodeBlockItemSyntax
  │   ╰─item: IntegerLiteralExprSyntax
  │     ╰─literal: integerLiteral("0")
  ╰─rightBrace: rightBrace
```

which shows that `magic` is a declaration modifier.

`swift-module-diff` tracks member types (functions, vars, typealiases, and so on) with the `Member` type, and `Member` includes a `Decorator` enum with results stored in a `decorators` set.

All together, the results will look something like [this](https://github.com/zadr/swift-module-diff/commit/85bf1fb3fdbeb5982900264dac0ba4ed722976fc) commit that added support for tracking `optional` conformances of members within protocols.
