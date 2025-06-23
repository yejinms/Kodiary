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
    
    // MARK: - Language Support (확장됨)
    private func getSystemPrompt(_ language: String) -> String {
        switch language {
        case "ko":
            return "당신은 외국어를 배우는 학습자를 위한 친절한 글쓰기 선생님입니다. 초급 학습자도 이해할 수 있도록 쉽고 친근하게 설명해주세요. 반드시 올바른 JSON 형식으로만 응답해주세요."
        case "en":
            return "You are a friendly writing teacher for language learners. Please explain in a simple way that even beginners can understand. Please respond only in correct JSON format."
        case "ja":
            return "あなたは外国語を学ぶ学習者のための親切な文章の先生です。初級学習者でも理解できるように簡単で親しみやすく説明してください。必ず正しいJSON形式でのみ回答してください。"
        case "es":
            return "Eres un profesor de escritura amable para estudiantes de idiomas. Por favor explica de manera simple para que incluso los principiantes puedan entender. Por favor responde solo en formato JSON correcto."
        case "th":
            return "คุณเป็นครูสอนเขียนที่ใจดีสำหรับผู้เรียนภาษา โปรดอธิบายอย่างง่ายๆ เพื่อให้แม้แต่ผู้เริ่มต้นสามารถเข้าใจได้ โปรดตอบเฉพาะในรูปแบบ JSON ที่ถูกต้องเท่านั้น"
        case "de":
            return "Du bist ein freundlicher Schreiblehrer für Sprachenlernende. Bitte erkläre auf einfache Weise, damit auch Anfänger verstehen können. Bitte antworte nur im korrekten JSON-Format."
        case "zh":
            return "您是为语言学习者服务的友善写作老师。请用简单的方式解释，让初学者也能理解。请只用正确的JSON格式回答。"
        case "ar":
            return "أنت معلم كتابة ودود لمتعلمي اللغة. يرجى الشرح بطريقة بسيطة حتى يتمكن المبتدئون من الفهم. يرجى الرد فقط بصيغة JSON الصحيحة."
        case "fr":
            return "Vous êtes un professeur d'écriture bienveillant pour les apprenants de langues. Veuillez expliquer de manière simple pour que même les débutants puissent comprendre. Veuillez répondre uniquement au format JSON correct."
        case "it":
            return "Sei un insegnante di scrittura amichevole per studenti di lingue. Per favore spiega in modo semplice così che anche i principianti possano capire. Per favore rispondi solo nel formato JSON corretto."
        case "pt":
            return "Você é um professor de escrita amigável para estudantes de idiomas. Por favor explique de forma simples para que até iniciantes possam entender. Por favor responda apenas no formato JSON correto."
        case "hi":
            return "आप भाषा सीखने वालों के लिए एक दयालु लेखन शिक्षक हैं। कृपया सरल तरीके से समझाएं ताकि शुरुआती लोग भी समझ सकें। कृपया केवल सही JSON प्रारूप में उत्तर दें।"
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
        case ("ko", "es"): return "Coreano"
        case ("ko", "th"): return "เกาหลี"
        case ("ko", "de"): return "Koreanisch"
        case ("ko", "zh"): return "韩语"
        case ("ko", "ar"): return "الكورية"
        case ("ko", "fr"): return "Coréen"
        case ("ko", "it"): return "Coreano"
        case ("ko", "pt"): return "Coreano"
        case ("ko", "hi"): return "कोरियाई"
            
        case ("en", "ko"): return "영어"
        case ("en", "en"): return "English"
        case ("en", "ja"): return "英語"
        case ("en", "es"): return "Inglés"
        case ("en", "th"): return "อังกฤษ"
        case ("en", "de"): return "Englisch"
        case ("en", "zh"): return "英语"
        case ("en", "ar"): return "الإنجليزية"
        case ("en", "fr"): return "Anglais"
        case ("en", "it"): return "Inglese"
        case ("en", "pt"): return "Inglês"
        case ("en", "hi"): return "अंग्रेजी"
            
        case ("ja", "ko"): return "일본어"
        case ("ja", "en"): return "Japanese"
        case ("ja", "ja"): return "日本語"
        case ("ja", "es"): return "Japonés"
        case ("ja", "th"): return "ญี่ปุ่น"
        case ("ja", "de"): return "Japanisch"
        case ("ja", "zh"): return "日语"
        case ("ja", "ar"): return "اليابانية"
        case ("ja", "fr"): return "Japonais"
        case ("ja", "it"): return "Giapponese"
        case ("ja", "pt"): return "Japonês"
        case ("ja", "hi"): return "जापानी"
            
        case ("es", "ko"): return "스페인어"
        case ("es", "en"): return "Spanish"
        case ("es", "ja"): return "スペイン語"
        case ("es", "es"): return "Español"
        case ("es", "th"): return "สเปน"
        case ("es", "de"): return "Spanisch"
        case ("es", "zh"): return "西班牙语"
        case ("es", "ar"): return "الإسبانية"
        case ("es", "fr"): return "Espagnol"
        case ("es", "it"): return "Spagnolo"
        case ("es", "pt"): return "Espanhol"
        case ("es", "hi"): return "स्पेनिश"
            
        case ("th", "ko"): return "태국어"
        case ("th", "en"): return "Thai"
        case ("th", "ja"): return "タイ語"
        case ("th", "es"): return "Tailandés"
        case ("th", "th"): return "ไทย"
        case ("th", "de"): return "Thailändisch"
        case ("th", "zh"): return "泰语"
        case ("th", "ar"): return "التايلاندية"
        case ("th", "fr"): return "Thaï"
        case ("th", "it"): return "Tailandese"
        case ("th", "pt"): return "Tailandês"
        case ("th", "hi"): return "थाई"
            
        case ("de", "ko"): return "독일어"
        case ("de", "en"): return "German"
        case ("de", "ja"): return "ドイツ語"
        case ("de", "es"): return "Alemán"
        case ("de", "th"): return "เยอรมัน"
        case ("de", "de"): return "Deutsch"
        case ("de", "zh"): return "德语"
        case ("de", "ar"): return "الألمانية"
        case ("de", "fr"): return "Allemand"
        case ("de", "it"): return "Tedesco"
        case ("de", "pt"): return "Alemão"
        case ("de", "hi"): return "जर्मन"
            
        case ("zh", "ko"): return "중국어"
        case ("zh", "en"): return "Chinese"
        case ("zh", "ja"): return "中国語"
        case ("zh", "es"): return "Chino"
        case ("zh", "th"): return "จีน"
        case ("zh", "de"): return "Chinesisch"
        case ("zh", "zh"): return "中文"
        case ("zh", "ar"): return "الصينية"
        case ("zh", "fr"): return "Chinois"
        case ("zh", "it"): return "Cinese"
        case ("zh", "pt"): return "Chinês"
        case ("zh", "hi"): return "चीनी"
            
        case ("ar", "ko"): return "아랍어"
        case ("ar", "en"): return "Arabic"
        case ("ar", "ja"): return "アラビア語"
        case ("ar", "es"): return "Árabe"
        case ("ar", "th"): return "อาหรับ"
        case ("ar", "de"): return "Arabisch"
        case ("ar", "zh"): return "阿拉伯语"
        case ("ar", "ar"): return "العربية"
        case ("ar", "fr"): return "Arabe"
        case ("ar", "it"): return "Arabo"
        case ("ar", "pt"): return "Árabe"
        case ("ar", "hi"): return "अरबी"
            
        case ("fr", "ko"): return "프랑스어"
        case ("fr", "en"): return "French"
        case ("fr", "ja"): return "フランス語"
        case ("fr", "es"): return "Francés"
        case ("fr", "th"): return "ฝรั่งเศส"
        case ("fr", "de"): return "Französisch"
        case ("fr", "zh"): return "法语"
        case ("fr", "ar"): return "الفرنسية"
        case ("fr", "fr"): return "Français"
        case ("fr", "it"): return "Francese"
        case ("fr", "pt"): return "Francês"
        case ("fr", "hi"): return "फ्रेंच"
            
        case ("it", "ko"): return "이탈리아어"
        case ("it", "en"): return "Italian"
        case ("it", "ja"): return "イタリア語"
        case ("it", "es"): return "Italiano"
        case ("it", "th"): return "อิตาลี"
        case ("it", "de"): return "Italienisch"
        case ("it", "zh"): return "意大利语"
        case ("it", "ar"): return "الإيطالية"
        case ("it", "fr"): return "Italien"
        case ("it", "it"): return "Italiano"
        case ("it", "pt"): return "Italiano"
        case ("it", "hi"): return "इतालवी"
            
        case ("pt", "ko"): return "포르투갈어"
        case ("pt", "en"): return "Portuguese"
        case ("pt", "ja"): return "ポルトガル語"
        case ("pt", "es"): return "Portugués"
        case ("pt", "th"): return "โปรตุเกส"
        case ("pt", "de"): return "Portugiesisch"
        case ("pt", "zh"): return "葡萄牙语"
        case ("pt", "ar"): return "البرتغالية"
        case ("pt", "fr"): return "Portugais"
        case ("pt", "it"): return "Portoghese"
        case ("pt", "pt"): return "Português"
        case ("pt", "hi"): return "पुर्तगाली"
            
        case ("hi", "ko"): return "힌디어"
        case ("hi", "en"): return "Hindi"
        case ("hi", "ja"): return "ヒンディー語"
        case ("hi", "es"): return "Hindi"
        case ("hi", "th"): return "ฮินดี"
        case ("hi", "de"): return "Hindi"
        case ("hi", "zh"): return "印地语"
        case ("hi", "ar"): return "الهندية"
        case ("hi", "fr"): return "Hindi"
        case ("hi", "it"): return "Hindi"
        case ("hi", "pt"): return "Hindi"
        case ("hi", "hi"): return "हिन्दी"
            
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
        case "es":
            return """
            Por favor corrige el diario de un estudiante de \(targetLang).
            - Máximo 3 correcciones
            - Explicaciones simples para principiantes
            - Responde solo en formato JSON
            """
        case "th":
            return """
            โปรดแก้ไขไดอารี่ของผู้เรียน\(targetLang)
            - แก้ไขสูงสุด 3 จุด
            - คำอธิบายง่ายๆ สำหรับผู้เริ่มต้น
            - ตอบเฉพาะในรูปแบบ JSON เท่านั้น
            """
        case "de":
            return """
            Bitte korrigiere das Tagebuch eines \(targetLang)-Lernenden.
            - Maximal 3 Korrekturen
            - Einfache Erklärungen für Anfänger
            - Nur im JSON-Format antworten
            """
        case "zh":
            return """
            请批改\(targetLang)学习者的日记。
            - 最多3个批改点
            - 适合初学者的简单解释
            - 仅用JSON格式回答
            """
        case "ar":
            return """
            يرجى تصحيح يوميات متعلم \(targetLang).
            - 3 تصحيحات كحد أقصى
            - شروحات بسيطة للمبتدئين
            - الرد فقط بصيغة JSON
            """
        case "fr":
            return """
            Veuillez corriger le journal d'un apprenant de \(targetLang).
            - Maximum 3 corrections
            - Explications simples pour débutants
            - Répondre uniquement au format JSON
            """
        case "it":
            return """
            Per favore correggi il diario di uno studente di \(targetLang).
            - Massimo 3 correzioni
            - Spiegazioni semplici per principianti
            - Rispondi solo in formato JSON
            """
        case "pt":
            return """
            Por favor corrija o diário de um estudante de \(targetLang).
            - Máximo 3 correções
            - Explicações simples para iniciantes
            - Responda apenas em formato JSON
            """
        case "hi":
            return """
            कृपया \(targetLang) सीखने वाले की डायरी को सुधारें।
            - अधिकतम 3 सुधार
            - शुरुआती लोगों के लिए सरल व्याख्या
            - केवल JSON प्रारूप में उत्तर दें
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
        case "es": return ["Gramática", "Ortografía", "Expresión"]
        case "th": return ["ไวยากรณ์", "การสะกด", "การแสดงออก"]
        case "de": return ["Grammatik", "Rechtschreibung", "Ausdruck"]
        case "zh": return ["语法", "拼写", "表达"]
        case "ar": return ["نحو", "إملاء", "تعبير"]
        case "fr": return ["Grammaire", "Orthographe", "Expression"]
        case "it": return ["Grammatica", "Ortografia", "Espressione"]
        case "pt": return ["Gramática", "Ortografia", "Expressão"]
        case "hi": return ["व्याकरण", "वर्तनी", "अभिव्यक्ति"]
        default: return ["Grammar", "Spelling", "Expression"]
        }
    }
    
    private func getFieldLabels(_ language: String) -> (original: String, corrected: String, explanation: String) {
        switch language {
        case "ko": return ("수정 전 텍스트", "수정 후 텍스트", "초급자용 설명")
        case "en": return ("Original text", "Corrected text", "Beginner explanation")
        case "ja": return ("修正前テキスト", "修正後テキスト", "初級者向け説明")
        case "es": return ("Texto original", "Texto corregido", "Explicación para principiantes")
        case "th": return ("ข้อความต้นฉบับ", "ข้อความที่แก้ไข", "คำอธิบายสำหรับผู้เริ่มต้น")
        case "de": return ("Originaltext", "Korrigierter Text", "Erklärung für Anfänger")
        case "zh": return ("原文", "修正后文本", "初学者解释")
        case "ar": return ("النص الأصلي", "النص المصحح", "شرح للمبتدئين")
        case "fr": return ("Texte original", "Texte corrigé", "Explication pour débutants")
        case "it": return ("Testo originale", "Testo corretto", "Spiegazione per principianti")
        case "pt": return ("Texto original", "Texto corrigido", "Explicação para iniciantes")
        case "hi": return ("मूल पाठ", "सुधारा गया पाठ", "शुरुआती लोगों के लिए व्याख्या")
        default: return ("Original", "Corrected", "Explanation")
        }
    }
    
    private func getAPIKeyErrorMessage(_ language: String) -> String {
        switch language {
        case "ko": return "API 키가 유효하지 않아 더미 데이터를 표시하고 있습니다."
        case "en": return "Displaying dummy data because API key is invalid."
        case "ja": return "APIキーが無効なため、ダミーデータを表示しています。"
        case "es": return "Mostrando datos de prueba porque la clave API es inválida."
        case "th": return "แสดงข้อมูลทดสอบเนื่องจาก API key ไม่ถูกต้อง"
        case "de": return "Zeige Testdaten an, da der API-Schlüssel ungültig ist."
        case "zh": return "由于API密钥无效，正在显示测试数据。"
        case "ar": return "عرض بيانات تجريبية لأن مفتاح API غير صالح."
        case "fr": return "Affichage de données de test car la clé API est invalide."
        case "it": return "Visualizzazione dati di test perché la chiave API non è valida."
        case "pt": return "Exibindo dados de teste porque a chave API é inválida."
        case "hi": return "API key अमान्य होने के कारण डमी डेटा दिखा रहे हैं।"
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
