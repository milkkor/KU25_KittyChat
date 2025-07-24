import UIKit
import Foundation
import SendbirdChatSDK
import SendbirdUIKit

// Delegate protocol for interaction events
protocol BiDirectionalInteractionDelegate: AnyObject {
    func interactionManager(_ manager: BiDirectionalInteractionManager, didSendMessage message: String, parentMessage: BaseMessage?)
    func interactionManager(_ manager: BiDirectionalInteractionManager, didCompleteInteractionWithStrikes strikes: Double, limitReached: Bool)
    func interactionManager(_ manager: BiDirectionalInteractionManager, didRequestEducationModule completion: @escaping () -> Void)
    func interactionManager(_ manager: BiDirectionalInteractionManager, didRequestConversationExit reason: String)
    func interactionManager(_ manager: BiDirectionalInteractionManager, didShowMessage title: String, message: String)
    func interactionManager(_ manager: BiDirectionalInteractionManager, didClearMessageInput: Void)
    func interactionManager(_ manager: BiDirectionalInteractionManager, didRestoreMessageInput message: String)
}

class BiDirectionalInteractionManager {
    
    weak var delegate: BiDirectionalInteractionDelegate?
    private weak var presentingViewController: UIViewController?
    private var currentInteractionId: String?
    
    init(presentingViewController: UIViewController) {
        self.presentingViewController = presentingViewController
    }
    
    // MARK: - Public Methods
    
    /// Handle a flagged message with the bidirectional interaction system
    func handleFlaggedMessage(
        originalMessage: String,
        detectionResult: DetectionResult,
        senderId: String,
        receiverId: String,
        parentMessage: BaseMessage? = nil
    ) {
        // Create pending interaction
        let interactionId = StrikeManager.shared.createPendingInteraction(
            senderId: senderId,
            receiverId: receiverId,
            message: originalMessage,
            detectionResult: detectionResult
        )
        
        self.currentInteractionId = interactionId
        
        // Show sender's choice dialog
        showSenderActionSheet(
            for: originalMessage,
            detectionResult: detectionResult,
            interactionId: interactionId,
            parentMessage: parentMessage
        )
    }
    
    /// Handle received flagged message (for receiver's device)
    func handleReceivedFlaggedMessage(interactionId: String, message: String) {
        print("[DEBUG] BiDirectionalInteractionManager: handleReceivedFlaggedMessage called")
        print("[DEBUG] Interaction ID: \(interactionId)")
        print("[DEBUG] Message: '\(message)'")
        print("[DEBUG] Presenting ViewController exists: \(presentingViewController != nil)")
        showReceiverActionSheet(interactionId: interactionId, sentMessage: message)
    }
    
    /// Get current interaction ID for message metadata
    func getCurrentInteractionId() -> String? {
        return currentInteractionId
    }
    
    // MARK: - Private Methods - Sender Interaction
    
    /// Show sender's action sheet (first step)
    private func showSenderActionSheet(
        for originalMessage: String,
        detectionResult: DetectionResult,
        interactionId: String,
        parentMessage: BaseMessage?
    ) {
        guard let viewController = presentingViewController else { return }
        
        let alertController = UIAlertController(
            title: "⚠️ Message Flagged",
            message: "\(detectionResult.suggestion)\n\nFlagged content: \"\(detectionResult.matchedText)\"",
            preferredStyle: .actionSheet
        )
        
        // Retract action
        let retractAction = UIAlertAction(title: SenderResponse.retract.displayText, style: .destructive) { [weak self] _ in
            self?.handleSenderResponse(.retract, interactionId: interactionId, originalMessage: originalMessage, parentMessage: parentMessage)
        }
        
        // Edit action
        let editAction = UIAlertAction(title: SenderResponse.edit.displayText, style: .default) { [weak self] _ in
            self?.handleSenderResponse(.edit, interactionId: interactionId, originalMessage: originalMessage, parentMessage: parentMessage)
        }
        
        // Just joking action
        let jokingAction = UIAlertAction(title: SenderResponse.justJoking.displayText, style: .default) { [weak self] _ in
            self?.handleSenderResponse(.justJoking, interactionId: interactionId, originalMessage: originalMessage, parentMessage: parentMessage)
        }
        
        alertController.addAction(retractAction)
        alertController.addAction(editAction)
        alertController.addAction(jokingAction)
        
        viewController.present(alertController, animated: true)
    }
    
    /// Handle sender's response and proceed based on choice
    private func handleSenderResponse(
        _ response: SenderResponse,
        interactionId: String,
        originalMessage: String,
        parentMessage: BaseMessage?
    ) {
        // Record sender's response
        StrikeManager.shared.recordSenderResponse(interactionId: interactionId, response: response) { [weak self] success in
            DispatchQueue.main.async {
                guard success else {
                    print("Failed to record sender response")
                    return
                }
                
                switch response {
                case .retract:
                    // Message is cancelled - no strikes, no receiver interaction needed
                    self?.delegate?.interactionManager(self!, didClearMessageInput: ())
                    self?.cleanupInteraction(interactionId: interactionId)
                    
                case .edit:
                    // Put message back for editing - no strikes, no receiver interaction needed
                    self?.delegate?.interactionManager(self!, didRestoreMessageInput: originalMessage)
                    self?.cleanupInteraction(interactionId: interactionId)
                    
                case .justJoking:
                    // Send the message anyway - receiver will handle their own response
                    self?.sendFlaggedMessage(originalMessage, parentMessage: parentMessage)
                }
            }
        }
    }
    
    // MARK: - Private Methods - Message Sending
    
    /// Send message with flagged metadata
    private func sendFlaggedMessage(_ originalMessage: String, parentMessage: BaseMessage?) {
        delegate?.interactionManager(self, didSendMessage: originalMessage, parentMessage: parentMessage)
    }
    
    // MARK: - Private Methods - Receiver Interaction
    
    /// Show receiver's action sheet (second step)
    private func showReceiverActionSheet(interactionId: String, sentMessage: String) {
        print("[DEBUG] showReceiverActionSheet called")
        print("[DEBUG] Interaction ID: \(interactionId)")
        print("[DEBUG] Sent message: '\(sentMessage)'")
        
        guard let viewController = presentingViewController else {
            print("[DEBUG] ❌ No presenting view controller available")
            return
        }
        
        print("[DEBUG] ✅ Creating action sheet alert")
        
        let alertController = UIAlertController(
            title: "AI Guardian Alert",
            message: "A message has been flagged by AI Guardian. How do you feel about this interaction?\n\nMessage: \"\(sentMessage)\"",
            preferredStyle: .alert
        )
            
        // Acceptable response
        let acceptableAction = UIAlertAction(title: ReceiverResponse.acceptable.displayText, style: .default) { [weak self] _ in
            print("[DEBUG] Receiver chose: acceptable")
            self?.handleReceiverResponse(.acceptable, interactionId: interactionId)
        }
        
        // Uncomfortable but continue
        let uncomfortableAction = UIAlertAction(title: ReceiverResponse.uncomfortable.displayText, style: .default) { [weak self] _ in
            print("[DEBUG] Receiver chose: uncomfortable")
            self?.handleReceiverResponse(.uncomfortable, interactionId: interactionId)
        }
        
        // Exit conversation
        let exitAction = UIAlertAction(title: ReceiverResponse.exit.displayText, style: .destructive) { [weak self] _ in
            print("[DEBUG] Receiver chose: exit")
            self?.handleReceiverResponse(.exit, interactionId: interactionId)
        }
        
        alertController.addAction(acceptableAction)
        alertController.addAction(uncomfortableAction)
        alertController.addAction(exitAction)
        
        print("[DEBUG] Presenting action sheet...")
        viewController.present(alertController, animated: true) {
            print("[DEBUG] ✅ Action sheet presented successfully")
        }
    }
    
    /// Handle receiver's response and calculate final strikes
    private func handleReceiverResponse(_ response: ReceiverResponse, interactionId: String) {
        StrikeManager.shared.recordReceiverResponse(interactionId: interactionId, response: response) { [weak self] finalStrikes, limitReached in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if finalStrikes > 0 {
                    self.showInteractionResult(strikes: finalStrikes, limitReached: limitReached, receiverResponse: response)
                }
                
                self.delegate?.interactionManager(self, didCompleteInteractionWithStrikes: finalStrikes, limitReached: limitReached)
                
                if limitReached {
                    self.delegate?.interactionManager(self, didRequestEducationModule: {
                        // Education completion callback handled by delegate
                    })
                } else if response == .exit {
                    self.delegate?.interactionManager(self, didRequestConversationExit: "The other participant has chosen to exit the conversation due to inappropriate content.")
                }
            }
        }
    }
    
    // MARK: - Private Methods - UI Helpers
    
    /// Show the result of the interaction
    private func showInteractionResult(strikes: Double, limitReached: Bool, receiverResponse: ReceiverResponse) {
        let title = limitReached ? "Strike Limit Reached!" : "Interaction Recorded"
        let message = """
            Receiver response: \(receiverResponse.displayText)
            Strikes added: \(strikes)
            Total strikes: \(strikes)/3.0
            
            \(limitReached ? "Education module will be presented." : "Please be more mindful in future conversations.")
            """
        
        delegate?.interactionManager(self, didShowMessage: title, message: message)
    }
    
    /// Clean up interaction without strikes
    private func cleanupInteraction(interactionId: String) {
        // Since no strikes are involved, we can directly clean up
        DispatchQueue.global(qos: .background).async {
            // Delete the pending interaction since no strikes will be calculated
            let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("pending_interactions.json")
            
            var interactions: [PendingInteraction] = []
            if let data = try? Data(contentsOf: fileURL) {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                interactions = (try? decoder.decode([PendingInteraction].self, from: data)) ?? []
            }
            
            interactions.removeAll { $0.id == interactionId }
            
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(interactions)
                try data.write(to: fileURL)
                print("Cleaned up interaction \(interactionId) without strikes")
            } catch {
                print("Failed to cleanup interaction: \(error)")
            }
        }
    }
} 