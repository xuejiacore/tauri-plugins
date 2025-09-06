import StoreKit
import os

public typealias IapCallback = @convention(c) @Sendable (UnsafePointer<CChar>) -> Void

struct CallbackData: Codable {
    let type: String
    let data: String?
    let error: String?
}

@_cdecl("native_register_iap_callback")
public func native_register_iap_callback(callback: IapCallback) {
    DispatchQueue.main.async {
        StoreManager.shared.updateCallback(callback: callback);
    }
}

@_cdecl("native_restore_purchase")
public func native_restore_purchase() {
    DispatchQueue.main.async {
        StoreManager.shared.restorePurchases()
    }
}

class StoreManager: NSObject, SKPaymentTransactionObserver {

    @MainActor static let shared = StoreManager()  // 单例
    var restoredProducts: [String] = []
    var globalRestoreCallback: IapCallback?
    
    override init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }

    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
    func updateCallback(callback: IapCallback) {
        globalRestoreCallback = callback;
    }

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction: SKPaymentTransaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                // 正常购买成功
                unlockContent(for: transaction)
                SKPaymentQueue.default().finishTransaction(transaction)

            case .restored:
                // 恢复购买成功
                unlockContent(for: transaction)
                SKPaymentQueue.default().finishTransaction(transaction)

            case .failed:
                if let error = transaction.error as NSError? {
                    if error.code != SKError.paymentCancelled.rawValue {
                        // 处理错误
                        print("Transaction failed: \(error.localizedDescription)")
                    }
                }
                SKPaymentQueue.default().finishTransaction(transaction)

            default:
                break
            }
        }
    }

    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        // 所有可以恢复的交易都处理完毕
        print("Restore completed.")
        let receipt = loadReceipt()
        if let receiptString = receipt?.base64EncodedString() {
            doCallback(callbackType: "LOAD_RECEIPT", data: receiptString, error: nil)
        } else {
            doCallback(callbackType: "LOAD_RECEIPT", data: nil, error: "Could not load receipt.")
        }
    }

    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        // 恢复购买失败
        print("Restore failed: \(error.localizedDescription)")
    }

    private func unlockContent(for transaction: SKPaymentTransaction) {
        // 根据 transaction.payment.productIdentifier 解锁对应内容
        let productId = transaction.payment.productIdentifier
        let accountName = transaction.payment.applicationUsername
        let jsonData = """
        {
            "productId": "\(productId)",
            "appAccountToken": "\(accountName ?? "")"
        }
        """
        doCallback(callbackType: "UNLOCK_PRODUCT", data: jsonData, error: nil)
    }

    public func doCallback(callbackType: String, data: String?, error: String?) {
        if let callback = globalRestoreCallback {
            let payload = CallbackData(type: callbackType, data: data, error: error)
            do {
               let jsonData = try JSONEncoder().encode(payload)
               if let jsonString = String(data: jsonData, encoding: .utf8) {
                   // 创建一个 C 字符串副本（需手动分配）
                   let cString = strdup(jsonString)
                   callback(cString!)
                   free(UnsafeMutablePointer(mutating: cString))
               } else {
                   print("Failed to encode JSON string")
               }
           } catch {
               print("Failed to encode RestoreResult: \(error)")
           }
        }
    }
    
    func restorePurchases() {
        restoredProducts = []
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    func loadReceipt() -> Data? {
        guard let receiptURL = Bundle.main.appStoreReceiptURL else {
            return nil
        }
        return try? Data(contentsOf: receiptURL)
    }
}

