//
//  DataCompression.swift
//  HSAppFramework
//
//  Created by kai.sun on 2019/11/5.
//  Copyright © 2019 iHandySoft Inc. All rights reserved.
//

import Foundation

public struct CompressionLevel: RawRepresentable {
    
    // Compression level in the range of `0` (no compression) to `9` (maximum compression).
    public let rawValue: Int32
    
    public static let noCompression = CompressionLevel(Z_NO_COMPRESSION)
    public static let bestSpeed = CompressionLevel(Z_BEST_SPEED)
    public static let bestCompression = CompressionLevel(Z_BEST_COMPRESSION)
    
    public static let defaultCompression = CompressionLevel(Z_DEFAULT_COMPRESSION)
    
    
    public init(rawValue: Int32) {
        
        self.rawValue = rawValue
    }
    
    
    public init(_ rawValue: Int32) {
        
        self.rawValue = rawValue
    }
    
}

public struct GzipError: Swift.Error {

    public enum Kind: Equatable {
        /// The stream structure was inconsistent.
        ///
        /// - underlying zlib error: `Z_STREAM_ERROR` (-2)
        case stream
        
        /// The input data was corrupted
        /// (input stream not conforming to the zlib format or incorrect check value).
        ///
        /// - underlying zlib error: `Z_DATA_ERROR` (-3)
        case data
        
        /// There was not enough memory.
        ///
        /// - underlying zlib error: `Z_MEM_ERROR` (-4)
        case memory
        
        /// No progress is possible or there was not enough room in the output buffer.
        ///
        /// - underlying zlib error: `Z_BUF_ERROR` (-5)
        case buffer
        
        /// The zlib library version is incompatible with the version assumed by the caller.
        ///
        /// - underlying zlib error: `Z_VERSION_ERROR` (-6)
        case version
        
        /// An unknown error occurred.
        ///
        /// - parameter code: return error by zlib
        case unknown(code: Int)
    }
    
    /// Error kind.
    public let kind: Kind
    
    /// Returned message by zlib.
    public let message: String
    
    
    internal init(code: Int32, msg: UnsafePointer<CChar>?) {
        
        self.message = {
            guard let msg = msg, let message = String(validatingUTF8: msg) else {
                return "Unknown gzip error"
            }
            return message
        }()
        
        self.kind = {
            switch code {
            case Z_STREAM_ERROR:
                return .stream
            case Z_DATA_ERROR:
                return .data
            case Z_MEM_ERROR:
                return .memory
            case Z_BUF_ERROR:
                return .buffer
            case Z_VERSION_ERROR:
                return .version
            default:
                return .unknown(code: Int(code))
            }
        }()
    }
    
    
    public var localizedDescription: String {
        
        return self.message
    }
}

private struct DataSize {
    
    static let chunk = 1 << 14
    static let stream = MemoryLayout<z_stream>.size
    
    private init() { }
}

extension Data {
    public func compressedData(level: CompressionLevel = .defaultCompression) throws -> Data {
        guard !self.isEmpty else {
            return Data()
        }
        
        var stream = z_stream()
        var status: Int32
        
        status = deflateInit2_(&stream, level.rawValue, Z_DEFLATED, MAX_WBITS + 16, MAX_MEM_LEVEL, Z_DEFAULT_STRATEGY, ZLIB_VERSION, Int32(DataSize.stream))
        
        guard status == Z_OK else {
            throw GzipError(code: status, msg: stream.msg)
        }
        
        var data = Data(capacity: DataSize.chunk)
        repeat {
            if Int(stream.total_out) >= data.count {
                data.count += DataSize.chunk
            }
            
            let inputCount = self.count
            let outputCount = data.count
            
            self.withUnsafeBytes { (inputPointer: UnsafeRawBufferPointer) in
                stream.next_in = UnsafeMutablePointer<Bytef>(mutating: inputPointer.bindMemory(to: Bytef.self).baseAddress!).advanced(by: Int(stream.total_in))
                stream.avail_in = uint(inputCount) - uInt(stream.total_in)
                
                data.withUnsafeMutableBytes { (outputPointer: UnsafeMutableRawBufferPointer) in
                    stream.next_out = outputPointer.bindMemory(to: Bytef.self).baseAddress!.advanced(by: Int(stream.total_out))
                    stream.avail_out = uInt(outputCount) - uInt(stream.total_out)
                    
                    status = deflate(&stream, Z_FINISH)
                    
                    stream.next_out = nil
                }
                
                stream.next_in = nil
            }
            
        } while stream.avail_out == 0
        
        guard deflateEnd(&stream) == Z_OK, status == Z_STREAM_END else {
            throw GzipError(code: status, msg: stream.msg)
        }
        
        data.count = Int(stream.total_out)
        
        return data
    }

    public func decompressdData() throws -> Data {
        guard !self.isEmpty else {
           return Data()
        }

        var stream = z_stream()
        var status: Int32

        status = inflateInit2_(&stream, MAX_WBITS + 32, ZLIB_VERSION, Int32(DataSize.stream))

        guard status == Z_OK else {
           throw GzipError(code: status, msg: stream.msg)
        }

        var data = Data(capacity: self.count * 2)
        repeat {
           if Int(stream.total_out) >= data.count {
               data.count += self.count / 2
           }
           
           let inputCount = self.count
           let outputCount = data.count
           
           self.withUnsafeBytes { (inputPointer: UnsafeRawBufferPointer) in
               stream.next_in = UnsafeMutablePointer<Bytef>(mutating: inputPointer.bindMemory(to: Bytef.self).baseAddress!).advanced(by: Int(stream.total_in))
               stream.avail_in = uInt(inputCount) - uInt(stream.total_in)
               
               data.withUnsafeMutableBytes { (outputPointer: UnsafeMutableRawBufferPointer) in
                   stream.next_out = outputPointer.bindMemory(to: Bytef.self).baseAddress!.advanced(by: Int(stream.total_out))
                   stream.avail_out = uInt(outputCount) - uInt(stream.total_out)
                   
                   status = inflate(&stream, Z_SYNC_FLUSH)
                   
                   stream.next_out = nil
               }
               
               stream.next_in = nil
           }
           
        } while status == Z_OK

        guard inflateEnd(&stream) == Z_OK, status == Z_STREAM_END else {
           throw GzipError(code: status, msg: stream.msg)
        }

        data.count = Int(stream.total_out)

        return data
    }
}
