//
//  WebsocketStore.swift
//  Mobile
//
//  Created by Clemens Zangenfeind on 08.04.26.
//

import Foundation

import Foundation

// 1. Define the URL (use a public echo server for testing)
let url = URL(string: "wss://echo.websocket.org")!

// 2. Create the session and the task
let session = URLSession(configuration: .default)
let webSocketTask = session.webSocketTask(with: url)

class WebsocketStore {

    func connectWebsocket() {
        webSocketTask.resume()
        print("Connecting...")
    }

}






	
// 3. Start the connection	

