//
//  SearchView.swift
//  winpot-ios
//
//  Created by Gleb Goncharov on 19.03.2023.
//

import SwiftUI
import UIKit

struct SearchView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @EnvironmentObject var casinoGameModel: CasinoGameViewModel
    @EnvironmentObject private var coordinator: Coordinator
    @State private var name: String = ""
    @State var searshResult: [Game] = []
    @State var noResult: [Game] = []
    @State private var vendors: [Vendor] = []
    @FocusState var isFocused: Bool
    @State private var game: Game? = nil
    
    @Binding var tab: Tab
    
    @State var gameIsLoaded = false
    @EnvironmentObject private var gameViewModel: CasinoGameViewModel
    @State private var selectedItems: Set<Int> = []
    
    let columns = [ GridItem(.fixed(UIScreen.screenWidth/3 - 20),
                             spacing: 20,
                             alignment: .leading),
                    GridItem(.fixed(UIScreen.screenWidth/3 - 20),
                             spacing: 20,
                             alignment: .center),
                    GridItem(.fixed(UIScreen.screenWidth/3 - 20),
                             spacing: 20,
                             alignment: .trailing)]
    
    var body: some View {
        NavigationView{
            VStack{
                HStack{
                    Image("arrow-left")
                        .padding(.leading, 20)
                        .padding(.top, 20)
                        .onTapGesture {
                            viewModel.categoryState = viewModel.categoryStateToHold
                            self.tab = .main
                        }
                        .frame(alignment: .center)
                    HStack{
                        Image("search_menu")
                            .padding(10)
                        Spacer()
                        TextField("", text: $name)
                            .placeholder(when: name.isEmpty, placeholder: {
                                Text("Buscar Juegos")
                                    .foregroundColor(.white)
                            })
                            .onChange(of: name){ _ in
                                print("NAME: \(name)")
                                DispatchQueue.global().async {
                                    let filteredGames = GamesDataRepository.shared.fuseGetShortSearchGames(text: name)
                                    
                                    DispatchQueue.main.async {
                                        searshResult = filteredGames
                                    }
                                }
                                
                            }
                            .focused($isFocused)
                            .foregroundColor(.white)
                            .padding(.trailing, 20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .tint(.white)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    self.isFocused = true
                                }
                            }
                    }.background(.clear)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(10) /// make the background rounded
                        .overlay( /// apply a rounded border
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(.white, lineWidth: 1)
                        )
                        .padding(.top, 20)
                        .padding(.leading, 10)
                        .padding(.trailing, 20)
                }
                VStack{
                    VStack{
                        if self.searshResult.isEmpty{
                            if name.count > 0{
                                Text("no_search_result")
                                    .foregroundColor(.white)
                                    .padding(.bottom, 30)
                                    .padding(.top, 30)
                            }else{             
                                Text("Recomendado para ti")
                                    .font(.custom("Montserrat-SemiBold", size: 14))
                                    .foregroundStyle(Color(.white))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 10)
                                ScrollView {
                                    LazyVGrid(columns: columns, spacing: 20) {
                                        ForEach(self.noResult) { item in
                                            NewGameCell(game: item, category: nil, vendors: vendors, state: .constant(.all), gameToStart: $game)
                                                .environmentObject(viewModel)
                                                .environmentObject(coordinator)
                                                .environmentObject(casinoGameModel)
                                                .frame(width: UIScreen.screenWidth/3 - 20, height: (UIScreen.screenWidth/3 - 20) / 1.1)
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.bottom, 80)
                                }
                                .simultaneousGesture(
                                    DragGesture().onChanged({
                                        let isScrollDown = 0 < $0.translation.height
                                        isFocused = false
                                    }))
                            }
                        }else{
                            ScrollView {
                                LazyVGrid(columns: columns, spacing: 20) {
                                    ForEach(self.searshResult) { item in
                                        NewGameCell(game: item, category: nil, vendors: vendors, state: .constant(.all), gameToStart: $game)
                                            .environmentObject(viewModel)
                                            .environmentObject(coordinator)
                                            .environmentObject(casinoGameModel)
                                            .frame(width: UIScreen.screenWidth/3 - 20, height: (UIScreen.screenWidth/3 - 20) / 1.1)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .simultaneousGesture(
                                DragGesture().onChanged({
                                    let isScrollDown = 0 < $0.translation.height
                                    isFocused = false
                                }))
                        }
                    }
                }.padding(.top, 20)
                Spacer()
            }.background(Color("main_bg"))
                .navigationBarTitle(Text(""), displayMode: .inline)
                .toolbarBackground(Color("main_bg"), for: .navigationBar)
                .alert("El juego no está disponible.", isPresented: $viewModel.isErrorPresented, actions: {
                    Button("OK") {
                        viewModel.isErrorPresented.toggle()
                    }
                })
        }.onAppear{
            print(name)
            searshResult = GamesDataRepository.shared.fuseGetShortSearchGames(text: name)

            noResult = viewModel.findPopularGames()
            vendors = viewModel.fetchVendors()
        }.navigationBarHidden(true)
            .onDisappear{
                isFocused = false
            }
            .onLoad{
                print("weewwewe")
            }           
            .fullScreenCover(item: $game, content: { game in
                ConfirmationView(completion: { getGameData(oid: game.oid ?? "") }, game: $game)
                    .environmentObject(coordinator)
                    .environmentObject(viewModel)
            })
    }
    func getGameData(oid: String) {
        game = nil
        self.hideKeyboard()
        if !casinoGameModel.isGettingUrl{
            casinoGameModel.isGettingUrl = true
            viewModel.loadingStart = true
            let deadline = DispatchTime.now() + .microseconds(3)
            DispatchQueue.main.asyncAfter(deadline: deadline){
                if viewModel.isLogedIn{
                    viewModel.getShortGameUrl(oid: oid){ res in
                        if !res.isEmpty{
                            GamesDataRepository.shared.components = res
                            
                            if !coordinator.contains(Page.playShortGame){
                                coordinator.push(Page.playShortGame)
//                                viewModel.loadingStart = false
                            }
                        } else {
                            viewModel.loadingStart = false
                        }
                    }
                }else{
                    viewModel.loadingStart = false
                    casinoGameModel.isGettingUrl = false
                    coordinator.push(.registration)
                }
            }
        }
    }
    
    func startGameLoading() {
        guard let game = casinoGameModel.gameQueue.first else {
            return
        }
        
        Task {
            if await casinoGameModel.checkIfGameResourcesLoaded(folderName: game.cacheFolder, game: game) {
                selectedItems.removeAll()
                casinoGameModel.gameQueue.removeFirst() // Удаляем загруженную игру из очереди
                startGameLoading() // Запускаем загрузку следующей игры из очереди (если она есть)
            } else {
                if !casinoGameModel.isLoadingGame.contains("\(game.oid)") {
                    casinoGameModel.loadResourcesWith(game) { res in
                        if res {
                            casinoGameModel.gameQueue.removeFirst() // Удаляем загруженную игру из очереди
                            startGameLoading() // Запускаем загрузку следующей игры из очереди (если она есть)
                        }
                    }
                }
            }
        }
    }
    
    func getGameData(oid: String, item: GamesShortList){
        self.hideKeyboard()
        if !gameViewModel.isGettingUrl{
            gameViewModel.isGettingUrl = true
            viewModel.loadingStart = true
            let deadline = DispatchTime.now() + .microseconds(3)
            DispatchQueue.main.asyncAfter(deadline: deadline){
                if viewModel.isLogedIn{
                    viewModel.getShortGameUrl(oid: oid){ res in
                        if !res.isEmpty{
                            GamesDataRepository.shared.components = res
                            GamesDataRepository.shared.shortGameParams = item
                            viewModel.loadingStart = true
                            if !coordinator.contains(Page.playShortGame){
                                coordinator.push(Page.playShortGame)
                            }
                        } else {
                            viewModel.loadingStart = false
                        }
                    }
                }else{
                    viewModel.loadingStart = false
                    gameViewModel.isGettingUrl = false
                    coordinator.push(.registration)
                }
            }
        }
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
