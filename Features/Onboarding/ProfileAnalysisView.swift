import SwiftUI

struct ProfileAnalysisView: View {
    let profile: UserProfile
    let customThreadsHandle: String
    let onContinue: (String) -> Void
    @State private var displayName: String = ""
    @State private var isNameFocused: Bool = false
    @FocusState private var focusedField: Bool
    
    var body: some View {
        ZStack {
            // 背景色
            Color(hex: "fef9ff")
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Logo + 標題
                HeaderView(userId: profile.userId, threadsHandle: customThreadsHandle)
                
                // 統計數據視覺化卡片
                StatsGridView(profile: profile)
                
                // 總結判斷區塊
                SummaryBadge(isSafe: profile.misogynyRisk == "Safe")
                
                Spacer()
                
                // 使用者輸入暱稱 + 按鈕
                NicknameInputView(
                    displayName: $displayName,
                    isNameFocused: $isNameFocused,
                    focusedField: $focusedField,
                    onContinue: { onContinue(displayName) }
                )
                
                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - HeaderView
struct HeaderView: View {
    let userId: String
    let threadsHandle: String
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: 80, height: 80)
                    .shadow(color: Color.black.opacity(0.05), radius: 8)
                
                Image(systemName: "pawprint.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(Color(hex: "c084fc"))
            }
            
            Text("Threads Analysis")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color(hex: "374151"))
            
            VStack(spacing: 4) {
                Text("User ID: \(userId)")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "6b7280"))
                Text("Threads: @\(threadsHandle)")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "6b7280"))
            }
        }
    }
}

// MARK: - StatsGridView
struct StatsGridView: View {
    let profile: UserProfile
    
    // Mock data - can be fetched from API in actual application
    private var postCount: Int { Int.random(in: 80...200) }
    private var flaggedPosts: Int { profile.misogynyRisk == "Safe" ? Int.random(in: 0...5) : Int.random(in: 6...20) }
    private var riskPercentage: Double { 
        let percentage = Double(flaggedPosts) / Double(postCount) * 100
        return Double(round(percentage * 10) / 10)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ProfileStatCard(
                    title: "Post Count",
                    value: "\(postCount)",
                    bgColor: Color(hex: "f3f4f6"),
                    valueColor: Color(hex: "374151"),
                    icon: "doc.text.fill"
                )
                
                ProfileStatCard(
                    title: "Personality",
                    value: profile.personality,
                    bgColor: Color(hex: "f3e8ff"),
                    valueColor: Color(hex: "7c3aed"),
                    icon: "person.fill",
                    isTextValue: true
                )
            }
            
            HStack(spacing: 12) {
                ProfileStatCard(
                    title: "Flagged Posts",
                    value: "\(flaggedPosts)",
                    bgColor: flaggedPosts > 5 ? Color(hex: "fef2f2") : Color(hex: "f0fdf4"),
                    valueColor: flaggedPosts > 5 ? Color(hex: "ef4444") : Color(hex: "22c55e"),
                    icon: "flag.fill"
                )
                
                ProfileStatCard(
                    title: "Misogyny Percentage",
                    value: "\(riskPercentage)%",
                    bgColor: riskPercentage > 5 ? Color(hex: "fff7ed") : Color(hex: "f0fdf4"),
                    valueColor: riskPercentage > 5 ? Color(hex: "f97316") : Color(hex: "22c55e"),
                    icon: "chart.pie.fill"
                )
            }
            
            // Interest tags
            InterestsView(interests: profile.interests)
        }
    }
}



// MARK: - InterestsView
struct InterestsView: View {
    let interests: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(Color(hex: "f472b6"))
                Text("Interests")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "374151"))
                Spacer()
            }
            
            FlowLayout(spacing: 8) {
                ForEach(interests, id: \.self) { interest in
                    Text("#\(interest)")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "7c3aed"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(hex: "f3e8ff"))
                        .cornerRadius(12)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4)
    }
}

// MARK: - SummaryBadge
struct SummaryBadge: View {
    let isSafe: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isSafe ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(isSafe ? Color(hex: "22c55e") : Color(hex: "ef4444"))
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(isSafe ? "Safe User Verified" : "Potential Risk Detected")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isSafe ? Color(hex: "22c55e") : Color(hex: "ef4444"))
                
                Text(isSafe ? "This user passed safety verification" : "Recommend cautious interaction")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "6b7280"))
            }
            
            Spacer()
        }
        .padding(16)
        .background(isSafe ? Color(hex: "f0fdf4") : Color(hex: "fef2f2"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSafe ? Color(hex: "22c55e").opacity(0.2) : Color(hex: "ef4444").opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - NicknameInputView
struct NicknameInputView: View {
    @Binding var displayName: String
    @Binding var isNameFocused: Bool
    @FocusState.Binding var focusedField: Bool
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            TextField("Nickname", text: $displayName)
                .textFieldStyle(CustomTextFieldStyle(isFocused: isNameFocused))
                .focused($focusedField)
                .onChange(of: focusedField) { newValue in
                    isNameFocused = newValue
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 40)
            
            Button(action: onContinue) {
                Text("Continue")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "f472b6"), Color(hex: "c084fc")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                    .shadow(color: Color(hex: "c084fc").opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 40)
            .disabled(displayName.isEmpty)
        }
    }
}



struct ProfileAnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileAnalysisView(
            profile: UserProfile(
                userId: "user_123", 
                threadsHandle: "fake_handle",
                interests: ["Literature", "Writing", "History"],
                personality: "Introspective",
                misogynyRisk: "Safe",
                strikes: 0
            ),
            customThreadsHandle: "abcdefghijklmnop",
            onContinue: { _ in }
        )
    }
} 
