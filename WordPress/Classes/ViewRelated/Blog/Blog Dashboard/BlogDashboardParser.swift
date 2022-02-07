import Foundation
import UIKit

class DashboardSection: Hashable {
    let id: String

    let subtype: String?

    init(id: String, subtype: String? = nil) {
        self.id = id
        self.subtype = subtype
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(subtype)
    }

    static func == (lhs: DashboardSection, rhs: DashboardSection) -> Bool {
        lhs.id == rhs.id && lhs.subtype == rhs.subtype
    }
}

typealias DashboardCollectionViewCell = UICollectionViewCell & Reusable & BlogDashboardCardConfigurable

enum DashboardCard: String, CaseIterable {
    case quickActions
    case posts
    case todaysStats

    /// Does this card is powered by the API?
    var isRemote: Bool {
        switch self {
        case .posts, .todaysStats:
            return true
        default:
            return false
        }
    }

    var remoteIdentifier: String? {
        switch self {
        case .posts:
            return "posts"
        case .todaysStats:
            return "todays_stats"
        default:
            return nil
        }
    }

    var cell: DashboardCollectionViewCell.Type {
        switch self {
        case .quickActions:
            return HostCollectionViewCell<QuickLinksView>.self
        case .posts:
            return DashboardPostsCardCell.self
        case .todaysStats:
            return HostCollectionViewCell<QuickLinksView>.self
        }
    }
}

/// The view model to be injected on the cell
class Whatever: Decodable, Hashable {
    static func == (lhs: Whatever, rhs: Whatever) -> Bool {
        true
    }

    func hash(into hasher: inout Hasher) {

    }
}

class DashboardCardModel: Hashable {
    let id: DashboardCard

    let cellViewModel: NSDictionary?

    init(id: DashboardCard, cellViewModel: NSDictionary? = nil) {
        self.id = id
        self.cellViewModel = cellViewModel
    }

    static func == (lhs: DashboardCardModel, rhs: DashboardCardModel) -> Bool {
        lhs.cellViewModel == rhs.cellViewModel
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(cellViewModel)
    }
}

typealias DashboardSnapshot = NSDiffableDataSourceSnapshot<DashboardSection, DashboardCardModel>
typealias DashboardDataSource = UICollectionViewDiffableDataSource<DashboardSection, DashboardCardModel>

class BlogDashboardParser {
    func parse(cards: NSDictionary) -> DashboardSnapshot {
        // Append all sections (local and from remote)

        var snapshot = DashboardSnapshot()

        var sections: [DashboardSection] = []
        var items: [DashboardCardModel] = []

        DashboardCard.allCases.forEach { card in

            if card.isRemote {

                if card.remoteIdentifier == "posts" {

                    // Cards are special, since they relation is not exactly 1-1
                    if let posts = cards["posts"] as? NSDictionary {
                        let hasDrafts = (posts["draft"] as? Array<Any>)?.count ?? 0 > 0
                        let hasScheduled = (posts["scheduled"] as? Array<Any>)?.count ?? 0 > 0
                        let hasPublished = (posts["has_published"] as? Bool) ?? true
                        if hasDrafts && hasScheduled {
                            var drafts = posts.copy() as? [String: Any]
                            drafts?["scheduled"] = []
                            sections.append(DashboardSection(id: card.rawValue, subtype: "drafts"))
                            items.append(DashboardCardModel(id: card, cellViewModel: drafts as NSDictionary?))

                            var scheduled = posts.copy() as? [String: Any]
                            scheduled?["drafts"] = []
                            sections.append(DashboardSection(id: card.rawValue, subtype: "scheduled"))
                            items.append(DashboardCardModel(id: card, cellViewModel: scheduled as NSDictionary?))
                        } else {
                            sections.append(DashboardSection(id: card.rawValue))
                            items.append(DashboardCardModel(id: card, cellViewModel: posts))
                        }
                    }

                } else {

                    let jsonDecoder = JSONDecoder()
                    jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase

                    if let todaysStats = cards[card.remoteIdentifier!] {
                        sections.append(DashboardSection(id: card.rawValue))
                            sections.append(DashboardSection(id: card.rawValue))
                        items.append(DashboardCardModel(id: card, cellViewModel: todaysStats as? NSDictionary))
                    }

//                    if let data = try? JSONSerialization.data(withJSONObject: cards, options: []),
//                       let viewModel = try? jsonDecoder.decode(DashboardResponse.self, from: data) {
//                        sections.append(DashboardSection(id: card.rawValue))
//                        items.append(DashboardCardModel(id: card, cellViewModel: viewModel.todaysStats))
//                    }

                }

            } else {
                sections.append(DashboardSection(id: card.rawValue))
                items.append(DashboardCardModel(id: card))
            }

        }

        snapshot.appendSections(sections)
        items.enumerated().forEach { index, item in
            snapshot.appendItems([item], toSection: sections[index])
        }
        return snapshot
    }
}

class DashboardResponse: Decodable {
    var todaysStats: TodayStats
}

class TodayStats: Decodable, Hashable {
    var views: Int = 0
    var visitors: Int = 0
    var likes: Int = 0
    var comments: Int = 0

    static func == (lhs: TodayStats, rhs: TodayStats) -> Bool {
        lhs.views == rhs.views && lhs.visitors == rhs.visitors
        && lhs.likes == rhs.likes && lhs.comments == rhs.comments
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(views)
        hasher.combine(visitors)
        hasher.combine(likes)
        hasher.combine(comments)
    }
}
