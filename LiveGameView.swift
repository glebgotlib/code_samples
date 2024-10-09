//
//  LiveGameView.swift
//  winpot-ios
//
//  Created by Gleb Goncharov on 23.02.2023.
//

import SwiftUI

struct LiveGameView: View{
    @State var coordinator: Coordinator
    @State var viewModel: MainViewModel
    var gamesList: [GamesModelResult] = []
    let columns = [ GridItem(.fixed(UIScreen.screenWidth/2 - 10),
                             spacing: 5,
                             alignment: .leading),
                    GridItem(.fixed(UIScreen.screenWidth/2 - 10),
                             spacing: 5,
                             alignment: .trailing)]
    
    var body: some View{
        VStack{
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(gamesList) { item in
                        IfLet(gamesList.firstIndex(of: item)){ _ in
                            LiveGameCell(itemData: item, viewModel: viewModel)
                                .gridCellColumns(1)
                                .frame(width: UIScreen.screenWidth/2 - 20)
                                .onTapGesture{
                                    if viewModel.isLogedIn{
                                        if let oid = item.oid{
                                            self.getGameData(oid: oid)
                                        }
                                    }else{
                                        coordinator.push(.registration)
                                    }
                                }
                        }
                    }
                }
            }
        }
    }
    
    func getGameData(oid: String){
        viewModel.getGameUrl(oid: oid){ res in
            if res{
                coordinator.push(.playGame)
            }
        }
    }
}
