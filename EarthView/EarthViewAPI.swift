//
//  EarthViewAPI.swift
//  EarthView
//
//  Created by Jesse Friedman on 2/10/17.
//  Copyright © 2017 Jesse Friedman. All rights reserved.
//

import Foundation
import Alamofire

class EarthViewAPI {
    var delegate: EarthViewAPIDelegate?
    
    func requestImageData(imageId: Int) {
        let url = "https://www.gstatic.com/prettyearth/assets/data/\(imageId).json"
        Alamofire.request(url).responseJSON { response in
            if let json = response.result.value as? [String: Any?] {
                var imageData = [String: Any]();
                
                if let geocode = json["geocode"] as? [String: String] {
                    if let country = geocode["country"] {
                        imageData["country"] = country
                    } else {
                        imageData["country"] = ""
                    }
                    
                    if let locality = geocode["locality"] {
                        imageData["location"] = locality
                    } else if let administrative_area_level_1 = geocode["administrative_area_level_1"] {
                        imageData["location"] = administrative_area_level_1
                    } else if let administrative_area_level_2 = geocode["administrative_area_level_2"] {
                        imageData["location"] = administrative_area_level_2
                    } else {
                        imageData["location"] = ""
                    }
                } else {
                    imageData["country"] = ""
                    imageData["location"] = ""
                }
                
                if let attribution = json["attribution"] as? String {
                    let date = Date()
                    let calendar = Calendar.current
                    let year = calendar.component(.year, from: date)
                    
                    imageData["attribution"] = attribution.replacingOccurrences(of: "©\\s?\\d{4}", with: "© \(year)", options: [.regularExpression, .caseInsensitive]).decodeHtml()
                } else {
                    imageData["attribution"] = ""
                }
                
                if
                    let imageDataUri = json["dataUri"] as? String,
                    let data = NSURL(string: imageDataUri)?.base64DecodedData,
                    let uiImage = UIImage(data: data)
                {
                    imageData["image"] = uiImage
                } else {
                    imageData["attribution"] = nil
                }
                
                self.delegate?.handleImageData(imageData)
            }
        }
        
    }
}

protocol EarthViewAPIDelegate {
    func handleImageData(_ data: [String: Any])
}

// from https://gist.github.com/mattbischoff/c194015fdd492c62a400
extension NSURL {
    
    /// `true` if the receiver is a Data URI. See https://en.wikipedia.org/wiki/Data_URI_scheme.
    var dataURI: Bool {
        return scheme == "data"
    }
    
    /// Extracts the base 64 data string from the receiver if it is a Data URI. Otherwise or if there is no data, returns `nil`.
    var base64EncodedDataString: String? {
        guard dataURI else {
            return nil
        }
        guard let absString = absoluteString else {
            return nil
        }
        
        let components = absString.components(separatedBy: ";base64,")
        
        return components.last
    }
    
    /// Extracts the data from the receiver if it is a Data URI. Otherwise or if there is no data, returns `nil`.
    var base64DecodedData: Data? {
        guard let string = base64EncodedDataString else { return nil }
        
        // Ignore whitespace because "Data URIs encoded in Base64 may contain whitespace for human readability."
        
        return Data(base64Encoded: string, options: .ignoreUnknownCharacters)
    }
}

// from http://stackoverflow.com/a/40116326
extension String {
    func decodeHtml() -> String? {
        guard let data = data(using: .utf8) else { return nil }
        
        do {
            return try NSAttributedString(data: data, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: String.Encoding.utf8.rawValue], documentAttributes: nil).string
        } catch let error as NSError {
            print(error.localizedDescription)
            return self
        }
    }
}
