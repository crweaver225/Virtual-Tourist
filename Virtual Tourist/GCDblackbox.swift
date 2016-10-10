//
//  GCDblackbox.swift
//  Virtual Tourist
//
//  Created by Christopher Weaver on 8/22/16.
//  Copyright © 2016 Christopher Weaver. All rights reserved.
//

import Foundation


func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
    DispatchQueue.main.async {
        updates()
    }
}
