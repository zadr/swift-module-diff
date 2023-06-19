import Foundation
import SwiftParser
import SwiftSyntax

protocol PrimitiveParser {
	associatedtype Value
	var value: Value { get }
	init()
}

extension PrimitiveParser where Self: SyntaxVisitor {}

struct ParsePrimitive<T: SyntaxVisitor & PrimitiveParser> {
	let node: any SyntaxProtocol

	init(node: any SyntaxProtocol) {
		self.node = node
	}

	func run() -> T.Value {
		autoreleasepool {
			let tracker = T()
			tracker.walk(node)

			return tracker.value
		}
	}
}
