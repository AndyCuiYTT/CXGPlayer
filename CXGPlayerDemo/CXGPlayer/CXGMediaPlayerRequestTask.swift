//
//  CXGMediaPlayerRequestTask.swift
//  CXGPlayerDemo
//
//  Created by qiuweniOS on 2019/5/5.
//  Copyright © 2019 CuiXg. All rights reserved.
//

import UIKit

// MARK: - 数据请求代理
protocol CXGMediaPlayerRequestTaskDelegate {
    
    /// 刷新加载数据
    func requestTaskDidUpdateCache()
    
    /// 缓存加载完成
    func requestTaskDidFinishLoadCache()
    
    /// 下载进度
    ///
    /// - Parameter progress: 进度
    func requestTaskDownloadProgress(_ progress: Float)
    
    /// 刷新加载数据
    func requestTaskDidFailWithError(_ error: Error)
}

class CXGMediaPlayerRequestTask: NSObject {
    
    private var session: URLSession?
    private var dataTask: URLSessionDataTask?
    
    var requestURL: URL?
    
    /// 加载初始位置
    var requestOffset: Int64 = 0
    
    /// 文件大小
    var fileLength: Int64 = 0
    
    /// 已缓存数据大小
    var cacheLength: Int64 = 0
    
    /// 是否需要缓存,仅对在头开始的缓存
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
        self.delegate?.requestTaskDownloadProgress(Float(self.cacheLength) / Float(self.fileLength))
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if cancel {
            return
        }
        if error == nil, let fileName = self.requestURL?.path.components(separatedBy: "/").last {
            if cache {
                try? CXGMediaPlayerFileHandle.cacheTempFile(withFileName: fileName)
                delegate?.requestTaskDidFinishLoadCache()
            }
        }else {
            delegate?.requestTaskDidFailWithError(error!)
        }
    }
    
}
