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

	override func visit(_ node: ImportPathSyntax) -> SyntaxVisitorContinueKind {
		let name = ParsePrimitive<ImportTracker>(node: node).run()
		framework.dependencies.append(name)
		return super.visit(node)
	}

	// MARK: - Containers

	override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
		let p = ParseDataType<ProtocolTracker>(node: node).run()
		framework.dataTypes.append(p)
		return super.visit(node)
	}

	override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
		let e = ParseDataType<EnumTracker>(node: node).run()
		framework.dataTypes.append(e)
		return super.visit(node)
	}

	override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
		let s = ParseDataType<StructTracker>(node: node).run()
		framework.dataTypes.append(s)
		return super.visit(node)
	}

	override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
		let c = ParseDataType<ClassTracker>(node: node).run()
		framework.dataTypes.append(c)
		return super.visit(node)
	}

	override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
		let e = ParseDataType<ExtensionTracker>(node: node).run()
		framework.dataTypes.append(e)
		return super.visit(node)
	}

	// MARK: - Content

	override func visit(_ node: OperatorDeclSyntax) -> SyntaxVisitorContinueKind {
		let o = ParseMember<OperatorTracker>(node: node).run()
		framework.members.append(o)
		return super.visit(node)
	}

	override func visit(_ node: TypealiasDeclSyntax) -> SyntaxVisitorContinueKind {
		let t = ParseMember<TypealiasTracker>(node: node).run()
		framework.members.append(t)
		return super.visit(node)
	}

	override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
		let v = ParseMember<VariableTracker>(node: node).run()
		framework.members.append(v)
		return super.visit(node)
	}

	override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
		let f = ParseMember<FunctionTracker>(node: node).run()
		framework.members.append(f)
		return super.visit(node)
	}
}