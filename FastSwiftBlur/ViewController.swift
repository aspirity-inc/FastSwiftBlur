//
//  ViewController.swift
//  SwiftAsyncBlur
//
//  Created by Maxim on 07/05/2018.
//  Copyright © 2018 Aspirity. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var imageView: FastBlurImageView!
    @IBOutlet weak var slider: UISlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        slider.addTarget(self, action: #selector(sliderDidScroll(slider:)), for: UIControlEvents.valueChanged)
    }
    
    @objc func sliderDidScroll(slider: UISlider) {
        let maxBlur:Float = 35
        let currentBlurRadius = slider.value * maxBlur
        log("View Controller: set blur radius to \(currentBlurRadius)")
        self.imageView.blurRadius = currentBlurRadius
    }

    

}

