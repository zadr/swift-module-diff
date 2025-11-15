import Foundation
import SwiftSyntax

class DefaultValueTracker: SyntaxVisitor, AnyTypeParser {
	var value = ""

	required init() {
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: InitializerClauseSyntax) -> SyntaxVisitorContinueKind {
		// Get the string representation of the default value expression
		value = node.value.trimmedDescription
		return .skipChildren
	}
}
