//
//  Module.swift
//  NozeIO
//
//  Created by Helge Hess on 26/06/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import xsys
import core


// MARK: - Cows

public class NozeCows : NozeModule {
}
public let module = NozeCows()


// MARK: - Vaca

private let globalVaca = uniqueRandomArray(allCows)
public func vaca() -> String {
  return globalVaca()
}
