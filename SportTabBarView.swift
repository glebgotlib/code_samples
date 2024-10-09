//
//  SportTabBarView.swift
//  winpot-ios
//
//  Created by Gleb Goncharov on 14.04.2023.
//

import SwiftUI

struct SportTabBarView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State var selection: Tab = .main
    
    let sportTabsLoggedIn: [Tab] = [.main, .deposite, .winclub, .promo, .menu]
    let sportTabs: [Tab] = [.main, .deposite, .promo, .menu]
    
    init(){
        UITabBar.appearance().barTintColor = UIColor(Color("tab_bar_color"))
        UITabBar.appearance().tintColor = .white
        UITabBar.appearance().isTranslucent = true
        
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color("tab_bar_color"))
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = UITabBar.appearance().standardAppearance
        }
    }
    var body: some View{
        NavigationView {
            if viewModel.isLogedIn{
                ZStack(alignment: .bottom) {
                    TabView(selection: $selection){
                        MainViewSport(tab: $selection)
                            .tag(Tab.main)
                            .toolbar(.hidden, for: .tabBar)
                        
                        DepositTabView()
                            .tag(Tab.deposite)
                            .toolbar(.hidden, for: .tabBar)
                        
                        SportStaticLogoView(tab: $selection)
                            .tag(Tab.winclub)
                            .toolbar(.hidden, for: .tabBar)
                        
                        PromotionsView()
                            .tag(Tab.promo)
                            .toolbar(.hidden, for: .tabBar)
                        
                        MainMenuView(tab: $selection)
                            .tag(Tab.menu)
                            .toolbar(.hidden, for: .tabBar)
                    }
                    ZStack{
                        HStack{
                            ForEach(sportTabsLoggedIn, id: \.self) { item in
                                Spacer()
                                Button {
                                    selection = item
                                } label: {
                                    CustomTabItem(imageName: item.iconNameSport, title: item.titleSport, isActive: (selection == item), vip: item == .winclub, isSport: true)
                                }
                                Spacer()
                            }
                        }
                    }
                    .frame(height: 40)
                    .background(Color(.ntabBar))
                    .ignoresSafeArea(.all, edges: .bottom)
                }
                .onReceive(NotificationCenter.default.publisher(for: .deepLinkAction)) { _ in
                    if UserProfileRepository.shared.deepLinkURL.navigationPath != .none {
                        selection = UserProfileRepository.shared.deepLinkURL.navigationPath
                        UserProfileRepository.shared.deepLinkURL = .none
                    }
                }
                .onAppear() {
                    if UserProfileRepository.shared.deepLinkURL.navigationPath != .none {
                        selection = UserProfileRepository.shared.deepLinkURL.navigationPath
                        UserProfileRepository.shared.deepLinkURL = .none
                    }
                }
            }else{
                ZStack(alignment: .bottom) {
                    TabView(selection: $selection){
                        MainViewSport(tab: $selection)
                            .tag(Tab.main)
                            .toolbar(.hidden, for: .tabBar)
                        
                        LoginView(hide: true)
                            .tag(Tab.deposite)
                            .toolbar(.hidden, for: .tabBar)
                        
                        PromotionsView()
                            .tag(Tab.promo)
                            .toolbar(.hidden, for: .tabBar)
                        
                        MainMenuView(tab: $selection)
                            .tag(Tab.menu)
                            .toolbar(.hidden, for: .tabBar)
                    }
                    ZStack{
                        HStack{
                            ForEach(sportTabs, id: \.self) { item in
                                Spacer()
                                Button {
                                    selection = item
                                } label: {
                                    CustomTabItem(imageName: item.iconNameSport, title: item.titleSport, isActive: (selection == item), vip: item == .winclub, isSport: true)
                                }
                                Spacer()
                            }
                        }
                    }
                    .frame(height: 40)
                    .background(Color(.ntabBar))
                    .ignoresSafeArea(.all, edges: .bottom)
                }
                .onReceive(NotificationCenter.default.publisher(for: .deepLinkAction)) { _ in
                    if UserProfileRepository.shared.deepLinkURL.navigationPath != .none {
                        selection = UserProfileRepository.shared.deepLinkURL.navigationPath
                        UserProfileRepository.shared.deepLinkURL = .none
                    }
                }
                .onAppear() {
                    if UserProfileRepository.shared.deepLinkURL.navigationPath != .none {
                        selection = UserProfileRepository.shared.deepLinkURL.navigationPath
                        UserProfileRepository.shared.deepLinkURL = .none
                    }
                }
            }
        }
        .modifier(DoubleTapTabBarModifier(count: 2, perform: {
            // Handle the double-click action here
            // For example, you can reload the content of the active tab
            NotificationCenter.default.post(name: NSNotification.Name("ReloadActiveTab"), object: nil)
        }))
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ReloadActiveTab"))) { _ in
            if selection == .main {
                NotificationCenter.default.post(name: .SPORT_MAIN, object: nil)
            } else if selection == .promo {
                NotificationCenter.default.post(name: .SPORT_PROMO, object: nil)
            } else if selection == .deposite {
                NotificationCenter.default.post(name: .SPORT_DEPOSIT, object: nil)
            } else if selection == .menu {
                // Reload the content for the menu tab
                // ...
            }
        }
        .toolbar(.hidden)
        .accentColor(Color("login_text_red"))
    }
}

struct SportTabBarView_Previews: PreviewProvider {
    static var previews: some View {
        SportTabBarView()
    }
}
