import Foundation

struct UserProfile: Codable {
    let userId: String
    let threadsHandle: String
    let interests: [String]
    let personality: String
    let misogynyRisk: String
    var strikes: Int
    
    enum CodingKeys: String, CodingKey {
        case userId, threadsHandle, interests, personality, strikes
        case misogynyRisk = "misogyny_risk"
    }
} 