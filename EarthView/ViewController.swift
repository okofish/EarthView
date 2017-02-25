//
//  ViewController.swift
//  EarthView
//
//  Created by Jesse Friedman on 2/10/17.
//  Copyright © 2017 Jesse Friedman. All rights reserved.
//

import UIKit

func debug(_ message: Any) {
    #if DEBUG
        print(message)
    #endif
}

class ViewController: UIViewController, EarthViewAPIDelegate {
    let api = EarthViewAPI()
    let settings = UserDefaults.standard
    
    var timer: Timer!
    var timerActive = false
    
    @IBOutlet weak var loadingSpinner: UIActivityIndicatorView!
    @IBOutlet weak var imageGroup: UIView!
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var regionText: UILabel!
    @IBOutlet weak var countryText: UILabel!
    @IBOutlet weak var attributionText: UILabel!
    @IBOutlet weak var textBackdrop: UIView!
    @IBOutlet weak var textBackdropLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var textBackdropRegionHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var textBackdropCountryHeightConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        api.delegate = self;
        displayRandomImage()
        
        var interval = settings.float(forKey: "imageDuration") + settings.float(forKey: "fadeDuration")
        if interval <= 0 {
            interval = 63.0
        }
        
        // override the interval for testing
        #if OVERRIDE_INTERVAL
            interval = 10
        #endif
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(interval), repeats: true, block: {_ in
            if self.timerActive {
                debug("Timer fired.")
                self.displayRandomImage()
            }
        })
        timerActive = true
        debug("Timer created.")
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.pauseTimer), name: .UIApplicationWillResignActive, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.resumeTimer), name: .UIApplicationDidBecomeActive, object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func pauseTimer() {
        debug("Timer paused.")
        timerActive = false
    }
    
    func resumeTimer() {
        debug("Timer resumed.")
        timerActive = true
    }
    
    func displayRandomImage() {
        api.requestImageData(imageId: ImageIDs.randomItem())
    }

    func handleImageData(_ data: [String: Any]) {
        debug(data)
        
        if let image = data["image"] as? UIImage {
            var duration = settings.float(forKey: "fadeDuration")
            if duration <= 0 {
                duration = 3.0
            }
            UIView.transition(with: imageGroup, duration: TimeInterval(duration), options: .transitionCrossDissolve, animations: {
                self.imageView.image = image
            }, completion: { finished in
                if !finished {
                    debug("FADE DID NOT FINISH")
                }
            })
        }
        
        if let attribution = data["attribution"] as? String {
            attributionText.text = attribution
            attributionText.isHidden = false
        }
        
        if let location = data["location"] as? String {
            regionText.text = location
            regionText.isHidden = false
        }
        
        if let country = data["country"] as? String {
            countryText.text = country
            countryText.isHidden = false
        }
        
        // set backdrop leading constraint to the width of the longest label, plus a little more
        let regionTextWidth = (regionText.text! as NSString).size(attributes: [NSFontAttributeName: regionText.font]).width
        let countryTextWidth = (countryText.text! as NSString).size(attributes: [NSFontAttributeName: countryText.font]).width
        let textMaxWidth = max(regionTextWidth, countryTextWidth)
        textBackdropLeadingConstraint.constant = -(textMaxWidth + 35)
        
        // if missing region text, switch to a thinner backdrop
        if (regionText.text?.isEmpty)! {
            textBackdropRegionHeightConstraint.isActive = false
            textBackdropCountryHeightConstraint.isActive = true
        } else {
            textBackdropCountryHeightConstraint.isActive = false
            textBackdropRegionHeightConstraint.isActive = true
        }
        
        imageGroup.isHidden = false
        loadingSpinner.stopAnimating()
    }
}

extension Array {
    func randomItem() -> Element {
        let index = Int(arc4random_uniform(UInt32(self.count)))
        return self[index]
    }
}
