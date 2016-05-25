//
//  AkaCalendarDayCell.swift
//  AkaCalendar
//
//  Created by Yoann Cribier on 13/05/2016.
//  Copyright © 2016 Yoann Cribier. All rights reserved.
//

import UIKit

// TODO: replace with constant struct
let cellColorDefault = UIColor(white: 0.0, alpha: 0.1)
let cellColorToday = UIColor(red: 254.0/255.0, green: 73.0/255.0, blue: 64.0/255.0, alpha: 0.3)
let cellBorderColor = UIColor(red: 254.0/255.0, green: 73.0/255.0, blue: 64.0/255.0, alpha: 0.8)

class AkaCalendarViewDayCell: UICollectionViewCell {

  override var selected: Bool {
    didSet {
      self.bgView.layer.borderWidth = selected ? 2.0 : 0.0
    }
  }

  var isToday: Bool = false {
    didSet {
      self.bgView.backgroundColor = isToday ? cellColorToday : cellColorDefault
    }
  }

  lazy var bgView: UIView = {
    var viewFrame = CGRectInset(self.bounds, 2.0, 2.0)
    let view = UIView(frame: viewFrame)
    view.layer.cornerRadius = 5.0
    view.layer.borderColor = cellBorderColor.CGColor
    view.layer.borderWidth = 0.0
    view.center = CGPoint(x: self.bounds.size.width * 0.5, y: self.bounds.size.height * 0.5)
    view.backgroundColor = cellColorDefault
    view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]

    return view
  }()

  lazy var textLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = NSTextAlignment.Center
    label.textColor = UIColor.whiteColor()
    label.autoresizingMask = [.FlexibleTopMargin, .FlexibleBottomMargin, .FlexibleLeftMargin, .FlexibleRightMargin]

    return label
  }()


  // MARK: - Init

  override init(frame: CGRect) {
    super.init(frame: frame)

    self.addSubview(self.bgView)

    self.textLabel.frame = self.bounds
    self.addSubview(self.textLabel)
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

}
