//
//  DownloadOperation.swift
//  IowaCrawler
//
//  Created by Seungwon Ju on 2020/08/05.
//  Copyright © 2020 Seungwon Ju. All rights reserved.
//

import Foundation

class DownloadOperation : Operation, URLSessionTaskDelegate, URLSessionDownloadDelegate {
    
    private var task : URLSessionDownloadTask!
    private var userCompletionHandler : ((URL?) -> Void)?
    private lazy var session = URLSession(configuration: .default,
                                          delegate: self,
                                          delegateQueue: nil)
    
    private let totalBlock = 10
    private var printedBlock = 0
    
    enum OperationState : Int {
        case ready
        case executing
        case finished
    }
    
    // default state is ready (when the operation is created)
    private var state : OperationState = .ready {
        willSet {
            self.willChangeValue(forKey: "isExecuting")
            self.willChangeValue(forKey: "isFinished")
        }
        
        didSet {
            self.didChangeValue(forKey: "isExecuting")
            self.didChangeValue(forKey: "isFinished")
        }
    }
    
    override var isReady: Bool { return state == .ready }
    override var isExecuting: Bool { return state == .executing }
    override var isFinished: Bool { return state == .finished }
    
    init(downloadTaskURL: URL, completionHandler: ((URL?) -> Void)?) {
        super.init()
        
        task = session.downloadTask(with: downloadTaskURL)
        
        userCompletionHandler = completionHandler
    }
    
    override func start() {
        /*
         if the operation or queue got cancelled even
         before the operation has started, set the
         operation state to finished and return
         */
        if(self.isCancelled) {
            state = .finished
            return
        }
        
        // set the state to executing
        state = .executing
        
        print("DOWNLOAD: \(self.task.originalRequest?.url?.lastPathComponent ?? "")  ", terminator: "")
        
        // start the downloading
        self.task.resume()
    }
    
    override func cancel() {
        super.cancel()
        
        // cancel the downloading
        self.task.cancel()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if let completionHandler = userCompletionHandler {
            completionHandler(location)
        }
        self.state = .finished
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        let calculatedProgress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite) * Float(10)
        let FlooredProgress = Int(floorf(calculatedProgress))
        
        let blockToPrint = FlooredProgress - printedBlock
        for _ in 0 ..< blockToPrint {
            print("_", terminator: "")
        }
        
        printedBlock = FlooredProgress
        
        if printedBlock == totalBlock {
            printedBlock = 0
            print(" DONE")
        }
    }
    
    
}
