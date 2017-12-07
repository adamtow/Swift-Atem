import Foundation

/// Stores all relevant information to keep an ATEM connection alive.
/// Use this store to interprete incoming packets and construct new outgoing packets.
struct ConnectionState {
	/// Received packet id's. Contains all the packets that should still be acknowledged
	var received📦IDs = [UInt16]()
	
	/// The id of the last packet that was sent from this connection
	var lastSent📦ID: UInt16
	
	/// List of packets that are ready to be sent, ordered by packet number.
	/// - Attention: adding packets to this list in the wrong order, may cause them never to be sent.
	private var outBox: [SerialPacket]
	
	/// The id of the connection. At the initial connection phase this ID is temporarily set. After this phase a permanent ID is assigned.
	private(set) var id: UID
	
	private init(firstIncoming📦: Packet) {
		assert(firstIncoming📦.isConnect, "First packet should always be a connect packet")
		id = firstIncoming📦.connectionUID
		outBox = [
			SerialPacket.connectToController(uid: id, type: .connect),
			SerialPacket(connectionUID: id, data: initialMessage1,  number:  1),
			SerialPacket(connectionUID: id, data: initialMessage2,  number:  2),
			SerialPacket(connectionUID: id, data: initialMessage3,  number:  3),
			SerialPacket(connectionUID: id, data: initialMessage4,  number:  4),
			SerialPacket(connectionUID: id, data: initialMessage5,  number:  5),
			SerialPacket(connectionUID: id, data: initialMessage6,  number:  6),
			SerialPacket(connectionUID: id, data: initialMessage7,  number:  7),
			SerialPacket(connectionUID: id, data: initialMessage8,  number:  8),
			SerialPacket(connectionUID: id, data: initialMessage9,  number:  9),
			SerialPacket(connectionUID: id, data: initialMessage10, number: 10),
			SerialPacket(connectionUID: id, data: initialMessage11, number: 11),
			SerialPacket(connectionUID: id, data: initialMessage12, number: 12),
			SerialPacket(connectionUID: id, data: initialMessage13, number: 13),
			SerialPacket(connectionUID: id, data: initialMessage14, number: 14),
		]
		lastSent📦ID = 14
		received📦IDs.append(firstIncoming📦.number!)
	}
	
	private init() {
		let randomNumber = arc4random()
		id = [UInt8((randomNumber & 0x0700) >> 8), UInt8(randomNumber & UInt32(0x00FF))]
		outBox = [SerialPacket.connectToController(uid: id, type: .connect)]
		lastSent📦ID = 0
	}
	
	static func switcher(interpreting data: [UInt8]) -> ConnectionState {
		return ConnectionState(firstIncoming📦: Packet(bytes: data))
	}
	
	static func controller() -> ConnectionState {
		return ConnectionState()
	}
	
	/// Interprets data and returns the messages that it contains
	mutating func interpret(_ bytes: [UInt8]) -> [ArraySlice<UInt8>] {
		let packet = Packet(bytes: bytes)
		if let packetID = packet.number {
			received📦IDs.sortedInsert(packetID)
		}
		if let acknowledgedID = packet.acknowledgement {
			let upperBound = outBox.binarySearch { $0.number < acknowledgedID }
			if upperBound < outBox.endIndex {
				outBox.removeSubrange(0...upperBound)
			}
		}
		
		return packet.messages
	}
	
	/// Constructs a packet that should be sent to keep this connection alive
	mutating func constructKeepAlivePackets() -> [SerialPacket] {
		let originalOutBox = outBox
		for index in outBox.indices { outBox[index].makeRetransmission() }
		let oldPackets: [SerialPacket]
		if received📦IDs.isEmpty {
			oldPackets = originalOutBox
		} else {
			var (index, lastSequentialId) = (0, received📦IDs.first!)
			for id in received📦IDs[1...] {
				if id == lastSequentialId + 1 {
					lastSequentialId += 1
					index += 1
				} else {
					break
				}
			}
			received📦IDs.removeSubrange(...index)
			oldPackets = originalOutBox + [SerialPacket.init(connectionUID: id, number: nil, acknowledgement: lastSequentialId)]
		}
		if oldPackets.isEmpty {
			// If there are no packages to send, create an empty packet to keep the connection alive.
			lastSent📦ID += 1
			return [SerialPacket(connectionUID: id, number: lastSent📦ID)]
		} else {
			return oldPackets
		}
	}
	
	/// Constructs a packet containing messages you want to send
	func constructPacket(for messages: [Message]) -> SerialPacket {
		fatalError("not implemented")
	}
}
