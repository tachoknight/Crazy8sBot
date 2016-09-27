
import Foundation

enum Suit: Int {
	case hearts = 100
	case spades = 200
	case diamonds = 300
	case clubs = 400
	case noSuit = 0

	func simpleDescription() -> String {
		switch self {
		case .spades:
			return "spades"
		case .hearts:
			return "hearts"
		case .diamonds:
			return "diamonds"
		case .clubs:
			return "clubs"
		case .noSuit:
			return "no suit"
		}
	}

	func color() -> String {
		switch self {
		case .spades:
			return "black"
		case .clubs:
			return "black"
		case .diamonds:
			return "red"
		case .hearts:
			return "red"
		case .noSuit:
			return "none"
		}
	}

	func symbol() -> String {
		switch self {
		case .spades:
			return "♠"
		case .clubs:
			return "♣"
		case .diamonds:
			return "♦"
		case .hearts:
			return "♥"
		case .noSuit:
			return "NS"
		}
	}
}

enum Rank: Int {
	case ace = 1
	case two
	case three
	case four
	case five
	case six
	case seven
	case eight
	case nine
	case ten
	case jack
	case queen
	case king

	func simpleDescription() -> String {
		switch self {
		case .ace:
			return "ace"
		case .jack:
			return "jack"
		case .queen:
			return "queen"
		case .king:
			return "king"
		default:
			return String(self.rawValue)
		}
	}

	func symbol() -> String {
		switch self {
		case .ace:
			return "A"
		case .jack:
			return "J"
		case .queen:
			return "Q"
		case .king:
			return "K"
		default:
			return String(self.rawValue)
		}
	}
}

//
// The card struct/class that is what we're playing
// with
//
struct Card: Hashable, CustomStringConvertible {
	var rank: Rank
	var suit: Suit
	// For storing in dictionaries
	var hashValue: Int {
		return rank.rawValue + suit.rawValue
	}
    
	func simpleDescription() -> String {
		return "The \(rank.simpleDescription()) of \(suit.simpleDescription())"
	}

	// From CustomStringConvertable protocol
	var description: String {
		return "\(suit.symbol())\(rank.symbol())"
	}
}

// For the Card class' equatable protocol
func == (lhs: Card, rhs: Card) -> Bool {
	return lhs.hashValue == rhs.hashValue
}

//
// Function for creating a deck of cards
//
func createDeck() -> [Card] {
	var n = 1
	var deck = [Card]()
	while let rank = Rank(rawValue: n) {
		var m = 100
		while let suit = Suit(rawValue: m) {
			deck.append(Card(rank: rank, suit: suit))
			m += 100
		}
		n += 1
	}
	return deck
}
