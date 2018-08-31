//
//  Commit+CoreDataClass.swift
//  Project38
//
//  Created by Charles Martin Reed on 8/31/18.
//  Copyright © 2018 Charles Martin Reed. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Commit)
public class Commit: NSManagedObject {
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
        //this gets called EACH TIME a Commit object is pulled in by loadSavedData method
        //this is because a new entity object is created each time. This obvious scales poorly.
        //This is where NSFetchedResultsController comes in since it takes over the NSFetchedResults role to load data, using its own storage and keeps the UI in sync with changes to the data by controlling the way objects are inserted and deleted.
        print("Init called!")
    }
}
