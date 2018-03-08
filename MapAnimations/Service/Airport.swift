//
//  Airport.swift
//  MapAnimations
//
//  Created by Nicholas Furness on 2/28/18.
//  Copyright © 2018 Nicholas Furness. All rights reserved.
//

import ArcGIS

enum Airport:String {
    case atl
    case bkk
    case bom
    case ccu
    case cdg
    case cun
    case den
    case dfw
    case dxb
    case eze
    case gru
    case hkg
    case igt
    case ist
    case jfk
    case kix
    case lax
    case lhr
    case los
    case mex
    case mji
    case nbo
    case opo
    case ord
    case phl
    case sea
    case sfo
    case sin
    case thr
    case yeg
    case ymx
    case yqb
    case yvr
    case ywg
    case yyz

    var mapPoint:AGSPoint {
        switch self {
        case .lax:
            return AGSPoint(x: -118.408075, y: 33.942536, spatialReference: AGSSpatialReference.wgs84())
        case .lhr:
            return AGSPoint(x: -0.461389, y: 51.4775, spatialReference: AGSSpatialReference.wgs84())
        case .dxb:
            return AGSPoint(x: 55.364444, y: 25.252778, spatialReference: AGSSpatialReference.wgs84())
        case .hkg:
            return AGSPoint(x: 113.914603, y: 22.308919, spatialReference: AGSSpatialReference.wgs84())
        case .igt:
            return AGSPoint(x: 77.0999578, y: 28.5561624, spatialReference: AGSSpatialReference.wgs84())
        case .bom:
            return AGSPoint(x: 72.8663173, y: 19.0926195, spatialReference: AGSSpatialReference.wgs84())
        case .ccu:
            return AGSPoint(x: 88.4463299, y: 22.6520429, spatialReference: AGSSpatialReference.wgs84())
        case .cdg:
            return AGSPoint(x: 2.5479245, y: 49.0096906, spatialReference: AGSSpatialReference.wgs84())
        case .ist:
            return AGSPoint(x: 28.814599990799998, y: 40.9768981934, spatialReference: AGSSpatialReference.wgs84())
        case .opo:
            return AGSPoint(x: -8.68138980865, y: 41.2481002808, spatialReference: AGSSpatialReference.wgs84())
        case .nbo:
            return AGSPoint(x: 36.9277992249, y: -1.31923997402, spatialReference: AGSSpatialReference.wgs84())
        case .los:
            return AGSPoint(x: 3.321160078048706, y: 6.5773701667785645, spatialReference: AGSSpatialReference.wgs84())
        case .mji:
            return AGSPoint(x: 13.276000022888184, y: 32.894100189208984, spatialReference: AGSSpatialReference.wgs84())
        case .thr:
            return AGSPoint(x: 51.31340026855469, y: 35.68920135498047, spatialReference: AGSSpatialReference.wgs84())
        case .kix:
            return AGSPoint(x: 135.24400329589844, y: 34.42729949951172, spatialReference: AGSSpatialReference.wgs84())
        case .bkk:
            return AGSPoint(x: 100.74700164794922, y: 13.681099891662598, spatialReference: AGSSpatialReference.wgs84())
        case .sin:
            return AGSPoint(x: 103.994003, y: 1.35019, spatialReference: AGSSpatialReference.wgs84())
        case .yqb:
            return AGSPoint(x: -71.393303, y: 46.7911, spatialReference: AGSSpatialReference.wgs84())
        case .ymx:
            return AGSPoint(x: -74.0386962891, y: 45.6795005798, spatialReference: AGSSpatialReference.wgs84())
        case .yvr:
            return AGSPoint(x: -123.183998108, y: 49.193901062, spatialReference: AGSSpatialReference.wgs84())
        case .yyz:
            return AGSPoint(x: -79.63059997559999, y: 43.6772003174, spatialReference: AGSSpatialReference.wgs84())
        case .yeg:
            return AGSPoint(x: -113.580001831, y: 53.309700012200004, spatialReference: AGSSpatialReference.wgs84())
        case .ywg:
            return AGSPoint(x: -97.2398986816, y: 49.909999847399995, spatialReference: AGSSpatialReference.wgs84())
        case .jfk:
            return AGSPoint(x: -73.77890015, y: 40.63980103, spatialReference: AGSSpatialReference.wgs84())
        case .ord:
            return AGSPoint(x: -87.90480042, y: 41.97859955, spatialReference: AGSSpatialReference.wgs84())
        case .den:
            return AGSPoint(x: -104.672996521, y: 39.861698150635, spatialReference: AGSSpatialReference.wgs84())
        case .sfo:
            return AGSPoint(x: -122.375, y: 37.61899948120117, spatialReference: AGSSpatialReference.wgs84())
        case .phl:
            return AGSPoint(x: -159.33900451660156, y: 21.97599983215332, spatialReference: AGSSpatialReference.wgs84())
        case .atl:
            return AGSPoint(x: -84.4281005859375, y: 33.63669967651367, spatialReference: AGSSpatialReference.wgs84())
        case .dfw:
            return AGSPoint(x: -97.03800201416016, y: 32.89680099487305, spatialReference: AGSSpatialReference.wgs84())
        case .sea:
            return AGSPoint(x: -122.30899810791016, y: 47.44900131225586, spatialReference: AGSSpatialReference.wgs84())
        case .eze:
            return AGSPoint(x: -58.5358, y: -34.8222, spatialReference: AGSSpatialReference.wgs84())
        case .gru:
            return AGSPoint(x: -46.47305679321289, y: -23.435556411743164, spatialReference: AGSSpatialReference.wgs84())
        case .cun:
            return AGSPoint(x: -86.8770980835, y: 21.036500930800003, spatialReference: AGSSpatialReference.wgs84())
        case .mex:
            return AGSPoint(x: -99.072098, y: 19.4363, spatialReference: AGSSpatialReference.wgs84())
        }
    }
}
