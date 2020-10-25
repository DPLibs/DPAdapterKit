import Foundation
import UIKit

// MARK: - SearchBarAdapterOutput
public protocol SearchBarAdapterOutput: AnyObject {
    func tapSearchButton(_ adapter: SearchBarAdapter, value: String?)
    func textDidChange(_ adapter: SearchBarAdapter, value: String?, isAfterDelay: Bool)
    func tapCancelButton(_ adapter: SearchBarAdapter)
    func textMaxLengthAchived(_ adapter: SearchBarAdapter, textMaxLength: Int, isAchived: Bool)
}

public extension SearchBarAdapterOutput {
    func tapSearchButton(_ adapter: SearchBarAdapter, value: String?) {}
    func textDidChange(_ adapter: SearchBarAdapter, value: String?, isAfterDelay: Bool) {}
    func tapCancelButton(_ adapter: SearchBarAdapter) {}
    func textMaxLengthAchived(_ adapter: SearchBarAdapter, textMaxLength: Int, isAchived: Bool) {}
}

// MARK: - SearchBarAdapterOutputUI
public protocol SearchBarAdapterOutputUI: AnyObject {
    func showsCancelButton(_ adapter: SearchBarAdapter, isShown: Bool)
    func endEditing(_ adapter: SearchBarAdapter)
}

public extension SearchBarAdapterOutputUI {
    func showsCancelButton(_ adapter: SearchBarAdapter, isShown: Bool) {}
    func endEditing(_ adapter: SearchBarAdapter) {}
}

// MARK: - SearchBarAdapter
open class SearchBarAdapter: NSObject, UISearchBarDelegate {
    
    // MARK: - Init
    public init(textMaxLength: Int?, withCancelBtn: Bool, delayTextDidChange: TimeInterval = 0.3) {
        self.textMaxLength = textMaxLength
        self.withCancelBtn = withCancelBtn
        self.delayTextDidChange = delayTextDidChange
        super.init()
    }
    
    // MARK: - Props
    public weak var searchBar: UISearchBar? {
        didSet {
            self.searchBar?.delegate = self
        }
    }
    
    public weak var output: SearchBarAdapterOutput?
    public weak var outputUI: SearchBarAdapterOutputUI?
    
    private let textMaxLength: Int?
    private let withCancelBtn: Bool
    private let delayTextDidChange: TimeInterval
    
    private var timer: Timer?
    
    // MARK: - Public methods
    open func provideTextDidChange(value: String?) {
        self.output?.textDidChange(self, value: value, isAfterDelay: false)
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(withTimeInterval: self.delayTextDidChange, repeats: false, block: { [weak self] timer in
            guard let self = self else { return }
            timer.invalidate()
            self.output?.textDidChange(self, value: value, isAfterDelay: true)
        })
    }
    
    // MARK: - Private methods
    private func _setShowsCancelButton(_ isShown: Bool) {
        self.searchBar?.setShowsCancelButton(isShown, animated: true)
        self.outputUI?.showsCancelButton(self, isShown: isShown)
    }
    
    private func _endEditing() {
        self.searchBar?.endEditing(true)
        self.outputUI?.endEditing(self)
    }
    
    // MARK: - UISearchBarDelegate
    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        guard self.withCancelBtn else { return }
        self._setShowsCancelButton(true)
    }
    
    public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self._setShowsCancelButton(false)
    }
    
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self._endEditing()
        self.output?.tapSearchButton(self, value: searchBar.text)
        self.provideTextDidChange(value: searchBar.text)
    }

    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.provideTextDidChange(value: searchBar.text)
    }

    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self._setShowsCancelButton(false)
        self._endEditing()
        self.output?.tapCancelButton(self)
    }
    
    public func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard let textMaxLength = self.textMaxLength  else { return true }
        let count: Int = (searchBar.text as NSString?)?.replacingCharacters(in: range, with: text).count ?? 0
        let maxCountNotAchived = count <= textMaxLength
        self.output?.textMaxLengthAchived(self, textMaxLength: textMaxLength, isAchived: !maxCountNotAchived)
        return maxCountNotAchived
    }
    
}
