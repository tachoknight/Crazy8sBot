
import Foundation

#if os(Linux)
	extension MutableCollection where Index == Int {
		/// Shuffle the elements of `self` in-place.
		mutating func shuffle() {
			// empty and single-element collections don't shuffle
			if count < 2 { return }

			for i in startIndex ..< endIndex - 1 {
				let j = Int(random() % (endIndex - i)) + i
				guard i != j else { continue }
				swap(&self[i], &self[j])
			}
		}
	}
#else
	extension MutableCollection where Index == Int {
		/// Shuffle the elements of `self` in-place.
		mutating func shuffle() {
			// empty and single-element collections don't shuffle
			if count < 2 { return }

			for i in startIndex ..< endIndex - 1 {
				let j = Int(arc4random_uniform(UInt32(endIndex - i))) + i
				guard i != j else { continue }
				swap(&self[i], &self[j])
			}
		}
	}
#endif

// For sorting a dictionary that contains [Card:Weight] (See player.swift)
#if os(Linux)
	extension Dictionary {
		func sortedKeys(isOrderedBefore: (Key, Key) -> Bool) -> [Key] {
			var myArray = Array(self.keys)
			myArray.sort(by: isOrderedBefore)
			return myArray
		}

		// Slower because of a lot of lookups, but probably takes less memory (this is equivalent to Pascals answer in an generic extension)
		func sortedKeysByValue(isOrderedBefore: (Value, Value) -> Bool) -> [Key] {
			let mySortedKeys = sortedKeys {
				isOrderedBefore(self[$0]!, self[$1]!)
			}

			return mySortedKeys
		}
    }
#else
	extension Dictionary {
		func sortedKeys(_ isOrderedBefore: (Key, Key) -> Bool) -> [Key] {
			return Array(self.keys).sorted(by: isOrderedBefore)
		}

		// Slower because of a lot of lookups, but probably takes less memory (this is equivalent to Pascals answer in an generic extension)
		func sortedKeysByValue(_ isOrderedBefore: (Value, Value) -> Bool) -> [Key] {
			return sortedKeys {
				isOrderedBefore(self[$0]!, self[$1]!)
			}
		}

		// Faster because of no lookups, may take more memory because of duplicating contents
		func keysSortedByValue(_ isOrderedBefore: (Value, Value) -> Bool) -> [Key] {
			return Array(self)
				.sorted() {
					let (_, lv) = $0
					let (_, rv) = $1
					return isOrderedBefore(lv, rv)
			}
				.map {
					let (k, _) = $0
					return k
			}
		}
	}
#endif
