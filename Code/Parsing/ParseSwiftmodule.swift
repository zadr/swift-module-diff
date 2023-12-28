import Foundation
import SwiftParser
import SwiftSyntax

struct ParseSwiftmodule {
	let path: String

	init(path: String) {
		self.path = path
	}

	func run() -> Framework {
		autoreleasepool {
			let tracker = SwiftmoduleTracker()
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
	var framework: Framework
	var nestingCount = 0

	public init() {
		framework = Framework()
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: ImportDeclSyntax) -> SyntaxVisitorContinueKind {
		let name = ParseAnyType<DependencyTracker>(node: node).run()
		framework.dependencies.append(name)
		return super.visit(node)
	}

	// MARK: - Containers

	override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
		nestingCount += 1
		let p = ParseAnyType<ProtocolTracker>(node: node).run()
		framework.namedTypes.append(p)
		return super.visit(node)
	}

	override func visitPost(_ node: ProtocolDeclSyntax) {
		nestingCount -= 1
		super.visitPost(node)
	}

	override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
		nestingCount += 1
		let e = ParseAnyType<EnumTracker>(node: node).run()
		framework.namedTypes.append(e)
		return super.visit(node)
	}

	override func visitPost(_ node: EnumDeclSyntax) {
		nestingCount -= 1
		super.visitPost(node)
	}

	override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
		nestingCount += 1
		let a = ParseAnyType<ActorTracker>(node: node).run()
		framework.namedTypes.append(a)
		return super.visit(node)
	}

	override func visitPost(_ node: ActorDeclSyntax) {
		nestingCount -= 1
		super.visitPost(node)
	}

	override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
		nestingCount += 1
		let s = ParseAnyType<StructTracker>(node: node).run()
		framework.namedTypes.append(s)
		return super.visit(node)
	}

	override func visitPost(_ node: StructDeclSyntax) {
		nestingCount -= 1
		super.visitPost(node)
	}

	override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
		nestingCount += 1
		let c = ParseAnyType<ClassTracker>(node: node).run()
		framework.namedTypes.append(c)
		return super.visit(node)
	}

	override func visitPost(_ node: ClassDeclSyntax) {
		nestingCount -= 1
		super.visitPost(node)
	}

	override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
		nestingCount += 1
		let e = ParseAnyType<ExtensionTracker>(node: node).run()
		framework.namedTypes.append(e)
		return super.visit(node)
	}

	override func visitPost(_ node: ExtensionDeclSyntax) {
		nestingCount -= 1
		super.visitPost(node)
	}

	// MARK: - Content

	override func visit(_ node: MacroDeclSyntax) -> SyntaxVisitorContinueKind {
		let m = ParseAnyType<MacroTracker>(node: node).run()
		framework.namedTypes.append(m)
		return super.visit(node)
	}

	override func visit(_ node: OperatorDeclSyntax) -> SyntaxVisitorContinueKind {
		let o = ParseAnyType<OperatorTracker>(node: node).run()
		framework.namedTypes.append(o)
		return super.visit(node)
	}

	override func visit(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
		let t = ParseAnyType<TypeAliasTracker>(node: node).run()
		if nestingCount == 0 {
			framework.members.append(t)
		}
		return super.visit(node)
	}

	override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
		let v = ParseAnyTypeCollection<VariableTracker>(node: node).run()
		if nestingCount == 0 {
			framework.members += v
		}
		return super.visit(node)
	}

	override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
		let f = ParseAnyType<FunctionTracker>(node: node).run()
		if nestingCount == 0 {
			framework.members.append(f)
		}
		return super.visit(node)
	}
}
