//
//  UIImageView+Async.swift
//  ANF Code Test
//
//  Created by Hyndavi on 11/2/25.
//

import UIKit

extension UIImageView {
    func setImage(from string: String?) {
        self.image = nil
        guard let string = string, !string.isEmpty else { return }

        // Try as URL first
        if let url = URL(string: string), url.scheme != nil {
            // Remote image
            let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let data = data, let image = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    self?.image = image
                    self?.superview?.setNeedsLayout()
                }
            }
            task.resume()
        } else {
            // Local image
            self.image = UIImage(named: string)
        }
    }
}
