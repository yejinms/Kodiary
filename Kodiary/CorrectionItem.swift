//
//  CorrectionItem.swift
//  Kodiary
//
//  Created by Niko on 6/19/25.

import Foundation

// 첨삭 아이템 구조체 - Codable 호환성 개선
struct CorrectionItem: Identifiable, Hashable, Codable {
    var id: UUID = UUID()  // let에서 var로 변경
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
    
    // Codable 지원을 위한 init
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.original = try container.decode(String.self, forKey: .original)
        self.corrected = try container.decode(String.self, forKey: .corrected)
        self.explanation = try container.decode(String.self, forKey: .explanation)
        self.type = try container.decode(String.self, forKey: .type)
    }
}

// 네비게이션용 데이터 - Codable 추가
struct CorrectionData: Hashable {
    let originalText: String
    let corrections: [CorrectionItem]
    let isEditMode: Bool
    let originalDiary: DiaryEntry?
    
    init(originalText: String, corrections: [CorrectionItem], isEditMode: Bool = false, originalDiary: DiaryEntry? = nil) {
        self.originalText = originalText
        self.corrections = corrections
        self.isEditMode = isEditMode
        self.originalDiary = originalDiary
    }
}
