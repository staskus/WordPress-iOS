import Foundation

@objc protocol InteractivePostViewDelegate {
    func edit(_ post: AbstractPost)
    func view(_ post: AbstractPost)
    func stats(for post: AbstractPost)
    // We'd like the signature to be `duplicate(_ post:)`, but Xcode 14.0 beta 1 gives the
    // following build error:
    //
    // > Method 'duplicate' with Objective-C selector 'duplicate:' conflicts with method
    // > 'duplicate' from superclass 'UIResponder' with the same Objective-C selector
    //
    // Not sure whether that's a beta issue or a legitimate error. There doesn't seem to be any
    // `duplicate` method in the `UIResponder` documentation—unless that's a private method?
    //
    // See https://developer.apple.com/documentation/uikit/uiresponder
    func duplicatePost(_ post: AbstractPost)
    func publish(_ post: AbstractPost)
    func trash(_ post: AbstractPost)
    func restore(_ post: AbstractPost)
    func draft(_ post: AbstractPost)
    func retry(_ post: AbstractPost)
    func cancelAutoUpload(_ post: AbstractPost)
    func share(_ post: AbstractPost, fromView view: UIView)
    func copyLink(_ post: AbstractPost)
}
