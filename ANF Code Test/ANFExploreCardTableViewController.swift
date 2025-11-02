//
//  ANFExploreCardTableViewController.swift
//  ANF Code Test
//

import UIKit

class ANFExploreCardTableViewController: UITableViewController {

    private var exploreData: [ExploreCard] = []

    // ViewModel can be injected for testing; if nil, it's created in viewDidLoad
    var viewModel: ExploreViewModel?

    private func presentError(_ message: String) {
        let alert = UIAlertController(title: Constants.alertTitle, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }

    private func loadData() {
        Task { [weak self] in
            guard let self = self else { return }
            guard let viewModel = self.viewModel else { return }
            await viewModel.load()
            self.exploreData = viewModel.cards
            self.tableView.reloadData()
            if let error = viewModel.errorMessage, self.exploreData.isEmpty {
                self.presentError(error)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 200
        if viewModel == nil {
            // Primary: remote, Fallback: local file
            let remoteURL = URL(string: Constants.remoteUrl)!
            let remote = RemoteExploreCardRepository(url: remoteURL, session: .shared)
            let local = LocalExploreCardRepository(bundle: .main, fileName: Constants.localDataFileName)
            let composite = CompositeExploreCardRepository(primary: remote, fallback: local)
            viewModel = ExploreViewModel(repository: composite)
        }
        loadData()
        NotificationCenter.default.addObserver(self, selector: #selector(handleForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    @objc private func handleForeground() {
        loadData()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return exploreData.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier, for: indexPath) as? ANFExploreCardCell else {
            return UITableViewCell()
        }
        guard indexPath.row < exploreData.count else {
            return cell
        }
        cell.configure(with: exploreData[indexPath.row])
        return cell
    }
}

