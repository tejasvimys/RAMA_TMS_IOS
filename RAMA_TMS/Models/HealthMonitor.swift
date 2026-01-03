//
//  HealthMonitor.swift
//  RAMA_TMS
//
//  Created by Tejasvi Mahesh on 1/2/26.
//

import Foundation

class HealthMonitor: ObservableObject {
    @Published var isHealthy = true
    @Published var lastCheckTime: Date?
    
    private var timer: Timer?
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkHealth()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkHealth() {
        Task {
            let status = try await AuthAPI.shared.checkHealth()
            await MainActor.run {
                switch status {
                case .healthy:
                    isHealthy = true
                default:
                    isHealthy = false
                }
                lastCheckTime = Date()
            }
        }
    }
}
