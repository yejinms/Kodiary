//
//  PremiumView.swift
//  Kodiary
//
//  Created by Niko on 6/27/25.
//

import Foundation
import SwiftUI

struct PremiumView: View {
    @StateObject private var store = StoreManager()
    
    var body: some View {
        VStack {
            Text("🌟 Kodiary Premium")
            Text("월 무제한 일기 수정")
            
            ForEach(store.products, id: \.id) { product in
                Button("구독하기 \(product.displayPrice)") {
                    Task { await store.purchase(product) }
                }
            }
        }
    }
}
