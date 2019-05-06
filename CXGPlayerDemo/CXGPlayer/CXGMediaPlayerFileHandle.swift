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
    class func creatTempFile() throws {
        let fileManager = FileManager.default
        print(tempFilePath)
        if fileManager.fileExists(atPath: tempFilePath) {
            try fileManager.removeItem(atPath: tempFilePath)
        }
        fileManager.createFile(atPath: tempFilePath, contents: nil, attributes: nil)
    }
    
    
    /// 向缓存文件添加内容
    ///
    /// - Parameter data: 需要添加的内容
    class func writeToTempFile(withData data: Data) {
        let handle = FileHandle(forWritingAtPath: tempFilePath)
        // 将偏移位置设置到文件内容最后
        handle?.seekToEndOfFile()
        // 追加内容
        handle?.write(data)
    }
    
    /// 读取缓存文件内容
    ///
    /// - Parameters:
    ///   - offset: 文件便宜位置
    ///   - length: 读取数据长度
    /// - Returns: 读取到的文件
    class func readTempFileData(withOffset offset: Int64, length: Int) -> Data? {
        let handle = FileHandle(forReadingAtPath: tempFilePath)
        // 设置文件的偏移位置
        handle?.seek(toFileOffset: UInt64(offset))
        // 读取文件中一定长度的内容
        // UTF8编码汉字占3个字节 swift语言中汉字字符占1个字节
        return handle?.readData(ofLength: length)
    }
    
    
    /// 将临时缓存移到缓存文件
    ///
    /// - Parameter name: 缓存文件名
    /// - Throws: 错误异常
    class func cacheTempFile(withFileName name: String) throws {
        guard let cachePath = cacheFolderPath else { return }
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: cachePath) {
            try fileManager.createDirectory(atPath: cachePath, withIntermediateDirectories: true, attributes: nil)
        }
        let filePath = cachePath.appending("/\(name)")
        try fileManager.copyItem(atPath: tempFilePath, toPath: filePath)
    }
    
    /// 通过 url 获取缓存路径
    ///
    /// - Parameter url: 视频 URL
    /// - Returns: 缓存路径
    class func cacheFilePath(withURL url: URL) -> String? {
        if let cachePath = cacheFolderPath, let fileName = url.path.components(separatedBy: "/").last {
            let filePath = cachePath.appending("/\(fileName)")
            if FileManager.default.fileExists(atPath: filePath) {
                return filePath
            }
        }
        return nil
    }
   
    
}

// MARK: - 缓存文件路径
extension CXGMediaPlayerFileHandle {
    class var tempFilePath: String {
        return NSTemporaryDirectory().appending("MediaTemp.mp4")
    }
    
    class var cacheFolderPath: String? {
        if let path = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first {
            return path.appending("/MediaCaches")
        }
        return nil
    }
    
}


