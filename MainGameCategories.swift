//
//  GameCategories.swift
//  winpot-ios
//
//  Created by Gleb Goncharov on 08.02.2023.
//

import Foundation
import SwiftUI

struct CategoriesList: Hashable, Identifiable{
    let id: UUID
    let name: String
    let catId: String
}

struct GameCategories: View{
    @StateObject var viewModel: MainViewModel

    var body: some View {
        let callBack = { (data: CategoryData)  in
            viewModel.currentSelected = data
            GamesDataRepository.shared.selectedCategory = data.id
        }
        
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                IfLet(GamesDataRepository.shared.categoryData){ i in
                    ForEach(i) { t in
                        CategoryCell(viewModel: viewModel, item: t,
                                     callback: callBack,
                                     selected: viewModel.containsElement(selectedId: t.id,
                                                                         checkId: viewModel.currentSelected?.id))

                    }
                }
            }.padding(.leading, 10)
                .padding(.trailing, 20)
        }
        .onLoad{
            viewModel.currentSelected = GamesDataRepository.shared.categoryData[1]
        }
    }
}
