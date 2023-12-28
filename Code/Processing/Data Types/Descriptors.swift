import Foundation

protocol Attributed {
	var attributes: Set<Attribute> { get }
}

protocol Decorated {
	associatedtype Decorator: Hashable, Equatable

	var decorators: Set<Decorator> { get }
}

protocol Named {
	var name: String { get }
}

protocol Displayable {
	var developerFacingValue: String { get }
}
