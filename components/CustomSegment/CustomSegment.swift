//  License under the MIT License
//  Copyright (c) 2019 Hans Fehrmann

import UIKit

protocol CustomSegmentDelegate: class {
    func customSegmentShouldSelect(_ customSegment: CustomSegment, index: Int) -> Bool
}

class CustomSegment: UIView {

    private var currentIndex: Int
    private var numberOfSelectors: Int!

    private var labels: [UILabel] = []
    private var selectorView: UIView!
    private var leadingSelectorViewConstraint: NSLayoutConstraint!
    private var thickSelectorViewConstraint: NSLayoutConstraint!

    // MARK: - Public accesors

    weak var delegate: CustomSegmentDelegate?
    var selectedIndex: Int { return currentIndex }

    var textFont: UIFont? = .systemFont(ofSize: 14, weight: .regular) {
        didSet {
            setupTextFonts()
            layoutIfNeeded()
        }
    }

    var selectedTextFont: UIFont? = .systemFont(ofSize: 14, weight: .medium) {
        didSet {
            setupSelectedTextFont()
            layoutIfNeeded()
        }
    }

    @IBInspectable var textColor: UIColor? = .gray { didSet { setupTextColor() } }
    @IBInspectable var selectedTextColor: UIColor? = .black { didSet { setupSelectedTextColor() } }
    @IBInspectable var selectedColor: UIColor? = .red { didSet { setupSelectedColor() } }

    @IBInspectable var selectedThick: CGFloat = 2.0

    // MARK: - Inits

    private func guardCondition(desiredTitles: [String], desiredSelectedIndex: Int) {
        guard !desiredTitles.isEmpty else { fatalError("Segment cannot be used without titles") }
        guard desiredSelectedIndex < desiredTitles.count else {
            fatalError("Index should not be bigger than titles length")
        }
    }

    init(frame: CGRect = .zero, titles: [String], selectedIndex: Int = 0) {
        currentIndex = selectedIndex
        super.init(frame: frame)
        guardCondition(desiredTitles: titles, desiredSelectedIndex: selectedIndex)
        commonInit(titles: titles)
    }

    required init?(coder aDecoder: NSCoder) {
        currentIndex = 0
        super.init(coder: aDecoder)
        commonInit(titles: ["Default 1", "Default 2"])
    }

    // MARK: - Setup

    private func commonInit(titles: [String]) {
        setupContent(titles: titles)
        setupUI()
        setupListeners()
    }

    // MARK:  Content

    private func setupContent(titles: [String]) {
        numberOfSelectors = titles.count
        let zipped = zip(titles, titles.map { _ in UILabel() })
        labels = zipped.map { arg in
            let (title, label) = arg
            label.text = title
            label.textAlignment = .center
            label.isUserInteractionEnabled = true
            return label
        }
        let stack = UIStackView(arrangedSubviews: labels)
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        stack.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        stack.topAnchor.constraint(equalTo: topAnchor).isActive = true
        stack.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

        selectorView = UIView()
        addSubview(selectorView)
        selectorView.translatesAutoresizingMaskIntoConstraints = false
        selectorView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        let widthConstaint = selectorView.widthAnchor.constraint(
            equalTo: stack.widthAnchor,
            multiplier: CGFloat(1) / CGFloat(numberOfSelectors)
        )
        widthConstaint.isActive = true

        leadingSelectorViewConstraint = selectorView.leadingAnchor.constraint(
            equalTo: leadingAnchor
        )
        thickSelectorViewConstraint = selectorView.heightAnchor.constraint(equalToConstant: 0)
        leadingSelectorViewConstraint.isActive = true
        thickSelectorViewConstraint.isActive = true
        updateLeadingSelectorConstraint()
        updateThickSelectorConstraint()
    }

    private func updateLeadingSelectorConstraint() {
        let constant = CGFloat(currentIndex) * bounds.width / CGFloat(numberOfSelectors)
        leadingSelectorViewConstraint.constant = constant
        setNeedsLayout()
    }

    private func updateThickSelectorConstraint() {
        thickSelectorViewConstraint.constant = selectedThick
        setNeedsLayout()
    }

    // MARK: UI

    private func setupUI() {
        setupTextColor()
        setupSelectedTextColor()
        setupSelectedColor()
        setupBackground()
        setupTextFonts()
        setupSelectedTextFont()
    }

    private func setupTextColor() {
        labels[0..<currentIndex].forEach { $0.textColor = textColor }
        labels[(currentIndex + 1)...].forEach { $0.textColor = textColor }
    }

    private func setupSelectedTextColor() {
        labels[currentIndex].textColor = selectedTextColor
    }

    private func setupSelectedColor() {
        selectorView.backgroundColor = selectedColor
    }

    private func setupBackground() {
        labels.forEach { $0.backgroundColor = backgroundColor }
    }

    private func setupTextFonts() {
        labels[0..<currentIndex].forEach { $0.font = textFont }
        labels[(currentIndex + 1)...].forEach { $0.font = textFont }
    }

    private func setupSelectedTextFont() {
        labels[currentIndex].font = selectedTextFont
    }

    // MARK: Listeners

    private func setupListeners() {
        for label in labels {
            let tap = UITapGestureRecognizer(target: self, action: #selector(segmentTap))
            label.addGestureRecognizer(tap)
        }
    }

    @objc private func segmentTap(_ sender: UIGestureRecognizer) {
        if let label = sender.view as? UILabel, let index = labels.index(of: label) {
            guard index != currentIndex else { return }
            if delegate?.customSegmentShouldSelect(self, index: index) ?? true {
                select(index: index, animated: true)
            }
        }
    }

    // MARK: - Public Methods

    func set(titles: [String], selectedIndex: Int) {
        guardCondition(desiredTitles: titles, desiredSelectedIndex: selectedIndex)
        subviews.forEach { $0.removeFromSuperview() }
        setupContent(titles: titles)
        setupUI()
        setupListeners()
        select(index: selectedIndex, animated: false)
    }

    func select(index: Int, animated: Bool) {
        guard index != currentIndex else { return }

        let animationDuration: TimeInterval = animated ? 0.15 : 0
        currentIndex = index
        UIView.animate(withDuration: animationDuration) { [unowned self] in
            self.setupUI()
            self.updateLeadingSelectorConstraint()
            self.layoutIfNeeded()
        }
    }
}