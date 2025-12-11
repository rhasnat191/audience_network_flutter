// //
// //  FacebookAdErrorDetails.swift
// //  audience_network
// //
// //  Created by Leonardo da Silva on 19/12/21.
// //

// import Foundation

// struct FacebookAdErrorDetails {
//     let code: Int
//     let message: String?
    
//     init(code: Int, message: String?) {
//         self.code = code
//         self.message = message
//     }
    
//     init?(fromSDKError error: Error) {
//         let error = error as NSError
//         let details =  error.userInfo["FBAdErrorDetailKey"] as? [String: Any]
//         guard let details = details else { return nil }
//         let message = details["msg"] as? String
//         guard let message = message else { return nil }
//         self.init(code: error.code, message: message)
//     }
// }

//
//  FacebookAdErrorDetails.swift
//  audience_network
//
//  Created by Leonardo da Silva on 19/12/21.
//

import Foundation

/// Represents detailed error information returned by the Facebook Audience Network SDK.
struct FacebookAdErrorDetails {
    let code: Int
    let message: String?

    init(code: Int, message: String?) {
        self.code = code
        self.message = message
    }

    /// Attempts to extract error details from an SDK error.
    /// Returns `nil` if required fields are unavailable.
    init?(fromSDKError error: Error) {
        let nsError = error as NSError

        guard
            let details = nsError.userInfo["FBAdErrorDetailKey"] as? [String: Any],
            let message = details["msg"] as? String
        else {
            return nil
        }

        self.init(code: nsError.code, message: message)
    }
}