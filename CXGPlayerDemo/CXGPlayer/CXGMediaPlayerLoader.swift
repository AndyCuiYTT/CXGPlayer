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


class CXGMediaPlayerLoader: NSObject {
    
    private var requestList: [AVAssetResourceLoadingRequest] = []
    
    private var requestTask: CXGMediaPlayerRequestTask?
    
    private var isCacheEnoughToPlay: Bool = false
    
    var isSeekRequired: Bool = false

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
                if loadingOffset >= taskOffset && loadingOffset - taskOffset <= taskCachLength {
                    processRequestList()
                }else {
                    if isSeekRequired {
                        newTaskWithLoadingRequest(loadingRequest)
                    }else {
                        processRequestList()
                    }
                }
            }
            
        }else {
            newTaskWithLoadingRequest(loadingRequest)
        }
    }
    
    func newTaskWithLoadingRequest(_ loadingRequest: AVAssetResourceLoadingRequest) {
        requestList.removeAll()
        requestList.append(loadingRequest)
        var fileLength: Int64 = 0;
        if self.requestTask != nil {
            fileLength = self.requestTask?.fileLength ?? 0;
            self.requestTask?.setCancel()
        }
        self.requestTask = CXGMediaPlayerRequestTask()
        self.requestTask?.requestURL = loadingRequest.request.url
        self.requestTask?.requestOffset = loadingRequest.dataRequest?.requestedOffset ?? 0;
        self.requestTask?.cacheLength = 0
        if (fileLength > 0) {
            self.requestTask?.fileLength = Int64(fileLength);
        }
        self.requestTask?.delegate = self
        self.requestTask?.start()
        isSeekRequired = false
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

        guard let taskRequest = requestTask else { return false}
        
        loadingRequest.contentInformationRequest?.contentType = "video/mp4"
        loadingRequest.contentInformationRequest?.isByteRangeAccessSupported = true; // 是否支持分段加载
        loadingRequest.contentInformationRequest?.contentLength = self.requestTask?.fileLength ?? 0;
        
        guard let assetLoadingRequest = loadingRequest.dataRequest else { return false }
        
        //读文件，填充数据
        let cacheLength = taskRequest.cacheLength // 已经缓存数据长度
        let taskRequestOffset = taskRequest.requestOffset // 加载，缓存初始位置
        
        
        var assetLoadingRequestOffset = assetLoadingRequest.requestedOffset // 本次加载数据偏移
        let assetLoadingRequestLength = assetLoadingRequest.requestedLength // 本次加载数据长度
        
        if assetLoadingRequest.currentOffset != 0 {
            assetLoadingRequestOffset = assetLoadingRequest.currentOffset // 当前请求偏移
        }
        if assetLoadingRequestOffset >= taskRequestOffset {
            var canReadLength = cacheLength + taskRequestOffset - assetLoadingRequestOffset
            if canReadLength < 0 {
//                newTaskWithLoadingRequest(loadingRequest)
                return false
            }else {
                if canReadLength > assetLoadingRequestLength {
                    canReadLength = Int64(assetLoadingRequestLength)
                }
                
               
                loadingRequest.dataRequest?.respond(with:  CXGMediaPlayerFileHandle.readTempFileData(withURL: taskRequest.requestURL!, offset: assetLoadingRequestOffset - taskRequestOffset, length: assetLoadingRequestLength) ?? Data())
                print( CXGMediaPlayerFileHandle.readTempFileData(withURL: taskRequest.requestURL!, offset: assetLoadingRequestOffset - taskRequestOffset, length: assetLoadingRequestLength))
                 //如果完全响应了所需要的数据，则完成
                if assetLoadingRequestOffset + canReadLength >= assetLoadingRequestOffset + Int64(assetLoadingRequestLength) {
                    loadingRequest.finishLoading()
                    return true
                }
                return false
            }
        }else {
//            newTaskWithLoadingRequest(loadingRequest)
            return false
        }
    }
}

extension CXGMediaPlayerLoader: CXGMediaPlayerRequestTaskDelegate {
    func requestTaskDidFinishLoadCache() {
        
    }
    
    func requestTaskDownloadProgress(_ progress: Float) {
        processRequestList()
    }
    
    func requestTaskDidFailWithError(_ error: Error) {
        
    }
    
   
    func requestTaskDidUpdateCache() {
        processRequestList()
    }
    
}
