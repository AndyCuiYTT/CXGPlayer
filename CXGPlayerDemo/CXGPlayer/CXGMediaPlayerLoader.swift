//
//  CXGMediaPlayerLoader.swift
//  CXGPlayerDemo
//
//  Created by CuiXg on 2019/5/5.
//  Copyright © 2019 CuiXg. All rights reserved.
//


/**
 *
 *  参考: https://github.com/DaMingShen/SUCacheLoader
 *
 *  缓存仅对加载完全的数据进行缓存,对于因为快进造成的数据不完全不进行缓存
 *
 */
import UIKit
import MobileCoreServices

protocol CXGMediaPlayerLoaderDelegate {
    
    
    /// 进入加载缓冲状态
    func loaderWaitingForLoadCache()
    
    /// 缓冲足够播放
    func loaderCacheEnoughToPlay()
    
    /// 缓存进度
    ///
    /// - Parameter progress: 进度
    func loaderCacheProgress(_ progress: Float)
    
    /// 视频加载失败
    ///
    /// - Parameter error: 失败原因
    func loaderRequestFailWithError(_ error: Error)
    
    
}

class CXGMediaPlayerLoader: NSObject {
    
    private var requestList: [AVAssetResourceLoadingRequest] = []
    
    private var requestTask: CXGMediaPlayerRequestTask?
    
    var delegate: CXGMediaPlayerLoaderDelegate?
    
    private var isCacheEnoughToPlay: Bool = false


}

extension CXGMediaPlayerLoader: AVAssetResourceLoaderDelegate {
    
    /// 要求加载资源的代理方法
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        self.addLoadingRequest(loadingRequest)
        return true
    }
    
    /// 取消加载资源的代理方法
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        if let index = requestList.firstIndex(of: loadingRequest) {
            requestList.remove(at: index)
        }
    }
    
    
}

extension CXGMediaPlayerLoader {
    
    func addLoadingRequest(_ loadingRequest: AVAssetResourceLoadingRequest) {
        requestList.append(loadingRequest)
        if self.requestTask != nil {
            if let loadingOffset = loadingRequest.dataRequest?.requestedOffset, let taskCachLength = self.requestTask?.cacheLength, let taskOffset = self.requestTask?.requestOffset {
                // 判断是否有缓存可供播放,有则回填数据
                if loadingOffset - taskOffset < taskCachLength {
                    if !isCacheEnoughToPlay {
                        delegate?.loaderCacheEnoughToPlay()
                        isCacheEnoughToPlay = true
                    }
                    processRequestList()
                }else {
                    if isCacheEnoughToPlay {
                        delegate?.loaderWaitingForLoadCache()
                        isCacheEnoughToPlay = false
                    }
//                    newTaskWithLoadingRequest(loadingRequest, cache: false)
                }
            }
            
        }else {
            newTaskWithLoadingRequest(loadingRequest, cache: true)
        }
        
    }
    
    func newTaskWithLoadingRequest(_ loadingRequest: AVAssetResourceLoadingRequest, cache: Bool) {
        var fileLength: Int64 = 0;
        if self.requestTask != nil {
            fileLength = self.requestTask?.fileLength ?? 0;
            self.requestTask?.setCancel()
        }
        self.requestTask = CXGMediaPlayerRequestTask()
        self.requestTask?.requestURL = loadingRequest.request.url
        self.requestTask?.requestOffset = loadingRequest.dataRequest?.requestedOffset ?? 0;
        self.requestTask?.cache = cache;
        if (fileLength > 0) {
            self.requestTask?.fileLength = Int64(fileLength);
        }
        self.requestTask?.delegate = self
        self.requestTask?.start()
    }
    
    
    func processRequestList() {
        for loadingRequest in self.requestList {
            
            if finishLoadingWithLoadingRequest(loadingRequest) {
                if let index = requestList.firstIndex(of: loadingRequest) {
                    requestList.remove(at: index)
                }
            }
        }
        
    }
    
    func finishLoadingWithLoadingRequest(_ loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        //填充信息
        
        loadingRequest.contentInformationRequest?.contentType = "video/mp4"
        loadingRequest.contentInformationRequest?.isByteRangeAccessSupported = true;
        loadingRequest.contentInformationRequest?.contentLength = self.requestTask?.fileLength ?? 0;
        
        
        guard let task = requestTask else { return false}
        
        guard let dataRequest = loadingRequest.dataRequest else { return false }
        
        //读文件，填充数据
        let cacheLength = task.cacheLength
        var requestedOffset: Int64 = dataRequest.requestedOffset
        if dataRequest.currentOffset != 0 {
            requestedOffset = dataRequest.currentOffset
        }
        let canReadLength = cacheLength - requestedOffset
        
        let respondLength = Int(canReadLength) < dataRequest.requestedLength ? Int(canReadLength) :  dataRequest.requestedLength
        
//        print("cacheLength \(cacheLength), requestedOffset \(requestedOffset), currentOffset \(dataRequest.currentOffset), canReadLength \(canReadLength), requestedLength \(dataRequest.requestedLength)");
        
//        print(task.requestOffset)
        
        /// 在缓存文件取出数据回填(在头开始加载,以及半路加载)
        loadingRequest.dataRequest?.respond(with: CXGMediaPlayerFileHandle.readTempFileData(withOffset: requestedOffset - task.requestOffset, length: respondLength) ?? Data())
        
                
        //如果完全响应了所需要的数据，则完成
        let nowendOffset = requestedOffset + canReadLength;
        let reqEndOffset = dataRequest.requestedOffset + Int64(dataRequest.requestedLength);
        if (nowendOffset >= reqEndOffset) {
            loadingRequest.finishLoading()
            return true
        }
        return false
    }
}

extension CXGMediaPlayerLoader: CXGMediaPlayerRequestTaskDelegate {
    func requestTaskDidFinishLoadCache() {
        
    }
    
    
    func requestTaskDownloadProgress(_ progress: Float) {
        if let task = requestTask {
            delegate?.loaderCacheProgress(Float(task.cacheLength + task.requestOffset) / Float(task.fileLength))
        }
    }
    
    func requestTaskDidUpdateCache() {
        processRequestList()
    }
    
    func requestTaskDidFailWithError(_ error: Error) {
        delegate?.loaderRequestFailWithError(error)
    }
    
    
}
