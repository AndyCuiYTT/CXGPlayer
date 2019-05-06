//
//  CXGMediaPlayerRequestTask.swift
//  CXGPlayerDemo
//
//  Created by qiuweniOS on 2019/5/5.
//  Copyright © 2019 CuiXg. All rights reserved.
//

import UIKit

protocol CXGMediaPlayerRequestTaskDelegate {
   func requestTaskDidUpdateCache()
}

class CXGMediaPlayerRequestTask: NSObject {
    
    private var session: URLSession?
    private var dataTask: URLSessionDataTask?
    
    var requestURL: URL?
    var requestOffset: Int64 = 0
    var fileLength: Int64 = 0
    var cacheLength: Int64 = 0
    var cache: Bool = false
    private var cancel: Bool = false
    var delegate: CXGMediaPlayerRequestTaskDelegate?

    override init() {
        super.init()
        try? CXGMediaPlayerFileHandle.creatTempFile()
    }
    
    func start() {
        guard var url = requestURL else { return }
        
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        urlComponents?.scheme = "http"
        if let u = urlComponents?.url {
            url = u
        }
        
        var request = URLRequest(url: url)
        if requestOffset > 0 {
            request.addValue("bytes=\(requestOffset)-\(fileLength - 1)", forHTTPHeaderField: "Range")
        }
        session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
        dataTask = session?.dataTask(with: request)
        dataTask?.resume()
    }
    
    func setCancel() {
        cancel = true
        dataTask?.cancel()
        session?.invalidateAndCancel()
    }
    
    

}

extension CXGMediaPlayerRequestTask: URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        if cancel {
            return
        }
        completionHandler(.allow)
        let httpResponse = response as! HTTPURLResponse
        
        if let contentRange = httpResponse.allHeaderFields["Content-Range"] as? String {
            if let fileLength = contentRange.split(separator: "/").last {
                self.fileLength = Int(fileLength) ?? 0 > 0 ? Int64(fileLength) ?? 0 : response.expectedContentLength
            }
        }else {
            self.fileLength = response.expectedContentLength
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if cancel {
            return
        }
        CXGMediaPlayerFileHandle.writeToTempFile(withData: data)
        self.cacheLength += Int64(data.count)
        self.delegate?.requestTaskDidUpdateCache()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if cancel {
            return
        }
        if error == nil, let fileName = self.requestURL?.path.components(separatedBy: "/").last {
            if cache {
                try? CXGMediaPlayerFileHandle.cacheTempFile(withFileName: fileName)
            }
        }
    }
    
}
