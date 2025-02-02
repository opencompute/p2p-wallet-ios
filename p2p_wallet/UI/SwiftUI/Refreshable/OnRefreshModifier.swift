//
//  RefreshModifier.swift
//  SwiftUI_Pull_to_Refresh
//
//  Created by Geri Borbás on 14/03/2022.
//

import Introspect
import SwiftUI

extension UIScrollView {
    enum Keys {
        static var onValueChanged: UInt8 = 0
    }

    public typealias ValueChangedAction = (_ refreshControl: UIRefreshControl) -> Void

    var onValueChanged: ValueChangedAction? {
        get {
            objc_getAssociatedObject(self, &Keys.onValueChanged) as? ValueChangedAction
        }
        set {
            objc_setAssociatedObject(self, &Keys.onValueChanged, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    public func onRefresh(_ onValueChanged: @escaping ValueChangedAction) {
        if refreshControl == nil {
            let refreshControl = UIRefreshControl()
            refreshControl.addTarget(
                self,
                action: #selector(onValueChangedAction),
                for: .valueChanged
            )
            self.refreshControl = refreshControl
        }
        self.onValueChanged = onValueChanged
    }

    @objc func onValueChangedAction(sender: UIRefreshControl) {
        onValueChanged?(sender)
        refreshControl?.endRefreshing()
    }
}

struct OnListRefreshModifier: ViewModifier {
    let onValueChanged: UIScrollView.ValueChangedAction

    func body(content: Content) -> some View {
        content.introspectScrollView { scrollView in
            scrollView.onRefresh(onValueChanged)
        }
    }
}

public extension View {
    func onRefresh(onValueChanged: @escaping UIScrollView.ValueChangedAction) -> some View {
        modifier(OnListRefreshModifier(onValueChanged: onValueChanged))
    }
}
