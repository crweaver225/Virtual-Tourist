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
    
    let delegate = UIApplication.shared.delegate as! AppDelegate
    
    var selectedIndexes = [IndexPath]()
    
    var insertedIndexPaths = [IndexPath]()
    
    var deletedIndexPaths = [IndexPath]()
    
    var updatedIndexPaths = [IndexPath]()
    
    var fetchedResultsController : NSFetchedResultsController<Photos>?{
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
    
    func numberOfSectionsInCollectionView(_ collectionView: UICollectionView) -> Int {
        
        if let count = self.fetchedResultsController{
           return (count.sections?.count)!
        } else {
           return 0
       }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    
        if let sectionInfo = self.fetchedResultsController!.sections {
            return sectionInfo[section].numberOfObjects
        } else {
            return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        
        let numberOfCell: CGFloat = 3   //you need to give a type as CGFloat
        let cellWidth = UIScreen.main.bounds.size.width / numberOfCell
        return CGSize(width: cellWidth, height: cellWidth)
    }

    @objc(collectionView:didSelectItemAtIndexPath:) func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath:IndexPath) {
        
        if let fc = self.fetchedResultsController {
            fc.managedObjectContext.delete((fetchedResultsController?.object(at: indexPath))! as! NSManagedObject)
            delegate.stack?.save()
        }
    }
}

extension CoreDataCollectionView: NSFetchedResultsControllerDelegate{
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        self.insertedIndexPaths.removeAll()
        self.deletedIndexPaths.removeAll()
        self.updatedIndexPaths.removeAll()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            self.insertedIndexPaths.append(newIndexPath!)
            break
        case .delete:
            self.deletedIndexPaths.append(indexPath!)
            break
        case .update:
            self.updatedIndexPaths.append(indexPath!)
            break
        default:
            return
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        self.CollectionView.performBatchUpdates({ () -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.CollectionView.insertItems(at: [indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.CollectionView.deleteItems(at: [indexPath])
            }
 
            for indexPath in self.updatedIndexPaths {
                self.CollectionView.reloadItems(at: [indexPath])
            }
            
            }, completion: nil)
    }
}

