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


fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

class CollectionViewController: CoreDataCollectionView, MKMapViewDelegate {
    
    @IBOutlet weak var collectionViewMap: MKMapView!
    @IBOutlet weak var getNewCollectionButton: UIButton!
    
    var annotations = [MKPointAnnotation]()
    var pin : Pin!
    
    
    @IBAction func getNewCollection(_ sender: AnyObject) {
        getNewCollectionButton.isEnabled = false
        let photoSet = (self.pin.photo!) as NSSet
            for item in photoSet{
                self.fetchedResultsController?.managedObjectContext.delete(item as! NSManagedObject)
                }
        backgroundDownload(){ (success, error) in
            performUIUpdatesOnMain{
            self.getNewCollectionButton.isEnabled = true
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
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAtIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FlickrImage", for: indexPath) as! CollectionViewCell
        cell.activityIndicator.isHidden = false
        cell.activityIndicator.startAnimating()
        cell.collectionImage.image = nil
        
        let row = fetchedResultsController!.object(at: indexPath) as? Photos
        
        
        if row?.image == nil  {
            DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
                
                self.fetchedResultsController?.managedObjectContext.perform{
                    
                let finalImageconvert = URL(string:(row?.imageURL)!)
                
                let finalImageDisplay = try? Data(contentsOf: finalImageconvert!)
                
                row!.image = finalImageDisplay
                
                self.delegate.stack?.save()
                    
                }
            }
        }
        
        if row?.image != nil {
            cell.collectionImage?.image = UIImage(data:(row?.image)!)
            cell.activityIndicator.stopAnimating()
            cell.activityIndicator.isHidden = true
        }
        
        return cell
    }
    
    func backgroundDownload(_ completionHandler: @escaping (_ success: Bool, _ error: String?) -> Void) {
        
        let flickrDownloader = DownloadPhotos()
        
        flickrDownloader.displayImageFromFlickr(self.pin) { (results, pagesNumber, error) in
            
            func errorProduced(_ error: String) {
                completionHandler(false, error)
            }
            
            guard (error == nil) else {
                errorProduced(error!)
                return
            }
            
            for i in results!{
                guard let finalImage = i["url_m"] as? String else {
                    return
                }
                
                self.fetchedResultsController?.managedObjectContext.perform{
                    let newPhoto = Photos(image: nil, context: (self.fetchedResultsController!.managedObjectContext))
                    newPhoto.imageURL = finalImage
                    newPhoto.pin = self.pin
                    self.pin.pages = pagesNumber as NSNumber?
                }
            }
            completionHandler(true, nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.getNewCollectionButton.isEnabled = false
        
        generateMap()
        
        let fr = NSFetchRequest<Photos>(entityName: "Photos")
        fr.sortDescriptors = [NSSortDescriptor(key: "pin", ascending: true)]
        let pred = NSPredicate(format: "pin = %@", argumentArray: [self.pin])
        fr.predicate = pred
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: (delegate.stack?.context)!, sectionNameKeyPath: nil, cacheName: nil)

        if pin.photo?.count < 1 {

            self.backgroundDownload(){ (success, error) in
                performUIUpdatesOnMain{
                self.getNewCollectionButton.isEnabled = true
                }
                if success == false {
                    performUIUpdatesOnMain{
                    self.displayAlert(error!)
                    }
                }
                
                self.delegate.stack?.save()
               
            }
        } else {
            self.getNewCollectionButton.isEnabled = true
        }
    }
    
    func displayAlert(_ message: String) {
        let downloadAlert = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.alert)
        downloadAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (UIAlertAction) in
            
        }))
        self.present(downloadAlert, animated: true, completion: nil)
    }
    
    func generateMap() {
        let lat = CLLocationDegrees((self.pin.latitude!))
        
        let long = CLLocationDegrees((self.pin.longitude!))
        
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
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pins"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.pinColor = .red
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
}
