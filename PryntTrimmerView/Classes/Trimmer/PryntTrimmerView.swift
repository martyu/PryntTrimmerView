//
//  PryntTrimmerView.swift
//  PryntTrimmerView
//
//  Created by HHK on 27/03/2017.
//  Copyright © 2017 Prynt. All rights reserved.
//

import AVFoundation
import UIKit

public protocol TrimmerViewDelegate: class {
    func didChangePositionBar(_ playerTime: CMTime)
    func positionBarStoppedMoving(_ playerTime: CMTime)
}

/// A view to select a specific time range of a video. It consists of an asset preview with thumbnails inside a scroll view, two
/// handles on the side to select the beginning and the end of the range, and a position bar to synchronize the control with a
/// video preview, typically with an `AVPlayer`.
/// Load the video by setting the `asset` property. Access the `startTime` and `endTime` of the view to get the selected time
// range
@IBDesignable public class TrimmerView: AVAssetTimeSelector {

    // MARK: - Properties

    // MARK: Color Customization

    /// The color of the main border of the view
    @IBInspectable public var mainColor: UIColor = UIColor.orange {
        didSet {
            updateMainColor()
        }
    }

    /// The color of the handles on the side of the view
    @IBInspectable public var handleColor: UIColor = UIColor.gray {
        didSet {
           updateHandleColor()
        }
    }

    /// The color of the position indicator
    @IBInspectable public var positionBarColor: UIColor = UIColor.white {
        didSet {
            positionBar.backgroundColor = positionBarColor
        }
    }

    // MARK: Interface

    public weak var delegate: TrimmerViewDelegate?

    // MARK: Subviews

    private let trimView = UIView()
	private lazy var leftHandleView: HandlerView? = HandlerView()
	private lazy var rightHandleView: HandlerView? = HandlerView()
    private let positionBar = UIView()
    private let leftHandleKnob = UIView()
    private let rightHandleKnob = UIView()
    private let leftMaskView = UIView()
    private let rightMaskView = UIView()

    // MARK: Constraints

    private var currentLeftConstraint: CGFloat = 0
    private var currentRightConstraint: CGFloat = 0
    private var leftConstraint: NSLayoutConstraint?
    private var rightConstraint: NSLayoutConstraint?
    private var positionConstraint: NSLayoutConstraint?

	private var handleWidth: CGFloat {
		return leftHandleView != nil ? 15 : 0
	}

    /// The maximum duration allowed for the trimming. Change it before setting the asset, as the asset preview
    public var maxDuration: Double = Double.greatestFiniteMagnitude {
        didSet {
            assetPreview.maxDuration = maxDuration
        }
    }

    /// The minimum duration allowed for the trimming. The handles won't pan further if the minimum duration is attained.
    public var minDuration: Double = 3

    // MARK: - View & constraints configurations
	
	public func hideHandles() {
		leftHandleView?.removeFromSuperview()
		rightHandleView?.removeFromSuperview()
		leftHandleView = nil
		rightHandleView = nil
		updatePositionBarLeftConstraint()
		mainColor = .clear
		assetPreview.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
		assetPreview.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
		for constraint in assetContraints {
			constraint.isActive = false
		}
		leftMaskView.removeFromSuperview()
		rightMaskView.removeFromSuperview()
	}
	
    override func setupSubviews() {

        super.setupSubviews()
        backgroundColor = UIColor.clear
        layer.zPosition = 1
        setupTrimmerView()
        setupHandleView()
        setupMaskView()
        setupPositionBar()
        setupGestures()
        updateMainColor()
        updateHandleColor()
    }
	
	private var assetContraints = [NSLayoutConstraint]()

    override func constrainAssetPreview() {
		assetContraints.append(assetPreview.leftAnchor.constraint(equalTo: leftAnchor, constant: handleWidth))
		assetContraints.append(assetPreview.rightAnchor.constraint(equalTo: rightAnchor, constant: -handleWidth))
		for constraint in assetContraints {
			constraint.isActive = true
		}
        assetPreview.topAnchor.constraint(equalTo: topAnchor).isActive = true
        assetPreview.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }

    private func setupTrimmerView() {

        trimView.layer.borderWidth = 2.0
        trimView.layer.cornerRadius = 2.0
        trimView.translatesAutoresizingMaskIntoConstraints = false
        trimView.isUserInteractionEnabled = false
        addSubview(trimView)

        trimView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        trimView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        leftConstraint = trimView.leftAnchor.constraint(equalTo: leftAnchor)
        rightConstraint = trimView.rightAnchor.constraint(equalTo: rightAnchor)
        leftConstraint?.isActive = true
        rightConstraint?.isActive = true
    }

    private func setupHandleView() {
		
		guard
			let leftHandleView = self.leftHandleView,
			let rightHandleView = self.rightHandleView
		else {
			NSLog("ERROR::: trimmer view leftHandleView or rightHandleView nil")
			return
		}

        leftHandleView.isUserInteractionEnabled = true
        leftHandleView.layer.cornerRadius = 2.0
        leftHandleView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(leftHandleView)

        leftHandleView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        leftHandleView.widthAnchor.constraint(equalToConstant: handleWidth).isActive = true
        leftHandleView.leftAnchor.constraint(equalTo: trimView.leftAnchor).isActive = true
        leftHandleView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

        leftHandleKnob.translatesAutoresizingMaskIntoConstraints = false
        leftHandleView.addSubview(leftHandleKnob)

        leftHandleKnob.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.5).isActive = true
        leftHandleKnob.widthAnchor.constraint(equalToConstant: 2).isActive = true
        leftHandleKnob.centerYAnchor.constraint(equalTo: leftHandleView.centerYAnchor).isActive = true
        leftHandleKnob.centerXAnchor.constraint(equalTo: leftHandleView.centerXAnchor).isActive = true

        rightHandleView.isUserInteractionEnabled = true
        rightHandleView.layer.cornerRadius = 2.0
        rightHandleView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rightHandleView)

        rightHandleView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        rightHandleView.widthAnchor.constraint(equalToConstant: handleWidth).isActive = true
        rightHandleView.rightAnchor.constraint(equalTo: trimView.rightAnchor).isActive = true
        rightHandleView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

        rightHandleKnob.translatesAutoresizingMaskIntoConstraints = false
        rightHandleView.addSubview(rightHandleKnob)

        rightHandleKnob.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.5).isActive = true
        rightHandleKnob.widthAnchor.constraint(equalToConstant: 2).isActive = true
        rightHandleKnob.centerYAnchor.constraint(equalTo: rightHandleView.centerYAnchor).isActive = true
        rightHandleKnob.centerXAnchor.constraint(equalTo: rightHandleView.centerXAnchor).isActive = true
    }

    private func setupMaskView() {
		
		guard
			let leftHandleView = self.leftHandleView,
			let rightHandleView = self.rightHandleView
		else {
			return
		}

        leftMaskView.isUserInteractionEnabled = false
        leftMaskView.backgroundColor = .black
        leftMaskView.alpha = 0.7
        leftMaskView.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(leftMaskView, belowSubview: leftHandleView)

        leftMaskView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        leftMaskView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        leftMaskView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        leftMaskView.rightAnchor.constraint(equalTo: leftHandleView.centerXAnchor).isActive = true

        rightMaskView.isUserInteractionEnabled = false
        rightMaskView.backgroundColor = .black
        rightMaskView.alpha = 0.7
        rightMaskView.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(rightMaskView, belowSubview: rightHandleView)

        rightMaskView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        rightMaskView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        rightMaskView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        rightMaskView.leftAnchor.constraint(equalTo: rightHandleView.centerXAnchor).isActive = true
    }

    private func setupPositionBar() {

        positionBar.frame = CGRect(x: 0, y: 0, width: 3, height: frame.height)
        positionBar.backgroundColor = positionBarColor
		positionBar.center = CGPoint(x: leftmostScrollablePoint, y: center.y)
        positionBar.layer.cornerRadius = 1
        positionBar.translatesAutoresizingMaskIntoConstraints = false
        positionBar.isUserInteractionEnabled = false
        addSubview(positionBar)

        positionBar.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        positionBar.widthAnchor.constraint(equalToConstant: 3).isActive = true
        positionBar.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
		updatePositionBarLeftConstraint()
        positionConstraint?.isActive = true
    }
	
	private func updatePositionBarLeftConstraint() {
		if let oldPositionConstraint = positionConstraint {
			positionBar.removeConstraint(oldPositionConstraint)
		}
		positionConstraint = positionBar.leftAnchor.constraint(equalTo: leftHandleView?.rightAnchor ?? assetPreview.leftAnchor, constant: 0)
		positionConstraint?.isActive = true
	}

    private func setupGestures() {
		let seekPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(TrimmerView.handleSeekPanGesture))
		addGestureRecognizer(seekPanGestureRecognizer)		
        let leftPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(TrimmerView.handlePanGesture))
        leftHandleView?.addGestureRecognizer(leftPanGestureRecognizer)
        let rightPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(TrimmerView.handlePanGesture))
        rightHandleView?.addGestureRecognizer(rightPanGestureRecognizer)
    }
	
	@objc func handleSeekPanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
		if let newTime = getTime(from: gestureRecognizer.location(in: gestureRecognizer.view).x - (leftHandleView?.frame.width ?? 0)) {
			seek(to: newTime)
			updateSelectedTime(stoppedMoving: false)
		}
	}

    private func updateMainColor() {
        trimView.layer.borderColor = mainColor.cgColor
        leftHandleView?.backgroundColor = mainColor
        rightHandleView?.backgroundColor = mainColor
    }

    private func updateHandleColor() {
        leftHandleKnob.backgroundColor = .white
        rightHandleKnob.backgroundColor = .white
    }

    // MARK: - Trim Gestures

    @objc func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard
			let view = gestureRecognizer.view,
			let superView = gestureRecognizer.view?.superview
		else { return }
        let isLeftGesture = view == leftHandleView
        switch gestureRecognizer.state {

        case .began:
            if isLeftGesture {
                currentLeftConstraint = leftConstraint!.constant
            } else {
                currentRightConstraint = rightConstraint!.constant
            }
            updateSelectedTime(stoppedMoving: false)
        case .changed:
            let translation = gestureRecognizer.translation(in: superView)
            if isLeftGesture {
                updateLeftConstraint(with: translation)
            } else {
                updateRightConstraint(with: translation)
            }
            layoutIfNeeded()
            if let startTime = startTime, isLeftGesture {
                seek(to: startTime)
            } else if let endTime = endTime {
                seek(to: endTime)
            }
            updateSelectedTime(stoppedMoving: false)

        case .cancelled, .ended, .failed:
            updateSelectedTime(stoppedMoving: true)
        default: break
        }
    }

    private func updateLeftConstraint(with translation: CGPoint) {
        let maxConstraint = max(rightmostScrollablePoint - handleWidth - minimumDistanceBetweenHandle, 0)
        let newConstraint = min(max(0, currentLeftConstraint + translation.x), maxConstraint)
        leftConstraint?.constant = newConstraint
    }
	
	private func updateRightConstraint(with translation: CGPoint) {
		let maxConstraint = min(2 * handleWidth - frame.width + leftmostScrollablePoint + minimumDistanceBetweenHandle, 0)
		let newConstraint = max(min(0, currentRightConstraint + translation.x), maxConstraint)
		rightConstraint?.constant = newConstraint
	}
	
	private var leftmostScrollablePoint: CGFloat {
		return leftHandleView?.frame.maxX ?? assetPreview.frame.minX
	}
	
	private var rightmostScrollablePoint: CGFloat {
		return rightHandleView?.frame.minX ?? assetPreview.frame.maxX
	}
	
	public func setStartTime(_ time: CMTime) {
		setNeedsLayout()
		layoutIfNeeded()
		guard let constant = getPosition(from: time) else { return }
		leftConstraint?.constant = constant
		layoutIfNeeded()
	}
	
	public var positionBarIsAtOrPastEnd: Bool {
		return (rightmostScrollablePoint - positionBar.frame.maxX) < positionBar.frame.width ||
			(positionBar.frame.maxX > rightmostScrollablePoint)
	}

    // MARK: - Asset loading

    override func assetDidChange(newAsset: AVAsset?) {
        super.assetDidChange(newAsset: newAsset)
        resetHandleViewPosition()
    }

    private func resetHandleViewPosition() {
        leftConstraint?.constant = 0
        rightConstraint?.constant = 0
        layoutIfNeeded()
    }

    // MARK: - Time Equivalence

    /// Move the position bar to the given time.
    public func seek(to time: CMTime) {
        if let newPosition = getPosition(from: time) {

			let offsetPosition = newPosition - assetPreview.contentOffset.x - (leftHandleView?.frame.origin.x ?? assetPreview.frame.minX)
            let maxPosition = rightHandleView?.frame.origin.x ?? assetPreview.frame.maxX - (leftHandleView?.frame.origin.x ?? assetPreview.frame.minX + handleWidth)
                              - positionBar.frame.width
            let normalizedPosition = min(max(0, offsetPosition), maxPosition)
            positionConstraint?.constant = normalizedPosition
            layoutIfNeeded()
        }
    }

    /// The selected start time for the current asset.
    public var startTime: CMTime? {
		let startPosition = (leftHandleView?.frame.origin.x ?? assetPreview.frame.minX) + assetPreview.contentOffset.x
        return getTime(from: startPosition)
    }

    /// The selected end time for the current asset.
    public var endTime: CMTime? {
        let endPosition = rightmostScrollablePoint + assetPreview.contentOffset.x - handleWidth
        return getTime(from: endPosition)
    }

    private func updateSelectedTime(stoppedMoving: Bool) {
        guard let playerTime = positionBarTime else {
            return
        }
        if stoppedMoving {
            delegate?.positionBarStoppedMoving(playerTime)
        } else {
            delegate?.didChangePositionBar(playerTime)
        }
    }

    private var positionBarTime: CMTime? {
        let barPosition = positionBar.frame.origin.x + assetPreview.contentOffset.x - handleWidth
        return getTime(from: barPosition)
    }

    private var minimumDistanceBetweenHandle: CGFloat {
        guard let asset = asset else { return 0 }
        return CGFloat(minDuration) * assetPreview.contentView.frame.width / CGFloat(asset.duration.seconds)
    }

    // MARK: - Scroll View Delegate

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateSelectedTime(stoppedMoving: true)
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            updateSelectedTime(stoppedMoving: true)
        }
    }
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateSelectedTime(stoppedMoving: false)
    }
}
