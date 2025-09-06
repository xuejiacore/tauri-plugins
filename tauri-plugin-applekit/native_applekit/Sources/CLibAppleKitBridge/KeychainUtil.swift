import Foundation
import Security

@_cdecl("echo")
public func echo(value: UnsafePointer<CChar>) -> UnsafeMutablePointer<CChar>? {
    return strdup(value)
}

// @_cdecl("get_user_default")
// public func get_user_default(keyPtr: UnsafePointer<CChar>) -> UnsafePointer<CChar>? {
//     let key = String(cString: keyPtr)
//     let value = UserDefaults.standard.string(forKey: key) ?? ""
//     return strdup(value)
// }
//
// @_cdecl("set_user_default")
// public func set_user_default(keyPtr: UnsafePointer<CChar>, valuePtr: UnsafePointer<CChar>) {
//     let key = String(cString: keyPtr)
//     let value = String(cString: valuePtr)
//     UserDefaults.standard.set(value, forKey: key)
// }