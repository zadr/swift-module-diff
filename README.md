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
Swift is a big and evolving language, so it is likely that edge-cases or lesser-used features are missing. Some known gaps are:

- [ ] subscript support
- [ ] operator precedencegroup support
- [ ] Dictionary literal support in type names
- [ ] Array literal support in type names
- [ ] `some`/`any` keyword in return types
- [ ] default values in function parameters
- [ ] `unowned(safe)` and `unowned(unsafe)` on member storage

#### But Why?
Having everything that changed one one page can be nice

If more information than base additions / deprecations / removals is needed, official documentation is always available

#### Inspiration
Code Workshop's [`objc-diff`](http://codeworkshop.net/objc-diff/)
