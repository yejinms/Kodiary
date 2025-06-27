//
//  StoreManager.swift
//  Kodiary
//
//  Created by Niko on 6/27/25.
//

import Foundation
import StoreKit

@MainActor
class StoreManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    
    private let productIDs = ["kodiary_premium_monthly"]
    
    init() {
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    func loadProducts() async {
        do {
            products = try await Product.products(for: productIDs)
        } catch {
            print("❌ 상품 로드 실패: \(error)")
        }
    }
    
    // 🆕 누락된 메서드 추가
    func updatePurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                purchasedProductIDs.insert(transaction.productID)
            }
        }
    }
    
    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            return await handlePurchaseResult(result)
        } catch {
            print("❌ 결제 실패: \(error)")
            return false
        }
    }
    
    // 🆕 누락된 메서드 추가
    private func handlePurchaseResult(_ result: Product.PurchaseResult) async -> Bool {
        switch result {
        case .success(let verification):
            if case .verified(let transaction) = verification {
                purchasedProductIDs.insert(transaction.productID)
                await transaction.finish()
                
                // 🆕 UserManager에 프리미엄 상태 업데이트
                UserManager.shared.setPremiumUser(true)
                print("✅ 결제 성공 - 프리미엄 활성화")
                return true
            }
        case .userCancelled:
            print("🚫 사용자가 결제 취소")
        case .pending:
            print("⏳ 결제 대기 중")
        @unknown default:
            print("❓ 알 수 없는 결제 결과")
        }
        return false
    }
}
