import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers

class ShareViewController: SLComposeServiceViewController {
    
    let appGroupId = "group.com.example.tooManyTabs"
    let sharedDefaultsKey = "shared_database_path"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set placeholder text
        placeholder = "Share database file"
        
        // Customize the UI
        navigationController?.navigationBar.topItem?.rightBarButtonItem?.title = "Import"
    }
    
    override func isContentValid() -> Bool {
        // Basic validation
        return true
    }
    
    override func didSelectPost() {
        // Show loading indicator
        showLoadingIndicator()
        
        // Process the shared item
        processSharedItems()
    }
    
    private func processSharedItems() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProvider = extensionItem.attachments?.first else {
            completeRequest(success: false, message: "No file attached")
            return
        }
        
        // Check for file URL
        let fileType = UTType.data.identifier
        
        if itemProvider.hasItemConformingToTypeIdentifier(fileType) {
            itemProvider.loadItem(forTypeIdentifier: fileType, options: nil) { [weak self] (item, error) in
                guard let self = self else { return }
                
                if let error = error {
                    self.completeRequest(success: false, message: "Error loading file: \(error.localizedDescription)")
                    return
                }
                
                if let url = item as? URL {
                    self.handleFileURL(url)
                } else if let data = item as? Data {
                    self.handleFileData(data)
                } else {
                    self.completeRequest(success: false, message: "Unsupported file format")
                }
            }
        } else {
            completeRequest(success: false, message: "No valid file found")
        }
    }
    
    private func handleFileURL(_ url: URL) {
        // Validate it's a database file
        let fileExtension = url.pathExtension.lowercased()
        guard fileExtension == "db" || fileExtension == "sqlite" || fileExtension == "sqlite3" else {
            completeRequest(success: false, message: "Please share a valid SQLite database file (.db, .sqlite, or .sqlite3)")
            return
        }
        
        // Copy file to shared container
        guard let sharedContainerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            completeRequest(success: false, message: "Failed to access shared container")
            return
        }
        
        let fileName = "shared_database_\(Date().timeIntervalSince1970).db"
        let destinationURL = sharedContainerURL.appendingPathComponent(fileName)
        
        do {
            // Remove existing file if any
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            // Copy the file
            try FileManager.default.copyItem(at: url, to: destinationURL)
            
            // Save the path to UserDefaults (App Group)
            saveSharedDatabasePath(destinationURL.path)
            
            // Notify the main app
            notifyMainApp()
            
            completeRequest(success: true, message: "Database imported successfully!")
            
        } catch {
            completeRequest(success: false, message: "Failed to copy file: \(error.localizedDescription)")
        }
    }
    
    private func handleFileData(_ data: Data) {
        // Save data to shared container
        guard let sharedContainerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            completeRequest(success: false, message: "Failed to access shared container")
            return
        }
        
        let fileName = "shared_database_\(Date().timeIntervalSince1970).db"
        let destinationURL = sharedContainerURL.appendingPathComponent(fileName)
        
        do {
            try data.write(to: destinationURL)
            saveSharedDatabasePath(destinationURL.path)
            notifyMainApp()
            completeRequest(success: true, message: "Database imported successfully!")
        } catch {
            completeRequest(success: false, message: "Failed to save file: \(error.localizedDescription)")
        }
    }
    
    private func saveSharedDatabasePath(_ path: String) {
        let sharedDefaults = UserDefaults(suiteName: appGroupId)
        sharedDefaults?.set(path, forKey: sharedDefaultsKey)
        sharedDefaults?.set(Date().timeIntervalSince1970, forKey: "shared_database_timestamp")
        sharedDefaults?.synchronize()
    }
    
    private func notifyMainApp() {
        // Open the main app with a custom URL scheme
        let url = URL(string: "tooManyTabs://import-database")!
        
        var responder: UIResponder? = self as UIResponder
        let selector = #selector(openURL(_:))
        
        while responder != nil {
            if responder!.responds(to: selector) && responder != self {
                responder!.perform(selector, with: url, afterDelay: 0)
                break
            }
            responder = responder?.next
        }
    }
    
    @objc private func openURL(_ url: URL) {
        // This will be called by the extension context
    }
    
    private func showLoadingIndicator() {
        // Disable post button while processing
        navigationController?.navigationBar.topItem?.rightBarButtonItem?.isEnabled = false
    }
    
    private func completeRequest(success: Bool, message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if success {
                // Show success message briefly before closing
                let alert = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
                self.present(alert, animated: true) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        alert.dismiss(animated: true) {
                            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                        }
                    }
                }
            } else {
                // Show error message
                let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                    self.extensionContext?.cancelRequest(withError: NSError(domain: "ShareExtension", code: -1, userInfo: nil))
                })
                self.present(alert, animated: true)
            }
        }
    }
    
    override func configurationItems() -> [Any]! {
        // To add configuration options later if needed
        return []
    }
}
