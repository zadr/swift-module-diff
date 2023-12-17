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
			let contents = try! String(contentsOf: URL(fileURLWithPath: path))
			tracker.walk(Parser.parse(source: contents))
			return tracker.framework
		}
	}
}

// MARK: -

private class SwiftmoduleTracker: SyntaxVisitor {
	var framework: Framework

	public init() {
		self.framework = Framework()
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: ImportDeclSyntax) -> SyntaxVisitorContinueKind {
		let name = ParseAnyType<DependencyTracker>(node: node).run()
		framework.dependencies.append(name)
		return super.visit(node)
	}

	// MARK: - Containers

	override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
		let p = ParseAnyType<ProtocolTracker>(node: node).run()
		framework.namedTypes.append(p)
		return super.visit(node)
	}

	override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
		let e = ParseAnyType<EnumTracker>(node: node).run()
		framework.namedTypes.append(e)
		return super.visit(node)
	}

	override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
		let a = ParseAnyType<ActorTracker>(node: node).run()
		framework.namedTypes.append(a)
		return super.visit(node)
	}

	override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
		let s = ParseAnyType<StructTracker>(node: node).run()
		framework.namedTypes.append(s)
		return super.visit(node)
	}

	override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
		let c = ParseAnyType<ClassTracker>(node: node).run()
		framework.namedTypes.append(c)
		return super.visit(node)
	}

	override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
		let e = ParseAnyType<ExtensionTracker>(node: node).run()
		framework.namedTypes.append(e)
		return super.visit(node)
	}

	// MARK: - Content

	override func visit(_ node: OperatorDeclSyntax) -> SyntaxVisitorContinueKind {
		let o = ParseAnyType<OperatorTracker>(node: node).run()
		framework.members.append(o)
		return super.visit(node)
	}

	override func visit(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
		let t = ParseAnyType<TypeAliasTracker>(node: node).run()
		framework.members.append(t)
		return super.visit(node)
	}

	override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
		let v = ParseAnyTypeCollection<VariableTracker>(node: node).run()
		framework.members += v
		return super.visit(node)
	}

	override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
		let f = ParseAnyType<FunctionTracker>(node: node).run()
		framework.members.append(f)
		return super.visit(node)
	}
}
