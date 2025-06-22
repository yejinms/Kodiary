import Foundation
import SwiftUI

// 언어별 텍스트 구조체 확장
struct LanguageTexts {
    // 기본 정보
    let flag: String
    let locale: Locale
    let languageCode: String // "ko", "en", "ja" 등
    let languageName: String // "한국어", "English", "日本語"
    
    // 언어 번역 맵 (언어 코드 -> 해당 언어명)
    let languageNameTranslations: [String: String]
    
    // 날짜 관련
    let dateComponents: (year: String, month: String, weekday: String)
    let dayDateFormat: String
    
    // ContentView 텍스트들
    let writeButtonText: String
    let writeButtonCompletedText: String
    let historyButtonText: String
    
    // DiaryWriteView
    let diaryWriteTitle: String
    let diaryWritePlaceholder: String
    let analyzeDiaryButton: String
    let characterCount: (Int, Int) -> String
    
    // DiaryHistoryView
    let diaryHistoryTitle: String
    let viewDiaryButton: String
    let correctionCountText: (Int) -> String
    let characterCountText: (Int) -> String
    let noDiaryMessage: String
    let todayDiaryPrompt: String
    
    // CorrectionResultView
    let correctionResultTitle: String
    let writtenDiaryTitle: String
    let correctionCompleteTitle: String
    let correctionCompleteSubtitle: (Int) -> String
    let saveButton: String
    let originalExpressionTitle: String
    let correctionSuggestionTitle: String
    let explanationTitle: String
    
    // DiaryDetailView
    let diaryDetailTitle: String
    
    // ProfileSettingsView
    let profileSettingsTitle: String
    let profileUserName: String
    let profileInfoTitle: String
    let notificationSettingsTitle: String
    let privacySettingsTitle: String
    let helpTitle: String
    let appInfoTitle: String
    
    // LanguageSelectionView (새로 추가)
    let languageSettingsTitle: String
    let nativeLanguageTab: String
    let correctionLanguageTab: String
    let nativeLanguageDescription: String
    let correctionLanguageDescription: String
    let currentNativeLanguage: String
    let currentCorrectionLanguage: String
    
    // 로딩 및 에러 메시지
    let loadingMessage: String
    let loadingSubMessage: String
    let errorTitle: String
    let confirmButton: String
    let retryButton: String
    let unknownErrorMessage: String
    
    // 월/요일 이름들
    let monthNames: [String]
    let weekdayNames: [String]
    let shortWeekdayNames: [String]
    
    // 인사말 클로저들
    let greetingWithDiary: (String) -> (title: String, subtitle: String)
    let greetingWithoutDiary: (String) -> (title: String, subtitle: String)
}

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var nativeLanguage: LanguageTexts      // 모국어 (UI 언어)
    @Published var correctionLanguage: LanguageTexts  // 첨삭 언어
    
    // UI에서 사용할 현재 언어 (모국어)
    var currentLanguage: LanguageTexts {
        return nativeLanguage
    }
    
    private init() {
        self.nativeLanguage = Self.korean
        self.correctionLanguage = Self.korean
    }
    
    func setNativeLanguage(_ language: LanguageTexts) {
        nativeLanguage = language
    }
    
    func setCorrectionLanguage(_ language: LanguageTexts) {
        correctionLanguage = language
    }
    
    // API 호출 시 사용할 언어 코드들
    var correctionLanguageCode: String {
        return correctionLanguage.languageCode
    }
    
    var nativeLanguageCode: String {
        return nativeLanguage.languageCode
    }
    
    // 한국어
    static let korean = LanguageTexts(
        // 기본 정보
        flag: "🇰🇷",
        locale: Locale(identifier: "ko_KR"),
        languageCode: "ko",
        languageName: "한국어",
        
        // 언어 번역 맵
        languageNameTranslations: [
            "ko": "한국어",
            "en": "영어",
            "ja": "일본어"
        ],
        
        // 날짜 관련
        dateComponents: (year: "yyyy", month: "M월", weekday: "E요일"),
        dayDateFormat: "d",
        
        // ContentView
        writeButtonText: "오늘의 일기 쓰기",
        writeButtonCompletedText: "오늘의 일기 (작성완료)",
        historyButtonText: "일기 히스토리",
        
        // DiaryWriteView
        diaryWriteTitle: "오늘의 일기",
        diaryWritePlaceholder: "오늘 있었던 일을 자유롭게 써보세요...",
        analyzeDiaryButton: "첨삭 받기",
        characterCount: { current, max in "\(current)/\(max)" },
        
        // DiaryHistoryView
        diaryHistoryTitle: "일기 히스토리",
        viewDiaryButton: "보기",
        correctionCountText: { count in "첨삭 \(count)개" },
        characterCountText: { count in "\(count)자" },
        noDiaryMessage: "이 날은 일기를 쓰지 않았어요",
        todayDiaryPrompt: "오늘 일기를 써보세요! ✍️",
        
        // CorrectionResultView
        correctionResultTitle: "첨삭 결과",
        writtenDiaryTitle: "작성한 일기",
        correctionCompleteTitle: "첨삭 완료!",
        correctionCompleteSubtitle: { count in "총 \(count)개의 수정점을 찾았어요" },
        saveButton: "저장",
        originalExpressionTitle: "원래 표현",
        correctionSuggestionTitle: "수정 제안",
        explanationTitle: "설명",
        
        // DiaryDetailView
        diaryDetailTitle: "첨삭 결과",
        
        // ProfileSettingsView
        profileSettingsTitle: "설정",
        profileUserName: "사용자",
        profileInfoTitle: "프로필 정보",
        notificationSettingsTitle: "알림 설정",
        privacySettingsTitle: "개인정보 보호",
        helpTitle: "도움말",
        appInfoTitle: "앱 정보",
        
        // LanguageSelectionView
        languageSettingsTitle: "언어 설정",
        nativeLanguageTab: "모국어",
        correctionLanguageTab: "첨삭 언어",
        nativeLanguageDescription: "앱 화면에 표시되는 언어입니다",
        correctionLanguageDescription: "일기를 작성하고 첨삭받을 언어입니다",
        currentNativeLanguage: "현재 모국어",
        currentCorrectionLanguage: "현재 첨삭 언어",
        
        // 로딩 및 에러
        loadingMessage: "AI가 일기를 첨삭하고 있어요",
        loadingSubMessage: "잠시만 기다려주세요",
        errorTitle: "첨삭 오류",
        confirmButton: "확인",
        retryButton: "다시 시도",
        unknownErrorMessage: "알 수 없는 오류가 발생했습니다.",
        
        // 월/요일
        monthNames: ["1월", "2월", "3월", "4월", "5월", "6월", "7월", "8월", "9월", "10월", "11월", "12월"],
        weekdayNames: ["일요일", "월요일", "화요일", "수요일", "목요일", "금요일", "토요일"],
        shortWeekdayNames: ["일", "월", "화", "수", "목", "금", "토"],
        
        // 인사말
        greetingWithDiary: { username in
            (title: "안녕, \(username).",
             subtitle: "멋진 하루 보내요.")
        },
        greetingWithoutDiary: { username in
            (title: "안녕, \(username).",
             subtitle: "오늘은 어떤 하루를 보냈나요?")
        }
    )
    
    // 영어
    static let english = LanguageTexts(
        // 기본 정보
        flag: "🇺🇸",
        locale: Locale(identifier: "en_US"),
        languageCode: "en",
        languageName: "English",
        
        // 언어 번역 맵
        languageNameTranslations: [
            "ko": "Korean",
            "en": "English",
            "ja": "Japanese"
        ],
        
        // 날짜 관련
        dateComponents: (year: "yyyy", month: "MMM", weekday: "EEEE"),
        dayDateFormat: "d",
        
        // ContentView
        writeButtonText: "Write Today's Diary",
        writeButtonCompletedText: "Today's Diary (Completed)",
        historyButtonText: "Diary History",
        
        // DiaryWriteView
        diaryWriteTitle: "Today's Diary",
        diaryWritePlaceholder: "Write freely about what happened today...",
        analyzeDiaryButton: "Get Corrections",
        characterCount: { current, max in "\(current)/\(max)" },
        
        // DiaryHistoryView
        diaryHistoryTitle: "Diary History",
        viewDiaryButton: "View",
        correctionCountText: { count in "\(count) corrections" },
        characterCountText: { count in "\(count) chars" },
        noDiaryMessage: "No diary entry for this day",
        todayDiaryPrompt: "Write today's diary! ✍️",
        
        // CorrectionResultView
        correctionResultTitle: "Correction Results",
        writtenDiaryTitle: "Your Diary",
        correctionCompleteTitle: "Corrections Complete!",
        correctionCompleteSubtitle: { count in "Found \(count) correction points" },
        saveButton: "Save",
        originalExpressionTitle: "Original",
        correctionSuggestionTitle: "Suggestion",
        explanationTitle: "Explanation",
        
        // DiaryDetailView
        diaryDetailTitle: "Correction Results",
        
        // ProfileSettingsView
        profileSettingsTitle: "Settings",
        profileUserName: "User",
        profileInfoTitle: "Profile Information",
        notificationSettingsTitle: "Notification Settings",
        privacySettingsTitle: "Privacy Settings",
        helpTitle: "Help",
        appInfoTitle: "App Information",
        
        // LanguageSelectionView
        languageSettingsTitle: "Language Settings",
        nativeLanguageTab: "Native Language",
        correctionLanguageTab: "Correction Language",
        nativeLanguageDescription: "Language displayed in the app interface",
        correctionLanguageDescription: "Language for writing and correcting diaries",
        currentNativeLanguage: "Current Native Language",
        currentCorrectionLanguage: "Current Correction Language",
        
        // 로딩 및 에러
        loadingMessage: "AI is correcting your diary",
        loadingSubMessage: "Please wait a moment",
        errorTitle: "Correction Error",
        confirmButton: "OK",
        retryButton: "Retry",
        unknownErrorMessage: "An unknown error occurred.",
        
        // 월/요일
        monthNames: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
        weekdayNames: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"],
        shortWeekdayNames: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
        
        // 인사말
        greetingWithDiary: { username in
            (title: "Hi, \(username).",
             subtitle: "Hope you had a wonderful day.")
        },
        greetingWithoutDiary: { username in
            (title: "Hi, \(username).",
             subtitle: "How was your day?")
        }
    )
    
    // 일본어
    static let japanese = LanguageTexts(
        // 기본 정보
        flag: "🇯🇵",
        locale: Locale(identifier: "ja_JP"),
        languageCode: "ja",
        languageName: "日本語",
        
        // 언어 번역 맵
        languageNameTranslations: [
            "ko": "韓国語",
            "en": "英語",
            "ja": "日本語"
        ],
        
        // 날짜 관련
        dateComponents: (year: "yyyy", month: "M月", weekday: "EEEE"),
        dayDateFormat: "d",
        
        // ContentView
        writeButtonText: "今日の日記を書く",
        writeButtonCompletedText: "今日の日記（完了）",
        historyButtonText: "日記履歴",
        
        // DiaryWriteView
        diaryWriteTitle: "今日の日記",
        diaryWritePlaceholder: "今日あったことを自由に書いてみてください...",
        analyzeDiaryButton: "添削を受ける",
        characterCount: { current, max in "\(current)/\(max)" },
        
        // DiaryHistoryView
        diaryHistoryTitle: "日記履歴",
        viewDiaryButton: "見る",
        correctionCountText: { count in "添削\(count)個" },
        characterCountText: { count in "\(count)文字" },
        noDiaryMessage: "この日は日記を書いていません",
        todayDiaryPrompt: "今日の日記を書いてみましょう！ ✍️",
        
        // CorrectionResultView
        correctionResultTitle: "添削結果",
        writtenDiaryTitle: "書いた日記",
        correctionCompleteTitle: "添削完了！",
        correctionCompleteSubtitle: { count in "合計\(count)個の修正点を見つけました" },
        saveButton: "保存",
        originalExpressionTitle: "元の表現",
        correctionSuggestionTitle: "修正提案",
        explanationTitle: "説明",
        
        // DiaryDetailView
        diaryDetailTitle: "添削結果",
        
        // ProfileSettingsView
        profileSettingsTitle: "設定",
        profileUserName: "ユーザー",
        profileInfoTitle: "プロフィール情報",
        notificationSettingsTitle: "通知設定",
        privacySettingsTitle: "プライバシー設定",
        helpTitle: "ヘルプ",
        appInfoTitle: "アプリ情報",
        
        // LanguageSelectionView
        languageSettingsTitle: "言語設定",
        nativeLanguageTab: "母国語",
        correctionLanguageTab: "添削言語",
        nativeLanguageDescription: "アプリの画面に表示される言語です",
        correctionLanguageDescription: "日記を書いて添削を受ける言語です",
        currentNativeLanguage: "現在の母国語",
        currentCorrectionLanguage: "現在の添削言語",
        
        // 로딩 및 에러
        loadingMessage: "AIが日記を添削しています",
        loadingSubMessage: "少々お待ちください",
        errorTitle: "添削エラー",
        confirmButton: "確認",
        retryButton: "再試行",
        unknownErrorMessage: "不明なエラーが発生しました。",
        
        // 월/요일
        monthNames: ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"],
        weekdayNames: ["日曜日", "月曜日", "火曜日", "水曜日", "木曜日", "金曜日", "土曜日"],
        shortWeekdayNames: ["日", "月", "火", "水", "木", "金", "土"],
        
        // 인사말
        greetingWithDiary: { username in
            (title: "こんにちは、\(username).",
             subtitle: "素敵な一日を過ごしてね！")
        },
        greetingWithoutDiary: { username in
            (title: "こんにちは、\(username)さん！ 👋",
             subtitle: "今日はどうだった？")
        }
    )
    
    // 사용 가능한 언어 목록
    static let availableLanguages: [LanguageTexts] = [korean, english, japanese]
}
