//
//  DownloadPhotos.swift
//  Virtual Tourist
//
//  Created by Christopher Weaver on 8/18/16.
//  Copyright © 2016 Christopher Weaver. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class DownloadPhotos {
    
    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    func flickrURLFromParameters(parameters: [String:AnyObject]) -> NSURL {
        
        let components = NSURLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [NSURLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = NSURLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.URL!
    }
    
    func displayImageFromFlickr(pin: Pin, completionHandlerForPhotos: (results: [[String:AnyObject]]?, pagesNumber: Int, error: String?) -> Void)  {
        
        let pageChoosen = randomPage((pin.pages as? Int)!)
        
        let methodParameters: [String: String!] = [Constants.FlickrParameterKeys.Method:Constants.FlickrParameterValues.SearchMethod, Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey, Constants.FlickrParameterKeys.BoundingBox: bBoxString((pin.latitude as? Double)!, Long: (pin.longitude as? Double)!), Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL, Constants.FlickrParameterKeys.Page: String(pageChoosen), Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat, Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback]
        
        let request = NSURLRequest(URL: flickrURLFromParameters(methodParameters))
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) in
            
            func errorFound(error: String) {
                print(error)
                completionHandlerForPhotos(results: nil, pagesNumber: 0, error: error)
            }

            guard (error == nil) else {
                errorFound((error?.localizedDescription)!)
                return
            }
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                errorFound("Status Code was \(response as? NSHTTPURLResponse)?.statusCode), which in not within the 200 to 299 range")
                return
            }
            guard let data = data else {
                errorFound("no data returned")
                return
            }
            
            var parsedData: AnyObject!
            do {
                parsedData = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                errorFound("Unable to successfully parse data")
            }
            
            guard let photosDictionary = parsedData["photos"] as? [String:AnyObject] else {
                return
            }
            
            guard let pagesNumber = photosDictionary["pages"] as? Int else {
                return
            }
            
            guard let photoArray = photosDictionary["photo"] as? [[String:AnyObject]] else {
                return
            }
            
          let finalPhotoArray = self.randomPhotos(photoArray)
            
          completionHandlerForPhotos(results: finalPhotoArray, pagesNumber: pagesNumber, error: nil)
            
        }
        
        task.resume()
    }
    
    func randomPage(pages: Int) -> Int {
        var pageChoosen = Int()
        
        if pages == 0 {
             pageChoosen = 1
        } else {
             pageChoosen = Int(arc4random_uniform(UInt32((pages))))
        }
        return pageChoosen
    }
    
    func randomPhotos(photoArray: [[String:AnyObject]]) -> [[String:AnyObject]] {
        
        let number = Int(arc4random_uniform(UInt32(photoArray.count - 21)))
        
        var photoNum = 0
        
        var photoLimit = 0
        
        var finalPhotoArray = [[String:AnyObject]]()
        
        for i in photoArray {
            if photoNum >= number {
                if photoLimit < 21 {
                    finalPhotoArray.append(i)
                    photoLimit += 1
                }
            }
            photoNum += 1
        }
        return finalPhotoArray
    }
    
    func bBoxString(Lat: Double, Long: Double) -> String {
        
        let minimumLong =  min(Long + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
        
        let maximumLong =  max(Long - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
        
        let minimumLat =  min(Lat + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
        
        let maximumLat =  max(Lat - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
        
        return "\(maximumLong),\(maximumLat),\(minimumLong),\(minimumLat)"
    }

}
