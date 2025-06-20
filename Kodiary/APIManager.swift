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
    
    // API 키 유효성 검사 - 수정됨!
    private func hasValidAPIKey() -> Bool {
        return apiKey.hasPrefix("sk-") && apiKey.count > 20
    }
    
    // MARK: - 한국어 일기 첨삭 요청
    func analyzeDiary(text: String) async throws -> [CorrectionItem] {
        guard !text.isEmpty else {
            throw APIError.emptyText
        }
        
        // API 키 체크
        guard hasValidAPIKey() else {
            print("⚠️ API 키가 유효하지 않습니다")
            return createDevelopmentFallback()
        }
        
        print("✅ API 키 유효 - 실제 AI 호출 시작")
        
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
            print("❌ API 호출 에러: \(error)")
            
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }
            
            // 에러 시에도 폴백 데이터 대신 에러 던지기
            throw error
        }
    }
    
    // MARK: - OpenAI API 호출
    private func requestCorrection(for text: String) async throws -> [CorrectionItem] {
        print("🤖 OpenAI API 요청 시작")
        
        guard let url = URL(string: baseURL) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = createRequestBody(for: text)
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
    
    // MARK: - 요청 바디 생성
    private func createRequestBody(for text: String) -> [String: Any] {
        let prompt = createKoreanCorrectionPrompt(for: text)
        
        return [
            "model": "gpt-4o-mini",
            "messages": [
                [
                    "role": "system",
                    "content": """
                    당신은 한국어를 배우는 외국인을 위한 친절한 글쓰기 선생님입니다.
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
        아래는 한국어를 배우는 외국인 학습자가 쓴 일기입니다. 초급 학습자도 이해할 수 있도록 문법, 맞춤법, 표현을 친절하게 첨삭해주세요
        
        1-1. 첨삭 규칙:
            - 첨삭은 최대 3개까지만 해주세요.
            - '원문 → 수정문 : 설명' 순서로 첨삭 내용을 정리해주세요.
            - 설명은 반드시 초급자도 이해할 수 있도록 쉬운 말로 써주세요. (~가 자연스러워요, ~라고 써요)
            - 'type'은 아래 중 하나로 분류해주세요: "문법", "맞춤법", "표현"
            - JSON 형식은 아래 예시처럼 정확히 맞춰주세요. JSON 외의 어떠한 사족도 달지 마시오.
        
        1-2. 첨삭 시 참고 사항:
        - 아래 오류 위주로 찾아내시오
            * 조사 사용 오류 
            * 문법적 어순 오류
            * 높임말/반말 혼동 오류
            * 문화적 표현 오류
            * 철자 오류
        - 띄어쓰기 오류는 지적하지 마시오
        - 눈에 띄는 오류가 없을 경우 아무 결과값도 추출하지 마시오
        
        2. 일기 내용:
            "\(text)"

        3. 출력 JSON 형식:
            {
              "corrections": [
                {
                  "original": "잘못 쓴 문장 또는 단어",
                  "corrected": "자연스러운 문장 또는 단어",
                  "explanation": "왜 이렇게 쓰는지 초급자도 이해할 수 있는 쉬운 설명",
                  "type": "문법" // 혹은 "맞춤법", "표현"
                }
              ]
            }
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
        
        print("📝 GPT 응답 내용:")
        print(content)
        
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
    
    // MARK: - 개발용 폴백 데이터 (이제 거의 안 쓰임)
    private func createDevelopmentFallback() -> [CorrectionItem] {
        print("⚠️ 폴백 데이터 사용 중")
        return [
            CorrectionItem(
                original: "API 키 오류",
                corrected: "실제 API 키를 설정해주세요",
                explanation: "API 키가 유효하지 않아 더미 데이터를 표시하고 있습니다.",
                type: "시스템"
            )
        ]
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
