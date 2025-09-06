//
//  InAppPurchase.swift
//  CLibStoreKitBridge
//
//  Created by Nigel on 2025/4/28.
//

import Foundation
import StoreKit

@_cdecl("native_purchase")
public func native_purchase(accountToken: UnsafePointer<CChar>, productId: UnsafePointer<CChar>) -> UnsafeMutablePointer<CChar>? {
    let result = native_start_subscription(appAccountToken: accountToken, productId: productId)
    return strdup(result)
}

public func native_start_subscription(appAccountToken: UnsafePointer<CChar>, productId: UnsafePointer<CChar>) -> UnsafePointer<CChar>? {
    let tokenString = String(cString: appAccountToken)
    let productIdStr = String(cString: productId)
    var resultJson = #"{"type": "SUBSCRIPTION", "error": "Unknown", "productId": "\#(productIdStr)"}"#

    let semaphore = DispatchSemaphore(value: 0)

    Task {
        do {
            // 1. 权限检查
            guard AppStore.canMakePayments else {
                resultJson = #"{"type": "SUBSCRIPTION", "error": "In-app purchases are disabled", "productId": "\#(productIdStr)"}"#
                semaphore.signal()
                return
            }

            // 2. 拉取商品
            let products = try await Product.products(for: [productIdStr])
            guard let product = products.first else {
                resultJson = #"{"type": "SUBSCRIPTION", "error": "Product not found", "productId": "\#(productIdStr)"}"#
                semaphore.signal()
                return
            }

            // 3. 检查UUID
            guard let uuid = UUID(uuidString: tokenString) else {
                resultJson = #"{"type": "SUBSCRIPTION", "error": "Invalid UUID", "productId": "\#(productIdStr)"}"#
                semaphore.signal()
                return
            }

            let options: Set<Product.PurchaseOption> = [Product.PurchaseOption.appAccountToken(uuid)]

            // 4. 购买
            let purchaseResult = try await product.purchase(options: options)
            switch purchaseResult {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    // 5. 交易完成
                    let receiptData = await loadOrRefreshReceipt()
                    let receiptString = receiptData?.base64EncodedString() ?? ""
                    resultJson = #"{"type": "SUBSCRIPTION", "status": "success", "receipt-data": "\#(receiptString)", "transaction-id": "\#(transaction.id)", "productId": "\#(productIdStr)"}"#
                    await transaction.finish()

                case .unverified(_, let error):
                    resultJson = #"{"type": "SUBSCRIPTION", "error": "Verification failed: \#(error.localizedDescription)", "productId": "\#(productIdStr)"}"#

                @unknown default:
                    resultJson = #"{"type": "SUBSCRIPTION", "error": "Verification failed", "productId": "\#(productIdStr)"}"#
                }
            case .userCancelled:
                resultJson = #"{"type": "SUBSCRIPTION", "error": "User cancelled", "productId": "\#(productIdStr)"}"#

            case .pending:
                resultJson = #"{"type": "SUBSCRIPTION", "error": "Pending approval", "productId": "\#(productIdStr)"}"#

            @unknown default:
                resultJson = #"{"type": "SUBSCRIPTION", "error": "Unknown purchase result", "productId": "\#(productIdStr)"}"#
            }

        } catch {
            resultJson = #"{"type": "SUBSCRIPTION", "error": "\#(error.localizedDescription)", "productId": "\#(productIdStr)"}"#
        }

        semaphore.signal()
    }

    _ = semaphore.wait(timeout: .now() + 300)

    let cString = strdup(resultJson)
    return UnsafePointer(cString)
}

// 加载或刷新收据
func loadOrRefreshReceipt() async -> Data? {
    if let receiptURL = Bundle.main.appStoreReceiptURL,
       let receiptData = try? Data(contentsOf: receiptURL),
       receiptData.count > 0 {
        return receiptData
    }

    // 收据不存在，尝试刷新
    do {
        try await refreshReceipt()
        if let refreshedReceiptData = try? Data(contentsOf: Bundle.main.appStoreReceiptURL!) {
            return refreshedReceiptData
        }
    } catch {
        print("Failed to refresh receipt: \(error.localizedDescription)")
    }
    return nil
}

// 调用 StoreKit 刷新收据
func refreshReceipt() async throws {
    return try await withCheckedThrowingContinuation { continuation in
        let request = SKReceiptRefreshRequest()
        let delegate = ReceiptRefreshDelegate(continuation: continuation)
        request.delegate = delegate
        request.start()
    }
}

// 自定义收据刷新代理
class ReceiptRefreshDelegate: NSObject, SKRequestDelegate {
    let continuation: CheckedContinuation<Void, Error>

    init(continuation: CheckedContinuation<Void, Error>) {
        self.continuation = continuation
    }

    func requestDidFinish(_ request: SKRequest) {
        continuation.resume()
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        continuation.resume(throwing: error)
    }
}
