// Noze.io: miniirc

// MARK: - String Helpers

#if swift(>=3.0) // #swift3-fd

extension Collection where Iterator.Element : Equatable {
  
  func index(of v: Self.Iterator.Element, from: Self.Index) -> Index? {
    var idx = from
    
    while idx != endIndex {
      if self[idx] == v {
        return idx
      }
      idx = self.index(after: idx)
    }
    
    return nil
  }
}

extension String {
  
  func split(_ c: Character) -> [ String ] {
    return self.characters.split(separator: c).map { String($0) }
  }
  
}

#endif // Swift >=3
