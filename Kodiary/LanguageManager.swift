import Foundation
import SwiftUI

// 언어별 텍스트 구조체 확장
struct LanguageTexts {
    
    // 기본 정보
        let flag: String
        let locale: Locale
        let languageCode: String
        let languageName: String
        let languageNameTranslations: [String: String]
        
        // 로그인 관련 텍스트들
        let appDescription: String
        let privacyNotice: String
        let signingInMessage: String
        let signOutButton: String
        
        // 앱 둘러보기 관련 (새로 추가)
        let appTourButton: String
        let appTourTitle: String
        let appTourFeature1Title: String
        let appTourFeature1Description: String
        let appTourFeature2Title: String
        let appTourFeature2Description: String
        let appTourFeature3Title: String
        let appTourFeature3Description: String
        let appTourFeature4Title: String
        let appTourFeature4Description: String
        let appTourGetStarted: String
        let appTourSkip: String
    
    // 언어 학습 설정 관련 (새로 추가)
        let languageLearningWelcomeTitle: (String) -> String  // 사용자 이름을 받는 클로저
        let languageLearningWelcomeSubtitle: String
        let languageLearningPrompt: String
        let languageLearningContinueButton: String
    
    // 날짜 관련
    let dateComponents: (year: String, month: String, weekday: String)
    let dayDateFormat: String
    
    // ContentView 텍스트들
    let writeButtonText: (String) -> String // 첨삭 언어명을 매개변수로 받는 클로저
    let writeButtonCompletedText: (String) -> String  // 첨삭 언어명을 매개변수로 받는 클로저
    let historyButtonText: String
    
    // DiaryWriteView
    let diaryWriteTitle: String
    let diaryWritePlaceholder: String
    let analyzeDiaryButton: String
    let characterCount: (Int, Int) -> String
    let writeInLanguageText: (String) -> String // "한국어로 써주세요" 등
    let correctionLanguagePlaceholder: String // 첨삭 언어로 된 placeholder
    
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
    let savingMessage: String
    let savingSubMessage: String
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
    
    // UserDefaults 키들
    private let nativeLanguageKey = "native_language_code"
    private let correctionLanguageKey = "correction_language_code"
    
    // UI에서 사용할 현재 언어 (모국어)
    var currentLanguage: LanguageTexts {
        return nativeLanguage
    }
    
    var currentCorrectionLanguage: LanguageTexts {
        return correctionLanguage
    }
    
    private init() {
        // UserDefaults에서 저장된 언어 설정을 불러오기
        self.nativeLanguage = Self.loadSavedLanguage(key: nativeLanguageKey) ?? Self.getDeviceLanguage()
        self.correctionLanguage = Self.loadSavedLanguage(key: correctionLanguageKey) ?? Self.korean
    }
    
    // UserDefaults에서 저장된 언어 불러오기
    private static func loadSavedLanguage(key: String) -> LanguageTexts? {
        let savedLanguageCode = UserDefaults.standard.string(forKey: key)
        return availableLanguages.first { $0.languageCode == savedLanguageCode }
    }
    
    // 디바이스 설정 언어 감지
    private static func getDeviceLanguage() -> LanguageTexts {
        // 디바이스의 기본 언어 코드 가져오기
        let deviceLanguageCode = Locale.preferredLanguages.first?.prefix(2) ?? "en"
        
        // 지원하는 언어 중에서 찾기
        if let matchedLanguage = availableLanguages.first(where: { $0.languageCode == deviceLanguageCode }) {
            return matchedLanguage
        }
        
        // 지원하지 않는 언어면 영어로 기본 설정 (글로벌 언어)
        return english
    }
    
    // 언어 설정을 UserDefaults에 저장
    private func saveLanguageToUserDefaults(languageCode: String, key: String) {
        UserDefaults.standard.set(languageCode, forKey: key)
    }
    
    func setNativeLanguage(_ language: LanguageTexts) {
        nativeLanguage = language
        saveLanguageToUserDefaults(languageCode: language.languageCode, key: nativeLanguageKey)
    }
    
    func setCorrectionLanguage(_ language: LanguageTexts) {
        correctionLanguage = language
        saveLanguageToUserDefaults(languageCode: language.languageCode, key: correctionLanguageKey)
    }
    
    // API 호출 시 사용할 언어 코드들
    var correctionLanguageCode: String {
        return correctionLanguage.languageCode
    }
    
    var nativeLanguageCode: String {
        return nativeLanguage.languageCode
    }
    
    // 첨삭 언어명을 모국어로 번역해서 반환
    var correctionLanguageDisplayName: String {
        return nativeLanguage.languageNameTranslations[correctionLanguage.languageCode] ?? correctionLanguage.languageName
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
            "ko": "한국어", "en": "영어", "ja": "일본어", "es": "스페인어",
            "th": "태국어", "de": "독일어", "zh": "중국어", "ar": "아랍어",
            "fr": "프랑스어", "it": "이탈리아어", "pt": "포르투갈어", "hi": "힌디어"
        ],
        
        // 로그인 관련
        appDescription: "AI와 함께하는 언어 학습 일기장",
        privacyNotice: "Apple 로그인을 통해 안전하게 시작하세요.\n개인정보는 안전하게 보호됩니다.",
        signingInMessage: "로그인 중...",
        signOutButton: "로그아웃",
        
        // 앱 둘러보기
           appTourButton: "앱 둘러보기",
           appTourTitle: "Kodiary와 함께\n언어 학습을 시작해보세요",
           appTourFeature1Title: "AI 첨삭 일기",
           appTourFeature1Description: "원하는 언어로 일기를 쓰면\nAI가 자연스러운 표현으로 첨삭해드려요",
           appTourFeature2Title: "개인 맞춤 학습",
           appTourFeature2Description: "당신의 수준에 맞는\n맞춤형 언어 학습 경험을 제공해요",
           appTourFeature3Title: "학습 기록 관리",
           appTourFeature3Description: "매일의 학습 기록을 확인하고\n꾸준한 성장을 실감해보세요",
           appTourFeature4Title: "다양한 언어 지원",
           appTourFeature4Description: "12개 언어로 학습할 수 있어\n세계 어디서든 소통할 수 있어요",
           appTourGetStarted: "시작하기",
           appTourSkip: "건너뛰기",
        
        // 언어 학습 설정 관련
            languageLearningWelcomeTitle: { username in "\(username)님!" },
            languageLearningWelcomeSubtitle: "어떤 언어를 학습하고 싶으세요?",
            languageLearningPrompt: "학습할 언어를 선택해주세요",
            languageLearningContinueButton: "학습 시작하기",
        
        // 날짜 관련
        dateComponents: (year: "yyyy", month: "M월", weekday: "E요일"),
        dayDateFormat: "d",
        
        // ContentView
        writeButtonText: { correctionLanguageName in "\(correctionLanguageName) 일기 쓰기" },
        writeButtonCompletedText: { correctionLanguageName in "\(correctionLanguageName) 일기 [완료]" },
        historyButtonText: "일기 히스토리",
        
        // DiaryWriteView
        diaryWriteTitle: "오늘의 일기",
        diaryWritePlaceholder: "오늘 있었던 일을 자유롭게 써보세요...",
        analyzeDiaryButton: "첨삭 받기",
        characterCount: { current, max in "\(current)/\(max)" },
        writeInLanguageText: { languageName in "\(languageName)로 써주세요" },
        correctionLanguagePlaceholder: "오늘 있었던 일을 자유롭게 써보세요...",
        
        // DiaryHistoryView
        diaryHistoryTitle: "일기 히스토리",
        viewDiaryButton: "보기",
        correctionCountText: { count in "첨삭 \(count)개" },
        characterCountText: { count in "\(count)자" },
        noDiaryMessage: "이 날은 일기를 쓰지 않았어요",
        todayDiaryPrompt: "일기 쓰기",
        
        // CorrectionResultView
        correctionResultTitle: "첨삭 결과",
        writtenDiaryTitle: "작성한 일기",
        correctionCompleteTitle: "첨삭 완료",
        correctionCompleteSubtitle: { count in "수정점 \(count)개" },
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
        savingMessage: "오늘도 수고 많았어요.",
        savingSubMessage: "멋진 일기를 보여줘서 고마워요!",
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
            "ko": "Korean", "en": "English", "ja": "Japanese", "es": "Spanish",
            "th": "Thai", "de": "German", "zh": "Chinese", "ar": "Arabic",
            "fr": "French", "it": "Italian", "pt": "Portuguese", "hi": "Hindi"
        ],
        
        //로그인 관련
        appDescription: "AI-powered language learning diary",
        privacyNotice: "Sign in safely with Apple.\nYour privacy is protected.",
        signingInMessage: "Signing in...",
        signOutButton: "Sign Out",
        
        // 앱 둘러보기
            appTourButton: "App Tour",
            appTourTitle: "Start your language learning\njourney with Kodiary",
            appTourFeature1Title: "AI-Powered Corrections",
            appTourFeature1Description: "Write your diary in any language\nand get natural corrections from AI",
            appTourFeature2Title: "Personalized Learning",
            appTourFeature2Description: "Experience customized language learning\ntailored to your level",
            appTourFeature3Title: "Progress Tracking",
            appTourFeature3Description: "Monitor your daily learning progress\nand feel your continuous growth",
            appTourFeature4Title: "Multiple Languages",
            appTourFeature4Description: "Learn from 12 different languages\nto communicate anywhere in the world",
            appTourGetStarted: "Get Started",
            appTourSkip: "Skip",
        
        // 언어 학습 설정 관련
           languageLearningWelcomeTitle: { username in "\(username)!" },
           languageLearningWelcomeSubtitle: "Which language would you like to learn?",
           languageLearningPrompt: "Choose your learning language",
           languageLearningContinueButton: "Start Learning",
        
        // 날짜 관련
        dateComponents: (year: "yyyy", month: "MMM", weekday: "E"),
        dayDateFormat: "d",
        
        // ContentView
        writeButtonText: { correctionLanguageName in "Write \(correctionLanguageName) diary" },
        writeButtonCompletedText: { correctionLanguageName in "\(correctionLanguageName) diary [done]" },
        historyButtonText: "Diary History",
        
        // DiaryWriteView
        diaryWriteTitle: "Today's Diary",
        diaryWritePlaceholder: "Write freely about what happened today...",
        analyzeDiaryButton: "Get Corrections",
        characterCount: { current, max in "\(current)/\(max)" },
        writeInLanguageText: { languageName in "Please write in \(languageName)" },
        correctionLanguagePlaceholder: "Tell me about your day...",
        
        // DiaryHistoryView
        diaryHistoryTitle: "Diary History",
        viewDiaryButton: "View",
        correctionCountText: { count in "\(count) corrections" },
        characterCountText: { count in "\(count) chars" },
        noDiaryMessage: "No diary entry for this day",
        todayDiaryPrompt: "Write diary",
        
        // CorrectionResultView
        correctionResultTitle: "Correction Results",
        writtenDiaryTitle: "Your Diary",
        correctionCompleteTitle: "Corrected",
        correctionCompleteSubtitle: { count in "\(count) correction points" },
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
        savingMessage: "Great work today!",
        savingSubMessage: "Thanks for sharing your wonderful diary!",
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
            "ko": "韓国語", "en": "英語", "ja": "日本語", "es": "スペイン語",
            "th": "タイ語", "de": "ドイツ語", "zh": "中国語", "ar": "アラビア語",
            "fr": "フランス語", "it": "イタリア語", "pt": "ポルトガル語", "hi": "ヒンディー語"
        ],
        
        //로그인 관련
        appDescription: "AIと一緒に学ぶ言語学習日記",
        privacyNotice: "Appleサインインで安全に始めましょう。\nプライバシーは保護されます。",
        signingInMessage: "サインイン中...",
        signOutButton: "サインアウト",
        
        // 앱 둘러보기
            appTourButton: "アプリツアー",
            appTourTitle: "Kodiaryと一緒に\n言語学習を始めましょう",
            appTourFeature1Title: "AI添削日記",
            appTourFeature1Description: "好きな言語で日記を書くと\nAIが自然な表現に添削します",
            appTourFeature2Title: "個人カスタム学習",
            appTourFeature2Description: "あなたのレベルに合った\nカスタマイズ言語学習体験を提供",
            appTourFeature3Title: "学習記録管理",
            appTourFeature3Description: "毎日の学習記録を確認して\n着実な成長を実感してください",
            appTourFeature4Title: "多様な言語サポート",
            appTourFeature4Description: "12言語で学習できるので\n世界中どこでもコミュニケーション可能",
            appTourGetStarted: "始める",
            appTourSkip: "スキップ",
        
        // 언어 학습 설정 관련
            languageLearningWelcomeTitle: { username in "\(username)さん！" },
            languageLearningWelcomeSubtitle: "どの言語を学習したいですか？",
            languageLearningPrompt: "学習言語を選択してください",
            languageLearningContinueButton: "学習を始める",
        
        // 날짜 관련
        dateComponents: (year: "yyyy", month: "M月", weekday: "EEEE"),
        dayDateFormat: "d",
        
        // ContentView
        writeButtonText: { correctionLanguageName in "\(correctionLanguageName)日記を書く" },
        writeButtonCompletedText: { correctionLanguageName in "\(correctionLanguageName)日記 [完了]" },
        historyButtonText: "日記履歴",
        
        // DiaryWriteView
        diaryWriteTitle: "今日の日記",
        diaryWritePlaceholder: "今日あったことを自由に書いてみてください...",
        analyzeDiaryButton: "添削を受ける",
        characterCount: { current, max in "\(current)/\(max)" },
        writeInLanguageText: { languageName in "\(languageName)で書いてください" },
        correctionLanguagePlaceholder: "今日あったことを自由に書いてみてください...",
        
        // DiaryHistoryView
        diaryHistoryTitle: "日記履歴",
        viewDiaryButton: "見る",
        correctionCountText: { count in "添削\(count)個" },
        characterCountText: { count in "\(count)文字" },
        noDiaryMessage: "この日は日記を書いていません",
        todayDiaryPrompt: "日記を書く",
        
        // CorrectionResultView
        correctionResultTitle: "添削結果",
        writtenDiaryTitle: "書いた日記",
        correctionCompleteTitle: "添削完了",
        correctionCompleteSubtitle: { count in "修正点\(count)個" },
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
        savingMessage: "今日もお疲れ様でした。",
        savingSubMessage: "素敵な日記を見せてくれてありがとう！",
        errorTitle: "添削エラー",
        confirmButton: "確認",
        retryButton: "再試行",
        unknownErrorMessage: "不明なエラーが発生しました。",
        
        // 월/요일
        monthNames: ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11월", "12月"],
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
    
    // 스페인어
    static let spanish = LanguageTexts(
        flag: "🇪🇸",
        locale: Locale(identifier: "es_ES"),
        languageCode: "es",
        languageName: "Español",
        
        languageNameTranslations: [
            "ko": "Coreano", "en": "Inglés", "ja": "Japonés", "es": "Español",
            "th": "Tailandés", "de": "Alemán", "zh": "Chino", "ar": "Árabe",
            "fr": "Francés", "it": "Italiano", "pt": "Portugués", "hi": "Hindi"
        ],
        
        appDescription: "Diario de aprendizaje de idiomas con IA",
        privacyNotice: "Inicia sesión de forma segura con Apple.\nTu privacidad está protegida.",
        signingInMessage: "Iniciando sesión...",
        signOutButton: "Cerrar Sesión",
        
        // 앱 둘러보기
            appTourButton: "Tour de la App",
            appTourTitle: "Comienza tu viaje de aprendizaje\nde idiomas con Kodiary",
            appTourFeature1Title: "Correcciones con IA",
            appTourFeature1Description: "Escribe tu diario en cualquier idioma\ny recibe correcciones naturales de IA",
            appTourFeature2Title: "Aprendizaje Personalizado",
            appTourFeature2Description: "Experimenta aprendizaje de idiomas\npersonalizado para tu nivel",
            appTourFeature3Title: "Seguimiento de Progreso",
            appTourFeature3Description: "Monitorea tu progreso diario\ny siente tu crecimiento continuo",
            appTourFeature4Title: "Múltiples Idiomas",
            appTourFeature4Description: "Aprende 12 idiomas diferentes\npara comunicarte en cualquier lugar",
            appTourGetStarted: "Empezar",
            appTourSkip: "Saltar",
        
        // 언어 학습 설정 관련
           languageLearningWelcomeTitle: { username in "¡\(username)!" },
           languageLearningWelcomeSubtitle: "¿Qué idioma te gustaría aprender?",
           languageLearningPrompt: "Elige tu idioma de aprendizaje",
           languageLearningContinueButton: "Empezar a aprender",
        
        dateComponents: (year: "yyyy", month: "MMM", weekday: "EEEE"),
        dayDateFormat: "d",
        
        writeButtonText: { correctionLanguageName in "Escribir diario de \(correctionLanguageName) de hoy" },
        writeButtonCompletedText: { correctionLanguageName in "Diario de \(correctionLanguageName) de hoy [¡Completado!]" },
        historyButtonText: "Historial del diario",
        
        diaryWriteTitle: "Diario de hoy",
        diaryWritePlaceholder: "Escribe libremente sobre lo que pasó hoy...",
        analyzeDiaryButton: "Obtener correcciones",
        characterCount: { current, max in "\(current)/\(max)" },
        writeInLanguageText: { languageName in "Por favor escribe en \(languageName)" },
        correctionLanguagePlaceholder: "Cuéntame sobre tu día...",
        
        diaryHistoryTitle: "Historial del diario",
        viewDiaryButton: "Ver",
        correctionCountText: { count in "\(count) correcciones" },
        characterCountText: { count in "\(count) caracteres" },
        noDiaryMessage: "No hay entrada de diario para este día",
        todayDiaryPrompt: "Escribir diario",
        
        correctionResultTitle: "Resultados de corrección",
        writtenDiaryTitle: "Tu diario",
        correctionCompleteTitle: "Corregido",
        correctionCompleteSubtitle: { count in "\(count) puntos de corrección" },
        saveButton: "Guardar",
        originalExpressionTitle: "Original",
        correctionSuggestionTitle: "Sugerencia",
        explanationTitle: "Explicación",
        
        diaryDetailTitle: "Resultados de corrección",
        
        profileSettingsTitle: "Configuración",
        profileUserName: "Usuario",
        profileInfoTitle: "Información del perfil",
        notificationSettingsTitle: "Configuración de notificaciones",
        privacySettingsTitle: "Configuración de privacidad",
        helpTitle: "Ayuda",
        appInfoTitle: "Información de la aplicación",
        
        languageSettingsTitle: "Configuración de idioma",
        nativeLanguageTab: "Idioma nativo",
        correctionLanguageTab: "Idioma de corrección",
        nativeLanguageDescription: "Idioma mostrado en la interfaz de la aplicación",
        correctionLanguageDescription: "Idioma para escribir y corregir diarios",
        currentNativeLanguage: "Idioma nativo actual",
        currentCorrectionLanguage: "Idioma de corrección actual",
        
        loadingMessage: "IA está corrigiendo tu diario",
        loadingSubMessage: "Por favor espera un momento",
        savingMessage: "¡Excelente trabajo hoy!",
        savingSubMessage: "¡Gracias por compartir tu maravilloso diario!",
        errorTitle: "Error de corrección",
        confirmButton: "OK",
        retryButton: "Reintentar",
        unknownErrorMessage: "Ocurrió un error desconocido.",
        
        monthNames: ["Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"],
        weekdayNames: ["Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"],
        shortWeekdayNames: ["Dom", "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb"],
        
        greetingWithDiary: { username in
            (title: "Hola, \(username).",
             subtitle: "Espero que hayas tenido un día maravilloso.")
        },
        greetingWithoutDiary: { username in
            (title: "Hola, \(username).",
             subtitle: "¿Cómo estuvo tu día?")
        }
    )
    
    // 태국어
    static let thai = LanguageTexts(
        flag: "🇹🇭",
        locale: Locale(identifier: "th_TH"),
        languageCode: "th",
        languageName: "ไทย",
        
        languageNameTranslations: [
            "ko": "เกาหลี", "en": "อังกฤษ", "ja": "ญี่ปุ่น", "es": "สเปน",
            "th": "ไทย", "de": "เยอรมัน", "zh": "จีน", "ar": "อาหรับ",
            "fr": "ฝรั่งเศส", "it": "อิตาลี", "pt": "โปรตุเกส", "hi": "ฮินดี"
        ],
        
        appDescription: "ไดอารี่เรียนภาษาร่วมกับ AI",
        privacyNotice: "เข้าสู่ระบบอย่างปลอดภัยด้วย Apple\nความเป็นส่วนตัวของคุณได้รับการปกป้อง",
        signingInMessage: "กำลังเข้าสู่ระบบ...",
        signOutButton: "ออกจากระบบ",
        
        // 앱 둘러보기
            appTourButton: "ทัวร์แอป",
            appTourTitle: "เริ่มต้นการเรียนรู้ภาษา\nกับ Kodiary",
            appTourFeature1Title: "การแก้ไขด้วย AI",
            appTourFeature1Description: "เขียนไดอารี่ภาษาใดก็ได้\nและรับการแก้ไขที่เป็นธรรมชาติจาก AI",
            appTourFeature2Title: "การเรียนรู้ส่วนบุคคล",
            appTourFeature2Description: "สัมผัสการเรียนรู้ภาษา\nที่ปรับให้เหมาะกับระดับของคุณ",
            appTourFeature3Title: "ติดตามความก้าวหน้า",
            appTourFeature3Description: "ติดตามความก้าวหน้าประจำวัน\nและรู้สึกถึงการเติบโตอย่างต่อเนื่อง",
            appTourFeature4Title: "หลายภาษา",
            appTourFeature4Description: "เรียนรู้ 12 ภาษาต่างๆ\nเพื่อสื่อสารได้ทุกที่ในโลก",
            appTourGetStarted: "เริ่มต้น",
            appTourSkip: "ข้าม",
        
        // 언어 학습 설정 관련
            languageLearningWelcomeTitle: { username in "\(username)!" },
            languageLearningWelcomeSubtitle: "คุณอยากเรียนภาษาอะไร?",
            languageLearningPrompt: "เลือกภาษาที่จะเรียน",
            languageLearningContinueButton: "เริ่มเรียน",
        
        dateComponents: (year: "yyyy", month: "MMM", weekday: "EEEE"),
        dayDateFormat: "d",
        
        writeButtonText: { correctionLanguageName in "เขียนไดอารี่\(correctionLanguageName)" },
        writeButtonCompletedText: { correctionLanguageName in "ไดอารี่\(correctionLanguageName) [เสร็จแล้ว]" },
        historyButtonText: "ประวัติไดอารี่",
        
        diaryWriteTitle: "ไดอารี่วันนี้",
        diaryWritePlaceholder: "เขียนอย่างอิสระเกี่ยวกับสิ่งที่เกิดขึ้นวันนี้...",
        analyzeDiaryButton: "รับการแก้ไข",
        characterCount: { current, max in "\(current)/\(max)" },
        writeInLanguageText: { languageName in "โปรดเขียนเป็น\(languageName)" },
        correctionLanguagePlaceholder: "เล่าให้ฟังเกี่ยวกับวันของคุณ...",
        
        diaryHistoryTitle: "ประวัติไดอารี่",
        viewDiaryButton: "ดู",
        correctionCountText: { count in "\(count) การแก้ไข" },
        characterCountText: { count in "\(count) ตัวอักษร" },
        noDiaryMessage: "ไม่มีไดอารี่สำหรับวันนี้",
        todayDiaryPrompt: "เขียนไดอารี่",
        
        correctionResultTitle: "ผลการแก้ไข",
        writtenDiaryTitle: "ไดอารี่ของคุณ",
        correctionCompleteTitle: "แก้ไขแล้ว",
        correctionCompleteSubtitle: { count in "\(count) จุดแก้ไข" },
        saveButton: "บันทึก",
        originalExpressionTitle: "ต้นฉบับ",
        correctionSuggestionTitle: "คำแนะนำ",
        explanationTitle: "คำอธิบาย",
        
        diaryDetailTitle: "ผลการแก้ไข",
        
        profileSettingsTitle: "การตั้งค่า",
        profileUserName: "ผู้ใช้",
        profileInfoTitle: "ข้อมูลโปรไฟล์",
        notificationSettingsTitle: "การตั้งค่าการแจ้งเตือน",
        privacySettingsTitle: "การตั้งค่าความเป็นส่วนตัว",
        helpTitle: "ความช่วยเหลือ",
        appInfoTitle: "ข้อมูลแอป",
        
        languageSettingsTitle: "การตั้งค่าภาษา",
        nativeLanguageTab: "ภาษาแม่",
        correctionLanguageTab: "ภาษาแก้ไข",
        nativeLanguageDescription: "ภาษาที่แสดงในอินเทอร์เฟซแอป",
        correctionLanguageDescription: "ภาษาสำหรับเขียนและแก้ไขไดอารี่",
        currentNativeLanguage: "ภาษาแม่ปัจจุบัน",
        currentCorrectionLanguage: "ภาษาแก้ไขปัจจุบัน",
        
        loadingMessage: "AI กำลังแก้ไขไดอารี่ของคุณ",
        loadingSubMessage: "โปรดรอสักครู่",
        savingMessage: "ทำงานได้ดีมากวันนี้!",
        savingSubMessage: "ขอบคุณที่แชร์ไดอารี่ที่ยอดเยี่ยม!",
        errorTitle: "ข้อผิดพลาดในการแก้ไข",
        confirmButton: "ตกลง",
        retryButton: "ลองใหม่",
        unknownErrorMessage: "เกิดข้อผิดพลาดที่ไม่ทราบสาเหตุ",
        
        monthNames: ["ม.ค.", "ก.พ.", "มี.ค.", "เม.ย.", "พ.ค.", "มิ.ย.", "ก.ค.", "ส.ค.", "ก.ย.", "ต.ค.", "พ.ย.", "ธ.ค."],
        weekdayNames: ["วันอาทิตย์", "วันจันทร์", "วันอังคาร", "วันพุธ", "วันพฤหัสบดี", "วันศุกร์", "วันเสาร์"],
        shortWeekdayNames: ["อา", "จ", "อ", "พ", "พฤ", "ศ", "ส"],
        
        greetingWithDiary: { username in
            (title: "สวัสดี, \(username)",
             subtitle: "หวังว่าจะมีวันที่ยอดเยี่ยม")
        },
        greetingWithoutDiary: { username in
            (title: "สวัสดี, \(username)",
             subtitle: "วันนี้เป็นอย่างไรบ้าง?")
        }
    )
    
    // 독일어
    static let german = LanguageTexts(
        flag: "🇩🇪",
        locale: Locale(identifier: "de_DE"),
        languageCode: "de",
        languageName: "Deutsch",
        
        languageNameTranslations: [
            "ko": "Koreanisch", "en": "Englisch", "ja": "Japanisch", "es": "Spanisch",
            "th": "Thailändisch", "de": "Deutsch", "zh": "Chinesisch", "ar": "Arabisch",
            "fr": "Französisch", "it": "Italienisch", "pt": "Portugiesisch", "hi": "Hindi"
        ],
        
        appDescription: "KI-gestütztes Sprachlern-Tagebuch",
        privacyNotice: "Melden Sie sich sicher mit Apple an.\nIhre Privatsphäre ist geschützt.",
        signingInMessage: "Anmeldung läuft...",
        signOutButton: "Abmelden",
        
        // 앱 둘러보기
            appTourButton: "App-Tour",
            appTourTitle: "Beginnen Sie Ihre Sprachlernreise\nmit Kodiary",
            appTourFeature1Title: "KI-Korrekturen",
            appTourFeature1Description: "Schreiben Sie Ihr Tagebuch in jeder Sprache\nund erhalten Sie natürliche KI-Korrekturen",
            appTourFeature2Title: "Personalisiertes Lernen",
            appTourFeature2Description: "Erleben Sie angepasstes Sprachlernen\nmaßgeschneidert für Ihr Niveau",
            appTourFeature3Title: "Fortschrittsverfolgung",
            appTourFeature3Description: "Überwachen Sie Ihren täglichen Lernfortschritt\nund spüren Sie Ihr kontinuierliches Wachstum",
            appTourFeature4Title: "Mehrere Sprachen",
            appTourFeature4Description: "Lernen Sie 12 verschiedene Sprachen\num überall auf der Welt zu kommunizieren",
            appTourGetStarted: "Loslegen",
            appTourSkip: "Überspringen",
        
        // 언어 학습 설정 관련
            languageLearningWelcomeTitle: { username in "\(username)!" },
            languageLearningWelcomeSubtitle: "Welche Sprache möchten Sie lernen?",
            languageLearningPrompt: "Wählen Sie Ihre Lernsprache",
            languageLearningContinueButton: "Lernen beginnen",
        
        dateComponents: (year: "yyyy", month: "MMM", weekday: "EEEE"),
        dayDateFormat: "d",
        
        writeButtonText: { correctionLanguageName in "\(correctionLanguageName) Tagebuch schreiben" },
        writeButtonCompletedText: { correctionLanguageName in "\(correctionLanguageName) Tagebuch [fertig]" },
        historyButtonText: "Tagebuch-Historie",
        
        diaryWriteTitle: "Heutiges Tagebuch",
        diaryWritePlaceholder: "Schreibe frei über das, was heute passiert ist...",
        analyzeDiaryButton: "Korrekturen erhalten",
        characterCount: { current, max in "\(current)/\(max)" },
        writeInLanguageText: { languageName in "Bitte schreibe auf \(languageName)" },
        correctionLanguagePlaceholder: "Erzähl mir von deinem Tag...",
        
        diaryHistoryTitle: "Tagebuch-Historie",
        viewDiaryButton: "Ansehen",
        correctionCountText: { count in "\(count) Korrekturen" },
        characterCountText: { count in "\(count) Zeichen" },
        noDiaryMessage: "Kein Tagebucheintrag für diesen Tag",
        todayDiaryPrompt: "Tagebuch schreiben",
        
        correctionResultTitle: "Korrekturergebnisse",
        writtenDiaryTitle: "Dein Tagebuch",
        correctionCompleteTitle: "Korrigiert",
        correctionCompleteSubtitle: { count in "\(count) Korrekturpunkte" },
        saveButton: "Speichern",
        originalExpressionTitle: "Original",
        correctionSuggestionTitle: "Vorschlag",
        explanationTitle: "Erklärung",
        
        diaryDetailTitle: "Korrekturergebnisse",
        
        profileSettingsTitle: "Einstellungen",
        profileUserName: "Benutzer",
        profileInfoTitle: "Profilinformationen",
        notificationSettingsTitle: "Benachrichtigungseinstellungen",
        privacySettingsTitle: "Datenschutzeinstellungen",
        helpTitle: "Hilfe",
        appInfoTitle: "App-Informationen",
        
        languageSettingsTitle: "Spracheinstellungen",
        nativeLanguageTab: "Muttersprache",
        correctionLanguageTab: "Korrektursprache",
        nativeLanguageDescription: "In der App-Oberfläche angezeigte Sprache",
        correctionLanguageDescription: "Sprache zum Schreiben und Korrigieren von Tagebüchern",
        currentNativeLanguage: "Aktuelle Muttersprache",
        currentCorrectionLanguage: "Aktuelle Korrektursprache",
        
        loadingMessage: "KI korrigiert dein Tagebuch",
        loadingSubMessage: "Bitte warte einen Moment",
        savingMessage: "Großartige Arbeit heute!",
        savingSubMessage: "Danke, dass du dein wunderbares Tagebuch geteilt hast!",
        errorTitle: "Korrekturfehler",
        confirmButton: "OK",
        retryButton: "Erneut versuchen",
        unknownErrorMessage: "Ein unbekannter Fehler ist aufgetreten.",
        
        monthNames: ["Jan", "Feb", "Mär", "Apr", "Mai", "Jun", "Jul", "Aug", "Sep", "Okt", "Nov", "Dez"],
        weekdayNames: ["Sonntag", "Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag"],
        shortWeekdayNames: ["So", "Mo", "Di", "Mi", "Do", "Fr", "Sa"],
        
        greetingWithDiary: { username in
            (title: "Hallo, \(username).",
             subtitle: "Ich hoffe, du hattest einen wunderbaren Tag.")
        },
        greetingWithoutDiary: { username in
            (title: "Hallo, \(username).",
             subtitle: "Wie war dein Tag?")
        }
    )
    
    // 중국어 (간체)
    static let chinese = LanguageTexts(
        flag: "🇨🇳",
        locale: Locale(identifier: "zh_CN"),
        languageCode: "zh",
        languageName: "中文",
        
        languageNameTranslations: [
            "ko": "韩语", "en": "英语", "ja": "日语", "es": "西班牙语",
            "th": "泰语", "de": "德语", "zh": "中文", "ar": "阿拉伯语",
            "fr": "法语", "it": "意大利语", "pt": "葡萄牙语", "hi": "印地语"
        ],
        
        appDescription: "AI驱动的语言学习日记",
        privacyNotice: "通过Apple安全登录。\n您的隐私受到保护。",
        signingInMessage: "正在登录...",
        signOutButton: "退出登录",
        
        // 앱 둘러보기
            appTourButton: "应用导览",
            appTourTitle: "与Kodiary一起\n开始您的语言学习之旅",
            appTourFeature1Title: "AI智能批改",
            appTourFeature1Description: "用任何语言写日记\nAI为您提供自然的批改建议",
            appTourFeature2Title: "个性化学习",
            appTourFeature2Description: "体验根据您的水平\n量身定制的语言学习",
            appTourFeature3Title: "进度跟踪",
            appTourFeature3Description: "监控您的每日学习进度\n感受持续的成长",
            appTourFeature4Title: "多语言支持",
            appTourFeature4Description: "学习12种不同语言\n在世界任何地方都能交流",
            appTourGetStarted: "开始",
            appTourSkip: "跳过",
        
        // 언어 학습 설정 관련
           languageLearningWelcomeTitle: { username in "\(username)！" },
           languageLearningWelcomeSubtitle: "您想学习哪种语言？",
           languageLearningPrompt: "选择您的学习语言",
           languageLearningContinueButton: "开始学习",
        
        dateComponents: (year: "yyyy", month: "M月", weekday: "EEEE"),
        dayDateFormat: "d",
        
        writeButtonText: { correctionLanguageName in "写\(correctionLanguageName)日记" },
        writeButtonCompletedText: { correctionLanguageName in "\(correctionLanguageName)日记 [完成]" },
        historyButtonText: "日记历史",
        
        diaryWriteTitle: "今天的日记",
        diaryWritePlaceholder: "自由写下今天发生的事情...",
        analyzeDiaryButton: "获取批改",
        characterCount: { current, max in "\(current)/\(max)" },
        writeInLanguageText: { languageName in "请用\(languageName)写" },
        correctionLanguagePlaceholder: "告诉我你今天的经历...",
        
        diaryHistoryTitle: "日记历史",
        viewDiaryButton: "查看",
        correctionCountText: { count in "\(count)个批改" },
        characterCountText: { count in "\(count)个字符" },
        noDiaryMessage: "这天没有日记记录",
        todayDiaryPrompt: "写日记",
        
        correctionResultTitle: "批改结果",
        writtenDiaryTitle: "你的日记",
        correctionCompleteTitle: "已批改",
        correctionCompleteSubtitle: { count in "\(count)个批改点" },
        saveButton: "保存",
        originalExpressionTitle: "原文",
        correctionSuggestionTitle: "建议",
        explanationTitle: "解释",
        
        diaryDetailTitle: "批改结果",
        
        profileSettingsTitle: "设置",
        profileUserName: "用户",
        profileInfoTitle: "个人信息",
        notificationSettingsTitle: "通知设置",
        privacySettingsTitle: "隐私设置",
        helpTitle: "帮助",
        appInfoTitle: "应用信息",
        
        languageSettingsTitle: "语言设置",
        nativeLanguageTab: "母语",
        correctionLanguageTab: "批改语言",
        nativeLanguageDescription: "应用界面显示的语言",
        correctionLanguageDescription: "用于写作和批改日记的语言",
        currentNativeLanguage: "当前母语",
        currentCorrectionLanguage: "当前批改语言",
        
        loadingMessage: "AI正在批改你的日记",
        loadingSubMessage: "请稍等",
        savingMessage: "今天做得很棒!",
        savingSubMessage: "感谢分享你精彩的日记!",
        errorTitle: "批改错误",
        confirmButton: "确定",
        retryButton: "重试",
        unknownErrorMessage: "发生未知错误。",
        
        monthNames: ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"],
        weekdayNames: ["星期日", "星期一", "星期二", "星期三", "星期四", "星期五", "星期六"],
        shortWeekdayNames: ["日", "一", "二", "三", "四", "五", "六"],
        
        greetingWithDiary: { username in
            (title: "你好, \(username)。",
             subtitle: "希望你今天过得愉快。")
        },
        greetingWithoutDiary: { username in
            (title: "你好, \(username)。",
             subtitle: "你今天过得怎么样？")
        }
    )
    
    // 아랍어
    static let arabic = LanguageTexts(
        flag: "🇸🇦",
        locale: Locale(identifier: "ar_SA"),
        languageCode: "ar",
        languageName: "العربية",
        
        languageNameTranslations: [
            "ko": "الكورية", "en": "الإنجليزية", "ja": "اليابانية", "es": "الإسبانية",
            "th": "التايلاندية", "de": "الألمانية", "zh": "الصينية", "ar": "العربية",
            "fr": "الفرنسية", "it": "الإيطالية", "pt": "البرتغالية", "hi": "الهندية"
        ],
        
        appDescription: "يوميات تعلم اللغة بالذكاء الاصطناعي",
        privacyNotice: "سجل الدخول بأمان مع Apple.\nخصوصيتك محمية.",
        signingInMessage: "جاري تسجيل الدخول...",
        signOutButton: "تسجيل الخروج",
        
        // 앱 둘러보기
       appTourButton: "جولة التطبيق",
       appTourTitle: "ابدأ رحلة تعلم اللغة\nمع Kodiary",
       appTourFeature1Title: "تصحيحات الذكاء الاصطناعي",
       appTourFeature1Description: "اكتب يومياتك بأي لغة\nواحصل على تصحيحات طبيعية من الذكاء الاصطناعي",
       appTourFeature2Title: "تعلم شخصي",
       appTourFeature2Description: "اختبر تعلم اللغة المخصص\nحسب مستواك",
       appTourFeature3Title: "تتبع التقدم",
       appTourFeature3Description: "راقب تقدمك اليومي في التعلم\nواشعر بنموك المستمر",
       appTourFeature4Title: "لغات متعددة",
       appTourFeature4Description: "تعلم 12 لغة مختلفة\nللتواصل في أي مكان في العالم",
       appTourGetStarted: "ابدأ",
       appTourSkip: "تخطي",
        
        // 언어 학습 설정 관련
            languageLearningWelcomeTitle: { username in "\(username)!" },
            languageLearningWelcomeSubtitle: "أي لغة تريد أن تتعلم؟",
            languageLearningPrompt: "اختر لغة التعلم",
            languageLearningContinueButton: "ابدأ التعلم",
        
        dateComponents: (year: "yyyy", month: "MMM", weekday: "EEEE"),
        dayDateFormat: "d",
        
        writeButtonText: { correctionLanguageName in "كتابة يوميات \(correctionLanguageName)" },
        writeButtonCompletedText: { correctionLanguageName in "يوميات \(correctionLanguageName) [مكتمل]" },
        historyButtonText: "تاريخ اليوميات",
        
        diaryWriteTitle: "يوميات اليوم",
        diaryWritePlaceholder: "اكتب بحرية عما حدث اليوم...",
        analyzeDiaryButton: "الحصول على التصحيحات",
        characterCount: { current, max in "\(current)/\(max)" },
        writeInLanguageText: { languageName in "يرجى الكتابة بـ\(languageName)" },
        correctionLanguagePlaceholder: "أخبرني عن يومك...",
        
        diaryHistoryTitle: "تاريخ اليوميات",
        viewDiaryButton: "عرض",
        correctionCountText: { count in "\(count) تصحيحات" },
        characterCountText: { count in "\(count) حرف" },
        noDiaryMessage: "لا توجد مذكرة يومية لهذا اليوم",
        todayDiaryPrompt: "كتابة يوميات",
        
        correctionResultTitle: "نتائج التصحيح",
        writtenDiaryTitle: "يومياتك",
        correctionCompleteTitle: "مُصحح",
        correctionCompleteSubtitle: { count in "\(count) نقاط تصحيح" },
        saveButton: "حفظ",
        originalExpressionTitle: "الأصل",
        correctionSuggestionTitle: "اقتراح",
        explanationTitle: "شرح",
        
        diaryDetailTitle: "نتائج التصحيح",
        
        profileSettingsTitle: "الإعدادات",
        profileUserName: "المستخدم",
        profileInfoTitle: "معلومات الملف الشخصي",
        notificationSettingsTitle: "إعدادات الإشعارات",
        privacySettingsTitle: "إعدادات الخصوصية",
        helpTitle: "مساعدة",
        appInfoTitle: "معلومات التطبيق",
        
        languageSettingsTitle: "إعدادات اللغة",
        nativeLanguageTab: "اللغة الأم",
        correctionLanguageTab: "لغة التصحيح",
        nativeLanguageDescription: "اللغة المعروضة في واجهة التطبيق",
        correctionLanguageDescription: "اللغة لكتابة وتصحيح اليوميات",
        currentNativeLanguage: "اللغة الأم الحالية",
        currentCorrectionLanguage: "لغة التصحيح الحالية",
        
        loadingMessage: "الذكاء الاصطناعي يصحح يومياتك",
        loadingSubMessage: "يرجى الانتظار لحظة",
        savingMessage: "عمل رائع اليوم!",
        savingSubMessage: "شكراً لمشاركة يومياتك الرائعة!",
        errorTitle: "خطأ في التصحيح",
        confirmButton: "موافق",
        retryButton: "إعادة المحاولة",
        unknownErrorMessage: "حدث خطأ غير معروف.",
        
        monthNames: ["يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو", "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر"],
        weekdayNames: ["الأحد", "الاثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة", "السبت"],
        shortWeekdayNames: ["أحد", "اثن", "ثلا", "أرب", "خمي", "جمع", "سبت"],
        
        greetingWithDiary: { username in
            (title: "مرحباً، \(username).",
             subtitle: "أتمنى أن تكون قد قضيت يوماً رائعاً.")
        },
        greetingWithoutDiary: { username in
            (title: "مرحباً، \(username).",
             subtitle: "كيف كان يومك؟")
        }
    )
    
    // 프랑스어
    static let french = LanguageTexts(
        flag: "🇫🇷",
        locale: Locale(identifier: "fr_FR"),
        languageCode: "fr",
        languageName: "Français",
        
        languageNameTranslations: [
            "ko": "Coréen", "en": "Anglais", "ja": "Japonais", "es": "Espagnol",
            "th": "Thaï", "de": "Allemand", "zh": "Chinois", "ar": "Arabe",
            "fr": "Français", "it": "Italien", "pt": "Portugais", "hi": "Hindi"
        ],
        
        appDescription: "Journal d'apprentissage linguistique avec IA",
        privacyNotice: "Connectez-vous en toute sécurité avec Apple.\nVotre confidentialité est protégée.",
        signingInMessage: "Connexion en cours...",
        signOutButton: "Se Déconnecter",
        
        // 앱 둘러보기
           appTourButton: "Visite de l'App",
           appTourTitle: "Commencez votre voyage d'apprentissage\nlinguistique avec Kodiary",
           appTourFeature1Title: "Corrections IA",
           appTourFeature1Description: "Écrivez votre journal dans n'importe quelle langue\net recevez des corrections naturelles de l'IA",
           appTourFeature2Title: "Apprentissage Personnalisé",
           appTourFeature2Description: "Découvrez l'apprentissage linguistique\nadapté à votre niveau",
           appTourFeature3Title: "Suivi des Progrès",
           appTourFeature3Description: "Surveillez vos progrès quotidiens\net ressentez votre croissance continue",
           appTourFeature4Title: "Langues Multiples",
           appTourFeature4Description: "Apprenez 12 langues différentes\npour communiquer partout dans le monde",
           appTourGetStarted: "Commencer",
           appTourSkip: "Passer",
        
        // 언어 학습 설정 관련
            languageLearningWelcomeTitle: { username in "\(username)!" },
            languageLearningWelcomeSubtitle: "Quelle langue souhaitez-vous apprendre?",
            languageLearningPrompt: "Choisissez votre langue d'apprentissage",
            languageLearningContinueButton: "Commencer à apprendre",
        
        dateComponents: (year: "yyyy", month: "MMM", weekday: "EEEE"),
        dayDateFormat: "d",
        
        writeButtonText: { correctionLanguageName in "Écrire journal \(correctionLanguageName)" },
        writeButtonCompletedText: { correctionLanguageName in "Journal \(correctionLanguageName) [terminé]" },
        historyButtonText: "Historique du journal",
        
        diaryWriteTitle: "Journal d'aujourd'hui",
        diaryWritePlaceholder: "Écrivez librement sur ce qui s'est passé aujourd'hui...",
        analyzeDiaryButton: "Obtenir des corrections",
        characterCount: { current, max in "\(current)/\(max)" },
        writeInLanguageText: { languageName in "Veuillez écrire en \(languageName)" },
        correctionLanguagePlaceholder: "Parlez-moi de votre journée...",
        
        diaryHistoryTitle: "Historique du journal",
        viewDiaryButton: "Voir",
        correctionCountText: { count in "\(count) corrections" },
        characterCountText: { count in "\(count) caractères" },
        noDiaryMessage: "Aucune entrée de journal pour ce jour",
        todayDiaryPrompt: "Écrire journal",
        
        correctionResultTitle: "Résultats de correction",
        writtenDiaryTitle: "Votre journal",
        correctionCompleteTitle: "Corrigé",
        correctionCompleteSubtitle: { count in "\(count) points de correction" },
        saveButton: "Enregistrer",
        originalExpressionTitle: "Original",
        correctionSuggestionTitle: "Suggestion",
        explanationTitle: "Explication",
        
        diaryDetailTitle: "Résultats de correction",
        
        profileSettingsTitle: "Paramètres",
        profileUserName: "Utilisateur",
        profileInfoTitle: "Informations du profil",
        notificationSettingsTitle: "Paramètres de notification",
        privacySettingsTitle: "Paramètres de confidentialité",
        helpTitle: "Aide",
        appInfoTitle: "Informations de l'application",
        
        languageSettingsTitle: "Paramètres de langue",
        nativeLanguageTab: "Langue maternelle",
        correctionLanguageTab: "Langue de correction",
        nativeLanguageDescription: "Langue affichée dans l'interface de l'application",
        correctionLanguageDescription: "Langue pour écrire et corriger les journaux",
        currentNativeLanguage: "Langue maternelle actuelle",
        currentCorrectionLanguage: "Langue de correction actuelle",
        
        loadingMessage: "L'IA corrige votre journal",
        loadingSubMessage: "Veuillez patienter un moment",
        savingMessage: "Excellent travail aujourd'hui!",
        savingSubMessage: "Merci d'avoir partagé votre merveilleux journal!",
        errorTitle: "Erreur de correction",
        confirmButton: "OK",
        retryButton: "Réessayer",
        unknownErrorMessage: "Une erreur inconnue s'est produite.",
        
        monthNames: ["Jan", "Fév", "Mar", "Avr", "Mai", "Jun", "Jul", "Aoû", "Sep", "Oct", "Nov", "Déc"],
        weekdayNames: ["Dimanche", "Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi"],
        shortWeekdayNames: ["Dim", "Lun", "Mar", "Mer", "Jeu", "Ven", "Sam"],
        
        greetingWithDiary: { username in
            (title: "Salut, \(username).",
             subtitle: "J'espère que vous avez passé une journée merveilleuse.")
        },
        greetingWithoutDiary: { username in
            (title: "Salut, \(username).",
             subtitle: "Comment s'est passée votre journée?")
        }
    )
    
    // 이탈리아어
    static let italian = LanguageTexts(
        flag: "🇮🇹",
        locale: Locale(identifier: "it_IT"),
        languageCode: "it",
        languageName: "Italiano",
        
        languageNameTranslations: [
            "ko": "Coreano", "en": "Inglese", "ja": "Giapponese", "es": "Spagnolo",
            "th": "Tailandese", "de": "Tedesco", "zh": "Cinese", "ar": "Arabo",
            "fr": "Francese", "it": "Italiano", "pt": "Portoghese", "hi": "Hindi"
        ],
        
        appDescription: "Diario di apprendimento linguistico con IA",
        privacyNotice: "Accedi in sicurezza con Apple.\nLa tua privacy è protetta.",
        signingInMessage: "Accesso in corso...",
        signOutButton: "Esci",
        
        // 앱 둘러보기
            appTourButton: "Tour dell'App",
            appTourTitle: "Inizia il tuo viaggio di apprendimento\nlinguistico con Kodiary",
            appTourFeature1Title: "Correzioni IA",
            appTourFeature1Description: "Scrivi il tuo diario in qualsiasi lingua\ne ricevi correzioni naturali dall'IA",
            appTourFeature2Title: "Apprendimento Personalizzato",
            appTourFeature2Description: "Sperimenta l'apprendimento linguistico\npersonalizzato per il tuo livello",
            appTourFeature3Title: "Monitoraggio Progressi",
            appTourFeature3Description: "Monitora i tuoi progressi quotidiani\ne senti la tua crescita continua",
            appTourFeature4Title: "Lingue Multiple",
            appTourFeature4Description: "Impara 12 lingue diverse\nper comunicare ovunque nel mondo",
            appTourGetStarted: "Inizia",
            appTourSkip: "Salta",
        
        // 언어 학습 설정 관련
            languageLearningWelcomeTitle: { username in "\(username)!" },
            languageLearningWelcomeSubtitle: "Quale lingua vorresti imparare?",
            languageLearningPrompt: "Scegli la tua lingua di apprendimento",
            languageLearningContinueButton: "Inizia ad imparare",
        
        dateComponents: (year: "yyyy", month: "MMM", weekday: "EEEE"),
        dayDateFormat: "d",
        
        writeButtonText: { correctionLanguageName in "Scrivi diario \(correctionLanguageName)" },
        writeButtonCompletedText: { correctionLanguageName in "Diario \(correctionLanguageName) [completo]" },
        historyButtonText: "Cronologia del diario",
        
        diaryWriteTitle: "Diario di oggi",
        diaryWritePlaceholder: "Scrivi liberamente su quello che è successo oggi...",
        analyzeDiaryButton: "Ottieni correzioni",
        characterCount: { current, max in "\(current)/\(max)" },
        writeInLanguageText: { languageName in "Per favore scrivi in \(languageName)" },
        correctionLanguagePlaceholder: "Raccontami della tua giornata...",
        
        diaryHistoryTitle: "Cronologia del diario",
        viewDiaryButton: "Visualizza",
        correctionCountText: { count in "\(count) correzioni" },
        characterCountText: { count in "\(count) caratteri" },
        noDiaryMessage: "Nessuna voce del diario per questo giorno",
        todayDiaryPrompt: "Scrivi diario",
        
        correctionResultTitle: "Risultati delle correzioni",
        writtenDiaryTitle: "Il tuo diario",
        correctionCompleteTitle: "Corretto",
        correctionCompleteSubtitle: { count in "\(count) punti di correzione" },
        saveButton: "Salva",
        originalExpressionTitle: "Originale",
        correctionSuggestionTitle: "Suggerimento",
        explanationTitle: "Spiegazione",
        
        diaryDetailTitle: "Risultati delle correzioni",
        
        profileSettingsTitle: "Impostazioni",
        profileUserName: "Utente",
        profileInfoTitle: "Informazioni del profilo",
        notificationSettingsTitle: "Impostazioni di notifica",
        privacySettingsTitle: "Impostazioni sulla privacy",
        helpTitle: "Aiuto",
        appInfoTitle: "Informazioni dell'app",
        
        languageSettingsTitle: "Impostazioni della lingua",
        nativeLanguageTab: "Lingua madre",
        correctionLanguageTab: "Lingua di correzione",
        nativeLanguageDescription: "Lingua visualizzata nell'interfaccia dell'app",
        correctionLanguageDescription: "Lingua per scrivere e correggere i diari",
        currentNativeLanguage: "Lingua madre attuale",
        currentCorrectionLanguage: "Lingua di correzione attuale",
        
        loadingMessage: "L'IA sta correggendo il tuo diario",
        loadingSubMessage: "Aspetta un momento per favore",
        savingMessage: "Ottimo lavoro oggi!",
        savingSubMessage: "Grazie per aver condiviso il tuo meraviglioso diario!",
        errorTitle: "Errore di correzione",
        confirmButton: "OK",
        retryButton: "Riprova",
        unknownErrorMessage: "Si è verificato un errore sconosciuto.",
        
        monthNames: ["Gen", "Feb", "Mar", "Apr", "Mag", "Giu", "Lug", "Ago", "Set", "Ott", "Nov", "Dic"],
        weekdayNames: ["Domenica", "Lunedì", "Martedì", "Mercoledì", "Giovedì", "Venerdì", "Sabato"],
        shortWeekdayNames: ["Dom", "Lun", "Mar", "Mer", "Gio", "Ven", "Sab"],
        
        greetingWithDiary: { username in
            (title: "Ciao, \(username).",
             subtitle: "Spero che tu abbia avuto una giornata meravigliosa.")
        },
        greetingWithoutDiary: { username in
            (title: "Ciao, \(username).",
             subtitle: "Com'è andata la tua giornata?")
        }
    )
    
    // 포르투갈어
    static let portuguese = LanguageTexts(
        flag: "🇵🇹",
        locale: Locale(identifier: "pt_PT"),
        languageCode: "pt",
        languageName: "Português",
        
        languageNameTranslations: [
            "ko": "Coreano", "en": "Inglês", "ja": "Japonês", "es": "Espanhol",
            "th": "Tailandês", "de": "Alemão", "zh": "Chinês", "ar": "Árabe",
            "fr": "Francês", "it": "Italiano", "pt": "Português", "hi": "Hindi"
        ],
        
        appDescription: "Diário de aprendizado de idiomas com IA",
        privacyNotice: "Entre com segurança usando Apple.\nSua privacidade está protegida.",
        signingInMessage: "Entrando...",
        signOutButton: "Sair",
        
        // 앱 둘러보기
            appTourButton: "Tour do App",
            appTourTitle: "Comece sua jornada de aprendizado\nde idiomas com Kodiary",
            appTourFeature1Title: "Correções IA",
            appTourFeature1Description: "Escreva seu diário em qualquer idioma\ne receba correções naturais da IA",
            appTourFeature2Title: "Aprendizado Personalizado",
            appTourFeature2Description: "Experimente aprendizado de idiomas\npersonalizado para seu nível",
            appTourFeature3Title: "Acompanhamento de Progresso",
            appTourFeature3Description: "Monitore seu progresso diário de aprendizado\ne sinta seu crescimento contínuo",
            appTourFeature4Title: "Múltiplos Idiomas",
            appTourFeature4Description: "Aprenda 12 idiomas diferentes\npara se comunicar em qualquer lugar do mundo",
            appTourGetStarted: "Começar",
            appTourSkip: "Pular",
        
        // 언어 학습 설정 관련
            languageLearningWelcomeTitle: { username in "\(username)!" },
            languageLearningWelcomeSubtitle: "Qual idioma você gostaria de aprender?",
            languageLearningPrompt: "Escolha seu idioma de aprendizado",
            languageLearningContinueButton: "Começar a aprender",
        
        dateComponents: (year: "yyyy", month: "MMM", weekday: "E"),
        dayDateFormat: "d",
        
        writeButtonText: { correctionLanguageName in "Escrever diário \(correctionLanguageName)" },
        writeButtonCompletedText: { correctionLanguageName in "Diário \(correctionLanguageName) [concluído]" },
        historyButtonText: "Histórico do diário",
        
        diaryWriteTitle: "Diário de hoje",
        diaryWritePlaceholder: "Escreva livremente sobre o que aconteceu hoje...",
        analyzeDiaryButton: "Obter correções",
        characterCount: { current, max in "\(current)/\(max)" },
        writeInLanguageText: { languageName in "Por favor escreva em \(languageName)" },
        correctionLanguagePlaceholder: "Conte-me sobre o seu dia...",
        
        diaryHistoryTitle: "Histórico do diário",
        viewDiaryButton: "Ver",
        correctionCountText: { count in "\(count) correções" },
        characterCountText: { count in "\(count) caracteres" },
        noDiaryMessage: "Nenhuma entrada de diário para este dia",
        todayDiaryPrompt: "Escrever diário",
        
        correctionResultTitle: "Resultados da correção",
        writtenDiaryTitle: "Seu diário",
        correctionCompleteTitle: "Corrigido",
        correctionCompleteSubtitle: { count in "\(count) pontos de correção" },
        saveButton: "Salvar",
        originalExpressionTitle: "Original",
        correctionSuggestionTitle: "Sugestão",
        explanationTitle: "Explicação",
        
        diaryDetailTitle: "Resultados da correção",
        
        profileSettingsTitle: "Configurações",
        profileUserName: "Usuário",
        profileInfoTitle: "Informações do perfil",
        notificationSettingsTitle: "Configurações de notificação",
        privacySettingsTitle: "Configurações de privacidade",
        helpTitle: "Ajuda",
        appInfoTitle: "Informações do app",
        
        languageSettingsTitle: "Configurações de idioma",
        nativeLanguageTab: "Idioma nativo",
        correctionLanguageTab: "Idioma de correção",
        nativeLanguageDescription: "Idioma exibido na interface do app",
        correctionLanguageDescription: "Idioma para escrever e corrigir diários",
        currentNativeLanguage: "Idioma nativo atual",
        currentCorrectionLanguage: "Idioma de correção atual",
        
        loadingMessage: "IA está corrigindo seu diário",
        loadingSubMessage: "Por favor aguarde um momento",
        savingMessage: "Excelente trabalho hoje!",
        savingSubMessage: "Obrigado por compartilhar seu maravilhoso diário!",
        errorTitle: "Erro de correção",
        confirmButton: "OK",
        retryButton: "Tentar novamente",
        unknownErrorMessage: "Ocorreu um erro desconhecido.",
        
        monthNames: ["Jan", "Fev", "Mar", "Abr", "Mai", "Jun", "Jul", "Ago", "Set", "Out", "Nov", "Dez"],
        weekdayNames: ["Domingo", "Segunda-feira", "Terça-feira", "Quarta-feira", "Quinta-feira", "Sexta-feira", "Sábado"],
        shortWeekdayNames: ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"],
        
        greetingWithDiary: { username in
            (title: "Olá, \(username).",
             subtitle: "Espero que tenha tido um dia maravilhoso.")
        },
        greetingWithoutDiary: { username in
            (title: "Olá, \(username).",
             subtitle: "Como foi o seu dia?")
        }
    )
    
    // 힌디어
    static let hindi = LanguageTexts(
        flag: "🇮🇳",
        locale: Locale(identifier: "hi_IN"),
        languageCode: "hi",
        languageName: "हिन्दी",
        
        languageNameTranslations: [
            "ko": "कोरियाई", "en": "अंग्रेजी", "ja": "जापानी", "es": "स्पेनिश",
            "th": "थाई", "de": "जर्मन", "zh": "चीनी", "ar": "अरबी",
            "fr": "फ्रेंच", "it": "इतालवी", "pt": "पुर्तगाली", "hi": "हिन्दी"
        ],
        
        appDescription: "AI के साथ भाषा सीखने की डायरी",
        privacyNotice: "Apple के साथ सुरक्षित रूप से साइन इन करें।\nआपकी गोपनीयता सुरक्षित है।",
        signingInMessage: "साइन इन हो रहे हैं...",
        signOutButton: "साइन आउट",
        
        // 앱 둘러보기
            appTourButton: "ऐप टूर",
            appTourTitle: "Kodiary के साथ अपनी भाषा सीखने\nकी यात्रा शुरू करें",
            appTourFeature1Title: "AI सुधार",
            appTourFeature1Description: "किसी भी भाषा में अपनी डायरी लिखें\nऔर AI से प्राकृतिक सुधार प्राप्त करें",
            appTourFeature2Title: "व्यक्तिगत शिक्षा",
            appTourFeature2Description: "अपने स्तर के अनुकूल\nव्यक्तिगत भाषा शिक्षा का अनुभव करें",
            appTourFeature3Title: "प्रगति ट्रैकिंग",
            appTourFeature3Description: "अपनी दैनिक सीखने की प्रगति को\nट्रैक करें और निरंतर विकास महसूस करें",
            appTourFeature4Title: "कई भाषाएं",
            appTourFeature4Description: "12 विभिन्न भाषाएं सीखें\nदुनिया में कहीं भी संवाद करने के लिए",
            appTourGetStarted: "शुरू करें",
            appTourSkip: "छोड़ें",
        
        // 언어 학습 설정 관련
            languageLearningWelcomeTitle: { username in "\(username)!" },
            languageLearningWelcomeSubtitle: "आप कौन सी भाषा सीखना चाहते हैं?",
            languageLearningPrompt: "अपनी सीखने की भाषा चुनें",
            languageLearningContinueButton: "सीखना शुरू करें",
        
        dateComponents: (year: "yyyy", month: "MMM", weekday: "EEEE"),
        dayDateFormat: "d",
        
        writeButtonText: { correctionLanguageName in "\(correctionLanguageName) डायरी लिखें" },
        writeButtonCompletedText: { correctionLanguageName in "\(correctionLanguageName) डायरी [पूर्ण]" },
        historyButtonText: "डायरी इतिहास",
        
        diaryWriteTitle: "आज की डायरी",
        diaryWritePlaceholder: "आज जो कुछ हुआ उसके बारे में स्वतंत्र रूप से लिखें...",
        analyzeDiaryButton: "सुधार प्राप्त करें",
        characterCount: { current, max in "\(current)/\(max)" },
        writeInLanguageText: { languageName in "कृपया \(languageName) में लिखें" },
        correctionLanguagePlaceholder: "मुझे अपने दिन के बारे में बताएं...",
        
        diaryHistoryTitle: "डायरी इतिहास",
        viewDiaryButton: "देखें",
        correctionCountText: { count in "\(count) सुधार" },
        characterCountText: { count in "\(count) अक्षर" },
        noDiaryMessage: "इस दिन के लिए कोई डायरी प्रविष्टि नहीं",
        todayDiaryPrompt: "डायरी लिखें",
        
        correctionResultTitle: "सुधार परिणाम",
        writtenDiaryTitle: "आपकी डायरी",
        correctionCompleteTitle: "सुधारा गया",
        correctionCompleteSubtitle: { count in "\(count) सुधार बिंदु" },
        saveButton: "सेव करें",
        originalExpressionTitle: "मूल",
        correctionSuggestionTitle: "सुझाव",
        explanationTitle: "व्याख्या",
        
        diaryDetailTitle: "सुधार परिणाम",
        
        profileSettingsTitle: "सेटिंग्स",
        profileUserName: "उपयोगकर्ता",
        profileInfoTitle: "प्रोफ़ाइल जानकारी",
        notificationSettingsTitle: "सूचना सेटिंग्स",
        privacySettingsTitle: "गोपनीयता सेटिंग्स",
        helpTitle: "सहायता",
        appInfoTitle: "ऐप जानकारी",
        
        languageSettingsTitle: "भाषा सेटिंग्स",
        nativeLanguageTab: "मातृभाषा",
        correctionLanguageTab: "सुधार भाषा",
        nativeLanguageDescription: "ऐप इंटरफ़ेस में प्रदर्शित भाषा",
        correctionLanguageDescription: "डायरी लिखने और सुधारने के लिए भाषा",
        currentNativeLanguage: "वर्तमान मातृभाषा",
        currentCorrectionLanguage: "वर्तमान सुधार भाषा",
        
        loadingMessage: "AI आपकी डायरी सुधार रहा है",
        loadingSubMessage: "कृपया एक क्षण प्रतीक्षा करें",
        savingMessage: "आज बहुत अच्छा काम!",
        savingSubMessage: "आपकी अद्भुत डायरी साझा करने के लिए धन्यवाद!",
        errorTitle: "सुधार त्रुटि",
        confirmButton: "ठीक है",
        retryButton: "पुनः प्रयास",
        unknownErrorMessage: "एक अज्ञात त्रुटि हुई।",
        
        monthNames: ["जन", "फर", "मार", "अप्र", "मई", "जून", "जुल", "अग", "सित", "अक्त", "नव", "दिस"],
        weekdayNames: ["रविवार", "सोमवार", "मंगलवार", "बुधवार", "गुरुवार", "शुक्रवार", "शनिवार"],
        shortWeekdayNames: ["रवि", "सोम", "मंग", "बुध", "गुरु", "शुक्र", "शनि"],
        
        greetingWithDiary: { username in
            (title: "नमस्ते, \(username)।",
             subtitle: "आशा है आपका दिन अच्छा रहा।")
        },
        greetingWithoutDiary: { username in
            (title: "नमस्ते, \(username)।",
             subtitle: "आपका दिन कैसा रहा?")
        }
    )
    
    // 사용 가능한 언어 목록 (확장됨)
    static let availableLanguages: [LanguageTexts] = [
        korean, english, japanese, spanish, thai, german,
        chinese, arabic, french, italian, portuguese, hindi
    ]
}
