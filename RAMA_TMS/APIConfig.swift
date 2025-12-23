//
//  APIConfig.swift
//  RAMA_TMS
//
//  Created by Tejasvi Mahesh on 12/23/25.
//

import Foundation

enum APIConfig {
    static let baseURL: String = {
        #if DEBUG
        return "http://10.0.0.3:5158" // Development
        #else
        return "http://10.0.0.3:5158" // Production
        #endif
    }()
}
