//
//  ViewController.swift
//  IowaCrawler
//
//  Created by Seungwon Ju on 2020/08/05.
//  Copyright © 2020 Seungwon Ju. All rights reserved.
//

import Cocoa
import SwiftSoup

class ViewController: NSViewController, URLSessionDelegate {
    
    private let queue = OperationQueue()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        queue.maxConcurrentOperationCount = 1
        
        let urlList = fetchPianoSoundLinks()
        downloadFilesSync(with: urlList)
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    private func fetchPianoSoundLinks() -> [String] {
        
        var result: [String] = []
        
        let urlAddress = "http://theremin.music.uiowa.edu/MISpiano.html"
        
        guard let url = URL(string: urlAddress) else { fatalError("Error occured while casting URL") }
        
        do {
            let html = try String(contentsOf: url, encoding: .utf8)
            let doc: Document = try SwiftSoup.parse(html)
            
            let aElements = try doc.select("a")
            
            var idx = 1
            for element in aElements {
                let elementHref: String = try element.attr("href")
                
                if elementHref.isAiffHref() {
                    let soundURL = "http://theremin.music.uiowa.edu/" + elementHref
                    result.append(soundURL)
                    idx += 1
                }
            }
            print("\(result.count) items to download")
            return result
            
        } catch {
            print("Error: \(error)")
            return []
        }
    }
    
    
    private func downloadFilesSync(with list: [String]) {
        for link in list {
            
            if let modifiedURL = link.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                guard let url = URL(string: modifiedURL) else { fatalError("Error occured while casting URL") }
                
                do {
                    let downloadsURL = try
                        FileManager.default.url(for: .downloadsDirectory,
                                                in: .userDomainMask,
                                                appropriateFor: nil,
                                                create: false)
                    
                    let savedURL = downloadsURL.appendingPathComponent(url.lastPathComponent)
                    
                    if FileManager.default.fileExists(atPath: savedURL.path) {
                        print("\(url.lastPathComponent) already exists.")
                        
                    } else {
                        let operation = DownloadOperation(session: URLSession.shared, downloadTaskURL: url) { (location, response, error) in
                            do {
                                try FileManager.default.moveItem(at: location!, to: savedURL)
                                
                                print("DONE")
                            } catch {
                                print("\(error)")
                            }
                        }
                        queue.addOperation(operation)
                    }
                } catch {
                    print("\(error)")
                }
            }
        }
    }
}



extension String {
    func isAiffHref() -> Bool {
        let pattern = ".aiff$"
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let range = NSRange(location: 0, length: self.utf8.count)
            
            return regex.firstMatch(in: self, options: [], range: range) != nil
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return false
        }
    }
}
