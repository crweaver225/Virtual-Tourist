//
//  CollectionViewController.swift
//  Virtual Tourist
//
//  Created by Christopher Weaver on 8/17/16.
//  Copyright © 2016 Christopher Weaver. All rights reserved.
//

import CoreData
import UIKit
import MapKit




class CollectionViewController: CoreDataCollectionView, MKMapViewDelegate {
    
    @IBOutlet weak var collectionViewMap: MKMapView!
    @IBOutlet weak var getNewCollectionButton: UIButton!
    
    var annotations = [MKPointAnnotation]()
    var pin = Pin!()
    
    @IBAction func getNewCollection(sender: AnyObject) {
        getNewCollectionButton.enabled = false
        let photoSet = self.pin.photo! as NSSet
            for item in photoSet{
                self.fetchedResultsController?.managedObjectContext.deleteObject(item as! NSManagedObject)
                }
        backgroundDownload(){ (success, error) in
            performUIUpdatesOnMain{
            self.getNewCollectionButton.enabled = true
            }
            if success == false {
                print("error occured")
                performUIUpdatesOnMain{
                    self.displayAlert(error!)
                }
            }

            self.delegate.stack?.save()
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("FlickrImage", forIndexPath: indexPath) as! CollectionViewCell
        cell.activityIndicator.hidden = false
        cell.activityIndicator.startAnimating()
        cell.collectionImage.image = nil
        
        let row = fetchedResultsController!.objectAtIndexPath(indexPath) as? Photos
        
        
        if row?.image == nil  {
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
                
                self.fetchedResultsController?.managedObjectContext.performBlock{
    
                let finalImageconvert = NSURL(string:(row?.imageURL)!)
                
                let finalImageDisplay = NSData(contentsOfURL: finalImageconvert!)
                
                row!.image = finalImageDisplay
                
                self.delegate.stack?.save()
                    
                }
            }
        }
        
        if row?.image != nil {
            cell.collectionImage?.image = UIImage(data:(row?.image)!)
            cell.activityIndicator.stopAnimating()
            cell.activityIndicator.hidden = true
        }
        
        return cell
    }
    
    func backgroundDownload(completionHandler: (success: Bool, error: String?) -> Void) {
        
        let flickrDownloader = DownloadPhotos()
        
        flickrDownloader.displayImageFromFlickr(self.pin) { (results, pagesNumber, error) in
            
            func errorProduced(error: String) {
                completionHandler(success: false, error: error)
            }
            
            guard (error == nil) else {
                errorProduced(error!)
                return
            }
            
            for i in results!{
                guard let finalImage = i["url_m"] as? String else {
                    return
                }
                
                self.fetchedResultsController?.managedObjectContext.performBlock{
                    let newPhoto = Photos(image: nil, context: (self.fetchedResultsController!.managedObjectContext))
                    newPhoto.imageURL = finalImage
                    newPhoto.pin = self.pin
                    self.pin.pages = pagesNumber
                }
            }
            completionHandler(success: true, error: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.getNewCollectionButton.enabled = false
        
        generateMap()
        
        let fr = NSFetchRequest(entityName: "Photos")
        fr.sortDescriptors = [NSSortDescriptor(key: "pin", ascending: true)]
        let pred = NSPredicate(format: "pin = %@", argumentArray: [self.pin])
        fr.predicate = pred
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: (delegate.stack?.context)!, sectionNameKeyPath: nil, cacheName: nil)

        if pin.photo?.count < 1 {

            self.backgroundDownload(){ (success, error) in
                performUIUpdatesOnMain{
                self.getNewCollectionButton.enabled = true
                }
                if success == false {
                    performUIUpdatesOnMain{
                    self.displayAlert(error!)
                    }
                }
                
                self.delegate.stack?.save()
               
            }
        } else {
            self.getNewCollectionButton.enabled = true
        }
    }
    
    func displayAlert(message: String) {
        let downloadAlert = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        downloadAlert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: { (UIAlertAction) in
            
        }))
        self.presentViewController(downloadAlert, animated: true, completion: nil)
    }
    
    func generateMap() {
        let lat = CLLocationDegrees(self.pin.latitude!)
        
        let long = CLLocationDegrees(self.pin.longitude!)
        
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotations.append(annotation)
        
        collectionViewMap.addAnnotations(annotations)
        
        let latDelta:CLLocationDegrees = 2.50
        
        let lonDelta:CLLocationDegrees = 2.50
        
        let span: MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lonDelta)
        
        let region:MKCoordinateRegion = MKCoordinateRegionMake(coordinate, span)
        
        collectionViewMap.setRegion(region, animated: true)
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pins"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.pinColor = .Red
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
}
