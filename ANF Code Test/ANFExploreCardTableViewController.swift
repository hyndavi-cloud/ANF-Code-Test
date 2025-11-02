//
//  ANFExploreCardTableViewController.swift
//  ANF Code Test
//

import UIKit

class ANFExploreCardTableViewController: UITableViewController {

    private var exploreData: [ExploreCard]? {
        if let filePath = Bundle.main.path(forResource: "exploreData", ofType: "json"),
           let fileContent = try? Data(contentsOf: URL(fileURLWithPath: filePath)),
           let cards = try? JSONDecoder().decode([ExploreCard].self, from: fileContent) {
            return cards
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        exploreData?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "exploreContentCell", for: indexPath) as? ANFExploreCardCell else {
            return UITableViewCell()
        }
        cell.configure(with: exploreData?[indexPath.row])
        return cell
    }
}
