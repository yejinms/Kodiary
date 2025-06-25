//
//  CorrectionItem.swift
//  Kodiary
//
//  Created by Niko on 6/19/25.

import Foundation

// 첨삭 아이템 구조체 - Codable 호환성 개선
struct CorrectionItem: Identifiable, Hashable, Codable {
    let id: UUID  // var에서 let으로 변경 (중요!)
    let original: String
    let corrected: String
    let explanation: String
    let type: String
    
    // Codable을 위한 CodingKeys 추가
    enum CodingKeys: String, CodingKey {
        case id, original, corrected, explanation, type
    }
    
    // 커스텀 초기화
    init(original: String, corrected: String, explanation: String, type: String) {
        self.id = UUID()
        self.original = original
        self.corrected = corrected
        self.explanation = explanation
        self.type = type
    }
    
    // Codable 지원을 위한 init - 수정됨
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // ID가 없으면 새로 생성하되, 있으면 그대로 사용
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.original = try container.decode(String.self, forKey: .original)
        self.corrected = try container.decode(String.self, forKey: .corrected)
        self.explanation = try container.decode(String.self, forKey: .explanation)
        self.type = try container.decode(String.self, forKey: .type)
    }
    
    // Codable 지원을 위한 encode - 명시적으로 추가
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(original, forKey: .original)
        try container.encode(corrected, forKey: .corrected)
        try container.encode(explanation, forKey: .explanation)
        try container.encode(type, forKey: .type)
    }
}

// 네비게이션용 데이터 - Codable 추가
struct CorrectionData: Hashable, Codable {
    let originalText: String
    let corrections: [CorrectionItem]
}
