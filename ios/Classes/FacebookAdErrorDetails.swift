//
//  FacebookAdErrorDetails.swift
//  audience_network
//
//  Created by Leonardo da Silva on 19/12/21.
//

import Foundation

struct FacebookAdErrorDetails {
    let code: Int
    let message: String?
    
    init(code: Int, message: String?) {
        self.code = code
        self.message = message
    }
    
    init?(fromSDKError error: Error) {
        let error = error as NSError
        let details =  error.userInfo["FBAdErrorDetailKey"] as? [String: Any]
        guard let details = details else { return nil }
        let message = details["msg"] as? String
        guard let message = message else { return nil }
        self.init(code: error.code, message: message)
    }
}
