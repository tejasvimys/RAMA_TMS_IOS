//
//  PasswordResetModels.swift
//  RAMA_TMS
//
//  Created by Tejasvi Mahesh on 1/2/26.
//  Created for Password Reset
//

import Foundation

struct ForgotPasswordRequest: Codable {
    let email: String
}

struct ForgotPasswordResponse: Codable {
    let message: String
    let resetToken: String?
}

struct ValidateResetTokenRequest: Codable {
    let token: String
}

struct ValidateResetTokenResponse: Codable {
    let message: String
    let email: String
}

struct ResetPasswordRequest: Codable {
    let token: String
    let newPassword: String
}

struct ResetPasswordResponse: Codable {
    let message: String
}
