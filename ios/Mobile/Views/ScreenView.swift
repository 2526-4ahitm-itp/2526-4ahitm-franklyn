//
//  ScreenView.swift
//  Mobile
//
//  Created by Zangenfeind Clemens on 19.03.26.
//

import SwiftUI

struct ScreenView: View {
    
    var body: some View {
        ScrollView {
            Grid(horizontalSpacing: 30, verticalSpacing: 30) {
                ForEach(0..<5) { row in
                    GridRow {
                        ForEach(0..<1) { column in
                            VStack {
                                Text("Screen \(row + column)")
                            }
                            .padding(EdgeInsets(top: 60, leading: 150, bottom: 60, trailing: 150))
                            .border(.black)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ScreenView()
}
