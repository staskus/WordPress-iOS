import Foundation
import UIKit
import CoreData

protocol BlogDashboardCardConfigurable {
    func configure(blog: Blog, viewController: BlogDashboardViewController?)
}

class BlogDashboardViewModel {
    private weak var viewController: BlogDashboardViewController?

    enum Section: CaseIterable {
        case quickLinks
        case posts
    }

    // FIXME: temporary placeholder
    private let quickLinks = ["Quick Links"]
    private let posts = ["Posts"]

    typealias QuickLinksHostCell = HostCollectionViewCell<QuickLinksView>

    private let managedObjectContext: NSManagedObjectContext
    private let blog: Blog

    private lazy var service: DashboardServiceRemote = {
        let api = WordPressComRestApi.defaultApi(in: managedObjectContext,
                                                 localeKey: WordPressComRestApi.LocaleKeyV2)

        return DashboardServiceRemote(wordPressComRestApi: api)
    }()

    private lazy var dataSource: DashboardDataSource? = {
        guard let viewController = viewController else {
            return nil
        }

        return DashboardDataSource(collectionView: viewController.collectionView) { [unowned self] collectionView, indexPath, identifier in
//            switch identifier.id {
//            case .quickActions:
//                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: QuickLinksHostCell.defaultReuseID, for: indexPath) as? QuickLinksHostCell
//                cell?.hostedView = QuickLinksView(title: self.quickLinks[indexPath.item])
//                return cell
//            case .drafts:
//                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DashboardPostsCardCell.defaultReuseID, for: indexPath) as? DashboardPostsCardCell
//                cell?.configure(viewController, blog: blog)
//                return cell
//            case .scheduled:
//                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DashboardPostsCardCell.defaultReuseID, for: indexPath) as? DashboardPostsCardCell
//                cell?.configure(viewController, blog: blog)
//                return cell
//            }

            
            let cellType = identifier.id.cell
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellType.defaultReuseID, for: indexPath)
            (cell as? BlogDashboardCardConfigurable)?.configure(blog: blog, viewController: viewController)

            return cell
        }
    }()

    init(viewController: BlogDashboardViewController, managedObjectContext: NSManagedObjectContext = ContextManager.shared.mainContext, blog: Blog) {
        self.viewController = viewController
        self.managedObjectContext = managedObjectContext
        self.blog = blog
    }

    /// Call the API to return cards for the current blog
    func start() {
        guard let dotComID = blog.dotComID?.intValue else {
            return
        }

        viewController?.showLoading()
        applySnapshotForInitialData()

        service.fetch(cards: DashboardCard.allCases.filter { $0.isRemote }.compactMap { $0.remoteIdentifier }, forBlogID: dotComID, success: { [weak self] cards in
            self?.viewController?.stopLoading()
            self?.applySnapshotWith(cards: cards)
        }, failure: { _ in

        })
    }
}

// MARK: - Private methods

private extension BlogDashboardViewModel {
    // This is necessary when using an IntrinsicCollectionView
    // Otherwise, the collection view will never update its height
    func applySnapshotForInitialData() {
        let snapshot = DashboardSnapshot()
        dataSource?.apply(snapshot, animatingDifferences: false)
    }

    func applySnapshotWith(cards: NSDictionary) {
        dataSource?.apply(BlogDashboardParser().parse(cards: cards), animatingDifferences: false)
    }
}
