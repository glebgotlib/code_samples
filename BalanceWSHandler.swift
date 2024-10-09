//
//  BalanceWSHandler.swift
//  winpot-ios
//
//  Created by Gleb Goncharov on 18.12.2023.
//

import Foundation
import Starscream

class BalanceWSHelper: ObservableObject{
    var webSocketWrapper = BalanceWSHandler()
    
    func runConnect(){
        webSocketWrapper.connect()
    }
    
    func runDisconnect(){
        webSocketWrapper.disconnect()
    }
}

class BalanceWSHandler: WebSocketDelegate, ObservableObject{
    
    var socket: WebSocket?
    @Published var total: String?
    @Published var jackpots: [JackpotsModel] = []

    init() {
        guard let url = URL(string: "wss://some_websocket") else { return }
        let request = URLRequest(url: url)
        socket = WebSocket(request: request)
        socket?.delegate = self
    }
    
    func connect() -> Void {
        socket?.connect()
    }
    
    func disconnect() -> Void {
        socket?.disconnect()
    }
    
    func sendDataString(message: String){
        self.socket?.write(string: message)
    }
    
    func sendPong(){
        self.sendDataString(message: "3")
    }
    
    func sendBal(){
        self.sendDataString(message: "42[\"balance\"]")
    }
    
    func sendJackpot(){
        self.sendDataString(message: "42[\"jackpot-feed\",[\"MXN\"]]")
    }
    
    func convertJackpots(_ string: String) {
        let trimmedString = String(string.dropFirst(2))
        if let data = trimmedString.data(using: .utf8) {
            do {
                if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [Any] {
                    if jsonArray.count > 1, let jackpotData = jsonArray[1] as? [String: Any], let egtJackpots = jackpotData["Egt"] as? [[String: Any]] {
                        for jackpot in egtJackpots {
                            var jackpotModel: JackpotsModel = .init(gamesOid: [], amount: 0)
                            if let gamesOID = jackpot["games_oid"] as? [String], 
                                let amountData = jackpot["amount"] as? [String: Int],
                                let amountMXN = amountData["MXN"] {
                                jackpotModel.gamesOid = gamesOID
                                jackpotModel.amount = amountMXN
                            }
                            
                            self.jackpots.append(jackpotModel)
                        }
                    }
                }
            } catch {
                print("Error decoding JSON: \(error)")
                
            }
        }
    }
    
    func sendLogin(){
        if let token = Methods.shared.accsess_token {
            self.sendDataString(message: """
                            42[\"login\",{\"token\":\"\(token)\"}]
                            """)
        }
    }
    
    func sendOrigin(){
        self.sendDataString(message: "40{\"origin\":\"\(RequestHelper.baseWebUrl)\"}")
    }
    
    func didReceive(event: Starscream.WebSocketEvent, client: Starscream.WebSocketClient) {
        switch event {
            
        case .connected(let headers):
            self.sendOrigin()
            
        case .disconnected(let reason, let code):
            self.total = "\(Methods.shared.df2so((0.0)))"
            
        case .text(let string):
            if string.contains("jackpot-feed") {
                convertJackpots(string)
            }
            if let intString = Int(string){
                if intString == 2{
                    self.sendPong()
                }
            }
            if string.contains("40{"){
                print("Balance sendLogin")
                self.sendLogin()
                self.sendJackpot()
            }
            if string.contains("Login success"){
                self.sendBal()
            }
            if string.contains("summary"){
                if let total = self.extractTotal(from: string){
                    DispatchQueue.main.async {
                        self.total = "\(Methods.shared.df2so((total)))"
                    }
                    
                }
            }
            
            
        case .binary(let data):
            print("Balance Received data: \(data.count)")

        case .pong(let data):
            print("Balance Received pong: \(data?.count ?? 0)")

        case .ping(let data):
            print("Balance Received ping: \(data?.count ?? 0)")

        case .error(let error):
            print("Balance Error: \(String(describing: error))")

        case .viabilityChanged(let isViable):
            print("Balance Connection viability changed: \(isViable)")

        case .reconnectSuggested(let shouldReconnect):
            print("Balance Reconnect suggested: \(shouldReconnect)")

        case .cancelled:
            print("BalanceWebSocket cancelled")
            
        case .peerClosed:
            break
        }
    }
    
    func extractTotal(from jsonString: String) -> Float? {
        let pattern = "\"total\":(\\d+(\\.\\d+)?)"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(location: 0, length: jsonString.utf16.count)
            
            if let match = regex.firstMatch(in: jsonString, options: [], range: range) {
                let totalRange = Range(match.range(at: 1), in: jsonString)!
                let totalString = jsonString[totalRange]
                
                return Float(totalString)
            }
        } catch {
            print("Error creating regular expression: \(error)")
        }
        
        return nil
    }
    
}
