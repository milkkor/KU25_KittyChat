import UIKit
import SendbirdUIKit
import SwiftUI
import SendbirdChatSDK

/// Simplified KittyChatChannelViewController that focuses only on sender-side AI Guardian logic
/// Receiver-side logic is handled by GlobalMessageMonitor with AIMessageRouter
class KittyChatChannelViewController: SBUGroupChannelViewController {
    
    private lazy var interactionManager: BiDirectionalInteractionManager = {
        let manager = BiDirectionalInteractionManager(presentingViewController: self)
        manager.delegate = self
        return manager
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupNavigationItem()
        print("[DEBUG] 📱 KittyChatChannelViewController: Entered chat room, current userId:", SendbirdChat.getCurrentUser()?.userId ?? "nil")
        
        // Test DetectionEngine initialization
        self.testDetectionEngine()
        
        // Register this controller as a receiver response handler for active channel
        GlobalMessageMonitor.shared.setReceiverResponseHandler(self)
        
        print("[DEBUG] ✅ KittyChatChannelViewController: Now uses GlobalMessageMonitor for message interception")
        print("[DEBUG] ✅ KittyChatChannelViewController: Focused on sender-side logic only")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Clear receiver response handler when leaving the chat
        GlobalMessageMonitor.shared.clearReceiverResponseHandler()
        print("[DEBUG] 🔗 KittyChatChannelViewController: Receiver response handler cleared")
    }
    
    private func testDetectionEngine() {
        print("[DEBUG] 🧪 Testing DetectionEngine...")
        
        // Test a known keyword
        let testMessage = "calm down"
        if let result = DetectionEngine.shared.analyzeMessage(testMessage) {
            print("[DEBUG] ✅ Detection working! Found: \(result.rule.keyword) -> \(result.rule.type)")
        } else {
            print("[DEBUG] ❌ Detection failed for test message: '\(testMessage)'")
        }
        
        // Test bundle resource
        if let url = Bundle.main.url(forResource: "DetectionRules", withExtension: "json") {
            print("[DEBUG] ✅ DetectionRules.json found at: \(url.path)")
        } else {
            print("[DEBUG] ❌ DetectionRules.json NOT found in bundle!")
        }
    }
    
    // MARK: - Sender-side Message Handling
    
    override func baseChannelModule(
        _ inputComponent: SBUBaseChannelModule.Input,
        didTapSend text: String,
        parentMessage: BaseMessage?
    ) {
        print("[DEBUG] 🚀 KittyChatChannelViewController: didTapSend called!")
        print("[DEBUG] 📝 Input text: '\(text)'")
        
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { 
            print("[DEBUG] ⚠️ Empty text, returning")
            return 
        }
        
        print("[DEBUG] 🔍 Analyzing message from userId:", SendbirdChat.getCurrentUser()?.userId ?? "nil")
        print("[DEBUG] 📝 Message content: '\(trimmedText)'")
        
        // Use AI Guardian detection system for outgoing messages
        if let detectionResult = DetectionEngine.shared.analyzeMessage(trimmedText) {
            print("[DEBUG] ⚠️ Message flagged! Severity: \(detectionResult.severity.description)")
            handleFlaggedMessage(originalMessage: trimmedText, detectionResult: detectionResult, parentMessage: parentMessage)
        } else {
            print("[DEBUG] ✅ Message is safe, sending normally")
            // Message is safe, send normally
            super.baseChannelModule(inputComponent, didTapSend: text, parentMessage: parentMessage)
        }
    }
    
    /// Handle flagged message using the interaction manager (sender-side only)
    private func handleFlaggedMessage(originalMessage: String, detectionResult: DetectionResult, parentMessage: BaseMessage?) {
        guard let currentUser = SBUGlobals.currentUser,
              let channel = self.channel,
              let receiverUserId = channel.members.first(where: { $0.userId != currentUser.userId })?.userId else {
            print("[DEBUG] ❌ Could not determine receiver for interaction")
            return
        }
        
        print("[DEBUG] 🎭 Delegating to interaction manager for sender-side handling")
        
        // Delegate to interaction manager
        interactionManager.handleFlaggedMessage(
            originalMessage: originalMessage,
            detectionResult: detectionResult,
            senderId: currentUser.userId,
            receiverId: receiverUserId,
            parentMessage: parentMessage
        )
    }
    
    // MARK: - UI Setup
    
    private func setupNavigationItem() {
        // Navigation setup - summary functionality removed
    }
    

    

}

// MARK: - ReceiverResponseHandler

extension KittyChatChannelViewController: ReceiverResponseHandler {
    
    func recordReceiverResponse(_ response: ReceiverResponse, interactionId: String) {
        print("[DEBUG] 📝 KittyChatChannelViewController: Recording receiver response '\(response.rawValue)' for interaction \(interactionId)")
        
        // Record the response directly without sending any chat messages
        StrikeManager.shared.recordReceiverResponse(interactionId: interactionId, response: response) { [weak self] finalStrikes, limitReached in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                print("[DEBUG] 🎯 KittyChatChannelViewController: Response recorded - \(finalStrikes) strikes, limit reached: \(limitReached)")
                
                // Handle consequences silently
                if limitReached {
                    print("[DEBUG] ⚠️ KittyChatChannelViewController: Strike limit reached - education module disabled")
                    // Education module has been removed
                } else if response == .exit {
                    print("[DEBUG] 🚪 KittyChatChannelViewController: User chose to exit")
                    self.showConversationExitAlert()
                }
            }
        }
        
        print("[DEBUG] ✅ KittyChatChannelViewController: Receiver response recorded silently")
    }
    
    private func showConversationExitAlert() {
        let alert = UIAlertController(
            title: "Conversation Ended",
            message: "You have chosen to exit this conversation due to inappropriate content.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            // Could navigate back or handle conversation exit
            self.navigationController?.popViewController(animated: true)
        })
        
        present(alert, animated: true)
    }
}

// MARK: - BiDirectionalInteractionDelegate

extension KittyChatChannelViewController: BiDirectionalInteractionDelegate {
    
    func interactionManager(_ manager: BiDirectionalInteractionManager, didSendMessage message: String, parentMessage: BaseMessage?) {
        print("[DEBUG] 📤 Sender: Sending flagged message with native Sendbird approach")
        print("[DEBUG] Message: '\(message)'")
        print("[DEBUG] Interaction ID: \(manager.getCurrentInteractionId() ?? "nil")")
        
        // Send flagged message using customType
        let messageParams = UserMessageCreateParams(message: message)
        messageParams.customType = "flagged_message"
        
        let flaggedData: [String: Any] = [
            "interaction_id": manager.getCurrentInteractionId() ?? UUID().uuidString,
            "flagged_type": "interaction_pending",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        print("[DEBUG] Flagged data to attach: \(flaggedData)")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: flaggedData, options: [])
            let jsonString = String(data: jsonData, encoding: .utf8)
            messageParams.data = jsonString
            print("[DEBUG] ✅ Flagged message data attached: \(jsonString ?? "nil")")
        } catch {
            print("[DEBUG] ❌ Error serializing flagged data: \(error)")
        }

        print("[DEBUG] Sending flagged message via viewModel...")
        self.viewModel?.sendUserMessage(messageParams: messageParams, parentMessage: parentMessage)
        print("[DEBUG] ✅ Flagged message sent with customType 'flagged_message'")
    }
    
    func interactionManager(_ manager: BiDirectionalInteractionManager, didCompleteInteractionWithStrikes strikes: Double, limitReached: Bool) {
        // Handle strike completion - already shown by manager
        print("Interaction completed with \(strikes) strikes, limit reached: \(limitReached)")
    }
    
    func interactionManager(_ manager: BiDirectionalInteractionManager, didRequestEducationModule completion: @escaping () -> Void) {
        // Education module has been removed
        print("[DEBUG] ⚠️ Education module request ignored - feature disabled")
        completion()
    }
    
    func interactionManager(_ manager: BiDirectionalInteractionManager, didRequestConversationExit reason: String) {
        let alert = UIAlertController(
            title: "Conversation Ended",
            message: reason,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        
        present(alert, animated: true)
    }
    
    func interactionManager(_ manager: BiDirectionalInteractionManager, didShowMessage title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
        
        // Auto dismiss informational messages after 3 seconds (except strike limit alerts)
        if !title.contains("Strike Limit") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                alert.dismiss(animated: true)
            }
        }
    }
    
    func interactionManager(_ manager: BiDirectionalInteractionManager, didClearMessageInput: Void) {
        messageInputView?.textView?.text = ""
    }
    
    func interactionManager(_ manager: BiDirectionalInteractionManager, didRestoreMessageInput message: String) {
        messageInputView?.textView?.text = message
    }
    
}

 
