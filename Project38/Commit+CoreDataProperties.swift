//
//  Commit+CoreDataProperties.swift
//  Project38
//
//  Created by Charles Martin Reed on 8/31/18.
//  Copyright © 2018 Charles Martin Reed. All rights reserved.
//
//

import Foundation
import CoreData


extension Commit {

    @nonobjc public class func createfetchRequest() -> NSFetchRequest<Commit> {
        return NSFetchRequest<Commit>(entityName: "Commit")
    }

    //@NSManaged means that our properties are being monitored for changes
    @NSManaged public var date: Date
    @NSManaged public var message: String
    @NSManaged public var sha: String
    @NSManaged public var url: String

}
