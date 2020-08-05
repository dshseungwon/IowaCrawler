//
//  ViewController.swift
//  IowaCrawler
//
//  Created by Seungwon Ju on 2020/08/05.
//  Copyright © 2020 Seungwon Ju. All rights reserved.
//

import Cocoa
import SwiftSoup

//extension URLSessionConfiguration {
//    static func getDefaultWithMaximumConnenction(as integer: Int) -> URLSessionConfiguration {
//        self.default.httpMaximumConnectionsPerHost = integer
//
//        return self.default
//    }
//}

class ViewController: NSViewController, URLSessionDelegate {
    
    private lazy var urlSession = URLSession(configuration: .default,
                                             delegate: self,
                                             delegateQueue: nil)
    
    
    private var taskFileNameDictionary: [URLSessionDownloadTask: String] = [:]
    private var taskList: [URLSessionDownloadTask] = []
    
    private let queue = OperationQueue()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        queue.maxConcurrentOperationCount = 1
        
        let nameUrlList = fetchPianoSoundLinks()
        createDownloadTasks(with: nameUrlList)
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    private func fetchPianoSoundLinks() -> [(String, String)] {
        
        var result: [(String, String)] = []
        
        let urlAddress = "http://theremin.music.uiowa.edu/MISpiano.html"
        
        guard let url = URL(string: urlAddress) else { fatalError("Error occured while casting URL") }
        
        do {
            let html = try String(contentsOf: url, encoding: .utf8)
            let doc: Document = try SwiftSoup.parse(html)
            
            let aElements = try doc.select("a")
            
            var idx = 1
            for element in aElements {
                let elementText: String = try element.text()
                let elementHref: String = try element.attr("href")
                
                if elementHref.isAiffHref() {
                    let soundURL = "http://theremin.music.uiowa.edu/" + elementHref
                    print("\(idx):: Text: \(elementText), href: \(soundURL)")
                    result.append((elementText, soundURL))
                    idx += 1
                }
            }
            print(result.count)
            return result
            
        } catch {
            print("Error: \(error)")
            return []
        }
    }
    
    
    private func createDownloadTasks(with list: [(String, String)]) {
        for tuple in list {
            let fileName = tuple.0
            let urlString = tuple.1
            
            if let modifiedURL = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                guard let url = URL(string: modifiedURL) else { fatalError("Error occured while casting URL") }
                
                let downloadTask = urlSession.downloadTask(with: url)
                
                self.taskFileNameDictionary.updateValue(fileName, forKey: downloadTask)
                
                let operation = DownloadOperation(session: urlSession, downloadTaskURL: url, completionHandler: { (location, response, error) in
                    do {
                        let downloadsURL = try
                            FileManager.default.url(for: .downloadsDirectory,
                                                    in: .userDomainMask,
                                                    appropriateFor: nil,
                                                    create: false)

                        guard let fileName = self.taskFileNameDictionary[downloadTask] else { fatalError("Task doesn't exist in dictionary") }

                        let savedURL = downloadsURL.appendingPathComponent(fileName+".aiff")

                        try FileManager.default.moveItem(at: location!, to: savedURL)
                    } catch {
                        // handle filesystem error
                        print("Filesystem Error: \(error)")
                    }
                    print("finished downloading \(url.absoluteString)")
                })
                
                queue.addOperation(operation)
            }
        }
    }
    
//    private func startDownload() {
//        for task in taskList {
//            task.resume()
//        }
//    }
    
//    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
//        do {
//            let downloadsURL = try
//                FileManager.default.url(for: .downloadsDirectory,
//                                        in: .userDomainMask,
//                                        appropriateFor: nil,
//                                        create: false)
//
//            guard let fileName = self.taskFileNameDictionary[downloadTask] else { fatalError("Task doesn't exist in dictionary") }
//
//            let savedURL = downloadsURL.appendingPathComponent(fileName+".aiff")
//
//            try FileManager.default.moveItem(at: location, to: savedURL)
//        } catch {
//            // handle filesystem error
//            print("Filesystem Error: \(error)")
//        }
//    }
//
//    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
//        print("delegate Called")
//        guard let fileName = self.taskFileNameDictionary[downloadTask] else { fatalError("Task doesn't exist in dictionary") }
//        let progressPercentage = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite) * Float(100)
//
//        print("\(fileName): \(progressPercentage)%")
//    }
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
