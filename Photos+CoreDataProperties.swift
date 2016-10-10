//
//  Photos+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Christopher Weaver on 8/18/16.
//  Copyright © 2016 Christopher Weaver. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Photos {

    @NSManaged var image: Data?
    @NSManaged var imageURL: String?
    @NSManaged var pin: Pin?

}
