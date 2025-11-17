import Foundation
import SwiftParser
import SwiftSyntax

struct ParseSwiftmodule {
	let path: String
	let typePrefixesToRemove: [String]

	init(path: String, typePrefixesToRemove: [String]) {
		self.path = path
		self.typePrefixesToRemove = typePrefixesToRemove
	}

	func run() -> Framework {
		autoreleasepool {
			let tracker = SwiftmoduleTracker(typePrefixesToRemove: typePrefixesToRemove)
			tracker.framework.name = (
				(
					(
						path as NSString
					).deletingLastPathComponent as NSString
				).lastPathComponent as NSString
			).deletingPathExtension

			let contents = try! String(contentsOf: URL(fileURLWithPath: path))
			tracker.walk(Parser.parse(source: contents))
			return tracker.framework
		}
	}
}

// MARK: -

private class SwiftmoduleTracker: SyntaxVisitor {
	var nestingCount = 0
	let typePrefixesToRemove: [String]

	var framework = Framework()
	var typeStack: [NamedType] = [] // Track parent types for nesting

	public init(typePrefixesToRemove: [String]) {
		self.typePrefixesToRemove = typePrefixesToRemove
		super.init(viewMode: .sourceAccurate)
	}

	private func popTypeStack() {
		let completed = typeStack.removeLast()
		if let lastIndex = typeStack.indices.last {
			// Copy completed nested type back to parent
			var parent = typeStack[lastIndex]
			if let idx = parent.nestedTypes.firstIndex(where: { $0.name == completed.name && $0.kind == completed.kind }) {
				parent.nestedTypes[idx] = completed
			}
			typeStack[lastIndex] = parent
		} else {
			// Copy completed top-level type back to framework
			if let idx = framework.namedTypes.firstIndex(where: { $0.name == completed.name && $0.kind == completed.kind }) {
				framework.namedTypes[idx] = completed
			}
		}
	}

	override func visit(_ node: ImportDeclSyntax) -> SyntaxVisitorContinueKind {
		let name = ParseAnyType<DependencyTracker>(node: node).run()
		framework.dependencies.append(name)
		return super.visit(node)
	}

	// MARK: - Containers

	override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
		nestingCount += 1
		let p = ParseAnyType<ProtocolTracker>(node: node)
			.run()
			.dropAnySubstring(in: typePrefixesToRemove)

		if let lastIndex = typeStack.indices.last {
			var parent = typeStack[lastIndex]
			parent.nestedTypes.append(p)
			typeStack[lastIndex] = parent
		} else {
			framework.namedTypes.append(p)
		}
		typeStack.append(p)
		return super.visit(node)
	}

	override func visitPost(_ node: ProtocolDeclSyntax) {
		popTypeStack()
		nestingCount -= 1
		super.visitPost(node)
	}

	override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
		nestingCount += 1
		let e = ParseAnyType<EnumTracker>(node: node)
			.run()
			.dropAnySubstring(in: typePrefixesToRemove)

		if let lastIndex = typeStack.indices.last {
			var parent = typeStack[lastIndex]
			parent.nestedTypes.append(e)
			typeStack[lastIndex] = parent
		} else {
			framework.namedTypes.append(e)
		}
		typeStack.append(e)
		return super.visit(node)
	}

	override func visitPost(_ node: EnumDeclSyntax) {
		popTypeStack()
		nestingCount -= 1
		super.visitPost(node)
	}

	override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
		nestingCount += 1
		let a = ParseAnyType<ActorTracker>(node: node)
			.run()
			.dropAnySubstring(in: typePrefixesToRemove)

		if let lastIndex = typeStack.indices.last {
			var parent = typeStack[lastIndex]
			parent.nestedTypes.append(a)
			typeStack[lastIndex] = parent
		} else {
			framework.namedTypes.append(a)
		}
		typeStack.append(a)
		return super.visit(node)
	}

	override func visitPost(_ node: ActorDeclSyntax) {
		popTypeStack()
		nestingCount -= 1
		super.visitPost(node)
	}

	override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
		nestingCount += 1
		let s = ParseAnyType<StructTracker>(node: node)
			.run()
			.dropAnySubstring(in: typePrefixesToRemove)

		if let lastIndex = typeStack.indices.last {
			var parent = typeStack[lastIndex]
			parent.nestedTypes.append(s)
			typeStack[lastIndex] = parent
		} else {
			framework.namedTypes.append(s)
		}
		typeStack.append(s)
		return super.visit(node)
	}

	override func visitPost(_ node: StructDeclSyntax) {
		popTypeStack()
		nestingCount -= 1
		super.visitPost(node)
	}

	override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
		nestingCount += 1
		let c = ParseAnyType<ClassTracker>(node: node)
			.run()
			.dropAnySubstring(in: typePrefixesToRemove)

		if let lastIndex = typeStack.indices.last {
			var parent = typeStack[lastIndex]
			parent.nestedTypes.append(c)
			typeStack[lastIndex] = parent
		} else {
			framework.namedTypes.append(c)
		}
		typeStack.append(c)
		return super.visit(node)
	}

	override func visitPost(_ node: ClassDeclSyntax) {
		popTypeStack()
		nestingCount -= 1
		super.visitPost(node)
	}

	override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
		nestingCount += 1
		let e = ParseAnyType<ExtensionTracker>(node: node)
			.run()
			.dropAnySubstring(in: typePrefixesToRemove)

		if let lastIndex = typeStack.indices.last {
			var parent = typeStack[lastIndex]
			parent.nestedTypes.append(e)
			typeStack[lastIndex] = parent
		} else {
			framework.namedTypes.append(e)
		}
		typeStack.append(e)
		return super.visit(node)
	}

	override func visitPost(_ node: ExtensionDeclSyntax) {
		popTypeStack()
		nestingCount -= 1
		super.visitPost(node)
	}

	// MARK: - Content

	override func visit(_ node: MacroDeclSyntax) -> SyntaxVisitorContinueKind {
		let m = ParseAnyType<MacroTracker>(node: node).run()
		if let lastIndex = typeStack.indices.last {
			var parent = typeStack[lastIndex]
			parent.nestedTypes.append(m)
			typeStack[lastIndex] = parent
		} else {
			framework.namedTypes.append(m)
		}
		return super.visit(node)
	}

	override func visit(_ node: OperatorDeclSyntax) -> SyntaxVisitorContinueKind {
		var o = ParseAnyType<OperatorTracker>(node: node).run()
		o.name = o.name.dropAnySubstring(in: typePrefixesToRemove)
		if let lastIndex = typeStack.indices.last {
			var parent = typeStack[lastIndex]
			parent.nestedTypes.append(o)
			typeStack[lastIndex] = parent
		} else {
			framework.namedTypes.append(o)
		}
		return super.visit(node)
	}

	override func visit(_ node: PrecedenceGroupDeclSyntax) -> SyntaxVisitorContinueKind {
		let p = ParseAnyType<PrecedenceGroupTracker>(node: node).run()
		framework.precedenceGroups.append(p)
		return super.visit(node)
	}

	override func visit(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
		let t = ParseAnyType<TypeAliasTracker>(node: node)
			.run()
			.dropAnySubstring(in: typePrefixesToRemove)
		if nestingCount == 0 {
			framework.members.append(t)
		}
		return super.visit(node)
	}

	override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
		let v = ParseAnyTypeCollection<VariableTracker>(node: node)
			.run()
			.dropAnySubstring(in: typePrefixesToRemove)
		if nestingCount == 0 {
			framework.members += v
		}
		return super.visit(node)
	}

	override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
		let f = ParseAnyType<FunctionTracker>(node: node)
			.run()
			.dropAnySubstring(in: typePrefixesToRemove)
		if nestingCount == 0 {
			framework.members.append(f)
		}
		return super.visit(node)
	}
}
