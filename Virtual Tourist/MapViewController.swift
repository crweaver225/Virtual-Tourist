//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Christopher Weaver on 8/17/16.
//  Copyright © 2016 Christopher Weaver. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate {
    
    var fetchedResultsController: NSFetchedResultsController!
    
    let fr = NSFetchRequest(entityName: "Pin")
    let sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true),
    NSSortDescriptor(key: "longitude", ascending: false)]
    
    
    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var deleteAllowed: Bool = false
    
    var appHadStarted: Bool = false
    
    var annotations = [MKPointAnnotation]()
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var deleteTextView: UITextView!
    @IBOutlet weak var doneEditingButton: UIButton!
    
    @IBAction func doneEditingPushed(sender: AnyObject) {
        deleteAllowed = false
        doneEditingButton.hidden = true
        editButton.enabled = true
        
        deleteTextView.frame.origin.y = (view.frame.height - deleteTextView.frame.height)
        
        UIView.beginAnimations(nil, context: nil)
        deleteTextView.frame.origin.y = view.frame.height
        mapView.frame.origin.y = 0
        UIView.commitAnimations()
        
        appHadStarted = true
    }
    
    @IBAction func editButtonPushed(sender: AnyObject) {
        deleteTextView.frame.origin.y = view.frame.height
        deleteTextView.hidden = false
        doneEditingButton.hidden = false
        editButton.enabled = false
        
        UIView.beginAnimations(nil, context: nil)
        deleteTextView.frame.origin.y -= deleteTextView.frame.height
        mapView.frame.origin.y -= deleteTextView.frame.height
        UIView.commitAnimations()
        
        deleteAllowed = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        doneEditingButton.hidden = true
        deleteTextView.hidden = true
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action:"handleTap:")
        gestureRecognizer.minimumPressDuration = 1.0
        gestureRecognizer.allowableMovement = 1
        gestureRecognizer.delegate = self
        mapView.addGestureRecognizer(gestureRecognizer)
        
        UIView.setAnimationDuration(0.5)
        UIView.setAnimationDelegate(self)
        UIView.setAnimationBeginsFromCurrentState(true)
        
        
        fr.sortDescriptors = sortDescriptors
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: (delegate.stack?.context)!, sectionNameKeyPath: nil, cacheName: nil)
        
        performFectch()
        
        for i in fetchedResultsController.fetchedObjects! {
            let managed = i as? NSManagedObject
            let managed2 = managed as? Pin
            let lat = CLLocationDegrees((managed2?.latitude)!)
            let long = CLLocationDegrees((managed2?.longitude)!)
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotations.append(annotation)
            generateMap()
        }
    }
    
    func generateMap() {
        mapView.addAnnotations(annotations)
    }
    
    func handleTap(gestureReconizer: UILongPressGestureRecognizer) {
        if (gestureReconizer.state == UIGestureRecognizerState.Began) {
            if !deleteAllowed {
                let location = gestureReconizer.locationInView(mapView)
                
                let coordinate = mapView.convertPoint(location,toCoordinateFromView: mapView)
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                
                annotations.append(annotation)
                
                generateMap()
                
                let newPin = Pin(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude, context: (self.fetchedResultsController.managedObjectContext))
                
                delegate.stack?.save()
            }
        }
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
    
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {

        fr.sortDescriptors = sortDescriptors
        
        let pred1 = NSPredicate(format: "latitude = %@", argumentArray: [(view.annotation?.coordinate.latitude)!])
        
        let pred2 = NSPredicate(format: "longitude = %@", argumentArray: [(view.annotation?.coordinate.longitude)!])
        
        let andPredicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [pred1, pred2])
        
        fr.predicate = andPredicate
        
        performFectch()
        
        let pinResults = fetchedResultsController?.fetchedObjects
        
        let manipulatedPinResults = pinResults![0] as? NSManagedObject
        
        let selectedPin = manipulatedPinResults as? Pin
        
            if deleteAllowed {
                var indexCounter = 0
                for items in annotations {
                    if selectedPin?.latitude == items.coordinate.latitude && selectedPin?.longitude == items.coordinate.longitude  {
                        mapView.removeAnnotations(annotations)
                        annotations.removeAtIndex(indexCounter)
                        fetchedResultsController.managedObjectContext.deleteObject(selectedPin!)
                        delegate.stack?.save()
                        generateMap()
                        return
                    }
                    indexCounter += 1
                }
            } else {
                let CollectionVC = self.storyboard!.instantiateViewControllerWithIdentifier("CollectionViewController") as! CollectionViewController
                CollectionVC.pin = selectedPin
                
                self.navigationController!.pushViewController(CollectionVC, animated: true)
                
                mapView.deselectAnnotation(view.annotation, animated: false)
                
                deleteTextView.hidden = true
            }
        }
    
    func performFectch() {
        do{
            try fetchedResultsController.performFetch()
        }catch {
            print("Error while trying to perform a search")
        }
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        
        if deleteAllowed {
            deleteTextView.frame.origin.y = (view.frame.height - deleteTextView.frame.height)
            mapView.frame.origin.y = (0 - deleteTextView.frame.height)
        } else {
            deleteTextView.frame.origin.y = view.frame.height
            mapView.frame.origin.y = 0
        }
    }

}
