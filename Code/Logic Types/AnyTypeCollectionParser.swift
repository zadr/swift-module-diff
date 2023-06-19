import Foundation
import SwiftParser
import SwiftSyntax

protocol AnyTypeCollectionParser {
	associatedtype AnyType

	typealias AnyTypeCollection = [AnyType]

	var collection: AnyTypeCollection { get }

	init()
}

extension AnyTypeParser where Self: SyntaxVisitor {}

struct ParseAnyTypeCollection<T: SyntaxVisitor & AnyTypeCollectionParser> {
	let node: any SyntaxProtocol

	init(node: any SyntaxProtocol) {
		self.node = node
	}

	func run() -> T.AnyTypeCollection {
		autoreleasepool {
			let tracker = T()
			tracker.walk(node)

			return tracker.collection
		}
	}
}
