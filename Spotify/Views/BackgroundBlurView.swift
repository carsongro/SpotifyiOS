//
//  BackgroundBlurView.swift
//  Spotify
//
//  Created by Carson Gross on 7/8/23.
//

import SwiftUI

struct BackgroundBlob: View {
    @State private var rotationAmount = 0.0
    let alignment: Alignment = [.topLeading, .topTrailing, .bottomLeading, .bottomTrailing].randomElement()!
    var color: Color = [.blue, Color(red: 0, green: 0, blue: 0.8)].randomElement()!
    
    var body: some View {
        Ellipse()
            .fill(color)
            .frame(width: .random(in: min(lowHeight, highHeight)...max(lowHeight, highHeight)), height: .random(in: min(lowHeight, highHeight)...max(lowHeight, highHeight)))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
            .offset(x: .random(in: -400...400), y: .random(in: -400...400))
            .rotationEffect(Angle(degrees: rotationAmount))
            .animation(.linear(duration: .random(in: 15...30)).repeatForever(), value: rotationAmount)
            .onAppear {
                rotationAmount = .random(in: -360...360)
            }
            .blur(radius: 75)
            .onAppear {
                Task {
                    await getWidth()
                }
            }
    }
    
    @State private var lowHeight: CGFloat = 200
    @State private var highHeight: CGFloat = 500
    
    private func getWidth() async {
        let width = await UIScreen.main.bounds.size.width
//        withAnimation(.edgeBounce(duration: 5)) {
            lowHeight = width * 0.5
            highHeight = width
//        }
    }
}

struct BackgroundBlurView: View {
    var body: some View {
        ZStack {
            ForEach(0..<15) { _ in
                BackgroundBlob()
            }
        }
        .background(.black)
    }
}

struct BackgroundBlurView_Previews: PreviewProvider {
    static var previews: some View {
        BackgroundBlurView()
    }
}
