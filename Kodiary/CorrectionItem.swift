//
//  CorrectionItem.swift
//  Kodiary
//
//  Created by Niko on 6/19/25.
//
//
//import Foundation
//
//// 첨삭 아이템 구조체
//struct CorrectionItem: Hashable, Identifiable {
//    let id = UUID()
//    let original: String      // 원본 표현
//    let corrected: String     // 수정된 표현
//    let explanation: String   // 설명
//    let type: String         // 수정 타입 (문법, 맞춤법, 표현)
//    
//    // Hashable 프로토콜 구현
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(id)
//        hasher.combine(original)
//        hasher.combine(corrected)
//        hasher.combine(explanation)
//        hasher.combine(type)
//    }
//    
//    static func == (lhs: CorrectionItem, rhs: CorrectionItem) -> Bool {
//        return lhs.id == rhs.id
//    }
//}
//
//// 네비게이션을 위한 첨삭 데이터
//struct CorrectionData: Hashable {
//    let originalText: String
//    let corrections: [CorrectionItem]
//    
//    // Hashable 프로토콜 구현
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(originalText)
//        hasher.combine(corrections)
//    }
//    
//    static func == (lhs: CorrectionData, rhs: CorrectionData) -> Bool {
//        return lhs.originalText == rhs.originalText &&
//               lhs.corrections == rhs.corrections
//    }
//}
import Foundation

// 첨삭 아이템 구조체 - Codable 추가
struct CorrectionItem: Identifiable, Hashable, Codable {
    let id = UUID()
    let original: String
    let corrected: String
    let explanation: String
    let type: String
}

// 네비게이션용 데이터 - Codable 추가
struct CorrectionData: Hashable, Codable {
    let originalText: String
    let corrections: [CorrectionItem]
}
