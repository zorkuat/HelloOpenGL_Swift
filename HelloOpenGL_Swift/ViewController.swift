//
//  ViewController.swift
//  HelloOpenGL_Swift
//
//  Created by DR on 8/25/15.
//  Copyright © 2015 DR. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    // No utilizas el GLKit controller. Directamente modificas el viewcontroller

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let TV = UIImage(named: "TV");
        let newSize = CGSize(width: view.frame.width, height: 300)
        
        let TV_Resize = scaleUIImageToSize(image: TV!, size: newSize)
        
        let TVFRAME = UIImageView(image: TV_Resize);
        TVFRAME.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0);
        //TVFRAME.frame.height = UIScreen.main.bounds.height;
        //TVFRAME.frame.width = UIScreen.main.bounds.width;
        //let TVView = UIView(frame: TVFRAME.bounds);
        
        //imageView.alpha = 0.5;
   
        // Definimos el frame. Elegimos que sea por completo
        //let frame = UIScreen.main.bounds
        let frame = CGRect(x: TVFRAME.frame.minX + 10, y: TVFRAME.frame.minY + 10, width:TVFRAME.frame.width - 70 , height: TVFRAME.frame.height - 10)
        let _glView = OpenGLView(frame: frame)
        
        
        let gestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(self.recogerDatos))
        self.view .addGestureRecognizer(gestureRecognizer)
        
        self.view.addSubview(_glView)
        self.view.addSubview(TVFRAME)
        
    }
    
    func recogerDatos()
    {
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
     Image Resizing Techniques: http://bit.ly/1Hv0T6i
     */
    func scaleUIImageToSize(image: UIImage, size: CGSize) -> UIImage {
        let hasAlpha = true
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        
        UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
        image.draw(in: CGRect(origin: CGPoint.zero, size: size))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage!
    }

}

