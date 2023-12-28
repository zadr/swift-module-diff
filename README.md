### swift-module-diff
#### What should this do
Given a pair of Xcode apps (such as Xcode.app and Xcode-beta.app):
1. Scan through known SDKs (iOS, macOS, watchOS, tvOS)
2. Compile a list of supported architectures and `swiftinterface` files for each architecture
3. For each `swiftinterface` file, parse it with [SwiftSyntax](https://github.com/apple/swift-syntax)
4. Repeat for the other copy of Xcode
5. Compare the two results, noting what frameworks are introduced, along with modifications to types, and members (additions, deprecations, etc)
6. Output some basic HTML to see all the frameworks with modifications on one page
7. Be able to click into a framework to see all modifications to types, and members (additions, deprecations, etc)

#### Things Left To Do
This command-line tool integrates SwiftSyntax and can handle the basics, such as listing and tracking…:
- `class`es, `struct`s, `enum`s
- member types (`func`s, `var`s, `let`s)
- non-generic parameter lists (including `inout`)
- member decorations (`async`, `throws`, `static`, etc)
- availability attributes

Swift is a big and evolving language, so it is likely that edge-cases are missing. Feel free to open a PR or file an issue.

#### But Why?
Having everything that changed one one page can be nice

If more information than base additions / deprecations / removals is needed, official documentation is always available

#### Inspiration
Code Workshop's [`objc-diff`](http://codeworkshop.net/objc-diff/)
