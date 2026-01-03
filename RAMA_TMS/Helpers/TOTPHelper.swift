//
//  TOTPHelper.swift
//  RAMA_TMS
//
//  Created by Tejasvi Mahesh on 1/2/26.
//
//  Time-based One-Time Password (TOTP) Implementation
//  Based on RFC 6238
//

import Foundation
import CryptoKit

class TOTPHelper {
    
    // MARK: - Constants
    
    private static let timeStep: Int = 30 // 30 seconds
    private static let codeLength: Int = 6
    
    // MARK: - Validate TOTP Code
    
    static func validateCode(_ secret: String, _ code: String, windowSize: Int = 1) -> Bool {
        guard !secret.isEmpty && !code.isEmpty else { return false }
        
        // Remove spaces and validate length
        let cleanCode = code.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " ", with: "")
        guard cleanCode.count == 6 || cleanCode.count == 8 else { return false }
        
        let currentTimestamp = getCurrentTimestamp()
        
        // Check current time window and adjacent windows
        for offset in -windowSize...windowSize {
            let timestamp = currentTimestamp + Int64(offset)
            if let expectedCode = generateCode(secret: secret, timestamp: timestamp) {
                if expectedCode == cleanCode {
                    return true
                }
            }
        }
        
        return false
    }
    
    // MARK: - Generate TOTP Code
    
    static func generateCurrentCode(secret: String) -> String? {
        let timestamp = getCurrentTimestamp()
        return generateCode(secret: secret, timestamp: timestamp)
    }
    
    private static func generateCode(secret: String, timestamp: Int64) -> String? {
        guard let key = base32Decode(secret) else { return nil }
        
        // Convert timestamp to bytes (big-endian)
        var counter = timestamp.bigEndian
        let counterData = withUnsafeBytes(of: &counter) { Data($0) }
        
        // HMAC-SHA1
        guard let hmac = hmacSHA1(key: key, message: counterData) else { return nil }
        
        // Dynamic truncation
        let offset = Int(hmac[hmac.count - 1] & 0x0F)
        let truncatedHash = hmac.subdata(in: offset..<offset + 4)
        
        var number = UInt32(truncatedHash.reduce(0) { ($0 << 8) | UInt32($1) })
        number &= 0x7FFFFFFF // Remove sign bit
        
        let otp = number % 1_000_000
        return String(format: "%06d", otp)
    }
    
    // MARK: - Get Current Timestamp
    
    private static func getCurrentTimestamp() -> Int64 {
        let unixTime = Int64(Date().timeIntervalSince1970)
        return unixTime / Int64(timeStep)
    }
    
    // MARK: - HMAC-SHA1
    
    private static func hmacSHA1(key: Data, message: Data) -> Data? {
        let keyBytes = [UInt8](key)
        let messageBytes = [UInt8](message)
        
        var key = keyBytes
        
        // Keys longer than blocksize are hashed
        if key.count > 64 {
            key = [UInt8](Insecure.SHA1.hash(data: Data(key)))
        }
        
        // Keys shorter than blocksize are zero-padded
        if key.count < 64 {
            key += [UInt8](repeating: 0, count: 64 - key.count)
        }
        
        var oKeyPad = [UInt8](repeating: 0x5c, count: 64)
        var iKeyPad = [UInt8](repeating: 0x36, count: 64)
        
        for i in 0..<64 {
            oKeyPad[i] = key[i] ^ oKeyPad[i]
            iKeyPad[i] = key[i] ^ iKeyPad[i]
        }
        
        // Hash(o_key_pad || Hash(i_key_pad || message))
        let innerHash = Insecure.SHA1.hash(data: Data(iKeyPad + messageBytes))
        let outerHash = Insecure.SHA1.hash(data: Data(oKeyPad + [UInt8](innerHash)))
        
        return Data(outerHash)
    }
    
    // MARK: - Base32 Decoding
    
    private static func base32Decode(_ encoded: String) -> Data? {
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        let cleanEncoded = encoded.uppercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "=", with: "")
        
        var result = Data()
        var buffer = 0
        var bitsLeft = 0
        
        for char in cleanEncoded {
            guard let index = alphabet.firstIndex(of: char) else { continue }
            let value = alphabet.distance(from: alphabet.startIndex, to: index)
            
            buffer <<= 5
            buffer |= value
            bitsLeft += 5
            
            if bitsLeft >= 8 {
                result.append(UInt8((buffer >> (bitsLeft - 8)) & 0xFF))
                bitsLeft -= 8
            }
        }
        
        return result
    }
    
    // MARK: - Generate Provisioning URI (for QR codes)
    
    static func getProvisioningUri(email: String, secret: String, issuer: String = "RAMA TMS") -> String {
        let encodedIssuer = issuer.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? issuer
        let encodedEmail = email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? email
        
        return "otpauth://totp/\(encodedIssuer):\(encodedEmail)?secret=\(secret)&issuer=\(encodedIssuer)&algorithm=SHA1&digits=6&period=30"
    }
    
    // MARK: - Generate Secret Key
    
    static func generateSecret() -> String {
        var bytes = [UInt8](repeating: 0, count: 20)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return base32Encode(Data(bytes))
    }
    
    // MARK: - Base32 Encoding
    
    private static func base32Encode(_ data: Data) -> String {
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        var result = ""
        
        let bytes = [UInt8](data)
        var buffer = 0
        var bitsLeft = 0
        
        for byte in bytes {
            buffer <<= 8
            buffer |= Int(byte)
            bitsLeft += 8
            
            while bitsLeft >= 5 {
                let index = (buffer >> (bitsLeft - 5)) & 0x1F
                result.append(alphabet[alphabet.index(alphabet.startIndex, offsetBy: index)])
                bitsLeft -= 5
            }
        }
        
        if bitsLeft > 0 {
            let index = (buffer << (5 - bitsLeft)) & 0x1F
            result.append(alphabet[alphabet.index(alphabet.startIndex, offsetBy: index)])
        }
        
        return result
    }
}
