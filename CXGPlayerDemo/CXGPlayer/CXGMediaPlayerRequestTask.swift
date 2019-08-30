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
    

    /// 缓存加载完成
    func requestTaskDidFinishLoadCache()
    
     func requestTaskDidUpdateCache() 
    
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
    
    /// 加载初始位置, 缓存初始位置
    var requestOffset: Int64 = 0
    
    /// 文件大小
    var fileLength: Int64 = 0
    
    /// 已缓存数据大小
    var cacheLength: Int64 = 0
    
    
    /// 是否需要缓存,仅对在头开始的缓存
    var isNeedCache: Bool = false
    private var isCancel: Bool = false
    var delegate: CXGMediaPlayerRequestTaskDelegate?

    override init() {
        super.init()
        
        session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
    }
    
    func start() {
        guard var url = requestURL else { return }
        try? CXGMediaPlayerFileHandle.creatTempFile(withURL: url)
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        urlComponents?.scheme = "http"
        if let u = urlComponents?.url {
            url = u
        }
        var request = URLRequest(url: url)
//        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 180
        if requestOffset > 0 {
            request.addValue("bytes=\(requestOffset)-\(fileLength - 1)", forHTTPHeaderField: "Range")
        }
        dataTask = session?.dataTask(with: request)
        dataTask?.resume()
    }
    
    func setCancel() {
        isCancel = true
        dataTask?.cancel()
        session?.invalidateAndCancel()
    }
    
    

}

extension CXGMediaPlayerRequestTask: URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        if isCancel {
            return
        }
        // 服务器首次响应请求时，返回的响应头，长度为2字节，包含该次网络请求返回的音频文件的内容信息，例如文件长度，类型等
        let httpResponse = response as! HTTPURLResponse
        
//        let isByteRangeAccessSupported = httpResponse.allHeaderFields["Accept-Ranges"] as? String == bytes  //服务器端是否支持分段传输
        
        if let contentRange = httpResponse.allHeaderFields["Content-Range"] as? String {
            if let fileLength = contentRange.split(separator: "/").last, let length = Int64(fileLength) {
                self.fileLength = length > 0 ? length : response.expectedContentLength
            }
        }else {
            self.fileLength = response.expectedContentLength
        }
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if isCancel {
            return
        }
        CXGMediaPlayerFileHandle.writeToTempFile(withURL: requestURL!, data: data)
        self.cacheLength += Int64(data.count)
        self.delegate?.requestTaskDownloadProgress(Float(self.requestOffset + self.cacheLength) / Float(self.fileLength))
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if isCancel {
            return
        }
        if error == nil, let url = self.requestURL {
            if isNeedCache {
                try? CXGMediaPlayerFileHandle.cacheTempFile(withURL: url)
                delegate?.requestTaskDidFinishLoadCache()
            }
        }else {
            delegate?.requestTaskDidFailWithError(error!)
        }
    }
    
}
