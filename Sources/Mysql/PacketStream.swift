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
        let len = try read(upTo: 3).uInt24()
        let seq = Int(try read(upTo: 1)[0])
        
        var bytes = Bytes()
        while bytes.count < Int(len) {
            bytes.append(contentsOf: try read(upTo: Int(len)))
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
