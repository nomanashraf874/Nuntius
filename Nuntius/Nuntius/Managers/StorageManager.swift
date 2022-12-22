//
//  StorageManager.swift
//  Nuntius
//
//  Created by Noman Ashraf on 11/23/22.
//

import Foundation
import FirebaseStorage


class StorageMangager {
    static let base = StorageMangager()
    
    private let storage = Storage.storage().reference()
    
    public func storePicture(with data: Data, fileName: String, completionHandler: @escaping(Result<String,Error>) -> Void){
        storage.child("images/\(fileName)").putData(data, metadata: nil, completion: {metadata,error in
            if let e = error {
                print(e)
                completionHandler(.failure(CustomError.failedToStore))
            }else{
                self.storage.child("images/\(fileName)").downloadURL(completion: { url, error in
                    if let e = error {
                        print(e)
                        completionHandler(.failure(CustomError.failedToGetURL))
                    }else{
                        let urlString = url?.absoluteString
                        completionHandler(.success(urlString!))
                    }
                })
            }
        })
    }
//test 1: check if only case reg
    public func getURL(for path: String, completion: @escaping (Result<URL, Error>) -> Void) {
            let reference = storage.child(path)

            reference.downloadURL(completion: { url, error in
                guard let url = url, error == nil else {
                    completion(.failure(CustomError.failedToGetURL2))
                    return
                }
                completion(.success(url))
            })
        }
    
    
}
