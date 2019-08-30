//
//  CXGMediaPlayerFileHandle.swift
//  CXGPlayerDemo
//
//  Created by CuiXg on 2019/5/5.
//  Copyright © 2019 CuiXg. All rights reserved.
//

import UIKit

class CXGMediaPlayerFileHandle: NSObject {

    
    /// 创建缓存文件
    ///
    /// - Throws: 错误异常
    class func creatTempFile(withURL url: URL) throws {
        let fileManager = FileManager.default
        print(tempPath)
        if let tempPath = tempCacheFilePath(withURL: url) {
            if fileManager.fileExists(atPath: tempPath) {
                try fileManager.removeItem(atPath: tempPath)
            }
            fileManager.createFile(atPath: tempPath, contents: nil, attributes: nil)
        }
    }
    
    
    /// 向缓存文件添加内容
    ///
    /// - Parameter data: 需要添加的内容
    class func writeToTempFile(withURL url: URL, data: Data) {
        if let tempPath = tempCacheFilePath(withURL: url) {
            let handle = FileHandle(forWritingAtPath: tempPath)
            // 将偏移位置设置到文件内容最后
            handle?.seekToEndOfFile()
            // 追加内容
            handle?.write(data)
        }
        
    }
    
    /// 读取缓存文件内容
    ///
    /// - Parameters:
    ///   - offset: 文件便宜位置
    ///   - length: 读取数据长度
    /// - Returns: 读取到的文件
    class func readTempFileData(withURL url: URL, offset: Int64, length: Int) -> Data? {
        if let tempPath = tempCacheFilePath(withURL: url) {
            let handle = FileHandle(forReadingAtPath: tempPath)
            // 设置文件的偏移位置
            handle?.seek(toFileOffset: UInt64(offset))
            // 读取文件中一定长度的内容
            // UTF8编码汉字占3个字节 swift语言中汉字字符占1个字节
            return handle?.readData(ofLength: length)
        }
        return nil
    }
    
    
    /// 将临时缓存移到缓存文件
    ///
    /// - Parameter name: 缓存文件名
    /// - Throws: 错误异常
    class func cacheTempFile(withURL url: URL) throws {
        guard let cachePath = cacheFolderPath else { return }
        guard let tempFilePath = tempCacheFilePath(withURL: url) else {
            return
        }
        
        guard let fileName = getFileName(withURL: url) else {
            return
        }
        
        
        
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: cachePath) {
            try fileManager.createDirectory(atPath: cachePath, withIntermediateDirectories: true, attributes: nil)
        }
        let filePath = cachePath.appending("/\(fileName)")
        try fileManager.copyItem(atPath: tempFilePath, toPath: filePath)
        try fileManager.removeItem(atPath: tempFilePath)
    }
    
    class func tempCacheFilePath(withURL url: URL) -> String? {
        if let fileName = getFileName(withURL: url) {
            return tempPath.appending("/\(fileName)")
        }
        return nil
    }
    
    /// 通过 url 获取缓存路径
    ///
    /// - Parameter url: 视频 URL
    /// - Returns: 缓存路径
    class func cacheFilePath(withURL url: URL) -> String? {
        if let cachePath = cacheFolderPath, let fileName = getFileName(withURL: url) {
            let filePath = cachePath.appending("/\(fileName)")
            if FileManager.default.fileExists(atPath: filePath) {
                return filePath
            }
        }
        return nil
    }
   
    /// 清除缓存
    ///
    /// - Returns: 是否清除成功
    class func clearCache() -> Bool {
        if let cachePath = cacheFolderPath {
            do {
                try FileManager.default.removeItem(atPath: cachePath)
                return true
            }catch {
                print(error)
            }
        }
        return false        
    }
    
    /// 清除缓存
    ///
    /// - Returns: 是否清除成功
    class func clearCacheWithURL(_ url: URL) -> Bool {
        
        if let cachePath = cacheFolderPath, let fileName = getFileName(withURL: url) {
            let filePath = cachePath.appending("/\(fileName)")
            do {
                try FileManager.default.removeItem(atPath: filePath)
                return true
            }catch {
                print(error)
            }
        }
        return false
    }
    
    class func getFileName(withURL url: URL) -> String? {
        
        if url.path.contains("?") {
            return url.path.components(separatedBy: "?").first?.components(separatedBy: "/").last
        }
        
        return url.path.components(separatedBy: "/").last
    }
    
}

// MARK: - 缓存文件路径
extension CXGMediaPlayerFileHandle {
    class var tempPath: String {
        return NSTemporaryDirectory()//.appending("MediaTemp.mp4")
    }
    
    class var cacheFolderPath: String? {
        if let path = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first {
            return path.appending("/MediaCaches")
        }
        return nil
    }
    
}


