//
//  ViewController.swift
//  Project38
//
//  Created by Charles Martin Reed on 8/30/18.
//  Copyright © 2018 Charles Martin Reed. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UITableViewController {

    //MARK:- Properties
    //think of the NSPersistentContainer as the staging area where you create, read, update or delete data before committing to the SQLite database underpinning Core Data.
    var container: NSPersistentContainer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //To set up the basic Core Data system:
        //1. Load ourdata model from the application bundle and create a NSManagedObjectModel object from it.
        //2. Create a NSPersistentStoreCoordinator object - this is used to read from and write to disk
        //3. Set up a URL pointing to the DB on the disk where our actual saved objects will live. The name of the SQLite DB will be Project38.sqlite.
        //4. Load that DB into NSPersistentStoreCoordinator so it knows where we want to save. It will be created if it doesn't exist.
        //5. Create an NSManagedObjectContext and point it at the coordinator.
        
        //param is the name of the Core Data model we created
        container = NSPersistentContainer(name: "Project38")
        
        //load the saved database, create it if it doesn't already exist
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error {
                print("Unresolved error \(error)")
            }
        }
    }
    
    func saveContext() {
        //we'll only save if the context, derived from the managed object context where data is modified in RAM, has uncommitted changes
        if container.viewContext.hasChanges {
            do {
                try container.viewContext.save()
            } catch {
                print("An error occurred while saving: \(error)")
            }
        }
    }

    


}

