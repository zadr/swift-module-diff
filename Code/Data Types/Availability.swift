import Foundation

enum Availability: Codable, Equatable, Hashable {
	case platform(name: String, version: String)
	case unavailablePlatform(name: String)
	case any
}
