//
// LoginView.swift
// RAMA_TMS
//
// Created by Tejasvi Mahesh on 12/22/25.
// Updated with Real-time Offline Authentication Support - PART 1
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: AuthViewModel
    
    // Direct references to shared instances
    private let offlineManager = OfflineManager.shared
    private let offlineAuthManager = OfflineAuthManager.shared
    
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var isRegister = false
    @State private var loading = false
    @State private var statusMessage: String?
    
    // Network state tracking (local state that updates from notifications)
    @State private var isOnline = true
    @State private var isOfflineLoginAvailable = false
    
    // 2FA state
    @State private var requires2FA = false
    @State private var requires2FASetup = false
    @State private var tempToken = ""
    @State private var twoFactorCode = ""
    
    // 2FA Setup state
    @State private var setupStep = 1
    @State private var setupPassword = ""
    @State private var qrCodeUri = ""
    @State private var secret = ""
    @State private var backupCodes: [String] = []
    @State private var verificationCode = ""
    
    // Forgot password state
    @State private var showForgotPassword = false
    
    // Offline mode state
    @State private var isOfflineAttempt = false
    @State private var cachedUserEmail: String?
    
    var body: some View {
        ZStack {
            RamaTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Logo and Header
                    Image("rama-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120)
                    
                    Text("Ananthaadi Rayara Matha")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(RamaTheme.primary)
                    
                    // Network Status Indicator
                    networkStatusBadge
                    
                    // Sync Status
                    syncStatusView
                    
                    // Main Content
                    if requires2FASetup {
                        twoFactorSetupSection
                    } else if requires2FA {
                        twoFactorVerificationSection
                    } else {
                        emailSignInSection
                    }
                    
                    // Status Message
                    if let status = statusMessage {
                        Text(status)
                            .font(.caption)
                            .foregroundColor(statusMessageColor)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
        .onAppear {
            setupView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .networkStatusChanged)) { notification in
            if let newStatus = notification.object as? Bool {
                handleNetworkStatusChange(isOnline: newStatus)
            }
        }
    }
    
    // MARK: - Network Status Badge
    
    @ViewBuilder
    private var networkStatusBadge: some View {
        if !isOnline {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                Text("Offline Mode")
                if isOfflineLoginAvailable {
                    Text("• Cached login available")
                        .font(.caption)
                }
            }
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.orange)
            .cornerRadius(20)
            .transition(.scale.combined(with: .opacity))
        } else {
            HStack(spacing: 8) {
                Image(systemName: "wifi")
                Text("Online")
            }
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.green)
            .cornerRadius(20)
            .transition(.scale.combined(with: .opacity))
        }
    }
    
    // MARK: - Sync Status View
    
    @ViewBuilder
    private var syncStatusView: some View {
        let pendingSyncCount = offlineManager.pendingSyncCount
        let pendingEmailCount = offlineManager.pendingEmailCount
        
        if pendingSyncCount > 0 || pendingEmailCount > 0 {
            VStack(spacing: 4) {
                if pendingSyncCount > 0 {
                    Text("\(pendingSyncCount) donation(s) pending sync")
                        .font(.caption2)
                }
                if pendingEmailCount > 0 {
                    Text("\(pendingEmailCount) email(s) pending")
                        .font(.caption2)
                }
            }
            .foregroundColor(.blue)
        }
    }
    
    private var statusMessageColor: Color {
        guard let message = statusMessage else { return .red }
        if message.contains("success") || message.contains("online") || message.contains("restored") {
            return .green
        }
        return .red
    }
    
    // MARK: - Setup
    
    func setupView() {
        // Initialize state from managers
        isOnline = offlineManager.isOnline
        isOfflineLoginAvailable = offlineAuthManager.isOfflineLoginAvailable()
        
        // Pre-fill email if cached credentials exist
        if let cached = offlineAuthManager.getCachedEmail() {
            email = cached
            cachedUserEmail = cached
        }
        
        print("📱 LoginView initialized")
        print("   Online: \(isOnline)")
        print("   Offline login available: \(isOfflineLoginAvailable)")
    }
    
    // MARK: - Network Status Change Handler
    
    func handleNetworkStatusChange(isOnline newStatus: Bool) {
        let wasOnline = isOnline
        
        // Update state with animation
        withAnimation(.easeInOut(duration: 0.3)) {
            isOnline = newStatus
        }
        
        print("🔄 Network status changed in LoginView: \(wasOnline ? "Online" : "Offline") → \(newStatus ? "Online" : "Offline")")
        
        // Transition from offline to online
        if !wasOnline && newStatus {
            statusMessage = "✓ Connection restored - You're back online!"
            isOfflineAttempt = false
            
            // Auto-dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                if statusMessage?.contains("restored") == true {
                    withAnimation {
                        statusMessage = nil
                    }
                }
            }
        }
        
        // Transition from online to offline
        if wasOnline && !newStatus {
            isOfflineAttempt = false
            statusMessage = isOfflineLoginAvailable
                ? "⚠️ Connection lost - Offline mode available"
                : "⚠️ Connection lost - Please reconnect to login"
            
            // Auto-dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                if statusMessage?.contains("Connection lost") == true {
                    withAnimation {
                        statusMessage = nil
                    }
                }
            }
        }
    }
    
    // MARK: - Email Sign In Section
    
    var emailSignInSection: some View {
        VStack(spacing: 12) {
            if isRegister {
                TextField("Name", text: $displayName)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.words)
                    .padding(.horizontal, 32)
            }
            
            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding(.horizontal, 32)
            
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 32)
            
            // Forgot Password Link
            if !isRegister {
                Button {
                    showForgotPassword = true
                } label: {
                    Text("Forgot Password?")
                        .font(.caption)
                        .foregroundColor(RamaTheme.primary)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 32)
            }
            
            // Offline Login Hint
            if !isOnline && isOfflineLoginAvailable && !isRegister {
                Text("You can login with cached credentials")
                    .font(.caption2)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 32)
            }
            
            Button {
                handleEmailAuth()
            } label: {
                if loading {
                    ProgressView()
                } else {
                    HStack {
                        Text(isRegister ? "Register" : "Login")
                        if !isOnline && !isRegister {
                            Text("(Offline)")
                                .font(.caption)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .background(canSubmit ? RamaTheme.primary : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
            .disabled(!canSubmit || loading)
            .padding(.horizontal, 32)
            
            Button {
                isRegister.toggle()
                statusMessage = nil
            } label: {
                Text(isRegister ? "Already have an account? Login" : "New here? Register")
                    .font(.caption)
                    .foregroundColor(RamaTheme.primary)
            }
        }
    }
    // MARK: - 2FA Verification Section
    
    var twoFactorVerificationSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(RamaTheme.primary)
            
            Text("Two-Factor Authentication")
                .font(.headline)
                .foregroundColor(RamaTheme.primary)
            
            Text(isOfflineAttempt ? "Enter your 6-digit code (Offline Mode)" : "Enter the 6-digit code from your authenticator app or use a backup code.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            TextField("000000", text: $twoFactorCode)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 24, weight: .medium, design: .monospaced))
                .padding(.horizontal, 32)
                .onChange(of: twoFactorCode) { oldValue, newValue in
                    if newValue.count > 8 {
                        twoFactorCode = String(newValue.prefix(8))
                    }
                }
            
            Button {
                handle2FAVerification()
            } label: {
                if loading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Verify")
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .background(can2FASubmit ? RamaTheme.primary : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
            .disabled(!can2FASubmit || loading)
            .padding(.horizontal, 32)
            
            Button {
                handleBack2FA()
            } label: {
                Text("Back to Login")
                    .font(.caption)
                    .foregroundColor(RamaTheme.primary)
            }
        }
    }
    
    // MARK: - 2FA Setup Section
    
    var twoFactorSetupSection: some View {
        VStack(spacing: 16) {
            if setupStep == 1 {
                setupStep1View
            } else if setupStep == 2 {
                setupStep2View
            }
        }
    }
    
    var setupStep1View: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(RamaTheme.primary)
            
            Text("Setup Two-Factor Authentication")
                .font(.headline)
                .foregroundColor(RamaTheme.primary)
            
            Text("For security, you must enable 2FA. Confirm your password to continue.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            SecureField("Confirm your password", text: $setupPassword)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 32)
            
            Button {
                handleSetupStep1()
            } label: {
                if loading {
                    ProgressView()
                } else {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .background(setupPassword.count >= 6 ? RamaTheme.primary : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
            .disabled(setupPassword.count < 6 || loading)
            .padding(.horizontal, 32)
            
            Button {
                handleBack2FASetup()
            } label: {
                Text("Back to Login")
                    .font(.caption)
                    .foregroundColor(RamaTheme.primary)
            }
        }
    }
    
    var setupStep2View: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Step 2: Scan QR Code")
                    .font(.headline)
                    .foregroundColor(RamaTheme.primary)
                
                if let qrImage = generateQRCode(from: qrCodeUri) {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                }
                
                Text("Manual: \(secret)")
                    .font(.system(.caption, design: .monospaced))
                    .padding(8)
                    .background(Color.white)
                    .cornerRadius(8)
                
                VStack {
                    Text("Backup Codes (Save these!)")
                        .font(.caption)
                        .bold()
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                        ForEach(backupCodes.prefix(4), id: \.self) { code in
                            Text(code)
                                .font(.system(.caption, design: .monospaced))
                                .padding(6)
                                .background(Color.white)
                                .cornerRadius(6)
                        }
                    }
                    
                    Button("Save All \(backupCodes.count) Codes") {
                        shareBackupCodes()
                    }
                    .font(.caption)
                    .padding(8)
                    .background(Color.white)
                    .foregroundColor(RamaTheme.primary)
                    .cornerRadius(8)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                
                TextField("000000", text: $verificationCode)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 24, design: .monospaced))
                    .padding(.horizontal, 32)
                    .onChange(of: verificationCode) { oldValue, newValue in
                        if newValue.count > 6 {
                            verificationCode = String(newValue.prefix(6))
                        }
                    }
                
                Button {
                    handleVerifySetup()
                } label: {
                    if loading {
                        ProgressView()
                    } else {
                        Text("Verify & Complete")
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(verificationCode.count == 6 ? RamaTheme.primary : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(verificationCode.count != 6 || loading)
                .padding(.horizontal, 32)
            }
        }
    }
    
    // MARK: - Validation
    
    var canSubmit: Bool {
        !email.isEmpty && password.count >= 6
    }
    
    var can2FASubmit: Bool {
        twoFactorCode.count == 6 || twoFactorCode.count == 8
    }
    // MARK: - Handlers
    
    func handleEmailAuth() {
        loading = true
        statusMessage = nil
        
        Task {
            do {
                if isRegister {
                    // Registration (online only)
                    if !isOnline {
                        await MainActor.run {
                            statusMessage = "Registration requires internet connection"
                            loading = false
                        }
                        return
                    }
                    
                    let message = try await AuthAPI.shared.register(
                        email: email,
                        displayName: displayName.isEmpty ? email : displayName,
                        password: password
                    )
                    await MainActor.run {
                        statusMessage = message + " Once approved, setup 2FA to login."
                        isRegister = false
                        password = ""
                        loading = false
                    }
                } else {
                    // Login - try online first, fallback to offline
                    if isOnline {
                        try await attemptOnlineLogin()
                    } else {
                        try await attemptOfflineLogin()
                    }
                }
            } catch {
                // If online login fails and we're offline, try offline login
                if !isOnline {
                    do {
                        try await attemptOfflineLogin()
                    } catch {
                        await MainActor.run {
                            statusMessage = error.localizedDescription
                            loading = false
                        }
                    }
                } else {
                    await MainActor.run {
                        statusMessage = error.localizedDescription
                        loading = false
                    }
                }
            }
        }
    }
    
    func attemptOnlineLogin() async throws {
        let response = try await AuthAPI.shared.login(email: email, password: password)
        
        await MainActor.run {
            if !response.isActive {
                statusMessage = "Account pending admin approval."
                loading = false
                return
            }
            
            if response.requires2FASetup == true {
                requires2FASetup = true
                tempToken = response.tempToken ?? ""
                statusMessage = "You must setup 2FA to continue"
                loading = false
                return
            }
            
            if response.requiresTwoFactor {
                requires2FA = true
                tempToken = response.tempToken ?? ""
                isOfflineAttempt = false
                statusMessage = "Please enter your 2FA code"
                loading = false
                return
            }
            
            statusMessage = "2FA is required for all users"
            loading = false
        }
    }
    
    func attemptOfflineLogin() async throws {
        let authManager = OfflineAuthManager.shared
        
        await MainActor.run {
            let result = authManager.verifyOfflineLogin(
                email: email,
                password: password
            )
            
            if !result.success {
                statusMessage = result.error
                loading = false
                return
            }
            
            if result.requires2FA {
                requires2FA = true
                isOfflineAttempt = true
                statusMessage = "Enter 2FA code (Offline)"
                loading = false
                return
            }
            
            // Login successful without 2FA
            auth.handleOfflineAuth(
                email: email,
                displayName: result.displayName ?? "User",
                role: result.role ?? "Collector",
                userId: result.userId ?? "offline"
            )
            loading = false
        }
    }
    
    func handle2FAVerification() {
        loading = true
        statusMessage = nil
        
        Task {
            if isOfflineAttempt {
                // Offline 2FA verification
                let authManager = OfflineAuthManager.shared
                
                await MainActor.run {
                    let result = authManager.verifyOffline2FA(code: twoFactorCode)
                    
                    if result.success {
                        if let cached = authManager.getCachedCredentials() {
                            auth.handleOfflineAuth(
                                email: cached.email,
                                displayName: cached.displayName,
                                role: cached.role,
                                userId: cached.userId
                            )
                        }
                    } else {
                        statusMessage = result.error
                    }
                    
                    loading = false
                }
            } else {
                // Online 2FA verification
                do {
                    let response = try await AuthAPI.shared.verify2FA(
                        email: email,
                        code: twoFactorCode,
                        tempToken: tempToken
                    )
                    
                    await MainActor.run {
                        auth.handleAuthResponse(response)
                        
                        // Cache credentials for offline use
                        auth.cacheCredentialsForOffline(
                            password: password,
                            userId: String(response.email.hashValue),
                            twoFactorEnabled: true,
                            twoFactorSecret: nil
                        )
                        
                        loading = false
                    }
                } catch {
                    await MainActor.run {
                        statusMessage = error.localizedDescription
                        loading = false
                    }
                }
            }
        }
    }
    
    func handleSetupStep1() {
        loading = true
        statusMessage = nil
        
        Task {
            do {
                let response = try await AuthAPI.shared.enable2FAFirstTime(
                    password: setupPassword,
                    tempToken: tempToken
                )
                await MainActor.run {
                    secret = response.secret
                    qrCodeUri = response.qrCodeUri
                    backupCodes = response.backupCodes
                    setupStep = 2
                    loading = false
                }
            } catch {
                await MainActor.run {
                    statusMessage = error.localizedDescription
                    loading = false
                }
            }
        }
    }
    
    func handleVerifySetup() {
        loading = true
        statusMessage = nil
        
        Task {
            do {
                let message = try await AuthAPI.shared.verify2FASetup(
                    code: verificationCode,
                    tempToken: tempToken
                )
                
                await MainActor.run {
                    // Cache credentials with 2FA secret for offline use
                    auth.cacheCredentialsForOffline(
                        password: password,
                        userId: String(email.hashValue),
                        twoFactorEnabled: true,
                        twoFactorSecret: secret
                    )
                    
                    statusMessage = "2FA setup complete! Please login again."
                    resetAll()
                    loading = false
                }
            } catch {
                await MainActor.run {
                    statusMessage = error.localizedDescription
                    loading = false
                }
            }
        }
    }
    
    func handleBack2FA() {
        requires2FA = false
        isOfflineAttempt = false
        tempToken = ""
        twoFactorCode = ""
        password = ""
        statusMessage = nil
    }
    
    func handleBack2FASetup() {
        requires2FASetup = false
        setupStep = 1
        setupPassword = ""
        tempToken = ""
        qrCodeUri = ""
        secret = ""
        backupCodes = []
        verificationCode = ""
        password = ""
        statusMessage = nil
    }
    
    func resetAll() {
        requires2FA = false
        requires2FASetup = false
        isOfflineAttempt = false
        setupStep = 1
        tempToken = ""
        twoFactorCode = ""
        setupPassword = ""
        qrCodeUri = ""
        secret = ""
        backupCodes = []
        verificationCode = ""
        password = ""
    }
    
    // MARK: - Helper Methods
    
    func generateQRCode(from string: String) -> UIImage? {
        let data = Data(string.utf8)
        
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        
        guard let output = filter.outputImage?.transformed(by: transform) else { return nil }
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(output, from: output.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
    
    func shareBackupCodes() {
        let text = "RAMA TMS Backup Codes\n" +
        "Keep these codes safe!\n\n" +
        backupCodes.joined(separator: "\n") +
        "\n\nThese codes can be used if you lose access to your authenticator app."
        
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Preview

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthViewModel())
    }
}

