import KeyAppUI
import SwiftUI
import UIKit

struct TextButtonView: UIViewRepresentable {
    private let title: String
    private let style: TextButton.Style
    private let size: TextButton.Size
    private let leading: UIImage?
    private let trailing: UIImage?

    init(
        title: String,
        style: TextButton.Style,
        size: TextButton.Size,
        leading: UIImage? = nil,
        trailing: UIImage? = nil
    ) {
        self.title = title
        self.style = style
        self.size = size
        self.leading = leading
        self.trailing = trailing
    }

    func makeUIView(context _: Context) -> TextButton {
        TextButton(title: title, style: style, size: size, leading: leading, trailing: trailing)
    }

    func updateUIView(_: TextButton, context _: Context) {}
}
