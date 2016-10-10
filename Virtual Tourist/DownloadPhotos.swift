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
    
    let delegate = UIApplication.shared.delegate as! AppDelegate
    
    func flickrURLFromParameters(_ parameters: [String:AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
    
    func displayImageFromFlickr(_ pin: Pin, completionHandlerForPhotos: @escaping (_ results: [[String:AnyObject]]?, _ pagesNumber: Int, _ error: String?) -> Void)  {
        
        let pageChoosen = randomPage((pin.pages as? Int)!)
        
        let methodParameters: [String: String?] = [Constants.FlickrParameterKeys.Method:Constants.FlickrParameterValues.SearchMethod, Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey, Constants.FlickrParameterKeys.BoundingBox: bBoxString((pin.latitude as? Double)!, Long: (pin.longitude as? Double)!), Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL, Constants.FlickrParameterKeys.Page: String(pageChoosen), Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat, Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback]
        
        let request = URLRequest(url: flickrURLFromParameters(methodParameters as [String : AnyObject]))
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            
            func errorFound(_ error: String) {
                print(error)
                completionHandlerForPhotos(nil, 0, error)
            }

            guard (error == nil) else {
                errorFound((error?.localizedDescription)!)
                return
            }
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode , statusCode >= 200 && statusCode <= 299 else {
                errorFound("Status Code was \(response as? HTTPURLResponse)?.statusCode), which in not within the 200 to 299 range")
                return
            }
            guard let data = data else {
                errorFound("no data returned")
                return
            }
            
            var parsedData: AnyObject!
            do {
                parsedData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject!
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
            
          completionHandlerForPhotos(finalPhotoArray, pagesNumber, nil)
            
        }) 
        
        task.resume()
    }
    
    func randomPage(_ pages: Int) -> Int {
        var pageChoosen = Int()
        
        if pages == 0 {
             pageChoosen = 1
        } else {
             pageChoosen = Int(arc4random_uniform(UInt32((pages))))
        }
        return pageChoosen
    }
    
    func randomPhotos(_ photoArray: [[String:AnyObject]]) -> [[String:AnyObject]] {
        
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
    
    func bBoxString(_ Lat: Double, Long: Double) -> String {
        
        let minimumLong =  min(Long + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
        
        let maximumLong =  max(Long - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
        
        let minimumLat =  min(Lat + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
        
        let maximumLat =  max(Lat - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
        
        return "\(maximumLong),\(maximumLat),\(minimumLong),\(minimumLat)"
    }

}
