//
//  DrawAnimationHelper.swift
//  MapAnimations
//
//  Created by Gagandeep Singh on 3/7/17.
//  Copyright © 2017 Gagandeep Singh. All rights reserved.
//

import UIKit
import ArcGIS

class AnimateLineTraceHelper {

    private var polyline:AGSPolyline
    private var animatingGraphic:AGSGraphic
    private var speed:Double

    var name:String = "Unnamed"

    private var polylineBuilder:AGSPolylineBuilder
    private var maxDeviation:Double = 0

    convenience init(polyline: AGSPolyline, animatingGraphic: AGSGraphic, speed: Double) {
        self.init(polyline: polyline, animatingGraphic: animatingGraphic, speed: speed, generalize: false)
    }

    init(polyline: AGSPolyline, animatingGraphic: AGSGraphic, speed: Double, generalize:Bool) {
        
        self.polyline = polyline
        self.animatingGraphic = animatingGraphic
        self.animatingGraphic.isVisible = false
        self.speed = speed
        
        self.maxDeviation = generalize ? 500 : 0 // min(10, self.polylineLength/500)

        if let firstPoint = self.polyline.parts.array().first?.startPoint {
            self.polylineBuilder = AGSPolylineBuilder(points: [firstPoint])
        } else {
            self.polylineBuilder = AGSPolylineBuilder(spatialReference: polyline.spatialReference)
        }

    }
    
    //MARK: - Start animation
    
    func startAnimation() {
        let length = AGSGeometryEngine.length(of: polyline)
        let duration = length/speed
        let startTime = Date()

        AnimationManager.animate(animationBlock: { () -> Bool in
            let doneFactor = Date().timeIntervalSince(startTime) / duration
            guard let newLocation = AGSGeometryEngine.point(along: self.polyline, distance: length * doneFactor) else {
                print("New location is not a valid point! Donefactor = \(doneFactor)")
                return true
            }

            self.polylineBuilder.add(newLocation)

            //assign the geometry to the polyline graphic
            if self.maxDeviation > 0 {
                let generalizedGeom = AGSGeometryEngine.generalizeGeometry(self.polylineBuilder.toGeometry(), maxDeviation: self.maxDeviation, removeDegenerateParts: true)
                self.animatingGraphic.geometry = generalizedGeom
            } else {
                self.animatingGraphic.geometry = self.polylineBuilder.toGeometry()
            }

            if !self.animatingGraphic.isVisible {
                self.animatingGraphic.isVisible = true
            }

            return doneFactor >= 1
        }, completion: nil)
    }
}
