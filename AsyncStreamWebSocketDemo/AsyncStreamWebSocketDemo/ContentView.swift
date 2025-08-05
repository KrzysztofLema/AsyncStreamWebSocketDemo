//
//  ContentView.swift
//  AsyncStreamWebSocketDemo
//
//  Created by Krzysztof Lema on 05/08/2025.
//
//
//  ContentView.swift
//  AsyncStreamWebSocketDemo
//
//  Created by Krzysztof Lema on 05/08/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var webSocketClient = WebSocketClient()
    @State private var messageText = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "network")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                
                Text("AsyncStream WebSocket Demo")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Learn Swift Concurrency with Real-time Communication")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top)
            
            // Connection Status
            HStack {
                Circle()
                    .fill(webSocketClient.isConnected ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                
                Text(webSocketClient.connectionStatus)
                    .font(.caption)
                    .foregroundColor(webSocketClient.isConnected ? .green : .red)
                
                Spacer()
                
                if webSocketClient.isConnected {
                    Button("Disconnect") {
                        webSocketClient.disconnect()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            
            // Message Input
            HStack {
                TextField("Type your message...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(!webSocketClient.isConnected)
                
                Button("Send") {
                    Task {
                        await webSocketClient.send(messageText)
                        messageText = ""
                    }
                }
                .disabled(!webSocketClient.isConnected || messageText.isEmpty)
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            
            // Messages Display
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Messages")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button("Clear") {
                        webSocketClient.messages.removeAll()
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                }
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(webSocketClient.messages, id: \.self) { message in
                            Text(message)
                                .font(.system(.caption, design: .monospaced))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.gray.opacity(0.1))
                                )
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .frame(maxHeight: 300)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.05))
                )
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 600, minHeight: 500)
        .background()
    }
}

#Preview {
    ContentView()
}
