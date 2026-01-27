import SwiftUI
import PhotosUI
import MessageUI

struct SupportView: View {
    @Environment(\.dismiss) var dismiss
    @State private var issueTitle: String = ""
    @State private var issueDescription: String = ""
    @State private var selectedCategory: IssueCategory = .bug
    @State private var selectedImage: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var showImagePicker = false
    @State private var showMailComposer = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    enum IssueCategory: String, CaseIterable {
        case bug = "Bug Report"
        case feature = "Feature Request"
        case question = "Question"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .bug: return "ladybug.fill"
            case .feature: return "lightbulb.fill"
            case .question: return "questionmark.circle.fill"
            case .other: return "ellipsis.circle.fill"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Issue Type")) {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(IssueCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text("Details")) {
                    TextField("Title", text: $issueTitle)
                        .autocapitalization(.sentences)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextEditor(text: $issueDescription)
                            .frame(height: 150)
                    }
                }
                
                Section(header: Text("Screenshot (Optional)")) {
                    if let imageData = selectedImageData,
                       let uiImage = UIImage(data: imageData) {
                        // Show selected image
                        VStack(spacing: 12) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .cornerRadius(8)
                            
                            Button(role: .destructive) {
                                selectedImage = nil
                                selectedImageData = nil
                            } label: {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Remove Screenshot")
                                }
                            }
                        }
                    } else {
                        // Image picker button
                        PhotosPicker(selection: $selectedImage, matching: .images) {
                            HStack {
                                Image(systemName: "photo.on.rectangle.angled")
                                Text("Add Screenshot")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onChange(of: selectedImage) { oldValue, newValue in
                            Task {
                                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                    selectedImageData = data
                                }
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: submitIssue) {
                        HStack {
                            Spacer()
                            Text("Submit Issue")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(issueTitle.isEmpty || issueDescription.isEmpty)
                }
                
                Section(header: Text("App Information")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("iOS Version")
                        Spacer()
                        Text(UIDevice.current.systemVersion)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Device")
                        Spacer()
                        Text(UIDevice.current.model)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Report an Issue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Issue Submission", isPresented: $showAlert) {
                Button("OK", role: .cancel) {
                    if alertMessage.contains("successfully") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showMailComposer) {
                if MFMailComposeViewController.canSendMail() {
                    MailComposeView(
                        category: selectedCategory,
                        title: issueTitle,
                        description: issueDescription,
                        imageData: selectedImageData
                    )
                }
            }
        }
    }
    
    private func submitIssue() {
        // Check if mail is available
        if MFMailComposeViewController.canSendMail() {
            showMailComposer = true
        } else {
            // Fallback: copy to clipboard
            let issueText = """
            Issue Type: \(selectedCategory.rawValue)
            Title: \(issueTitle)
            Description: \(issueDescription)
            
            App Version: 1.0.0
            iOS Version: \(UIDevice.current.systemVersion)
            Device: \(UIDevice.current.model)
            """
            
            UIPasteboard.general.string = issueText
            alertMessage = "Mail is not configured on this device. Issue details have been copied to your clipboard. Please email them to sethdowd@gmail.com"
            showAlert = true
        }
    }
}

// MARK: - Mail Compose View

struct MailComposeView: UIViewControllerRepresentable {
    @Environment(\.dismiss) var dismiss
    
    let category: SupportView.IssueCategory
    let title: String
    let description: String
    let imageData: Data?
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        
        // Email configuration
        composer.setToRecipients(["sethdowd@gmail.com"]) // Replace with your support email
        composer.setSubject("[\(category.rawValue)] \(title)")
        
        // Email body with app info
        let body = """
        \(description)
        
        ---
        App Information:
        - Version: 1.0.0
        - Build: 1
        - iOS: \(UIDevice.current.systemVersion)
        - Device: \(UIDevice.current.model)
        """
        
        composer.setMessageBody(body, isHTML: false)
        
        // Attach screenshot if available
        if let imageData = imageData,
           let image = UIImage(data: imageData),
           let jpegData = image.jpegData(compressionQuality: 0.8) {
            composer.addAttachmentData(jpegData, mimeType: "image/jpeg", fileName: "screenshot.jpg")
        }
        
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposeView
        
        init(_ parent: MailComposeView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.dismiss()
        }
    }
}

// MARK: - Preview
#Preview {
    SupportView()
}
