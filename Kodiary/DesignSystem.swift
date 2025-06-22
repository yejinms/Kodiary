//
//  DesignSystem.swift
//  Kodiary
//
//  Created by Niko on 6/20/25.
//

import SwiftUI

// MARK: - 컬러 시스템
extension Color {
    // Primary Colors
    static let primaryBlue = Color(red: 0.68, green: 0.87, blue: 1)        // #AEDDFF
    static let primaryDark = Color(red: 0.33, green: 0.35, blue: 0.33)        // #545855
    static let primaryYellow = Color(red: 1, green: 0.96, blue: 0.57)      // #FFF491
    
    // Secondary Colors
    static let secondaryRed = Color(red: 0.99, green: 0.4, blue: 0.29)     // #FD664B
    static let secondaryOrange = Color(red: 1.0, green: 0.6, blue: 0.2)    // #FF9933
    static let secondaryPurple = Color(red: 0.6, green: 0.4, blue: 0.8)    // #9966CC
    
    // Semantic Colors
    static let successColor = Color(red: 0.2, green: 0.7, blue: 0.3)       // #33B359
    static let warningColor = Color(red: 1.0, green: 0.7, blue: 0.0)       // #FFB300
    static let errorColor = Color(red: 0.9, green: 0.3, blue: 0.3)         // #E64D4D
    static let infoColor = Color(red: 0.3, green: 0.7, blue: 0.9)          // #4DB3E6
    
    // Background Colors
    static let background = Color(red: 0.95, green: 0.95, blue: 0.95) //#F2F2F2
    
}

// MARK: - 커스텀 폰트 헬퍼
struct CustomFont {
    static let chosunKm = "ChosunKm"
    static let chosunNm = "ChosunilboNM"
    static let chosunSm = "ChosunSm"
    static let yoonChild = "YoonChildfundkoreaDaeHan"
    
    static func font(name: String, size: CGFloat) -> Font {
        // 폰트 사용 가능 여부 확인
        let availableFonts = UIFont.fontNames(forFamilyName: name)
        
        if !availableFonts.isEmpty {
            return Font.custom(name, size: size)
        } else if UIFont(name: name, size: size) != nil {
            return Font.custom(name, size: size)
        } else {
            print("⚠️ 폰트를 찾을 수 없습니다: \(name)")
            print("📋 사용 가능한 폰트 패밀리:")
            UIFont.familyNames.forEach { familyName in
                if familyName.lowercased().contains(name.lowercased()) {
                    print("  - \(familyName)")
                    UIFont.fontNames(forFamilyName: familyName).forEach { fontName in
                        print("    • \(fontName)")
                    }
                }
            }
            return Font.system(size: size, weight: .regular)
        }
    }
}


// MARK: - 폰트 시스템
extension Font {
    // Title Fonts (섹션 제목용)
    static let titleHuge = CustomFont.font(name: CustomFont.chosunKm, size: 160)
    static let titleLarge = CustomFont.font(name: CustomFont.chosunKm, size: 28)
    static let titleSmall1 = CustomFont.font(name: CustomFont.chosunKm, size: 22)
    static let titleSmall2 = CustomFont.font(name: CustomFont.chosunSm, size: 22)
    
    // Body Fonts (본문용)
    static let bodyFontTitle = CustomFont.font(name: CustomFont.chosunKm, size: 17)
    static let bodyFont = CustomFont.font(name: CustomFont.chosunNm, size: 17)
    static let bodyFontSmall = CustomFont.font(name: CustomFont.chosunNm, size: 15)
    
    // Custom App Fonts (앱 전용)
    static let buttonFont = CustomFont.font(name: CustomFont.chosunNm, size: 17)
    static let buttonFontSmall = CustomFont.font(name: CustomFont.chosunNm, size: 12)
    static let handWrite = CustomFont.font(name: CustomFont.yoonChild, size: 17)
}





// MARK: - 스페이싱 시스템
struct Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64
}

// MARK: - 반지름 시스템
struct CornerRadius {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 28
    static let circle: CGFloat = .infinity
}

