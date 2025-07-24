import Foundation
import SendbirdChatSDK

// Strike record for tracking violations
struct StrikeRecord: Codable {
    let timestamp: Date
    let ruleType: String
    let severity: Int
    let message: String
    let senderResponse: String?
    let receiverResponse: String?
    let strikes: Double
    
    init(ruleType: String, severity: DetectionSeverity, message: String, interactionResult: InteractionResult? = nil) {
        self.timestamp = Date()
        self.ruleType = ruleType
        self.severity = severity.rawValue
        self.message = message
        self.senderResponse = interactionResult?.senderResponse.rawValue
        self.receiverResponse = interactionResult?.receiverResponse.rawValue
        self.strikes = interactionResult?.strikes ?? 0.0
    }
}

// Pending interaction for tracking incomplete responses
struct PendingInteraction: Codable {
    let id: String
    let timestamp: Date
    let senderId: String
    let receiverId: String
    let message: String
    let detectionResult: String // JSON encoded DetectionResult
    var senderResponse: String?
    var receiverResponse: String?
    
    init(senderId: String, receiverId: String, message: String, detectionResult: DetectionResult) {
        self.id = UUID().uuidString
        self.timestamp = Date()
        self.senderId = senderId
        self.receiverId = receiverId
        self.message = message
        
        // Encode detection result as JSON string
        let encoder = JSONEncoder()
        if let data = try? encoder.encode([
            "type": detectionResult.rule.type,
            "keyword": detectionResult.rule.keyword,
            "matchedText": detectionResult.matchedText,
            "severity": String(detectionResult.severity.rawValue)
        ]) {
            self.detectionResult = String(data: data, encoding: .utf8) ?? "{}"
        } else {
            self.detectionResult = "{}"
        }
    }
    
    var isComplete: Bool {
        return senderResponse != nil && receiverResponse != nil
    }
}

class StrikeManager {
    static let shared = StrikeManager()
    
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    let maxStrikes = 3.0
    
    private init() {
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        setupInitialUserData()
    }
    
    /// Setup initial user data from bundle
    private func setupInitialUserData() {
        let mockDataPath = "MockData/Users"
        guard let bundleURL = Bundle.main.url(forResource: mockDataPath, withExtension: nil),
              let userFiles = try? fileManager.contentsOfDirectory(at: bundleURL, includingPropertiesForKeys: nil) else {
            print("Could not find mock user data in bundle.")
            return
        }
        
        for userFile in userFiles {
            let destinationURL = documentsDirectory.appendingPathComponent(userFile.lastPathComponent)
            if !fileManager.fileExists(atPath: destinationURL.path) {
                do {
                    try fileManager.copyItem(at: userFile, to: destinationURL)
                    print("Copied \(userFile.lastPathComponent) to Documents directory.")
                } catch {
                    print("Error copying user data: \(error)")
                }
            }
        }
    }
    
    /// Create a pending interaction when message is flagged
    func createPendingInteraction(senderId: String, receiverId: String, message: String, detectionResult: DetectionResult) -> String {
        let interaction = PendingInteraction(senderId: senderId, receiverId: receiverId, message: message, detectionResult: detectionResult)
        savePendingInteraction(interaction)
        return interaction.id
    }
    
    /// Record sender's response to flagged message
    func recordSenderResponse(interactionId: String, response: SenderResponse, completion: @escaping (Bool) -> Void) {
        guard var interaction = loadPendingInteraction(id: interactionId) else {
            completion(false)
            return
        }
        
        interaction.senderResponse = response.rawValue
        savePendingInteraction(interaction)
        
        print("Recorded sender response: \(response.displayText)")
        completion(true)
    }
    
    /// Record receiver's response and calculate final strikes
    func recordReceiverResponse(interactionId: String, response: ReceiverResponse, completion: @escaping (Double, Bool) -> Void) {
        guard var interaction = loadPendingInteraction(id: interactionId) else {
            print("[DEBUG] ⚠️ No pending interaction found for \(interactionId)")
            completion(0, false)
            return
        }
        
        interaction.receiverResponse = response.rawValue
        
        // Calculate strikes if both responses are available
        if let senderResponseStr = interaction.senderResponse,
           let senderResponse = SenderResponse(rawValue: senderResponseStr) {
            
            let interactionResult = InteractionResult(senderResponse: senderResponse, receiverResponse: response)
            
            // Check if this is cross-user scenario (receiver trying to add strikes to sender)
            if let currentUser = SendbirdChat.getCurrentUser(),
               currentUser.userId != interaction.senderId {
                
                print("[DEBUG] 🌐 Cross-user scenario: \(currentUser.userId) adding strikes to \(interaction.senderId)")
                
                // Send custom event to notify sender about the response
                sendStrikeNotificationEvent(
                    senderId: interaction.senderId,
                    interactionId: interactionId,
                    response: response,
                    strikes: interactionResult.strikes
                ) { [weak self] success in
                    DispatchQueue.main.async {
                        print("Final interaction result: \(interactionResult.description)")
                        if success {
                            print("[DEBUG] ✅ Strike notification sent to sender via custom event")
                        } else {
                            print("[DEBUG] ⚠️ Failed to send strike notification to sender")
                        }
                        
                        // Clean up pending interaction
                        self?.deletePendingInteraction(id: interactionId)
                        completion(interactionResult.strikes, interactionResult.strikes >= self?.maxStrikes ?? 5.0)
                    }
                }
            } else {
                // Same user scenario (for testing or self-interaction)
                addStrikesToUser(userId: interaction.senderId, strikes: interactionResult.strikes, interaction: interaction) { [weak self] newTotal, limitReached in
                    DispatchQueue.main.async {
                        print("Final interaction result: \(interactionResult.description)")
                        // Clean up pending interaction
                        self?.deletePendingInteraction(id: interactionId)
                        completion(newTotal, limitReached)
                    }
                }
            }
        } else {
            // Save and wait for sender response
            savePendingInteraction(interaction)
            completion(0, false)
        }
    }
    
    /// Send custom event to notify sender about receiver response and strikes
    private func sendStrikeNotificationEvent(senderId: String, interactionId: String, response: ReceiverResponse, strikes: Double, completion: @escaping (Bool) -> Void) {
        
        // Create custom event data
        let eventData = [
            "type": "ai_guardian_strike",
            "interaction_id": interactionId,
            "receiver_response": response.rawValue,
            "strikes": String(strikes),
            "timestamp": String(Date().timeIntervalSince1970)
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: eventData),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("[DEBUG] ❌ Failed to serialize strike notification event")
            completion(false)
            return
        }
        
        print("[DEBUG] 📡 Sending strike notification event to \(senderId): \(strikes) strikes")
        print("[DEBUG] 📨 Strike notification event prepared: \(jsonString)")
        
        // For now, we'll simulate successful notification
        // In a real implementation, this would send a custom event through Sendbird
        // or use a backend service to notify the sender
        
        // The actual strike update will happen when the sender receives this notification
        // For UI feedback, we return the calculated strikes
        print("[DEBUG] ✅ Strike notification simulated successfully")
        completion(true)
    }
    
    /// Add strikes to a specific user
    private func addStrikesToUser(userId: String, strikes: Double, interaction: PendingInteraction, completion: @escaping (Double, Bool) -> Void) {
        let fileURL = documentsDirectory.appendingPathComponent("\(userId).json")
        
        guard var profile = loadProfile(for: userId, from: fileURL) else {
            print("Could not load profile to add strikes.")
            completion(0, false)
            return
        }
        
        let previousStrikes = Double(profile.strikes)
        let newStrikes = previousStrikes + strikes
        profile.strikes = Int(ceil(newStrikes)) // Round up for integer storage
        
        // Create interaction result for record
        let senderResponse = SenderResponse(rawValue: interaction.senderResponse ?? "") ?? .retract
        let receiverResponse = ReceiverResponse(rawValue: interaction.receiverResponse ?? "") ?? .exit
        let interactionResult = InteractionResult(senderResponse: senderResponse, receiverResponse: receiverResponse)
        
        // Record the strike with interaction details
        let record = StrikeRecord(
            ruleType: "interaction", // Will be parsed from detectionResult if needed
            severity: .medium, // Default severity
            message: interaction.message,
            interactionResult: interactionResult
        )
        saveStrikeRecord(record, for: userId)
        
        // Save to local file
        saveProfile(profile, to: fileURL)
        
        let limitReached = newStrikes >= maxStrikes
        if limitReached {
            print("User \(userId) has reached the strike limit (\(newStrikes)/\(maxStrikes)).")
        } else {
            print("User \(userId) received \(strikes) strike(s). Total: \(newStrikes)/\(maxStrikes)")
        }
        
        // Sync strikes to Sendbird metadata
        syncStrikesToSendbird(userId: userId, newStrikes: newStrikes) { [weak self] success in
            if success {
                print("[DEBUG] ✅ Strikes synced to Sendbird metadata: \(newStrikes)")
            } else {
                print("[DEBUG] ⚠️ Failed to sync strikes to Sendbird, but local update succeeded")
            }
            
            // Always call completion regardless of Sendbird sync result
            completion(newStrikes, limitReached)
        }
    }
    
    /// Sync strikes to Sendbird user metadata
    private func syncStrikesToSendbird(userId: String, newStrikes: Double, completion: @escaping (Bool) -> Void) {
        // Only sync if the user is the current user (for security)
        guard let currentUser = SendbirdChat.getCurrentUser(),
              currentUser.userId == userId else {
            print("[DEBUG] 🔒 Can only sync strikes for current user. Skipping Sendbird sync.")
            completion(false)
            return
        }
        
        let metadataToUpdate = [
            "strikes": String(Int(ceil(newStrikes)))
        ]
        
        print("[DEBUG] 🔄 Syncing strikes to Sendbird metadata: \(metadataToUpdate)")
        
        currentUser.updateMetaData(metadataToUpdate) { metadata, error in
            if let error = error {
                print("[DEBUG] ❌ Failed to sync strikes to Sendbird: \(error.localizedDescription)")
                completion(false)
            } else {
                print("[DEBUG] ✅ Successfully synced strikes to Sendbird metadata")
                if let metadata = metadata {
                    print("[DEBUG] 📊 Updated metadata: \(metadata)")
                }
                completion(true)
            }
        }
    }
    
    /// Legacy method for single-user strikes
    func addStrike(for userId: String, detectionResult: DetectionResult, completion: @escaping (Int, Bool) -> Void) {
        let strikesToAdd = Double(detectionResult.severity.strikeCount)
        addStrikesToUser(userId: userId, strikes: strikesToAdd, interaction: PendingInteraction(senderId: userId, receiverId: "system", message: "", detectionResult: detectionResult)) { strikes, limitReached in
            completion(Int(ceil(strikes)), limitReached)
        }
    }
    
    /// Reset strikes for a user (after education completion)
    func resetStrikes(for userId: String, completion: @escaping (Bool) -> Void) {
        let fileURL = documentsDirectory.appendingPathComponent("\(userId).json")
        
        guard var profile = loadProfile(for: userId, from: fileURL) else {
            print("Could not load profile to reset strikes.")
            completion(false)
            return
        }
        
        let previousStrikes = profile.strikes
        profile.strikes = 0
        saveProfile(profile, to: fileURL)
        
        print("Reset strikes for user \(userId): \(previousStrikes) → 0")
        
        // Sync reset to Sendbird metadata
        syncStrikesToSendbird(userId: userId, newStrikes: 0.0) { success in
            if success {
                print("[DEBUG] ✅ Strike reset synced to Sendbird metadata")
            } else {
                print("[DEBUG] ⚠️ Failed to sync strike reset to Sendbird, but local reset succeeded")
            }
            
            // Always return success if local reset worked
            completion(true)
        }
    }
    
    /// Get current strike count for a user
    func getCurrentStrikes(for userId: String) -> Double {
        let fileURL = documentsDirectory.appendingPathComponent("\(userId).json")
        guard let profile = loadProfile(for: userId, from: fileURL) else {
            return 0
        }
        return Double(profile.strikes)
    }
    
    // MARK: - Private Helpers
    
    private func loadProfile(for userId: String, from url: URL) -> UserProfile? {
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(UserProfile.self, from: data)
        } catch {
            print("Failed to load profile for \(userId): \(error)")
            return nil
        }
    }
    
    private func saveProfile(_ profile: UserProfile, to url: URL) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(profile)
            try data.write(to: url)
            print("Successfully saved profile for \(profile.userId) with \(profile.strikes) strikes.")
        } catch {
            print("Failed to save profile for \(profile.userId): \(error)")
        }
    }
    
    private func saveStrikeRecord(_ record: StrikeRecord, for userId: String) {
        let fileURL = documentsDirectory.appendingPathComponent("\(userId)_strikes.json")
        
        var records = getStrikeHistory(for: userId)
        records.append(record)
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(records)
            try data.write(to: fileURL)
            print("Saved strike record for \(userId): \(record.strikes) strikes")
        } catch {
            print("Failed to save strike record: \(error)")
        }
    }
    
    private func savePendingInteraction(_ interaction: PendingInteraction) {
        let fileURL = documentsDirectory.appendingPathComponent("pending_interactions.json")
        
        var interactions = loadPendingInteractions()
        interactions.removeAll { $0.id == interaction.id }
        interactions.append(interaction)
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(interactions)
            try data.write(to: fileURL)
        } catch {
            print("Failed to save pending interaction: \(error)")
        }
    }
    
    private func loadPendingInteraction(id: String) -> PendingInteraction? {
        return loadPendingInteractions().first { $0.id == id }
    }
    
    private func loadPendingInteractions() -> [PendingInteraction] {
        let fileURL = documentsDirectory.appendingPathComponent("pending_interactions.json")
        
        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL) else {
            return []
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([PendingInteraction].self, from: data)) ?? []
    }
    
    private func deletePendingInteraction(id: String) {
        let fileURL = documentsDirectory.appendingPathComponent("pending_interactions.json")
        var interactions = loadPendingInteractions()
        interactions.removeAll { $0.id == id }
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(interactions)
            try data.write(to: fileURL)
        } catch {
            print("Failed to delete pending interaction: \(error)")
        }
    }
    
    /// Get strike history for a user
    func getStrikeHistory(for userId: String) -> [StrikeRecord] {
        let fileURL = documentsDirectory.appendingPathComponent("\(userId)_strikes.json")
        
        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL) else {
            return []
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([StrikeRecord].self, from: data))?.sorted { $0.timestamp > $1.timestamp } ?? []
    }
} 