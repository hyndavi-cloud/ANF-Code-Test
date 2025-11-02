//
//  ANFExploreCardCell.swift
//  ANF Code Test
//
//  Created by Hyndavi on 11/2/25.
//

import UIKit

final class ANFExploreCardCell: UITableViewCell {
    @IBOutlet weak var heroImageView: UIImageView!
    @IBOutlet weak var topDescriptionLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var promoLabel: UILabel!
    @IBOutlet weak var contentStackView: UIStackView!
    @IBOutlet weak var bottomDescriptionLabel: UILabel!
    
    private let actionsStackView = UIStackView()
    private var actionURLs: [URL] = []
    private var currentImageURL: URL?
    override func awakeFromNib() {
        super.awakeFromNib()
        
        actionsStackView.axis = .vertical
        actionsStackView.spacing = 8
        actionsStackView.alignment = .center
        actionsStackView.distribution = .fill
        actionsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(actionsStackView)
        
        NSLayoutConstraint.activate([
            actionsStackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            actionsStackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            actionsStackView.topAnchor.constraint(equalTo: bottomDescriptionLabel.bottomAnchor, constant: 16),
            actionsStackView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor, constant: -8)
        ])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        actionsStackView.arrangedSubviews.forEach { view in
            actionsStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        actionURLs.removeAll()
    }

    func configure(with card: ExploreCard?) {
        guard let card else { return }
        titleLabel.text = card.title
        topDescriptionLabel.text = card.topDescription
        promoLabel.text = card.promoMessage
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        topDescriptionLabel.font = UIFont.systemFont(ofSize: 13)
        promoLabel.font = UIFont.systemFont(ofSize: 11)
        bottomDescriptionLabel.font = UIFont.systemFont(ofSize: 13)
        
        if let nameOrURL = card.backgroundImage, nameOrURL.lowercased().hasPrefix("http") {
            // REMOTE IMAGE
            if let url = URL(string: nameOrURL) {
                currentImageURL = url
                heroImageView.image = nil // or a placeholder
                URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                    guard
                        let self = self,
                        let data = data,
                        let image = UIImage(data: data),
                        url == self.currentImageURL // prevent cell reuse issue
                    else { return }
                    DispatchQueue.main.async {
                        self.heroImageView.image = image
                    }
                }.resume()
            } else {
                heroImageView.image = nil
            }
        } else {
            // LOCAL ASSET
            currentImageURL = nil
            heroImageView.setImage(from: card.backgroundImage) { _ in
            }
        }
         
        if let html = card.bottomDescription,
           let data = html.data(using: .utf8),
           let attributed = try? NSAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil) {
            bottomDescriptionLabel.attributedText = attributed
        } else {
            bottomDescriptionLabel.text = nil
            bottomDescriptionLabel.attributedText = nil
        }
        
        guard let content = card.content, !content.isEmpty else {
            actionsStackView.isHidden = true
            return
        }
        
        actionsStackView.arrangedSubviews.forEach { view in
            actionsStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        actionURLs.removeAll()
        
        for (index, item) in content.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(item.title, for: .normal)
            button.tag = index
            button.addTarget(self, action: #selector(actionButtonTapped(_:)), for: .touchUpInside)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
            
            button.setTitleColor(.darkGray, for: .normal)
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.gray.cgColor
            button.layer.cornerRadius = 0
            button.clipsToBounds = true
            
            actionsStackView.addArrangedSubview(button)
            NSLayoutConstraint.activate([
                button.centerXAnchor.constraint(equalTo: actionsStackView.centerXAnchor), // Center horizontally
                button.widthAnchor.constraint(equalToConstant: 200),         // Fixed width
                button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)         // Fixed height
               ])
            if let url = URL(string: item.target) {
                actionURLs.append(url)
            } else {
                actionURLs.append(URL(string: "about:blank")!) // fallback invalid URL
            }
        }
        actionsStackView.isHidden = false
    }
    
    @objc private func actionButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index < actionURLs.count else { return }
        let url = actionURLs[index]
        UIApplication.shared.open(url)
    }
}

private extension UIImageView {
    /// Sets the image asynchronously from an optional image name in asset catalog,
    /// then calls completion with the image or nil.
    func setImage(from imageName: String?, completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var image: UIImage? = nil
            if let name = imageName {
                image = UIImage(named: name)
            }
            DispatchQueue.main.async {
                self.image = image
                completion(image)
            }
        }
    }
}
