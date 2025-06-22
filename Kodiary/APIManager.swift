//
//  APIManager.swift
//  Kodiary
//
//  Created by Niko on 6/20/25.
//

import Foundation

class APIManager: ObservableObject {
    static let shared = APIManager()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let apiKey = "secret"
    
    private init() {}
    
    // MARK: - Public Methods
    func analyzeDiary(text: String) async throws -> [CorrectionItem] {
        return try await analyzeDiary(text: text, correctionLanguage: "ko", explanationLanguage: "ko")
    }
    
    func analyzeDiary(text: String, correctionLanguage: String, explanationLanguage: String) async throws -> [CorrectionItem] {
        guard !text.isEmpty else { throw APIError.emptyText }
        
        // API 키 체크
        guard apiKey.hasPrefix("sk-") && apiKey.count > 20 else {
            print("⚠️ API 키가 유효하지 않습니다")
            return createFallbackData(explanationLanguage)
        }
        
        await updateLoadingState(true)
        
        do {
            let corrections = try await performAPICall(text, correctionLanguage, explanationLanguage)
            await updateLoadingState(false)
            return corrections
        } catch {
            await updateLoadingState(false, error.localizedDescription)
            throw error
        }
    }
    
    // MARK: - Private Methods
    private func updateLoadingState(_ loading: Bool, _ error: String? = nil) async {
        await MainActor.run {
            isLoading = loading
            errorMessage = error
        }
    }
    
    private func performAPICall(_ text: String, _ correctionLang: String, _ explanationLang: String) async throws -> [CorrectionItem] {
        let url = URL(string: baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": getSystemPrompt(explanationLang)],
                ["role": "user", "content": createPrompt(text, correctionLang, explanationLang)]
            ],
            "temperature": 0.3,
            "max_tokens": 1000
        ] as [String : Any]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 { throw APIError.invalidAPIKey }
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        return try parseResponse(data)
    }
    
    private func parseResponse(_ data: Data) throws -> [CorrectionItem] {
        struct APIResponse: Codable {
            let choices: [Choice]
            struct Choice: Codable {
                let message: Message
                struct Message: Codable {
                    let content: String
                }
            }
        }
        
        let response = try JSONDecoder().decode(APIResponse.self, from: data)
        guard let content = response.choices.first?.message.content else {
            throw APIError.emptyResponse
        }
        
        struct CorrectionResponse: Codable {
            let corrections: [CorrectionData]
            struct CorrectionData: Codable {
                let original: String
                let corrected: String
                let explanation: String
                let type: String
            }
        }
        
        let correctionResponse = try JSONDecoder().decode(CorrectionResponse.self, from: content.data(using: .utf8)!)
        
        return correctionResponse.corrections.map { correction in
            CorrectionItem(
                original: correction.original,
                corrected: correction.corrected,
                explanation: correction.explanation,
                type: correction.type
            )
        }
    }
    
    // MARK: - Language Support
    private func getSystemPrompt(_ language: String) -> String {
        switch language {
        case "ko":
            return "당신은 외국어를 배우는 학습자를 위한 친절한 글쓰기 선생님입니다. 초급 학습자도 이해할 수 있도록 쉽고 친근하게 설명해주세요. 반드시 올바른 JSON 형식으로만 응답해주세요."
        case "en":
            return "You are a friendly writing teacher for language learners. Please explain in a simple way that even beginners can understand. Please respond only in correct JSON format."
        case "ja":
            return "あなたは外国語を学ぶ学習者のための親切な文章の先生です。初級学習者でも理解できるように簡単で親しみやすく説明してください。必ず正しいJSON形式でのみ回答してください。"
        default:
            return "You are a friendly writing teacher. Please respond only in JSON format."
        }
    }
    
    private func createPrompt(_ text: String, _ correctionLang: String, _ explanationLang: String) -> String {
        let targetLang = getLanguageName(correctionLang, explanationLang)
        let instructions = getInstructions(explanationLang, targetLang)
        let jsonFormat = getJSONFormat(explanationLang)
        
        return "\(instructions)\n\n텍스트: \"\(text)\"\n\n\(jsonFormat)"
    }
    
    private func getLanguageName(_ correctionLang: String, _ explanationLang: String) -> String {
        switch (correctionLang, explanationLang) {
        case ("ko", "ko"): return "한국어"
        case ("ko", "en"): return "Korean"
        case ("ko", "ja"): return "韓国語"
        case ("en", "ko"): return "영어"
        case ("en", "en"): return "English"
        case ("en", "ja"): return "英語"
        case ("ja", "ko"): return "일본어"
        case ("ja", "en"): return "Japanese"
        case ("ja", "ja"): return "日本語"
        default: return correctionLang
        }
    }
    
    private func getInstructions(_ explanationLang: String, _ targetLang: String) -> String {
        switch explanationLang {
        case "ko":
            return """
            \(targetLang) 학습자의 일기를 첨삭해주세요.
            - 최대 3개 첨삭
            - 초급자도 이해할 수 있는 쉬운 설명
            - JSON 형식으로만 응답
            """
        case "en":
            return """
            Please correct a \(targetLang) learner's diary.
            - Maximum 3 corrections
            - Simple explanations for beginners
            - Respond only in JSON format
            """
        case "ja":
            return """
            \(targetLang)学習者の日記を添削してください。
            - 最大3個の添削
            - 初級者でも理解できる簡単な説明
            - JSON形式でのみ回答
            """
        default:
            return "Please correct the text and respond in JSON format."
        }
    }
    
    private func getJSONFormat(_ explanationLang: String) -> String {
        let typeLabels = getTypeLabels(explanationLang)
        let labels = getFieldLabels(explanationLang)
        
        return """
        JSON 형식:
        {
          "corrections": [
            {
              "original": "\(labels.original)",
              "corrected": "\(labels.corrected)",
              "explanation": "\(labels.explanation)",
              "type": "\(typeLabels.joined(separator: "\" 또는 \""))"
            }
          ]
        }
        """
    }
    
    private func getTypeLabels(_ language: String) -> [String] {
        switch language {
        case "ko": return ["문법", "맞춤법", "표현"]
        case "en": return ["Grammar", "Spelling", "Expression"]
        case "ja": return ["文法", "スペル", "表現"]
        default: return ["Grammar", "Spelling", "Expression"]
        }
    }
    
    private func getFieldLabels(_ language: String) -> (original: String, corrected: String, explanation: String) {
        switch language {
        case "ko": return ("수정 전 텍스트", "수정 후 텍스트", "초급자용 설명")
        case "en": return ("Original text", "Corrected text", "Beginner explanation")
        case "ja": return ("修正前テキスト", "修正後テキスト", "初級者向け説明")
        default: return ("Original", "Corrected", "Explanation")
        }
    }
    
    private func getAPIKeyErrorMessage(_ language: String) -> String {
        switch language {
        case "ko": return "API 키가 유효하지 않아 더미 데이터를 표시하고 있습니다."
        case "en": return "Displaying dummy data because API key is invalid."
        case "ja": return "APIキーが無効なため、ダミーデータを表示しています。"
        default: return "API key is invalid."
        }
    }
    
    private func createFallbackData(_ explanationLang: String) -> [CorrectionItem] {
        let message = getAPIKeyErrorMessage(explanationLang)
        let typeLabels = getTypeLabels(explanationLang)
        
        return [
            CorrectionItem(
                original: "API 키 오류",
                corrected: "실제 API 키를 설정해주세요",
                explanation: message,
                type: typeLabels[0]
            )
        ]
    }
}

// MARK: - API Errors
enum APIError: LocalizedError {
    case emptyText, invalidAPIKey, invalidURL, invalidResponse, httpError(Int), emptyResponse, invalidJSON
    
    var errorDescription: String? {
        switch self {
        case .emptyText: return "일기 내용을 입력해주세요."
        case .invalidAPIKey: return "API 키 오류입니다."
        case .invalidURL: return "서버 연결 오류입니다."
        case .invalidResponse: return "서버 응답 오류입니다."
        case .httpError(let code): return "서버 오류 (코드: \(code))"
        case .emptyResponse: return "AI 응답을 받지 못했습니다."
        case .invalidJSON: return "AI 응답 처리 중 오류가 발생했습니다."
        }
    }
}
