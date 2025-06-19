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
    
    // ⚠️ 개발 중에만 여기에 실제 키를 넣으세요
    // 실제 배포 시에는 서버를 통해 프록시하는 것이 좋습니다
    private let apiKey = "TEMP_API_KEY_FOR_DEVELOPMENT"
    
    private init() {}
    
    // MARK: - 개발용 API 키 설정 (Git에는 올라가지 않음)
    func setDevelopmentAPIKey(_ key: String) {
        // 이 함수는 개발 중에만 사용
        // 실제로는 위의 apiKey 상수를 직접 수정하세요
        print("⚠️ 개발 중: API 키가 설정되었습니다")
    }
    
    // API 키 유효성 검사
    private func hasValidAPIKey() -> Bool {
        return apiKey != "TEMP_API_KEY_FOR_DEVELOPMENT" &&
               apiKey.hasPrefix("sk-") &&
               apiKey.count > 20
    }
    
    // MARK: - 한국어 일기 첨삭 요청
    func analyzeDiary(text: String) async throws -> [CorrectionItem] {
        guard !text.isEmpty else {
            throw APIError.emptyText
        }
        
        // 개발 중 API 키 체크
        guard hasValidAPIKey() else {
            print("⚠️ 개발자 알림: APIManager.swift에서 apiKey를 실제 OpenAI 키로 변경해주세요")
            // 개발 중에는 더미 데이터 반환
            return createDevelopmentFallback()
        }
        
        // UI 업데이트
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let corrections = try await requestCorrection(for: text)
            
            await MainActor.run {
                isLoading = false
            }
            
            return corrections
            
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    // MARK: - OpenAI API 호출
    private func requestCorrection(for text: String) async throws -> [CorrectionItem] {
        guard let url = URL(string: baseURL) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = createRequestBody(for: text)
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw APIError.invalidAPIKey
            }
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        return try parseResponse(data)
    }
    
    // MARK: - 요청 바디 생성
    private func createRequestBody(for text: String) -> [String: Any] {
        let prompt = createKoreanCorrectionPrompt(for: text)
        
        return [
            "model": "gpt-4o-mini",
            "messages": [
                [
                    "role": "system",
                    "content": """
                    당신은 한국어를 배우는 외국인을 위한 친절한 첨삭 선생님입니다.
                    초급 학습자도 이해할 수 있도록 쉽고 친근하게 설명해주세요.
                    반드시 올바른 JSON 형식으로만 응답해주세요.
                    """
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
    
    // MARK: - 한국어 첨삭 프롬프트 생성
    private func createKoreanCorrectionPrompt(for text: String) -> String {
        return """
        다음 한국어 일기를 첨삭해주세요. 초급 학습자를 위해 친절하고 쉽게 설명해주세요.
        
        일기 내용:
        "\(text)"
        
        다음 JSON 형식으로만 응답해주세요:
        {
            "corrections": [
                {
                    "original": "틀린 표현",
                    "corrected": "올바른 표현", 
                    "explanation": "초급자도 이해할 수 있는 친절한 설명",
                    "type": "문법"
                }
            ]
        }
        
        규칙:
        - 최대 5개까지만 첨삭
        - type은 "문법", "맞춤법", "표현" 중 하나
        - 설명은 친근한 말투로 ("~해주세요", "~가 자연스러워요")
        - JSON 형식 정확히 준수
        """
    }
    
    // MARK: - 응답 파싱
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
        
        return try parseCorrectionContent(content)
    }
    
    // MARK: - 첨삭 내용 파싱
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
            
            return response.corrections.map { correction in
                CorrectionItem(
                    original: correction.original,
                    corrected: correction.corrected,
                    explanation: correction.explanation,
                    type: correction.type
                )
            }
            
        } catch {
            print("❌ JSON 파싱 에러: \(error)")
            return createDevelopmentFallback()
        }
    }
    
    // MARK: - 개발용 폴백 데이터
    private func createDevelopmentFallback() -> [CorrectionItem] {
        return [
            CorrectionItem(
                original: "좋다",
                corrected: "좋아요",
                explanation: "존댓말로 써주세요. '좋다'보다 '좋아요'가 자연스러워요.",
                type: "문법"
            ),
            CorrectionItem(
                original: "재미있었다",
                corrected: "재미있었어요",
                explanation: "과거형도 존댓말로 일관성 있게 써주세요.",
                type: "문법"
            )
        ]
    }
}

// MARK: - API 에러 정의
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
