//
//  ImageDownloader.swift
//  Nuntius
//
//  Created by Noman Ashraf on 9/16/23.
//

import UIKit

class ImageDownloader {
    static func downloadImage(_ urlString: String, completion: ((_ image: UIImage?) -> ())?) {
       guard let url = URL(string: urlString) else {
          completion?(nil)
          return
      }
      URLSession.shared.dataTask(with: url) { (data, response,error) in
         if let error = error {
            print("error in downloading image: \(error)")
            completion?(nil)
            return
         }
         guard let httpResponse = response as? HTTPURLResponse,(200...299).contains(httpResponse.statusCode) else {
            completion?(nil)
            return
         }
         if let data = data, let image = UIImage(data: data) {
            completion?(image)
            return
         }
         completion?(nil)
      }.resume()
   }
}
