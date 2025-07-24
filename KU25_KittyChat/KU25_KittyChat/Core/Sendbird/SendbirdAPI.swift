import Foundation

struct SendbirdAPI {
    static let appId = "YOURID" // 請填入你的 App ID
    static let apiToken = "YOURTOKEN" // 請填入你的 Server API Token

    /// 檢查 userId 是否存在於 Sendbird
    static func checkUserExists(userId: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "https://api-\(appId).sendbird.com/v3/users/\(userId)") else {
            print("SendbirdAPI.checkUserExists: URL 產生失敗")
            completion(false)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiToken, forHTTPHeaderField: "Api-Token")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                print("SendbirdAPI.checkUserExists statusCode:", httpResponse.statusCode)
                if let data = data, let body = String(data: data, encoding: .utf8) {
                    print("SendbirdAPI.checkUserExists response body:", body)
                }
                completion(httpResponse.statusCode == 200)
            } else {
                print("SendbirdAPI.checkUserExists: no valid HTTPURLResponse")
                completion(false)
            }
        }
        task.resume()
    }
} 
