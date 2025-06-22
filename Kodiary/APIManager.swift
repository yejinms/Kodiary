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
    
    // 실제 API 키
    private let apiKey = "secret"
    
    private init() {}
    
    // API 키 유효성 검사
    private func hasValidAPIKey() -> Bool {
        return apiKey.hasPrefix("sk-") && apiKey.count > 20
    }
    
    // MARK: - 기존 함수 (하위 호환성)
    func analyzeDiary(text: String) async throws -> [CorrectionItem] {
        return try await analyzeDiary(
            text: text,
            correctionLanguage: "ko",
            explanationLanguage: "ko"
        )
    }
    
    // MARK: - 새로운 다국어 지원 함수
    func analyzeDiary(
        text: String,
        correctionLanguage: String,
        explanationLanguage: String
    ) async throws -> [CorrectionItem] {
        guard !text.isEmpty else {
            throw APIError.emptyText
        }
        
        // API 키 체크
        guard hasValidAPIKey() else {
            print("⚠️ API 키가 유효하지 않습니다")
            return createDevelopmentFallback(
                correctionLanguage: correctionLanguage,
                explanationLanguage: explanationLanguage
            )
        }
        
        print("✅ API 키 유효 - 실제 AI 호출 시작")
        print("📝 첨삭 언어: \(correctionLanguage)")
        print("🌍 설명 언어: \(explanationLanguage)")
        
        // UI 업데이트
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let corrections = try await requestCorrection(
                for: text,
                correctionLanguage: correctionLanguage,
                explanationLanguage: explanationLanguage
            )
            
            await MainActor.run {
                isLoading = false
            }
            
            return corrections
            
        } catch {
            print("❌ API 호출 에러: \(error)")
            
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }
            
            // 에러 시에도 폴백 데이터 대신 에러 던지기
            throw error
        }
    }
    
    // MARK: - OpenAI API 호출 (다국어 지원)
    private func requestCorrection(
        for text: String,
        correctionLanguage: String,
        explanationLanguage: String
    ) async throws -> [CorrectionItem] {
        print("🤖 OpenAI API 요청 시작")
        
        guard let url = URL(string: baseURL) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = createRequestBody(
            for: text,
            correctionLanguage: correctionLanguage,
            explanationLanguage: explanationLanguage
        )
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("📤 API 요청 전송 중...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("📥 API 응답 받음 - 상태 코드: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                print("❌ 401 에러: API 키가 잘못되었습니다")
                throw APIError.invalidAPIKey
            }
            print("❌ HTTP 에러: \(httpResponse.statusCode)")
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        return try parseResponse(data)
    }
    
    // MARK: - 요청 바디 생성 (다국어 지원)
    private func createRequestBody(
        for text: String,
        correctionLanguage: String,
        explanationLanguage: String
    ) -> [String: Any] {
        let prompt = createCorrectionPrompt(
            for: text,
            correctionLanguage: correctionLanguage,
            explanationLanguage: explanationLanguage
        )
        
        let systemMessage = getSystemMessage(explanationLanguage: explanationLanguage)
        
        return [
            "model": "gpt-4o-mini",
            "messages": [
                [
                    "role": "system",
                    "content": systemMessage
                ],
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "temperature": 0.3,
            "max_tokens": 1000
        ]
    }
    
    // MARK: - 시스템 메시지 (언어별)
    private func getSystemMessage(explanationLanguage: String) -> String {
        switch explanationLanguage {
        case "ko":
            return """
            당신은 외국어를 배우는 학습자를 위한 친절한 글쓰기 선생님입니다.
            초급 학습자도 이해할 수 있도록 쉽고 친근하게 설명해주세요.
            반드시 올바른 JSON 형식으로만 응답해주세요.
            """
        case "en":
            return """
            You are a friendly writing teacher for language learners.
            Please explain in a simple and friendly way that even beginner learners can understand.
            Please respond only in correct JSON format.
            """
        case "ja":
            return """
            あなたは外国語を学ぶ学習者のための親切な文章の先生です。
            初級学習者でも理解できるように簡単で親しみやすく説明してください。
            必ず正しいJSON形式でのみ回答してください。
            """
        default:
            return """
            You are a friendly writing teacher for language learners.
            Please respond only in correct JSON format.
            """
        }
    }
    
    // MARK: - 첨삭 프롬프트 생성 (다국어 지원)
    private func createCorrectionPrompt(
        for text: String,
        correctionLanguage: String,
        explanationLanguage: String
    ) -> String {
        let languageName = getLanguageName(correctionLanguage, in: explanationLanguage)
        let typeLabels = getTypeLabels(explanationLanguage)
        let instructions = getInstructions(explanationLanguage, targetLanguage: languageName)
        
        return """
        \(instructions)
        
        \(getTextLabel(explanationLanguage)): "\(text)"
        
        \(getOutputFormatLabel(explanationLanguage)):
        {
          "corrections": [
            {
              "original": "\(getOriginalLabel(explanationLanguage))",
              "corrected": "\(getCorrectedLabel(explanationLanguage))",
              "explanation": "\(getExplanationLabel(explanationLanguage))",
              "type": "\(typeLabels.joined(separator: "\" // 또는 \""))"
            }
          ]
        }
        """
    }
    
    // MARK: - 언어별 텍스트 함수들
    private func getLanguageName(_ code: String, in explanationLang: String) -> String {
        switch (code, explanationLang) {
        case ("ko", "ko"): return "한국어"
        case ("ko", "en"): return "Korean"
        case ("ko", "ja"): return "韓国語"
        case ("en", "ko"): return "영어"
        case ("en", "en"): return "English"
        case ("en", "ja"): return "英語"
        case ("ja", "ko"): return "일본어"
        case ("ja", "en"): return "Japanese"
        case ("ja", "ja"): return "日本語"
        default: return code
        }
    }
    
    private func getTypeLabels(_ language: String) -> [String] {
        switch language {
        case "ko": return ["문법", "맞춤법", "표현"]
        case "en": return ["Grammar", "Spelling", "Expression"]
        case "ja": return ["文法", "スペル", "表現"]
        default: return ["Grammar", "Spelling", "Expression"]
        }
    }
    
    private func getInstructions(_ explanationLang: String, targetLanguage: String) -> String {
        switch explanationLang {
        case "ko":
            return """
            아래는 \(targetLanguage)를 배우는 학습자가 쓴 일기입니다. 초급 학습자도 이해할 수 있도록 문법, 맞춤법, 표현을 친절하게 첨삭해주세요.
            
            첨삭 규칙:
            - 첨삭은 최대 3개까지만 해주세요
            - 설명은 반드시 초급자도 이해할 수 있도록 쉬운 말로 써주세요
            - JSON 외의 어떠한 사족도 달지 마시오
            """
        case "en":
            return """
            Below is a diary written by a learner studying \(targetLanguage). Please kindly correct grammar, spelling, and expressions so that even beginner learners can understand.
            
            Correction rules:
            - Please provide only up to 3 corrections
            - Explanations must be written in simple language that even beginners can understand
            - Do not add any extra text outside of JSON
            """
        case "ja":
            return """
            以下は\(targetLanguage)を学ぶ学習者が書いた日記です。初級学習者でも理解できるように文法、スペル、表現を親切に添削してください。
            
            添削ルール:
            - 添削は最大3個まででお願いします
            - 説明は必ず初級者でも理解できるような簡単な言葉で書いてください
            - JSON以外の余計な文章は付けないでください
            """
        default:
            return "Please correct the following text and respond in JSON format only."
        }
    }
    
    private func getTextLabel(_ language: String) -> String {
        switch language {
        case "ko": return "일기 내용"
        case "en": return "Diary content"
        case "ja": return "日記の内容"
        default: return "Text"
        }
    }
    
    private func getOutputFormatLabel(_ language: String) -> String {
        switch language {
        case "ko": return "출력 JSON 형식"
        case "en": return "Output JSON format"
        case "ja": return "出力JSON形式"
        default: return "Output JSON format"
        }
    }
    
    private func getOriginalLabel(_ language: String) -> String {
        switch language {
        case "ko": return "잘못 쓴 문장 또는 단어"
        case "en": return "Incorrect sentence or word"
        case "ja": return "間違った文章または単語"
        default: return "Original text"
        }
    }
    
    private func getCorrectedLabel(_ language: String) -> String {
        switch language {
        case "ko": return "자연스러운 문장 또는 단어"
        case "en": return "Natural sentence or word"
        case "ja": return "自然な文章または単語"
        default: return "Corrected text"
        }
    }
    
    private func getExplanationLabel(_ language: String) -> String {
        switch language {
        case "ko": return "왜 이렇게 쓰는지 초급자도 이해할 수 있는 쉬운 설명"
        case "en": return "Easy explanation that even beginners can understand"
        case "ja": return "初級者でも理解できる簡単な説明"
        default: return "Explanation"
        }
    }
    
    // MARK: - 응답 파싱 (동일)
    private func parseResponse(_ data: Data) throws -> [CorrectionItem] {
        struct OpenAIResponse: Codable {
            let choices: [Choice]
            struct Choice: Codable {
                let message: Message
                struct Message: Codable {
                    let content: String
                }
            }
        }
        
        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        guard let content = openAIResponse.choices.first?.message.content else {
            throw APIError.emptyResponse
        }
        
        print("📝 GPT 응답 내용:")
        print(content)
        
        return try parseCorrectionContent(content)
    }
    
    // MARK: - 첨삭 내용 파싱 (동일)
    private func parseCorrectionContent(_ content: String) throws -> [CorrectionItem] {
        let cleanContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let jsonData = cleanContent.data(using: .utf8) else {
            throw APIError.invalidJSON
        }
        
        do {
            struct CorrectionResponse: Codable {
                let corrections: [CorrectionData]
                struct CorrectionData: Codable {
                    let original: String
                    let corrected: String
                    let explanation: String
                    let type: String
                }
            }
            
            let response = try JSONDecoder().decode(CorrectionResponse.self, from: jsonData)
            
            let correctionItems = response.corrections.map { correction in
                CorrectionItem(
                    original: correction.original,
                    corrected: correction.corrected,
                    explanation: correction.explanation,
                    type: correction.type
                )
            }
            
            print("✅ 실제 AI 첨삭 \(correctionItems.count)개 파싱 완료")
            return correctionItems
            
        } catch {
            print("❌ JSON 파싱 에러: \(error)")
            print("📄 파싱 실패한 내용: \(content)")
            throw APIError.invalidJSON
        }
    }
    
    // MARK: - 개발용 폴백 데이터 (다국어 지원)
    private func createDevelopmentFallback(
        correctionLanguage: String,
        explanationLanguage: String
    ) -> [CorrectionItem] {
        print("⚠️ 폴백 데이터 사용 중")
        
        let explanation = getAPIKeyErrorMessage(explanationLanguage)
        let typeLabel = getTypeLabels(explanationLanguage)[0] // "문법", "Grammar", "文法"
        
        return [
            CorrectionItem(
                original: "API 키 오류",
                corrected: "실제 API 키를 설정해주세요",
                explanation: explanation,
                type: typeLabel
            )
        ]
    }
    
    private func getAPIKeyErrorMessage(_ language: String) -> String {
        switch language {
        case "ko": return "API 키가 유효하지 않아 더미 데이터를 표시하고 있습니다."
        case "en": return "Displaying dummy data because API key is invalid."
        case "ja": return "APIキーが無効なため、ダミーデータを表示しています。"
        default: return "API key is invalid."
        }
    }
}

// MARK: - API 에러 정의 (동일)
enum APIError: LocalizedError {
    case emptyText
    case invalidAPIKey
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case emptyResponse
    case invalidJSON
    
    var errorDescription: String? {
        switch self {
        case .emptyText:
            return "일기 내용을 입력해주세요."
        case .invalidAPIKey:
            return "API 키 오류입니다. 잠시 후 다시 시도해주세요."
        case .invalidURL:
            return "서버 연결 오류입니다."
        case .invalidResponse:
            return "서버 응답 오류입니다."
        case .httpError(let code):
            return "서버 오류 (코드: \(code))"
        case .emptyResponse:
            return "AI 응답을 받지 못했습니다."
        case .invalidJSON:
            return "AI 응답 처리 중 오류가 발생했습니다."
        }
    }
}
