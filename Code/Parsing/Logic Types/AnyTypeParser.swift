import Foundation
import SwiftParser
import SwiftSyntax

protocol AnyTypeParser {
	associatedtype AnyType

	var value: AnyType { get }

	init()
}

extension AnyTypeParser where Self: SyntaxVisitor {}

struct ParseAnyType<T: SyntaxVisitor & AnyTypeParser> {
	let node: any SyntaxProtocol

	init(node: any SyntaxProtocol) {
		self.node = node
	}

	func run() -> T.AnyType {
		autoreleasepool {
			let tracker = T()
			tracker.walk(node)

			return tracker.value
		}
	}
}
