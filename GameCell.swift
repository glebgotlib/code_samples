//
//  GameCell.swift
//  winpot-ios
//
//  Created by Gleb Goncharov on 08.02.2023.
//

import Foundation
import SwiftUI
import Kingfisher
import Shimmer

struct ShortGameCell: View{
    @EnvironmentObject var viewModel: MainViewModel
    var itemData: GamesShortList
    @StateObject var gameModel: CasinoGameViewModel
    @State var isFavorite = false
    @State var isPromo = true
    @State var gameIsLoaded = false
    
    var body: some View{
        VStack{
            ZStack{
                VStack{
                    HStack{
                        Image("Ribbon")
                            .resizable()
                            .frame(width: 36, height: 48)
                        Spacer()
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                    .isHidden(isPromo, remove: isPromo)
                }
                
                VStack{
                    if !gameModel.gameQueue.contains(where: { $0.oid == itemData.oid }){
                        if self.gameIsLoaded{
                            HStack{
                                Spacer()
                                Image("downloaded")
                            }
                            .frame(maxHeight: .infinity, alignment: .top)
                        }else{
                            HStack{
                                Spacer()
                                Image("download")
                            }
                            .frame(maxHeight: .infinity, alignment: .top)
                        }
                    }else if gameModel.gameQueue.contains(where: { $0.oid == itemData.oid }) {
                        HStack{
                            Spacer()
                            ProgressGaugeView(progressValue: gameModel.progressDict["\(itemData.oid)"] ?? 0.0)
                                .frame(width: 10, height: 10)
                                .frame(maxHeight: .infinity, alignment: .top)
                                .padding(.top, 5)
                                .padding(.trailing, 3)
                        }
                    }
                }   .padding(.trailing, 5)
                    .padding(.top, 7)
                    .hidden()
                
            }
            
            HStack{
                Spacer()
                Text(itemData.name).foregroundColor(.white)
                    .lineLimit(3)
                    .font(.custom("Montserrat-SemiBold", size: 10))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                
                Image(self.isFavorite ? "Favorite_selected" : "Favorite_not_selected")
                    .isHidden(!viewModel.isLogedIn, remove: false)
                    .frame(height: 30)
                    .onTapGesture {
                        if let index = GamesDataRepository.shared.favoritesList.firstIndex(of: itemData.id) {
                            GamesDataRepository.shared.favoritesList.remove(at: index)
                        } else {
                            GamesDataRepository.shared.favoritesList.insert(itemData.id, at: 0)
                        }
                        gameModel.favList = GamesDataRepository.shared.favoritesList
                        self.isFavorite = GamesDataRepository.shared.favoritesList.contains(where: { $0 == (itemData.id) })
                        let favorites = GamesDataRepository.shared.favoritesList
                        
                        if self.isFavorite{
                            for game in GamesDataRepository.shared.shortGamesList.indices {
                                let gameID = GamesDataRepository.shared.shortGamesList[game].id
                                if favorites.contains(where: { $0 == gameID }) && !(GamesDataRepository.shared.gamesCategories[.favorites]?.contains(GamesDataRepository.shared.shortGamesList[game]) ?? false) {
                                    let category: Categories = .favorites
                                    
                                    if var array = GamesDataRepository.shared.gamesCategories[category] {
                                        array.insert(GamesDataRepository.shared.shortGamesList[game], at: 0)
                                        GamesDataRepository.shared.gamesCategories[category] = array
                                    } else {
                                        GamesDataRepository.shared.gamesCategories[category] = [GamesDataRepository.shared.shortGamesList[game]]
                                    }
                                }
                            }
                        }else{
                            for i in GamesDataRepository.shared.shortGamesList.indices {
                                if let index = GamesDataRepository.shared.gamesCategories[.favorites]?.firstIndex(of: GamesDataRepository.shared.shortGamesList[i]) {
                                    if GamesDataRepository.shared.shortGamesList[i].id == itemData.id{
                                        if var array = GamesDataRepository.shared.gamesCategories[.favorites] {
                                            array.remove(at: index)
                                            GamesDataRepository.shared.gamesCategories[.favorites] = array
                                        }
                                    }
                                }
                            }
                        }
                    }
            }
            .padding(.top, -8)
        }
        
        .onAppear{
            Task{
                self.gameIsLoaded = await gameModel.checkIfGameResourcesLoaded(folderName: itemData.cacheFolder, game: itemData)
            }
            isPromo = true
            if GamesDataRepository.shared.promoList.contains(where: { $0 == ("\((itemData.id))") }){
                isPromo = false
            }
            self.isFavorite = GamesDataRepository.shared.favoritesList.contains(where: { $0 == ("\((itemData.id))") })
        }
        .onReceive(gameModel.$isLoadingGame){ _ in
            Task{
                self.gameIsLoaded = await gameModel.checkIfGameResourcesLoaded(folderName: itemData.cacheFolder, game: itemData)
            }
        }
        .onReceive(gameModel.$favList){ _ in
            self.isFavorite = GamesDataRepository.shared.favoritesList.contains(where: { $0 == ("\((itemData.id))") })
        }
    }
    
    func checkGameStatus(oid: Int) -> Bool {
        var gameLoaded = false
        Task {
            gameLoaded = await gameModel.checkIfGameResourcesLoaded(folderName: itemData.cacheFolder, game: itemData)
        }
        return gameLoaded
    }
}


struct ShortLiveGameCell: View{
    var itemData: GamesShortList
    @StateObject var gameModel: CasinoGameViewModel
    @State var isFavorite = false
    @State var isPromo = true
    @State var gameIsLoaded = false
    
    var body: some View{
        VStack{
            ZStack{
                VStack{
                    HStack{
                        Image("Ribbon")
                            .resizable()
                            .frame(width: 36, height: 48)
                        Spacer()
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                    .isHidden(isPromo, remove: isPromo)
                }
                
                VStack{
                    if !gameModel.isLoadingGame.contains("\(itemData.oid)") {
                        if self.gameIsLoaded{
                            HStack{
                                Spacer()
                                Image("downloaded")
                            }
                            .frame(maxHeight: .infinity, alignment: .top)
                        }else{
                            HStack{
                                Spacer()
                                Image("download")
                            }
                            .frame(maxHeight: .infinity, alignment: .top)
                        }
                    }else if gameModel.isLoadingGame.contains("\(itemData.oid)") {
                        HStack{
                            Spacer()
                            ProgressGaugeView(progressValue: gameModel.progressDict["\(itemData.oid)"] ?? 0.0)
                                .frame(width: 10, height: 10)
                                .frame(maxHeight: .infinity, alignment: .top)
                                .padding(.top, 5)
                                .padding(.trailing, 3)
                        }
                    }
                }   .padding(.trailing, 5)
                    .padding(.top, 7)
                    .hidden()
                
            }
            
            HStack{
                Spacer()
                Text(itemData.name).foregroundColor(.white)
                    .lineLimit(2)
                    .font(.custom("Montserrat-SemiBold", size: 13))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                
                Image(self.isFavorite ? "Favorite_selected" : "Favorite_not_selected")
                    .isHidden(true, remove: false)
                    .frame(height: 30)
            }
            .padding(.top, -8)
        }
        
        .onAppear{
            Task{
                self.gameIsLoaded = await gameModel.checkIfGameResourcesLoaded(folderName: itemData.cacheFolder,
                                                                               game: itemData)
            }
            isPromo = true
            if GamesDataRepository.shared.promoList.contains(where: { $0 == "\(itemData.id)" }){
                isPromo = false
            }
        }
        .onReceive(gameModel.$isLoadingGame){ _ in
            Task{
                self.gameIsLoaded = await gameModel.checkIfGameResourcesLoaded(folderName: itemData.cacheFolder,
                                                                               game: itemData)
            }
        }
    }
    
    func checkGameStatus(oid: Int) -> Bool {
        var gameLoaded = false
        
        Task {
            gameLoaded = await gameModel.checkIfGameResourcesLoaded(folderName: itemData.cacheFolder,
                                                                    game: itemData)
        }
        return gameLoaded
    }
}
