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
    
    func storePicture(with data: Data, fileName: String, completionHandler: @escaping(String) -> Void){
        storage.child("profileImages/\(fileName)").putData(data, metadata: nil, completion: {metadata,error in
            if let e = error {
                print("putDataERROR\(e)")
            }else{
                self.storage.child("profileImages/\(fileName)").downloadURL(completion: { url, error in
                    if let e = error {
                        print("downloadURLERROR\(e)")
                    }else{
                        let urlString = url?.absoluteString
                        completionHandler(urlString!)
                    }
                })
            }
        })
    }
    func storeImage(with data: Data, fileName: String, completionHandler: @escaping(String) -> Void){
        storage.child("messageImages/\(fileName)").putData(data, metadata: nil, completion: {metadata,error in
            if let e = error {
                print("putDataERROR\(e)")
            }else{
                self.storage.child("messageImages/\(fileName)").downloadURL(completion: { url, error in
                    if let e = error {
                        print("downloadURLERROR\(e)")
                    }else{
                        completionHandler((url?.absoluteString)!)
                    }
                })
            }
        })
    }
    
    //test 1: check if only case reg
    func getURL(for path: String, completionHandler: @escaping (URL) -> Void) {
        let reference = storage.child(path)
        
        reference.downloadURL(completion: { url, error in
            if let e = error {
                print("downloadURLERROR\(e)")
            }else{
                completionHandler(url!)
            }
        })
    }
    
    
}
