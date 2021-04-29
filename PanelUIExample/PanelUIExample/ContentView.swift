import PanelUI
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Text("Hello, world!")
                    .padding()
                Spacer()
            }
            Spacer()
        }
//        .overlay(AiolosWrapper {
//            Text("Hello, world!")
//                .padding()
//        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
