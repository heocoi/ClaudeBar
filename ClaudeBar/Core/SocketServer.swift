import Foundation
import os

private let logger = Logger(subsystem: "com.anhphong.ClaudeBar", category: "SocketServer")

final class SocketServer {
    private var serverFD: Int32 = -1
    private var onDataReceived: ((Data) -> Void)?
    private var isRunning = false

    private let socketPath = "/tmp/claudebar.sock"

    func start(onData: @escaping (Data) -> Void) {
        self.onDataReceived = onData

        // Remove existing socket file
        unlink(socketPath)

        // Create socket
        serverFD = socket(AF_UNIX, SOCK_STREAM, 0)
        guard serverFD >= 0 else {
            logger.error("Failed to create socket")
            return
        }

        // Bind
        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        withUnsafeMutablePointer(to: &addr) { addrPtr in
            socketPath.withCString { pathPtr in
                let sunPathOffset = MemoryLayout.offset(of: \sockaddr_un.sun_path)!
                let dest = UnsafeMutableRawPointer(addrPtr).advanced(by: sunPathOffset)
                    .assumingMemoryBound(to: CChar.self)
                _ = strcpy(dest, pathPtr)
            }
        }

        let bindResult = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(serverFD, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        guard bindResult == 0 else {
            logger.error("Failed to bind: \(String(cString: strerror(errno)))")
            close(serverFD)
            return
        }

        guard listen(serverFD, 5) == 0 else {
            logger.error("Failed to listen: \(String(cString: strerror(errno)))")
            close(serverFD)
            return
        }

        isRunning = true
        logger.info("Socket server ready at \(self.socketPath)")

        // Accept loop on a dedicated thread (accept() blocks)
        Thread.detachNewThread { [weak self] in
            self?.acceptLoop()
        }
    }

    func stop() {
        isRunning = false
        if serverFD >= 0 {
            close(serverFD)
            serverFD = -1
        }
        unlink(socketPath)
    }

    private func acceptLoop() {
        while isRunning {
            var clientAddr = sockaddr_un()
            var clientLen = socklen_t(MemoryLayout<sockaddr_un>.size)

            let clientFD = withUnsafeMutablePointer(to: &clientAddr) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    accept(serverFD, $0, &clientLen)
                }
            }

            guard clientFD >= 0 else {
                if isRunning {
                    logger.error("Accept failed: \(String(cString: strerror(errno)))")
                }
                continue
            }

            logger.info("Client connected")

            // Read on a separate thread so accept loop isn't blocked
            Thread.detachNewThread { [weak self] in
                self?.readClient(fd: clientFD)
            }
        }
    }

    private func readClient(fd: Int32) {
        var allData = Data()
        let bufferSize = 4096
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer {
            buffer.deallocate()
            close(fd)
        }

        while true {
            let bytesRead = read(fd, buffer, bufferSize)
            if bytesRead > 0 {
                allData.append(buffer, count: bytesRead)
            } else {
                break
            }
        }

        if !allData.isEmpty {
            let str = String(data: allData, encoding: .utf8) ?? "(binary)"
            logger.info("Received \(allData.count) bytes: \(str)")
            onDataReceived?(allData)
        } else {
            logger.warning("Client connected but sent no data")
        }
    }
}
