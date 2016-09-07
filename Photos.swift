//
//  Photos.swift
//  Virtual Tourist
//
//  Created by Christopher Weaver on 8/18/16.
//  Copyright © 2016 Christopher Weaver. All rights reserved.
//

import Foundation
import CoreData


class Photos: NSManagedObject {

    convenience init(image:NSData?, context: NSManagedObjectContext) {
        if let ent = NSEntityDescription.entityForName("Photos", inManagedObjectContext: context){
            self.init(entity: ent, insertIntoManagedObjectContext: context)
            self.image = image
        } else {
            fatalError("Unable to find Entity Name!")
        }
    }

}
