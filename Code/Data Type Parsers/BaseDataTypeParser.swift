import Foundation
import SwiftParser
import SwiftSyntax

protocol DataTypeParser {
	static var kind: DataType.Kind { get }
	var dataType: DataType { get }
	init()
}

extension DataTypeParser where Self: SyntaxVisitor {}

struct ParseDataType<T: SyntaxVisitor & DataTypeParser> {
	let node: any SyntaxProtocol

	init(node: any SyntaxProtocol) {
		self.node = node
	}

	func run() -> DataType {
		autoreleasepool {
			let tracker = T()
			tracker.walk(node)

			var dataType = tracker.dataType
			dataType.kind = T.kind

			return dataType
		}
	}
}
