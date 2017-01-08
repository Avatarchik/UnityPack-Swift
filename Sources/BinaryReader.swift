//
//  BinaryReader.swift
//  UnityPack-Swift
//
//  Created by Istvan Fehervari on 05/01/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation

public typealias Byte = UInt8

extension Data {
    
    func toByteArray() -> [Byte] {
        let count = self.count / MemoryLayout<Byte>.size
        var array = [Byte](repeating: 0, count: count)
        copyBytes(to: &array, count:count * MemoryLayout<Byte>.size)
        return array
    }
    
}

public protocol Readable {
    func readBytes(count: Int) -> [UInt8]
    func seek(count: Int, whence: Int)
    var tell: Int { get }
}

class UPData : Readable {
    var location: Int = 0
    var data: Data
    
    init(withData data: Data) {
        self.data = data
    }
    
    func readBytes(count: Int) -> [UInt8] {
        if location >= data.count {
            return [UInt8]()
        }
        
        let startIndex = location
        let endIndex = location + count
        
        var bytes = [UInt8](repeating:0, count: count)
        data.copyBytes(to: &bytes, from: startIndex..<endIndex)
        
        location += count
        return bytes
    }
    
    var tell: Int { return location }
    
    func seek(count: Int, whence: Int = 0) {
        location = count
    }
}

public class BinaryReader {
    var buffer: Readable
    
    init(data: Readable) {
        self.buffer = data
    }
    
    func tell() -> Int { return buffer.tell }
    
    func readBytes(count: Int) -> [UInt8] {
        return buffer.readBytes(count: count)
    }
    
    func seek(count: Int32) {
        buffer.seek(count: Int(count), whence: 0)
    }
    
    func readUInt8() -> UInt8 {
        var bytes = readBytes(count: 1)
        return bytes[0]
    }
    
    func readInt() -> Int32 {
        let b = buffer.readBytes(count: 4)
        let int: Int32 = BinaryReader.fromByteArray(b, Int32.self)
        return int
    }
    
    func readInt16() -> Int16 {
        let b = buffer.readBytes(count: 2)
        let int: Int16 = BinaryReader.fromByteArray(b, Int16.self)
        return int
    }
    
    func readInt64() -> Int64 {
        let b = buffer.readBytes(count: 8)
        let int: Int64 = BinaryReader.fromByteArray(b, Int64.self)
        return int
    }
    
    func readUInt() -> UInt32 {
        let b = buffer.readBytes(count: 4)
        let int: UInt32 = BinaryReader.fromByteArray(b, UInt32.self)
        return int
    }
    
    func readString() -> String {
        var bytes:[UInt8] = []
        
        while true {
            if let byte = readBytes(count: 1).first {
                if UInt32(byte) == ("\0" as UnicodeScalar).value {
                    break
                }
                bytes.append(byte)
            } else {
                break
            }
        }
        
        //print("Bytes: \(bytes)")
        //print("\(MemoryLayout<String>.size)")
        //let bytes = readBytes(count: 8)
        let string = String(bytes: bytes, encoding: .utf8)?
            .characters.filter { $0 != "\0" }
            .map { String($0) }
            .joined()
        //print("String : \(string)")
        return string ?? ""
    }
    
    static func toByteArray<T>(_ value: T) -> [UInt8] {
        var value = value
        return withUnsafeBytes(of: &value) { Array($0) }
    }
    
    static func fromByteArray<T>(_ value: [UInt8], _: T.Type) -> T {
        return value.withUnsafeBytes {
            $0.baseAddress!.load(as: T.self)
        }
    }
}
