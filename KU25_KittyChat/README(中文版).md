# KittyChat

一個具有AI安全防護機制的現代化iOS聊天應用，專注於創造安全、友善的聊天環境。

## 📱 應用概述

KittyChat 是一個基於SwiftUI開發的iOS聊天應用，整合了先進的AI Guardian安全系統，能夠即時檢測並處理不當言論，為用戶提供安全的聊天體驗。

### 🌟 核心特色

- **AI Guardian安全系統** - 即時檢測厭女言論和不當內容
- **智能匹配系統** - 基於興趣相似度的用戶配對
- **雙向互動管理** - 完整的發送者與接收者回應機制
- **即時聊天功能** - 基於Sendbird的穩定聊天服務
- **用戶資料分析** - 詳細的個性分析和安全狀態監控

## 🏗 架構設計

### 技術棧
- **UI Framework**: SwiftUI + UIKit (混合架構)
- **Architecture Pattern**: MVVM
- **Chat SDK**: Sendbird UIKit & Chat SDK
- **Programming Language**: Swift 5.0+
- **iOS Version**: iOS 14.0+

### 項目結構

```
KU25_KittyChat/
├── Core/                           # 核心功能模組
│   ├── DetectionEngine/           # AI檢測引擎
│   │   ├── DetectionEngine.swift  # 主要檢測邏輯
│   │   └── BiDirectionalInteractionManager.swift # 雙向互動管理
│   ├── MessageMonitor/            # 消息監控系統
│   │   └── GlobalMessageMonitor.swift # 全局消息監控
│   ├── MessageRouter/             # 消息路由系統
│   │   └── AIMessageRouter.swift  # AI消息路由器
│   ├── LocalData/                 # 本地數據管理
│   │   └── StrikeManager.swift    # 警告記錄管理
│   ├── Sendbird/                  # Sendbird整合
│   │   └── SendbirdAPI.swift      # Sendbird API封裝
│   └── UI/                        # 共用UI組件
│       ├── Color+Hex.swift        # 顏色擴展
│       ├── FlowLayout.swift       # 流式佈局
│       └── StatCard.swift         # 統計卡片組件
├── Features/                       # 功能模組
│   ├── Chat/                      # 聊天功能
│   │   └── KittyChatChannelViewController.swift
│   ├── Matching/                  # 匹配功能
│   │   ├── MatchingView.swift     # 主匹配界面
│   │   ├── MatchingReadyView.swift # 配對準備頁面
│   │   └── MatchingCongratsView.swift # 配對成功頁面
│   ├── Onboarding/                # 入門流程
│   │   ├── OnboardingView.swift   # 歡迎頁面
│   │   └── ProfileAnalysisView.swift # 資料分析頁面
│   └── Profile/                   # 用戶資料
│       ├── ProfileView.swift      # 個人資料頁面
│       └── ProfileComponents.swift # 資料組件
├── Data/                          # 數據模型
│   └── UserProfile.swift         # 用戶資料模型
├── Resources/                     # 資源文件
│   ├── Assets.xcassets/          # 圖片資源
│   └── MockData/                 # 測試數據
│       ├── DetectionRules.json   # 檢測規則
│       └── Users/               # 測試用戶數據
└── KU25_KittyChatApp.swift      # 應用入口點
```

## 🔧 核心系統

### 1. AI Guardian 安全系統

#### 檢測引擎 (DetectionEngine)
- **功能**: 即時檢測厭女言論、刻板印象、貶低性語言
- **支援語言**: 英文、日文


#### 雙向互動管理 (BiDirectionalInteractionManager)
- **發送者選項**:
  - 撤回消息 (Retract)
  - 編輯消息 (Edit)
  - 表示玩笑 (Just Joking)
- **接收者選項**:
  - 可接受 (Acceptable)
  - 不舒服但繼續 (Uncomfortable but continue)
  - 立即退出 (Exit now)


### 2. 智能匹配系統

#### 興趣匹配算法
```swift
// 基於共同興趣數量進行配對
let commonInterests = myInterests.intersection(partnerInterests).count
```

#### 匹配流程
1. 獲取所有在線用戶
2. 分析興趣相似度
3. 選擇最佳匹配對象
4. 建立專屬聊天室


## 🚀 安裝與設置

### 環境需求
- Xcode 14.0+
- iOS 14.0+
- Swift 5.0+

### 安裝步驟

1. **克隆專案**
```bash
git clone <repository-url>
cd KU25_KittyChat
```

2. **開啟Xcode專案**
```bash
open KU25_KittyChat.xcodeproj
```

3. **添加Sendbird Package**
   
   在Xcode中：
   - 選擇 **File → Add Package Dependencies...**
   - 輸入Sendbird UIKit URL: `https://github.com/sendbird/sendbird-uikit-ios`
   - 選擇版本 (建議使用最新穩定版本)
   - 添加以下Target Dependencies:
     - `SendbirdUIKit`
     - `SendbirdChatSDK`

   或者使用Swift Package Manager：
   ```swift
   // Package.swift
   dependencies: [
       .package(url: "https://github.com/sendbird/sendbird-uikit-ios", from: "3.0.0")
   ]
   ```

4. **配置Sendbird**
   
   **⚠️ 重要：請向 Liao YUJU 索取以下必要資訊：**
   - **Sendbird Application ID**
   - **Sendbird API Token**
   
   獲得資訊後，請更新以下兩個文件：
   
   **📄 KU25_KittyChatApp.swift**
   ```swift
   // 第19行，將 "YOURID" 替換為實際的 Application ID
   SendbirdUI.initialize(
       applicationId: "YOUR_ACTUAL_APP_ID", // 替換此處
       startHandler: { ... }
   )
   ```
   
   **📄 Core/Sendbird/SendbirdAPI.swift**
   ```swift
   struct SendbirdAPI {
       static let appId = "YOUR_ACTUAL_APP_ID"     // 替換此處
       static let apiToken = "YOUR_ACTUAL_TOKEN"   // 替換此處
       // ...
   }
   ```
   
   > 💡 **提醒**：請確保不要將真實的ID和TOKEN提交到公開的代碼倉庫中


### 依賴套件

#### 主要依賴
- **SendbirdUIKit** (3.0.0+): 完整的聊天界面組件
- **SendbirdChatSDK** (4.0.0+): 聊天核心功能和API

#### Package Repository
- **GitHub**: https://github.com/sendbird/sendbird-uikit-ios
- **Documentation**: https://sendbird.com/docs/uikit/v3/ios/getting-started/about-uikit

#### 最低系統需求
- iOS 11.0+
- Xcode 14.0+
- Swift 5.0+

## 📚 使用說明

### 用戶註冊流程
1. 輸入用戶ID和Threads帳號
2. 系統分析用戶資料和興趣
3. 顯示個性分析結果
4. 設定顯示名稱並完成註冊

### 聊天功能
1. **安全配對**: 點擊「Safe Match」開始配對
2. **即時聊天**: 配對成功後進入聊天室
3. **AI監控**: 所有消息自動接受AI Guardian檢測
4. **互動回應**: 不當內容觸發雙向回應機制

### 個人資料管理
- 查看個人興趣標籤
- 監控安全狀態和警告記錄
- 個性分析結果展示


## 🧪 測試數據

應用內建豐富的測試數據：

### 測試用戶
- `user1` - user5: 不同性格和興趣的測試用戶
- 預設安全狀態和警告記錄
- 完整的個性分析資料

### 檢測規則
- 37組預定義檢測規則
- 涵蓋刻板印象、貶低語言、冒犯性內容
- 支援英文和日文檢測關鍵字



