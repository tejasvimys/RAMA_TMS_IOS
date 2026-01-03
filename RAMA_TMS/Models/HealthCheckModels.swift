//
//  HealthCheckModels.swift
//  RAMA_TMS
//
//  Created by Tejasvi Mahesh on 1/2/26.
//  Created for Health Check
//

import Foundation

struct HealthCheckResponse: Codable {
    let status: String
    let message: String
    let database: String?
    let timestamp: String?
    let version: String?
    let error: String?
}

enum HealthStatus {
    case healthy
    case unhealthy(message: String)
    case networkError
    case timeout
}
