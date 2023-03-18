import Foundation
import Combine

extension Publisher where Failure == Never {
    @available(*, deprecated, renamed: "assign(to:)")
    func assign<Root: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Output>, on root: Root) -> AnyCancellable {
        sink { [weak root] in
            root?[keyPath: keyPath] = $0
        }
    }
}
