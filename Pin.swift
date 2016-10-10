//
//  Pin.swift
//  Virtual Tourist
//
//  Created by Christopher Weaver on 8/18/16.
//  Copyright © 2016 Christopher Weaver. All rights reserved.
//

import Foundation
import CoreData


class Pin: NSManagedObject {

    convenience init(latitude: Double, longitude: Double, context: NSManagedObjectContext) {
        if let ent = NSEntityDescription.entity(forEntityName: "Pin", in:context){
            self.init(entity: ent, insertInto: context)
            self.latitude = latitude as NSNumber?
            self.longitude = longitude as NSNumber?
        } else {
            fatalError("Unable to find Entity Name!")
        }
    }

}
