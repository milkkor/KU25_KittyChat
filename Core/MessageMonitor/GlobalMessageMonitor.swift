import Foundation
import SendbirdChatSDK
import SendbirdUIKit
import UIKit

// Protocol for handling receiver responses from active chat view controllers
protocol ReceiverResponseHandler: AnyObject {
    func recordReceiverResponse(_ response: ReceiverResponse, interactionId: String)
}

/// Global message monitor using SendbirdChat.addChannelDelegate for comprehensive message monitoring
class GlobalMessageMonitor: NSObject, BaseChannelDelegate, GroupChannelDelegate {
    
    static let shared = GlobalMessageMonitor()
    
    // Protocol for handling receiver responses in active chat view controllers
    weak var receiverResponseHandler: ReceiverResponseHandler?
    
    private override init() {
        super.init()
    }
    
    /// Register the global message monitor
    func registerMonitor() {
        SendbirdChat.addChannelDelegate(self, identifier: "global-ai-guardian-monitor")
        print("[DEBUG] 🌍 Global AI Guardian message monitor registered")
        print("[DEBUG] 🔍 Current user: \(SBUGlobals.currentUser?.userId ?? "nil")")
        print("[DEBUG] 🔍 SendbirdChat user: \(SendbirdChat.getCurrentUser()?.userId ?? "nil")")
    }
    
    /// Unregister the global message monitor
    func unregisterMonitor() {
        SendbirdChat.removeChannelDelegate(forIdentifier: "global-ai-guardian-monitor")
        print("[DEBUG] 🌍 Global AI Guardian message monitor unregistered")
    }
    
    /// Set the active receiver response handler
    func setReceiverResponseHandler(_ handler: ReceiverResponseHandler) {
        self.receiverResponseHandler = handler
        print("[DEBUG] 🔗 Global Monitor: Receiver response handler set")
    }
    
    /// Clear the receiver response handler
    func clearReceiverResponseHandler() {
        self.receiverResponseHandler = nil
        print("[DEBUG] 🔗 Global Monitor: Receiver response handler cleared")
    }
    
    // MARK: - BaseChannelDelegate
    
    func channel(_ channel: BaseChannel, didReceive message: BaseMessage) {
        print("[DEBUG] 🔥 GlobalMessageMonitor (BaseChannel): didReceive called!")
        handleIncomingMessage(message: message, channel: channel)
    }
    
    // MARK: - GroupChannelDelegate  
    
    func channel(_ channel: GroupChannel, didReceive message: BaseMessage) {
        print("[DEBUG] 🔥 GlobalMessageMonitor (GroupChannel): didReceive called!")
        handleIncomingMessage(message: message, channel: channel)
    }
    
    // MARK: - Shared Message Handler
    
    private func handleIncomingMessage(message: BaseMessage, channel: BaseChannel) {
        print("[DEBUG] 📝 Message type: \(type(of: message))")
        print("[DEBUG] 📝 Message ID: \(message.messageId)")
        print("[DEBUG] 📝 Message content: '\(message.message)'")
        print("[DEBUG] 📝 Channel URL: \(channel.channelURL)")
        print("[DEBUG] 📝 Current user: \(SBUGlobals.currentUser?.userId ?? "nil")")
        
        guard let userMessage = message as? UserMessage else {
            print("[DEBUG] ⚠️ Message is not UserMessage, ignoring")
            return
        }
        
        guard let currentUser = SBUGlobals.currentUser else {
            print("[DEBUG] ❌ No current user available")
            return
        }
        
        print("[DEBUG] 📥 Global Monitor: Received message in \(channel.channelURL)")
        print("[DEBUG] 📝 Sender: \(userMessage.sender?.userId ?? "unknown")")
        print("[DEBUG] 📝 CustomType: '\(userMessage.customType ?? "nil")'")
        
        // Create AI message context using the new router system
        let context = AIMessageContext(message: userMessage, currentUserId: currentUser.userId)
        
        // Route message using the centralized router
        let action = AIMessageRouter.shared.routeMessage(context: context, channel: channel)
        
        // Execute the action
        executeAction(action)
    }
    
    // MARK: - Additional BaseChannelDelegate Methods
    
    func channel(_ channel: BaseChannel, didUpdate message: BaseMessage) {
        print("[DEBUG] 🔄 GlobalMessageMonitor: didUpdate message")
    }
    
    func channel(_ channel: BaseChannel, didDelete messageId: Int64) {
        print("[DEBUG] 🗑️ GlobalMessageMonitor: didDelete message")
    }
    
    func channel(_ channel: BaseChannel, userDidJoin user: User) {
        print("[DEBUG] 👋 GlobalMessageMonitor: user joined - \(user.userId)")
    }
    
    func channel(_ channel: BaseChannel, userDidLeave user: User) {
        print("[DEBUG] 👋 GlobalMessageMonitor: user left - \(user.userId)")
    }
    
    // MARK: - Action Execution
    
    private func executeAction(_ action: AIMessageAction) {
        print("[DEBUG] 🎬 Global Monitor: Executing action: \(action.description)")
        
        switch action {
        case .showReceiverAlert(let context, let channel):
            handleReceiverAlert(context: context, channel: channel)
            
        case .ignore:
            print("[DEBUG] ℹ️ Global Monitor: Action ignored")
        }
    }
    
    // MARK: - Action Handlers
    
    private func handleReceiverAlert(context: AIMessageContext, channel: BaseChannel) {
        guard let interactionId = context.interactionId else {
            print("[DEBUG] ❌ Global: No interaction ID found in flagged message")
            return
        }
        
        print("[DEBUG] 🎯 Global: Showing receiver action sheet for interaction: \(interactionId)")
        
        DispatchQueue.main.async {
            guard let topViewController = AIMessageRouter.shared.getTopViewController() else {
                print("[DEBUG] ❌ Global: No top view controller found")
                return
            }
            
            self.presentReceiverActionSheet(
                on: topViewController,
                context: context,
                interactionId: interactionId
            )
        }
    }
    
    // MARK: - UI Presentation
    
    private func presentReceiverActionSheet(on viewController: UIViewController, context: AIMessageContext, interactionId: String) {
        let router = AIMessageRouter.shared
        
        let alertController = UIAlertController(
            title: router.localizedText(for: "ai_guardian_title"),
            message: "\(router.localizedText(for: "ai_guardian_message"))\n\nMessage: \"\(context.message.message)\"",
            preferredStyle: .alert
        )
        
        alertController.addAction(UIAlertAction(title: router.localizedText(for: "response_acceptable"), style: .default) { [weak self] _ in
            print("[DEBUG] 👍 Global: Receiver chose acceptable")
            self?.sendReceiverResponse(.acceptable, interactionId: interactionId)
        })
        
        alertController.addAction(UIAlertAction(title: router.localizedText(for: "response_uncomfortable"), style: .default) { [weak self] _ in
            print("[DEBUG] 😐 Global: Receiver chose uncomfortable")
            self?.sendReceiverResponse(.uncomfortable, interactionId: interactionId)
        })
        
        alertController.addAction(UIAlertAction(title: router.localizedText(for: "response_exit"), style: .destructive) { [weak self] _ in
            print("[DEBUG] 🚪 Global: Receiver chose exit")
            self?.sendReceiverResponse(.exit, interactionId: interactionId)
        })
        
        viewController.present(alertController, animated: true) {
            print("[DEBUG] ✅ Global: Receiver action sheet presented successfully!")
        }
    }
    
    private func sendReceiverResponse(_ response: ReceiverResponse, interactionId: String) {
        print("[DEBUG] 📤 Global: Recording response '\(response.rawValue)' for interaction \(interactionId)")
        
        // Use the active receiver response handler if available (for logging/recording)
        if let handler = receiverResponseHandler {
            print("[DEBUG] ✅ Global: Delegating to active receiver response handler")
            handler.recordReceiverResponse(response, interactionId: interactionId)
        } else {
            // Fallback: Direct backend recording without any chat messages
            print("[DEBUG] 📝 Global: Recording directly via StrikeManager")
            StrikeManager.shared.recordReceiverResponse(interactionId: interactionId, response: response) { finalStrikes, limitReached in
                DispatchQueue.main.async {
                    print("[DEBUG] 🎯 Backend: Recorded response - \(finalStrikes) strikes, limit reached: \(limitReached)")
                    
                    // Handle consequences without sending messages
                    if limitReached {
                        print("[DEBUG] 🎓 Backend: Strike limit reached - education recommended")
                        // Could trigger local notification or other silent handling
                    } else if response == .exit {
                        print("[DEBUG] 🚪 Backend: User chose to exit conversation")
                        // Could trigger conversation end handling
                    }
                }
            }
        }
        
        print("[DEBUG] ✅ Global: Response recorded silently - no messages sent to chat")
    }
} 