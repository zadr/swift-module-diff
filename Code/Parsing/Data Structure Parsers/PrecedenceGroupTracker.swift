import Foundation
import SwiftSyntax

class PrecedenceGroupTracker: SyntaxVisitor, AnyTypeParser {
	var value = PrecedenceGroup()

	required init() {
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: PrecedenceGroupDeclSyntax) -> SyntaxVisitorContinueKind {
		value.name = node.name.text

		return super.visit(node)
	}

	override func visit(_ node: PrecedenceGroupAssociativitySyntax) -> SyntaxVisitorContinueKind {
		switch node.value.tokenKind {
		case .keyword(.left):
			value.associativity = .left
		case .keyword(.right):
			value.associativity = .right
		default: break
		}
		return super.visit(node)
	}

	override func visit(_ node: PrecedenceGroupRelationSyntax) -> SyntaxVisitorContinueKind {
		let precedences = node.precedenceGroups.map { $0.name.text }

		switch node.higherThanOrLowerThanLabel.tokenKind {
		case .keyword(.higherThan):
			value.higherThan += precedences
		case .keyword(.lowerThan):
			value.lowerThan += precedences
		default: break
		}

		return super.visit(node)
	}

	override func visit(_ node: PrecedenceGroupAssignmentSyntax) -> SyntaxVisitorContinueKind {
		if case .keyword(.true) = node.value.tokenKind {
			value.assignment = true
		}
		return super.visit(node)
	}
}
