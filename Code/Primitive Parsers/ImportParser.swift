import Foundation
import SwiftSyntax

class ImportTracker: SyntaxVisitor, PrimitiveParser {
	typealias Value = String

	var value = Value()

	required init() {
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: ImportPathComponentSyntax) -> SyntaxVisitorContinueKind {
		value = value.isEmpty ? node.name.text : node.name.text + "." + value
		return super.visit(node)
	}
}
