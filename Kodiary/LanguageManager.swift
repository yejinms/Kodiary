//
//  LanguageManager.swift
//  Kodiary
//
//  Created by Niko on 6/22/25.
//

import Foundation
import SwiftUI

// 지원하는 언어 열거형
enum SupportedLanguage: String, CaseIterable, Identifiable {
    case korean = "ko"
    case english = "en"
    case spanish = "es"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .korean:
            return "한국어"
        case .english:
            return "English"
        case .spanish:
            return "Español"
        }
    }
    
    var flag: String {
        switch self {
        case .korean:
            return "🇰🇷"
        case .english:
            return "🇺🇸"
        case .spanish:
            return "🇪🇸"
        }
    }
    
    // 날짜 구성 요소들을 분리해서 반환
    var dateComponents: (year: String, month: String, weekday: String) {
        switch self {
        case .korean:
            return ("yyyy", "M월", "EEEE")
        case .english:
            return ("yyyy", "MMMM", "EEEE")
        case .spanish:
            return ("yyyy", "MMMM", "EEEE")
        }
    }
    
    var dayDateFormat: String {
        return "d"
    }
    
    var locale: Locale {
        switch self {
        case .korean:
            return Locale(identifier: "ko_KR")
        case .english:
            return Locale(identifier: "en_US")
        case .spanish:
            return Locale(identifier: "es_ES")
        }
    }
    
    // 인사말 텍스트
    func greetingWithDiary(username: String) -> (title: String, subtitle: String) {
        switch self {
        case .korean:
            return ("안녕 \(username).", "멋진 하루 보내세요!")
        case .english:
            return ("Hello \(username).", "Have a wonderful day!")
        case .spanish:
            return ("Hola \(username).", "¡Que tengas un día maravilloso!")
        }
    }
    
    func greetingWithoutDiary(username: String) -> (title: String, subtitle: String) {
        switch self {
        case .korean:
            return ("안녕 \(username)!", "오늘은 어떤 하루를 보냈나요? ✨")
        case .english:
            return ("Hello \(username)!", "How was your day today? ✨")
        case .spanish:
            return ("¡Hola \(username)!", "¿Cómo fue tu día hoy? ✨")
        }
    }
    
    // 버튼 텍스트
    var writeButtonText: String {
        switch self {
        case .korean:
            return "일기 쓰기"
        case .english:
            return "Write Diary"
        case .spanish:
            return "Escribir Diario"
        }
    }
    
    var writeButtonCompletedText: String {
        switch self {
        case .korean:
            return "일기 쓰기 [오늘 완료]"
        case .english:
            return "Write Diary [Today Completed]"
        case .spanish:
            return "Escribir Diario [Hoy Completado]"
        }
    }
    
    var historyButtonText: String {
        switch self {
        case .korean:
            return "일기 보기"
        case .english:
            return "View Diary"
        case .spanish:
            return "Ver Diario"
        }
    }
}

// 언어 설정 관리 클래스
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: SupportedLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "selectedLanguage")
        }
    }
    
    private init() {
        let savedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") ?? SupportedLanguage.korean.rawValue
        self.currentLanguage = SupportedLanguage(rawValue: savedLanguage) ?? .korean
    }
    
    func setLanguage(_ language: SupportedLanguage) {
        currentLanguage = language
    }
}
