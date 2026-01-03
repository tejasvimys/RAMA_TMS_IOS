//
//  AddDonationView.swift
//  RAMA_TMS
//
//  Created by Tejasvi Mahesh on 12/21/25.
//
import SwiftUI
struct AddDonationView: View {
    // Donor
    @State private var isOrganization = false
    @State private var organizationName = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var address1 = ""
    @State private var address2 = ""
    @State private var city = ""
    @State private var stateText = ""
    @State private var country = "USA"
    @State private var postalCode = ""

    // Donation
    @State private var amount = ""
    @State private var donationType = "General"
    @State private var paymentMode = "Cash"
    @State private var referenceNo = ""
    @State private var notes = ""

    @State private var isSubmitting = false
    @State private var statusMessage: String?
    @State private var isSuccess = false
    
    @State private var showZelleQR = false
    @FocusState private var focusedField: Field?
    
    @StateObject private var offlineDonationManager = OfflineDonationManager.shared
    @StateObject private var offlineManager = OfflineManager.shared
    @EnvironmentObject var auth: AuthViewModel
    
    enum Field: Hashable {
        case organizationName, firstName, lastName, phone, email
        case address1, address2, city, state, country, postalCode
        case amount, referenceNo, notes
    }

    let donationTypes = ["Building Fund", "General", "Annadana", "Seva"]
    let paymentModes  = ["Cash", "Check", "Zelle", "CreditCard"]

    var body: some View {
        ZStack {
            RamaTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    headerView
                    donorSectionView
                    donationSectionView
                    statusMessageView
                    saveButtonView
                }
                .padding()
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Add Donation")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showZelleQR) { ZelleQRView() }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
                    .tint(RamaTheme.primary)
            }
        }
    }

    private var headerView: some View {
           VStack(spacing: 8) {
               Image(systemName: "")
                   .font(.system(size: 50))
                   .foregroundColor(.red)
               
               Text("New Donation")
                   .font(.title2)
                   .fontWeight(.bold)
                   .foregroundColor(.red)
               
               Text("Record a Donation or Seva Here")
                   .font(.subheadline)
                   .foregroundColor(.secondary)
           }
           .padding(.top, 8)
       }
       
       private var donorSectionView: some View {
           SectionCard(title: "Donor Information", icon: "person.fill") {
               VStack(spacing: 16) {
                   organizationToggleView
                   
                   if isOrganization {
                       organizationFieldView
                   } else {
                       nameFieldsView
                   }
                   
                   contactFieldsView
                   Divider().padding(.vertical, 8)
                   addressFieldsView
               }
           }
       }
       
       private var organizationToggleView: some View {
           HStack {
               Label("Organization Donation", systemImage: "building.2")
                   .font(.subheadline)
                   .foregroundColor(.primary)
               Spacer()
               Toggle("", isOn: $isOrganization)
                   .labelsHidden()
                   .tint(RamaTheme.primary)
           }
           .padding(.vertical, 8)
           .padding(.horizontal, 12)
           .background(Color(.systemGray6))
           .cornerRadius(10)
       }
       
       private var organizationFieldView: some View {
           RamaTextField(
               title: "Organization Name",
               text: $organizationName,
               icon: "building.2",
               placeholder: "Enter organization name"
           )
           .focused($focusedField, equals: .organizationName)
       }
       
       private var nameFieldsView: some View {
           HStack(spacing: 12) {
               RamaTextField(
                   title: "First Name",
                   text: $firstName,
                   icon: "person",
                   placeholder: "First"
               )
               .focused($focusedField, equals: .firstName)
               
               RamaTextField(
                   title: "Last Name",
                   text: $lastName,
                   icon: "person",
                   placeholder: "Last"
               )
               .focused($focusedField, equals: .lastName)
           }
       }
       
       private var contactFieldsView: some View {
           Group {
               RamaTextField(
                   title: "Phone",
                   text: $phone,
                   icon: "phone.fill",
                   placeholder: "(555) 123-4567",
                   keyboard: .phonePad
               )
               .focused($focusedField, equals: .phone)
               
               RamaTextField(
                   title: "Email",
                   text: $email,
                   icon: "envelope.fill",
                   placeholder: "donor@example.com",
                   keyboard: .emailAddress
               )
               .focused($focusedField, equals: .email)
           }
       }
       
       private var addressFieldsView: some View {
           Group {
               Text("Address")
                   .font(.subheadline)
                   .fontWeight(.semibold)
                   .foregroundColor(.secondary)
                   .frame(maxWidth: .infinity, alignment: .leading)
               
               RamaTextField(
                   title: "Address Line 1",
                   text: $address1,
                   icon: "map",
                   placeholder: "Street address"
               )
               .focused($focusedField, equals: .address1)
               
               RamaTextField(
                   title: "Address Line 2",
                   text: $address2,
                   icon: "map",
                   placeholder: "Apt, suite, etc. (optional)"
               )
               .focused($focusedField, equals: .address2)
               
               HStack(spacing: 12) {
                   RamaTextField(title: "City", text: $city, icon: "building.2", placeholder: "City")
                       .focused($focusedField, equals: .city)
                   RamaTextField(title: "State", text: $stateText, icon: "map", placeholder: "State")
                       .focused($focusedField, equals: .state)
               }
               
               HStack(spacing: 12) {
                   RamaTextField(title: "Country", text: $country, icon: "globe", placeholder: "Country")
                       .focused($focusedField, equals: .country)
                   RamaTextField(title: "Postal Code", text: $postalCode, icon: "mappin.circle", placeholder: "ZIP")
                       .focused($focusedField, equals: .postalCode)
               }
           }
       }
       
       private var donationSectionView: some View {
           SectionCard(title: "Donation Details", icon: "dollarsign.circle.fill") {
               VStack(spacing: 16) {
                   amountFieldView
                   donationTypePickerView
                   paymentModePickerView
                   referenceFieldView
                   notesFieldView
               }
           }
       }
       
       private var amountFieldView: some View {
           VStack(alignment: .leading, spacing: 8) {
               Label("Amount", systemImage: "dollarsign.circle.fill")
                   .font(.caption)
                   .fontWeight(.medium)
                   .foregroundColor(.black)
               
               HStack(spacing: 12) {
                   Image(systemName: "dollarsign.circle.fill")
                       .foregroundColor(RamaTheme.primary)
                       .font(.title3)
                   
                   TextField("0.00", text: $amount)
                       .keyboardType(.decimalPad)
                       .font(.system(size: 24, weight: .semibold))
                       .focused($focusedField, equals: .amount)
               }
               .padding()
               .background(Color(.systemGray6))
               .cornerRadius(12)
           }
       }
       
       private var donationTypePickerView: some View {
           VStack(alignment: .leading, spacing: 8) {
               Label("Donation Type", systemImage: "tag.fill")
                   .font(.caption)
                   .fontWeight(.medium)
                   .foregroundColor(Color.black)
               
               Picker("Donation Type", selection: $donationType) {
                   ForEach(donationTypes, id: \.self) { type in
                       Text(type).tag(type)
                   }
               }
               .pickerStyle(.segmented)
               .tint(RamaTheme.primary)
           }
       }
       
       private var paymentModePickerView: some View {
           VStack(alignment: .leading, spacing: 8) {
               Label("Payment Method", systemImage: "creditcard.fill")
                   .font(.caption)
                   .fontWeight(.medium)
                   .foregroundColor(Color.black)
               
               Picker("Payment Mode", selection: $paymentMode) {
                   ForEach(paymentModes, id: \.self) { mode in
                       Text(mode).tag(mode)
                   }
               }
               .pickerStyle(.segmented)
               .onChange(of: paymentMode) { _, newValue in
                   if newValue == "Zelle" { showZelleQR = true }
               }
           }
       }
       
       private var referenceFieldView: some View {
           VStack(alignment: .leading, spacing: 8) {
               RamaTextField(
                   title: isReferenceRequired ? "Reference Number *" : "Reference Number",
                   text: $referenceNo,
                   icon: "number.circle.fill",
                   placeholder: isReferenceRequired ? "Required for \(paymentMode)" : "Optional"
               )
               .focused($focusedField, equals: .referenceNo)
               
               if isReferenceRequired && referenceNo.isEmpty {
                   HStack(spacing: 6) {
                       Image(systemName: "exclamationmark.triangle.fill").font(.caption)
                       Text("Reference number is required for \(paymentMode)").font(.caption)
                   }
                   .foregroundColor(.red)
                   .frame(maxWidth: .infinity, alignment: .leading)
               }
           }
       }
       
       private var notesFieldView: some View {
           VStack(alignment: .leading, spacing: 8) {
               Label("Notes (Optional)", systemImage: "note.text")
                   .font(.caption)
                   .fontWeight(.medium)
                   .foregroundColor(Color.black)
               
               ZStack(alignment: .topLeading) {
                   if notes.isEmpty {
                       Text("Add any additional notes...")
                           .foregroundColor(.gray.opacity(0.5))
                           .padding(.horizontal, 12)
                           .padding(.vertical, 12)
                   }
                   
                   TextEditor(text: $notes)
                       .frame(minHeight: 80)
                       .scrollContentBackground(.hidden)
                       .padding(8)
                       .background(Color(.systemGray6))
                       .cornerRadius(12)
                       .focused($focusedField, equals: .notes)
               }
           }
       }
       
       @ViewBuilder
       private var statusMessageView: some View {
           if let status = statusMessage {
               HStack(spacing: 12) {
                   Image(systemName: isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                       .font(.title3)
                   Text(status)
                       .font(.subheadline)
                       .fontWeight(.medium)
               }
               .foregroundColor(isSuccess ? .green : .red)
               .padding()
               .frame(maxWidth: .infinity)
               .background(isSuccess ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
               .cornerRadius(12)
               .transition(.scale.combined(with: .opacity))
           }
       }
       
       private var saveButtonView: some View {
           Button(action: submit) {
               HStack(spacing: 12) {
                   if isSubmitting {
                       ProgressView().tint(.white)
                   } else {
                       Image(systemName: "checkmark.circle.fill").font(.title3)
                       Text("Save Donation").fontWeight(.semibold).font(.headline)
                   }
               }
               .frame(maxWidth: .infinity)
               .padding(.vertical, 16)
               .background(isFormValid && !isSubmitting ? RamaTheme.primary : Color.gray.opacity(0.5))
               .foregroundColor(.white)
               .cornerRadius(16)
               .shadow(
                   color: isFormValid && !isSubmitting ? RamaTheme.primary.opacity(0.4) : Color.clear,
                   radius: 8, x: 0, y: 4
               )
           }
           .disabled(!isFormValid || isSubmitting)
           .animation(.easeInOut, value: isFormValid)
           .padding(.top, 8)
       }
    
    var isReferenceRequired: Bool {
            paymentMode != "Cash"
        }

        var isFormValid: Bool {
            let hasName = isOrganization
                ? !organizationName.trimmingCharacters(in: .whitespaces).isEmpty
                : (!firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
                   !lastName.trimmingCharacters(in: .whitespaces).isEmpty)
            let hasAmount = Double(amount) != nil && Double(amount)! > 0
            let hasReferenceIfNeeded = !isReferenceRequired || !referenceNo.trimmingCharacters(in: .whitespaces).isEmpty
            return hasName && hasAmount && hasReferenceIfNeeded
        }

        // MARK: - Functions
        
        func submit() {
            guard let amt = Double(amount), amt > 0 else {
                withAnimation {
                    statusMessage = "Please enter a valid amount."
                    isSuccess = false
                }
                return
            }

            let donorDto = QuickDonorDto(
                firstName: firstName.trimmingCharacters(in: .whitespaces),
                lastName: lastName.trimmingCharacters(in: .whitespaces),
                phone: phone.isEmpty ? nil : phone,
                email: email.isEmpty ? nil : email,
                address1: address1.isEmpty ? nil : address1,
                address2: address2.isEmpty ? nil : address2,
                city: city.isEmpty ? nil : city,
                state: stateText.isEmpty ? nil : stateText,
                country: country.isEmpty ? nil : country,
                postalCode: postalCode.isEmpty ? nil : postalCode,
                isOrganization: isOrganization,
                organizationName: organizationName.isEmpty ? nil : organizationName,
                donorType: isOrganization ? "Organization" : "Individual"
            )

            let donationDto = QuickDonationDto(
                donationAmt: amt,
                donationType: donationType,
                dateOfDonation: Date(),
                paymentMode: paymentMode,
                referenceNo: referenceNo.isEmpty ? nil : referenceNo,
                notes: notes.isEmpty ? nil : notes
            )

            let payload = QuickDonorAndDonationRequest(donor: donorDto, donation: donationDto)

            isSubmitting = true
            statusMessage = nil
            isSuccess = false

            Task {
                do {
                    let _ = try await QuickDonationApi.shared.submitQuickDonation(payload)
                    await MainActor.run {
                        withAnimation {
                            statusMessage = "Donation saved and receipt sent!"
                            isSuccess = true
                        }
                        isSubmitting = false
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            clearForm()
                            withAnimation {
                                statusMessage = nil
                            }
                        }
                    }
                } catch {
                    await MainActor.run {
                        withAnimation {
                            statusMessage = "Failed: \(error.localizedDescription)"
                            isSuccess = false
                        }
                        isSubmitting = false
                    }
                }
            }
        }
        
        func clearForm() {
            firstName = ""
            lastName = ""
            organizationName = ""
            phone = ""
            email = ""
            address1 = ""
            address2 = ""
            city = ""
            stateText = ""
            postalCode = ""
            amount = ""
            referenceNo = ""
            notes = ""
            isOrganization = false
            donationType = "General"
            paymentMode = "Cash"
            country = "USA"
        }
    }

    // MARK: - Supporting Views

    struct SectionCard<Content: View>: View {
        let title: String
        let icon: String
        let content: Content
        
        init(title: String, icon: String, @ViewBuilder content: () -> Content) {
            self.title = title
            self.icon = icon
            self.content = content()
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(.red)
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.red)
                }
                
                content
            }
            .padding()
            .background(RamaTheme.card)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        }
    }

    struct RamaTextField: View {
        let title: String
        @Binding var text: String
        var icon: String = ""
        var placeholder: String = ""
        var keyboard: UIKeyboardType = .default

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                if !icon.isEmpty {
                    Label(title, systemImage: icon)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color.black.opacity(1.0))
                } else {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color.black.opacity(1.0))
                }
                
                HStack(spacing: 12) {
                    if !icon.isEmpty {
                        Image(systemName: icon)
                            .foregroundColor(RamaTheme.primary.opacity(1.0))
                            .frame(width: 20)
                    }
                    
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboard)
                        .autocapitalization(keyboard == .emailAddress ? .none : .words)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
        }
    }

    struct ZelleQRView: View {
        @Environment(\.dismiss) var dismiss
        
        var body: some View {
            NavigationView {
                ZStack {
                    RamaTheme.background.ignoresSafeArea()
                    
                    VStack(spacing: 32) {
                        VStack(spacing: 12) {
                            Image(systemName: "qrcode")
                                .font(.system(size: 60))
                                .foregroundColor(RamaTheme.primary)
                            
                            Text("Scan to Pay via Zelle")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(RamaTheme.primary)
                        }
                        
                        // QR Code placeholder
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                                .frame(width: 280, height: 280)
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                            
                            Image("zelle-qr")  // Add your Zelle QR image to Assets.xcassets
                                .resizable()
                                .scaledToFit()
                                .frame(width: 260, height: 260)
                                .cornerRadius(16)
                        }
                        
                        VStack(spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(RamaTheme.primary)
                                Text("Instructions")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            
                            Text("After completing the payment, please enter the transaction reference number in the donation form")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .padding()
                        .background(RamaTheme.primary.opacity(0.1))
                        .cornerRadius(12)
                        
                        Button(action: { dismiss() }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Done")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RamaTheme.primary)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 32)
                    }
                    .padding()
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    struct AddDonationView_Previews: PreviewProvider {
        static var previews: some View {
            NavigationView {
                AddDonationView()
            }
        }
    }
