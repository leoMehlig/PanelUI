//
//  SwiftUIView.swift
//  
//
//  Created by Leonard Mehlig on 28.04.21.
//

import SwiftUI

public struct AiolosWrapper<Content: View>: UIViewControllerRepresentable {

    public typealias UIViewControllerType = AiolosController<Content>

    var content: Content

    public  init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public  func makeUIViewController(context: Context) -> UIViewControllerType {
        let controller = AiolosController<Content>()
        controller.content = content
        return controller
    }

    public  func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        uiViewController.content = content
    }

}

//struct AiolosWrapper_Previews: PreviewProvider {
//    static var previews: some View {
//        SwiftUIView()
//    }
//}
