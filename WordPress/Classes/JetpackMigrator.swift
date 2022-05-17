import Foundation
import UIKit
import StoreKit

@objc class JetpackMigrator: NSObject {
    @objc static func jetpackAppInstalled() -> Bool {
        guard let url = URL(string: "jpdebug://reader") else {
            return false
        }

        if(UIApplication.shared.canOpenURL(url)){
            return true;
        }
    }

    @objc static func promptToInstall(from source: UIViewController) {
        let storeViewController = SKStoreProductViewController()
        let params = [SKStoreProductParameterITunesItemIdentifier: 1565481562,
                      // Demo that we can track app installs using a campaign
//                             SKStoreProductParameterCampaignToken: "wp_migration"
        ]

        storeViewController.loadProduct(withParameters: params) { loaded, error in
            print("all done")
        }

        source.present(storeViewController, animated: true)
    }

    @objc static func openReader() {
        Self.deepLink(fragment: "read")
    }

    @objc static func openNotifications() {
        Self.deepLink(fragment: "notifications")
    }

    @objc static func openStats(for blog: Blog) {
        var fragment = "stats/stats"
        if let blogID = blog.dotComID {
            fragment = String(format: "stats/stats/%@", blogID)
        }

        Self.deepLink(fragment: fragment)
    }

    private static func deepLink(fragment: String) {
        guard let url = URL(string: "jpdebug://" + fragment) else {
            return
        }

        UIApplication.shared.open(url, options: [:]) { success in
            print("success?", success)
        }
    }
}
