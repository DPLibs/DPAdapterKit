import Foundation
import UIKit
import DPLibrary

// MARK: - PageViewControllerAdapterInput
public protocol PageViewControllerAdapterInput: AnyObject {
    var pageViewController: UIPageViewController? { get set }
    var output: PageViewControllerAdapterOutput? { get set }
    var pages: [UIViewController] { get set }
    var swipeIsEnabled: Bool { get set }
    var currentPageIndex: Int { get }
    
    func createPageViewControllerAndAddToSuperview(_ superview: UIView?, parent: UIViewController?, transitionStyle: UIPageViewController.TransitionStyle, navigationOrientation: UIPageViewController.NavigationOrientation)
    func showCurrentPageIndex(_ currentPageIndex: Int)
    func showReversePage()
    func showForwardPage()
    func removePages(_ indices: [Int])
}

// MARK: - PageViewControllerAdapterOutput
public protocol PageViewControllerAdapterOutput: AnyObject {
    func didSelectCurrentPageIndex(_ adapter: PageViewControllerAdapter, currentPageIndex: Int)
    func didPages(_ adapter: PageViewControllerAdapter, pages: [UIViewController])
    func didLimitPageReached(_ adapter: PageViewControllerAdapter, for direction: UIPageViewController.NavigationDirection, fromSwipe: Bool)
}

public extension PageViewControllerAdapterOutput {
    func didSelectCurrentPageIndex(_ adapter: PageViewControllerAdapter, currentPageIndex: Int) {}
    func didPages(_ adapter: PageViewControllerAdapter, pages: [UIViewController]) {}
    func didLimitPageReached(_ adapter: PageViewControllerAdapter, for direction: UIPageViewController.NavigationDirection, fromSwipe: Bool) {}
}

// MARK: - PageViewControllerAdapter
open class PageViewControllerAdapter: NSObject, PageViewControllerAdapterInput, UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    // MARK: - Props
    public weak var pageViewController: UIPageViewController? {
        didSet {
            self.pageViewController?.delegate = self
        }
    }
    
    public weak var output: PageViewControllerAdapterOutput?
    
    public var pages: [UIViewController] = [] {
        didSet {
            self.output?.didPages(self, pages: self.pages)
            self.showCurrentPageIndex(self._currentPageIndex)
        }
    }
    
    public var swipeIsEnabled: Bool = true {
        didSet {
            self._swipeIsEnabledDidSet()
        }
    }
    
    public var currentPageIndex: Int {
        self._currentPageIndex
    }
    
    private var _currentPageIndex: Int = 0
    
    // MARK: - Public
    open func createPageViewControllerAndAddToSuperview(_ superview: UIView?, parent: UIViewController?, transitionStyle: UIPageViewController.TransitionStyle = .scroll, navigationOrientation: UIPageViewController.NavigationOrientation = .horizontal) {
        guard let superview = superview else { return }
        
        let pageViewController = UIPageViewController(transitionStyle: transitionStyle, navigationOrientation: navigationOrientation, options: nil)
        superview.addSubview(pageViewController.view)
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageViewController.view.topAnchor.constraint(equalTo: superview.topAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: superview.bottomAnchor),
            pageViewController.view.leadingAnchor.constraint(equalTo: superview.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: superview.trailingAnchor)
        ])
        parent?.addChild(pageViewController)
        
        self.pageViewController = pageViewController
        self._swipeIsEnabledDidSet()
        self.showCurrentPageIndex(self._currentPageIndex)
    }
    
    open func showCurrentPageIndex(_ currentPageIndex: Int) {
        guard self.pages.indices.contains(currentPageIndex) else { return }
        
        let controller = self.pages[currentPageIndex]
        let direction: UIPageViewController.NavigationDirection = currentPageIndex >= self._currentPageIndex ? .forward : .reverse
        self._currentPageIndex = currentPageIndex
        
        self.pageViewController?.setViewControllers([controller], direction: direction, animated: true, completion: { [weak self] completed in
            guard let self = self, completed else { return }
            self.output?.didSelectCurrentPageIndex(self, currentPageIndex: self._currentPageIndex)
        })
    }
    
    open func showReversePage() {
        let newCurrent = self._currentPageIndex - 1
        guard self.pages.indices.contains(newCurrent) else {
            self.output?.didLimitPageReached(self, for: .reverse, fromSwipe: false)
            return
        }
        self.showCurrentPageIndex(newCurrent)
    }

    open func showForwardPage() {
        let newCurrent = self._currentPageIndex + 1
        guard self.pages.indices.contains(newCurrent) else {
            self.output?.didLimitPageReached(self, for: .forward, fromSwipe: false)
            return
        }
        self.showCurrentPageIndex(newCurrent)
    }


    open func removePages(_ indices: [Int]) {
        self.pages.removeAll(at: indices)
        guard !self.pages.isEmpty else { return }
        if self.pages.indices.contains(self._currentPageIndex) {
            self.showCurrentPageIndex(self._currentPageIndex)
        }
        else {
            self.showCurrentPageIndex(self.pages.endIndex)
        }
    }
    
    // MARK: - UIPageViewControllerDelegate
    public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard let index = self.pages.firstIndex(where: { $0 == pageViewController.viewControllers?.first }) else { return }
        self._currentPageIndex = index
        self.output?.didSelectCurrentPageIndex(self, currentPageIndex: index)
    }
    
    // MARK: - UIPageViewControllerDataSource
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = self.pages.firstIndex(where: { $0 == viewController }), self.pages.indices.contains(index - 1) else {
            self.output?.didLimitPageReached(self, for: .reverse, fromSwipe: true)
            return nil
        }
        return self.pages[index - 1]
    }

    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = self.pages.firstIndex(where: { $0 == viewController }), self.pages.indices.contains(index + 1) else {
            self.output?.didLimitPageReached(self, for: .forward, fromSwipe: true)
            return nil
        }
        return self.pages[index + 1]
    }

    // MARK: - Private
    private func _swipeIsEnabledDidSet() {
        self.pageViewController?.dataSource = self.swipeIsEnabled ? self : nil
    }
}

