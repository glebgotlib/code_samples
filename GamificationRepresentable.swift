//
//  GamificationRepresentable.swift
//  winpot-casino
//
//  Created by Gleb Goncharov on 22.06.2023.
//

import SwiftUI
import WebKit
import Foundation
import UIKit

private let BCID_PAGE_READY_ID = 1
private let BCID_CLOSE_ID = 2
private let BCID_PAGE_READY_TO_BE_SHOWN_ID = 5
private let BRIDGE_NAME = "SOME_Bridge"

struct GamificationRepresentable: UIViewRepresentable {
    func updateUIView(_ uiView: UIViewType, context: Context) {}
    @StateObject var viewModel: MainViewModel
    @State var url: String
    @StateObject var coordinator: Coordinator
    @State var isPopup: Bool = false
    @Binding var tab: Tab
    @State private var webView: WKWebView?
    
    func makeCoordinator() -> WebGamificationCoordinator {
        WebGamificationCoordinator(self, viewModel)
    }

    func makeUIView(context: Context) -> some UIView {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.allowsInlineMediaPlayback = true
        webConfiguration.userContentController.add(context.coordinator, name: "nativeMessageHandler")
        webConfiguration.userContentController.add(context.coordinator, name: BRIDGE_NAME)
        if viewModel.gameficationUrl == ""{
            DispatchQueue.main.async {
                viewModel.gameficationUrl = url
            }
        }
        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.backgroundColor = .clear
        webView.isOpaque = false
        
        if isPopup{
            webView.backgroundColor = .clear
            webView.isOpaque = false
        }
        if let url = URL(string: url){
            webView.load(URLRequest(url: url))
        }

        webView.navigationDelegate = context.coordinator
        viewModel.loadingStart = true
        
        DispatchQueue.main.async {
            self.webView = webView
        }
        
        return webView
    }

    func reloadWebView(_ webView: WKWebView) {
        webView.reload()
    }
    
    class WebGamificationCoordinator: CustomNavigationDelegate, UIWebViewDelegate, WKScriptMessageHandler {
        let parent: GamificationRepresentable
        @State var viewModel: MainViewModel
        
        init(_ parent: GamificationRepresentable, _ viewModel: MainViewModel) {
            self.parent = parent
            self.viewModel = viewModel
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            let script = """
                           window.addEventListener('message', function(event) {
                               if (event.data === 'PAGE_READY') {
                                    window.webkit.messageHandlers.nativeMessageHandler.postMessage({\"PAGE_READY\"});
                               }
                           });
                        """

            let script2 = """
                           window.addEventListener('message', function(event) {
                               if (event.data === 'CLOSE_ME') {
                                    window.webkit.messageHandlers.nativeMessageHandler.postMessage('CLOSE_ME');
                               }
                           });
                        """

            let script3 = """
                           window.addEventListener('message', function(event) {
                                    window.webkit.messageHandlers.nativeMessageHandler.postMessage(event.data);
                           });
                        """
            
            webView.evaluateJavaScript(script, completionHandler: nil)
            webView.evaluateJavaScript(script2, completionHandler: nil)
            webView.evaluateJavaScript(script3, completionHandler: nil)
            webView.backgroundColor = .clear
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if shouldOpenMain{
                shouldOpenMain = false
                let url = URL(string: viewModel.gameficationUrl)!
                let request = NSMutableURLRequest(url: url)
                webView.load(request as URLRequest)
                decisionHandler(.cancel)
            }else{
                decisionHandler(.allow)
            }
            
        }

        var shouldOpenMain = false
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if let jsonString = message.body as? String, let data = jsonString.data(using: .utf8) {
                guard let data = message.body as? String,
                      let jsonData = data.data(using: .utf8) else {
                    return
                }
                do {
                    let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]

                    if let dp = json?["dp"] as? String, dp.contains("dp:go&url="){
                        if let link = dp.split(separator: "dp:go&url=").first{
                            print("message.body: = \(message.body)")
                            shouldOpenMain = true
                            Methods.shared.sport = String(link)
                            NotificationCenter.default.post(name: .sportOpenLink, object: link)
                            self.parent.tab = .main
                        }
                    }
                    
                    if let bcid = json?["bcid"] as? Int {
                        switch bcid {
                        case BCID_PAGE_READY_ID:
                            print("BCID_PAGE_READY_ID")
                        case BCID_PAGE_READY_TO_BE_SHOWN_ID:
                            self.viewModel.loadingStart = false
                        case BCID_CLOSE_ID:
                            if parent.isPopup{
                                parent.viewModel.minigame_should_hide = true
                            }else{
                                parent.viewModel.loadingStart = false
                                self.parent.tab = .main
                                let url = URL(string: viewModel.gameficationUrl)!
                                let request = NSMutableURLRequest(url: url)
                                parent.webView?.load(request as URLRequest)
                            }
                        default:
                            break
                        }
                    }
                } catch {
                    print("Error parsing JSON: \(error)")
                }
            }

        }
    }
}
