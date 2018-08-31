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
        
        //calling our fetch method
        performSelector(inBackground: #selector(fetchCommits), with: nil)
        
        //Xcode code generation in action - the Commit Core Data entity is converted into a Swift class named Commit, dynamically, when we build the app.
        //all of these properties are optional, even though we marked them as non-optional in the attributes editor
        //let commit = Commit()
        //commit.message = "Woo"
        //commit.url = "www.example.com"
        //commit.date = Date()
    }
    
    //MARK:- JSON Fetch
    @objc func fetchCommits() {
        
        //download the URL into a string object
        if let data = try? String(contentsOf: URL(string: "https://api.github.com/repos/apple/swift/commits?per_page=100")!) {
            
            let jsonCommits = JSON(parseJSON: data)
            
            //pass it to SwiftyJSON to convert to an array of objects
            let jsonCommitArray = jsonCommits.arrayValue
            
            print("Received \(jsonCommitArray.count) new commits.")
            
            //handling the important updates on the main thread
            DispatchQueue.main.async { [unowned self] in
                for jsonCommit in jsonCommitArray {
                    
                    //create a new Commit object inside of the managed object context given to us by NSPersistentContainer
                    let commit = Commit(context: self.container.viewContext)
                    self.configure(commit: commit, usingJSON: jsonCommit)
                }
                
                self.saveContext()
            }
        }
    }
    
    func configure(commit: Commit, usingJSON json: JSON) {
        //SwiftyJSON ensures a safe value gets returned even if the data is missing or broken, so if there's nothing in commit message, from example, we'll get an empty string.
        commit.sha = json["sha"].stringValue
        commit.message = json["commit"]["message"].stringValue
        commit.url = json["html_url"].stringValue
        
        //if we can't convert the date from ISO because the date isn't in that format, then we creae a new date
        let formatter = ISO8601DateFormatter()
        commit.date = formatter.date(from: json["commit"]["committer"]["date"].stringValue) ?? Date()
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

