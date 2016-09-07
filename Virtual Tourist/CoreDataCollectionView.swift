//
//  CoreDataCollectionView.swift
//  Virtual Tourist
//
//  Created by Christopher Weaver on 8/18/16.
//  Copyright © 2016 Christopher Weaver. All rights reserved.
//

import UIKit
import CoreData


class CoreDataCollectionView: UIViewController, UICollectionViewDelegate {
    
    @IBOutlet weak var CollectionView: UICollectionView!
    
    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var selectedIndexes = [NSIndexPath]()
    
    var insertedIndexPaths = [NSIndexPath]()
    
    var deletedIndexPaths = [NSIndexPath]()
    
    var updatedIndexPaths = [NSIndexPath]()
    
    var fetchedResultsController : NSFetchedResultsController?{
        didSet{
            self.fetchedResultsController?.delegate = self
            self.executeSearch()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func executeSearch(){
        if let fc = fetchedResultsController{
            do{
                try fc.performFetch()
            }catch {
                print("Error while trying to perform a search")
            }
        }
    }
}

extension CoreDataCollectionView{
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        
        if let count = self.fetchedResultsController{
           return (count.sections?.count)!
        } else {
           return 0
       }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    
        if let sectionInfo = self.fetchedResultsController!.sections {
            return sectionInfo[section].numberOfObjects
        } else {
            return 0
        }
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let numberOfCell: CGFloat = 3   //you need to give a type as CGFloat
        let cellWidth = UIScreen.mainScreen().bounds.size.width / numberOfCell
        return CGSizeMake(cellWidth, cellWidth)
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath:NSIndexPath) {
        
        if let fc = self.fetchedResultsController {
            fc.managedObjectContext.deleteObject((fetchedResultsController?.objectAtIndexPath(indexPath))! as! NSManagedObject)
            delegate.stack?.save()
        }
    }
}

extension CoreDataCollectionView: NSFetchedResultsControllerDelegate{
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        
        self.insertedIndexPaths.removeAll()
        self.deletedIndexPaths.removeAll()
        self.updatedIndexPaths.removeAll()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type {
        case .Insert:
            self.insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            self.deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            self.updatedIndexPaths.append(indexPath!)
            break
        default:
            return
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        self.CollectionView.performBatchUpdates({ () -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.CollectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.CollectionView.deleteItemsAtIndexPaths([indexPath])
            }
 
            for indexPath in self.updatedIndexPaths {
                self.CollectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
    }
}

