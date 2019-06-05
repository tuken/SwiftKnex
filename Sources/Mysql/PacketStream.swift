//
//  PacketStream.swift
//  SwiftKnex
//
//  Created by Yuki Takei on 2017/01/10.
//
//

import Foundation

typealias PacketStream = TCPStream

extension PacketStream {
    
    func readPacket() throws -> (Bytes, Int) {
        var header = Bytes()
        var expected = 4
        while header.count < expected {
            header.append(contentsOf: try read(upTo: expected - header.count))
        }
        
        let len = Int(header.uInt24())
        let seq = Int(header[3])
        
        var bytes = Bytes()
        expected = len
        while bytes.count < expected {
            bytes.append(contentsOf: try read(upTo: expected - bytes.count))
        }
        
        return (bytes, seq)
    }
    
    func writeHeader(_ len: UInt32, pn: UInt8) throws {
        try self.write([UInt8].UInt24Array(len) + [pn])
    }
    
    func writePacket(_ bytes: [UInt8], packnr: Int) throws {
        try writeHeader(UInt32(bytes.count), pn: UInt8(packnr + 1))
        try self.write(bytes)
    }
}
