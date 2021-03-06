//
//  ViewController.swift
//  Project38
//
//  Created by Charles Martin Reed on 8/30/18.
//  Copyright © 2018 Charles Martin Reed. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    //MARK:- Properties
    //think of the NSPersistentContainer as the staging area where you create, read, update or delete data before committing to the SQLite database underpinning Core Data.
    var container: NSPersistentContainer!
    
    //var commits = [Commit]() - no longer necessary since we're using a fetched results controller
    
    //predicate is a filter - specify the criteria you want to match and Core Data will ensure that only matching objects get returned
    //optional because fetch request takes a valid predicate OR a nil, no filter
    var commitPredicate: NSPredicate?
    
    //holds the fetched results controller for commits
    var fetchedResultsController: NSFetchedResultsController<Commit>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Filter", style: .plain, target: self, action: #selector(changeFilter))
        
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
            //allow updates to objects with a bias toward objects in memory when items with same unique constraint in in conflict
            //unique constraint for our Commit data model is the "sha" attribute
            self.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            if let error = error {
                print("Unresolved error \(error)")
            }
        }
        
        //calling our fetch method
        performSelector(inBackground: #selector(fetchCommits), with: nil)
        
        //loading our fetched data
        loadSavedData()
        
        //Xcode code generation in action - the Commit Core Data entity is converted into a Swift class named Commit, dynamically, when we build the app.
        //all of these properties are optional, even though we marked them as non-optional in the attributes editor
        //let commit = Commit()
        //commit.message = "Woo"
        //commit.url = "www.example.com"
        //commit.date = Date()
    }
    
    //MARK:- Table View methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        
        //number of objects corresponds to the rows.
        return sectionInfo.numberOfObjects
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //put the commit message and date into the cell's textLabel and detailTextLabel respectively
        //keeping it simple, we'll use the Date object's description property to convert the info to a human readable string
        let cell = tableView.dequeueReusableCell(withIdentifier: "Commit", for: indexPath)
        
        let commit = fetchedResultsController.object(at: indexPath)
        cell.textLabel?.text = commit.message
        cell.detailTextLabel?.text = "By \(commit.author.name) on \(commit.date.description)"
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //load a detail view from the storyboard, assign it the selected commit and push it onto the navigation stack
        if let vc = storyboard?.instantiateViewController(withIdentifier: "Detail") as? DetailViewController {
            vc.detailItem = fetchedResultsController.object(at: indexPath)
            navigationController?.pushViewController(vc, animated: true)
        }
    
    }
    
    //this method detects changes in our object model using fetched results controller and reacts accordingly
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
        default:
            break
            }
        }
    
    //deleting commits from our app
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            //with fetch results controller, we delete objects directly from the managed object context
            let commit = fetchedResultsController.object(at: indexPath)
            container.viewContext.delete(commit)
            saveContext()
            
            //remove it from the managed object context, the commits array of Commit objects and delete the row form the table view
            //container.viewContext.delete(commit)
            //commits.remove(at: indexPath.row)
            //tableView.deleteRows(at: [indexPath], with: .fade)
            
            //update our managed object context to reflect our changes
            //saveContext()
        }
    }
    
    
    //MARK:- JSON Fetch
    func getNewestCommitDate() -> String {
        let formatter = ISO8601DateFormatter()
        
        let newest = Commit.createFetchRequest()
        let sort = NSSortDescriptor(key: "date", ascending: false)
        newest.sortDescriptors = [sort]
        
        //only grab the first one
        newest.fetchLimit = 1
        
        if let commits = try? container.viewContext.fetch(newest) {
            if commits.count > 0 {
                //return a string of a  date that would be second from the last commit
                return formatter.string(from: commits[0].date.addingTimeInterval(1))
            }
        }
        
        //if no valid date is found, it'll return a date 0 seconds from 1/1/1970 forward, which reproduces the same behavior we had before introducing the date check/change
        return formatter.string(from: Date(timeIntervalSince1970: 0))
    }
    
    @objc func fetchCommits() {
        
        //get only the most recent commits
        //the function returns a date formatted as a ISO-8601 string
        let newestCommitDate = getNewestCommitDate()
        
        //download the URL into a string object
        if let data = try? String(contentsOf: URL(string: "https://api.github.com/repos/apple/swift/commits?per_page=100&since=\(newestCommitDate)")!) {
            
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
                self.loadSavedData()
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
        
        //MARK:- Attaching authors to commits
        var commitAuthor: Author!
        
        //see if author exists
        let authorRequest = Author.createFetchRequest()
        authorRequest.predicate = NSPredicate(format: "name == %@", json["commit"]["committer"]["name"].stringValue)
        
        //we can use try? here because it doesn't really matter if it fails - we have a conditional that executes if nil
        if let authors = try? container.viewContext.fetch(authorRequest) {
            if authors.count > 0 {
                //if this is not nil, then we already have this author
                commitAuthor = authors[0]
            }
        }
        
        if commitAuthor == nil {
            //save the author if we don't find them already
            let author = Author(context: container.viewContext)
            author.name = json["commit"]["committer"]["name"].stringValue
            author.email = json["commit"]["committer"]["email"].stringValue
            commitAuthor = author
        }
        
        //use the author, either saved or new
        commit.author = commitAuthor
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
    
    //MARK:- Retrieving data
    @objc func changeFilter() {
        //we need to create and utilize the predicate BEFORE loading the saved data
        
        let ac = UIAlertController(title: "Filter commits...", message: nil, preferredStyle: .actionSheet)
        
        //CONTAINS[c] means find any messages that contain fix, case-insensitive
        ac.addAction(UIAlertAction(title: "Show only fixes", style: .default, handler: { [unowned self] _ in
            self.commitPredicate = NSPredicate(format: "message CONTAINS[c] 'fix'")
            self.loadSavedData()
        }))
        
        //NOT inverts the search - this will only show items that don't begin with Merge Pull Request in our filtered table view
        ac.addAction(UIAlertAction(title: "Ignore Pull Requests", style: .default, handler: { [unowned self] _ in
            self.commitPredicate = NSPredicate(format: "NOT message BEGINSWITH 'Merge pull request'")
            self.loadSavedData()
        }))
        
        //Core Data can intelligently compare two dates. Also notice the use of Obj-C style format strings.
        ac.addAction(UIAlertAction(title: "Show only recent", style: .default, handler: { [unowned self] _ in
            let twelveHoursAgo = Date().addingTimeInterval(-43200)
            
            //Core Data wants to work with NSDate, not Date, so we actually have to typecast here
            self.commitPredicate = NSPredicate(format: "date > %@", twelveHoursAgo as NSDate)
            self.loadSavedData()
        }))
        
        //author.name in the predicate instructs Core Data to intelligently find the author relation for our commit Class and then look up the name attribute from the matching object
        //Joe Groff is a engineer at Apple, apparently.
        ac.addAction(UIAlertAction(title: "Show only Durian commits", style: .default, handler: { [unowned self] _ in
            self.commitPredicate = NSPredicate(format: "author.name == 'Joe Groff'")
            self.loadSavedData()
        }))
        
        //show all the commits again
        ac.addAction(UIAlertAction(title: "Show all commits", style: .default, handler: { [unowned self] _ in
            self.commitPredicate = nil
            self.loadSavedData()
        }))
        
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(ac, animated: true, completion: nil)
    }
    
    //this works because we have "author.name" set as the sectionNameKeyPath in our fetched results controller constructor
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return fetchedResultsController.sections![section].name
    }
    
    func loadSavedData() {
        //we'll be wrapping this inside of a fetchedResultsController to better manage objects
        if fetchedResultsController == nil {
            
            //create the request using our managed object context's fetch method
            let request = Commit.createFetchRequest()
            
            //sort the request, by date, in descending order
            let sort = NSSortDescriptor(key: "author.name", ascending: false)
            request.sortDescriptors = [sort]
            request.fetchBatchSize = 20
            
            //having fetchedResultsController handle our retrieval and setting up its delegate
            fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: container.viewContext, sectionNameKeyPath: "author.name", cacheName: nil)
            fetchedResultsController.delegate = self
            
        }
        
        //add the predicate for our commit fetch request
        //request.predicate = commitPredicate
        
        do {
            try fetchedResultsController.performFetch()
            tableView.reloadData()
        } catch {
            print("Fetch failed")
        }
    }

    


}

