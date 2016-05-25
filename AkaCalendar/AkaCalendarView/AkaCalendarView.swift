//
//  AkaCalendarView.swift
//  AkaCalendar
//
//  Created by Yoann Cribier on 12/05/2016.
//  Copyright © 2016 Yoann Cribier. All rights reserved.
//

import Foundation
import UIKit

let cellReuseIdentifier = "CalendarDayCell"

let NUMBER_OF_DAYS_IN_WEEK = 7
let MAXIMUM_NUMBER_OF_ROWS = 6

let FIRST_DAY_INDEX = 0
let NUMBER_OF_DAYS_INDEX = 1
let DATE_SELECTED_INDEX = 2


@objc public protocol AkaCalendarViewDataSource {

  func startDate() -> NSDate
  func endDate() -> NSDate

}

@objc public protocol AkaCalendarViewDelegate {

  optional func calendarView(calendarView: AkaCalendarView, didScrollToMonth date: NSDate) -> Void
  optional func calendarView(calendarView: AkaCalendarView, canSelectDate data: NSDate) -> Bool
  optional func calendarView(calendarView: AkaCalendarView, didSelectDate date: NSDate) -> Void
  optional func calendarView(calendarView: AkaCalendarView, didDeselectDate date: NSDate) -> Void

}

public class AkaCalendarView: UIView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

  public var dataSource: AkaCalendarViewDataSource?
  public var delegate: AkaCalendarViewDelegate?

  private var startDateCache: NSDate = NSDate()
  private var endDateCache: NSDate = NSDate()
  private var startOfMonthCache: NSDate = NSDate()
  private var todayIndexPath: NSIndexPath?

  public var displayDate: NSDate?

  private(set) var selectedIndexPaths: [NSIndexPath] = [NSIndexPath]()
  private(set) var selectedDates: [NSDate] = [NSDate]()

  lazy private var gregorianCalendar: NSCalendar = {
    let calendar = NSCalendar(identifier: NSCalendarIdentifierGregorian)!
    calendar.timeZone = NSTimeZone(abbreviation: "UTC")!

    return calendar
  }()

  public var calendar: NSCalendar {
    return self.gregorianCalendar
  }

  public var direction: UICollectionViewScrollDirection = .Horizontal {
    didSet {
      if let layout = self.daysCollectionView.collectionViewLayout as? AkaCalendarViewFlowLayout {
        layout.scrollDirection = direction
        self.reloadData()
      }
    }
  }

  lazy private var headerView: AkaCalendarViewHeaderView = {
    return AkaCalendarViewHeaderView(frame: CGRectZero)
  }()

  lazy public var daysCollectionView: UICollectionView = {
    let layout = AkaCalendarViewFlowLayout()
    layout.scrollDirection = self.direction;
    layout.minimumInteritemSpacing = 0
    layout.minimumLineSpacing = 0

    let cv = UICollectionView(frame: CGRectZero, collectionViewLayout: layout)
    cv.dataSource = self
    cv.delegate = self
    cv.pagingEnabled = true
    cv.backgroundColor = UIColor.clearColor()
    cv.showsHorizontalScrollIndicator = false
    cv.showsVerticalScrollIndicator = false
    cv.allowsMultipleSelection = true

    return cv
  }()


  // MARK: - Init

  override public init(frame: CGRect) {
    super.init(frame: frame)

    initialSetup()
  }

  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  override public func awakeFromNib() {
    super.awakeFromNib()

    initialSetup()
  }


  // MARK: - Setup

  private func initialSetup() {
    self.clipsToBounds = true

    self.daysCollectionView.registerClass(AkaCalendarViewDayCell.self, forCellWithReuseIdentifier: cellReuseIdentifier)

    self.addSubview(self.headerView)

    self.addSubview(self.daysCollectionView)
  }

  override public func layoutSubviews() {
    super.layoutSubviews()

//    print("layoutSubviews bounds: \(bounds)")

    let h = bounds.size.height
    let w = bounds.size.width

    let headerViewHeight = h / 7.0
    self.headerView.frame = CGRect(x: 0, y: 0, width: w, height: headerViewHeight)
    self.headerView.backgroundColor = UIColor.clearColor()
    //    self.headerView.backgroundColor = UIColor.greenColor() //

    let daysCollectionViewHeight = h - headerViewHeight

    let layout = self.daysCollectionView.collectionViewLayout as! UICollectionViewFlowLayout
    layout.itemSize = CGSizeMake(w / CGFloat(NUMBER_OF_DAYS_IN_WEEK), daysCollectionViewHeight / CGFloat(MAXIMUM_NUMBER_OF_ROWS))
    self.daysCollectionView.frame = CGRect(x: 0, y: headerViewHeight, width: w, height: daysCollectionViewHeight)

//    print("h: \(h) headerViewHeight: \(headerViewHeight) daysCollectionViewHeight: \(daysCollectionViewHeight)")
//    print("layout itemSize: \(layout.itemSize)")
  }


  // MARK: - UICollectionViewDataSource

  typealias MonthInfo = (firstWeekdayIndex: Int, numberOfDays: Int)

  private var monthInfos: [Int: MonthInfo] = [Int: MonthInfo]()


  public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
    guard let startDate = self.dataSource?.startDate(), endDate = self.dataSource?.endDate() else {
      return 0
    }

    startDateCache = startDate
    endDateCache = endDate

    // check if the dates are in correct order
    guard self.gregorianCalendar.compareDate(startDate, toDate: endDate, toUnitGranularity: .Nanosecond) == NSComparisonResult.OrderedAscending else {
      return 0
    }

    let firstDayOfStartMonth = self.gregorianCalendar.components([.Era, .Year, .Month], fromDate: startDateCache)
    firstDayOfStartMonth.day = 1

    guard let dateFromDayOneComponents = self.gregorianCalendar.dateFromComponents(firstDayOfStartMonth) else {
      return 0
    }

    startOfMonthCache = dateFromDayOneComponents

    let today = NSDate()

    if startOfMonthCache.compare(today) == NSComparisonResult.OrderedAscending &&
      endDateCache.compare(today) == NSComparisonResult.OrderedDescending {

      let differenceFromTodayComponents = self.gregorianCalendar.components([NSCalendarUnit.Month, NSCalendarUnit.Day], fromDate: startOfMonthCache, toDate: today, options: NSCalendarOptions())

      self.todayIndexPath = NSIndexPath(forItem: differenceFromTodayComponents.day, inSection: differenceFromTodayComponents.month)
    }

    let differenceComponents = self.gregorianCalendar.components(NSCalendarUnit.Month, fromDate: startDateCache, toDate: endDateCache, options: NSCalendarOptions())

    return differenceComponents.month + 1 // on the same month with a difference of 0 we still need 1 to display it
  }

  public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    let monthOffsetComponents = NSDateComponents()

    // offset by the number of months
    monthOffsetComponents.month = section

    guard let correctMonthForSectionDate = self.gregorianCalendar.dateByAddingComponents(monthOffsetComponents, toDate: startOfMonthCache, options: NSCalendarOptions()) else {
      return 0
    }

    let numberOfDaysInMonth = self.gregorianCalendar.rangeOfUnit(.Day, inUnit: .Month, forDate: correctMonthForSectionDate).length

    var firstWeekdayOfMonthIndex = self.gregorianCalendar.component(NSCalendarUnit.Weekday, fromDate: correctMonthForSectionDate)
    firstWeekdayOfMonthIndex = firstWeekdayOfMonthIndex - 1 // firstWeekdayOfMonthIndex should be 0-Indexed
    firstWeekdayOfMonthIndex = (firstWeekdayOfMonthIndex + 6) % 7 // push it modularly so that we take it back one day so that the first day is Monday instead of Sunday which is the default

    monthInfos[section] = (firstWeekdayIndex: firstWeekdayOfMonthIndex, numberOfDays: numberOfDaysInMonth)

    return NUMBER_OF_DAYS_IN_WEEK * MAXIMUM_NUMBER_OF_ROWS
  }

  public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let dayCell = collectionView.dequeueReusableCellWithReuseIdentifier(cellReuseIdentifier, forIndexPath: indexPath) as! AkaCalendarViewDayCell

    let currentMonthInfo: MonthInfo = monthInfos[indexPath.section]!

    let firstDayIndex = currentMonthInfo.firstWeekdayIndex
    let numberOfDays = currentMonthInfo.numberOfDays

    let fromStartOfMonthIndexPath = NSIndexPath(forItem: indexPath.item - firstDayIndex, inSection: indexPath.section)

    if indexPath.item >= firstDayIndex && indexPath.item < firstDayIndex + numberOfDays {
      dayCell.textLabel.text = String(fromStartOfMonthIndexPath.item + 1)
      dayCell.hidden = false
    } else {
      dayCell.textLabel.text = ""
      dayCell.hidden = true
    }

    dayCell.selected = selectedIndexPaths.contains(indexPath)

    if indexPath.section == 0 && indexPath.item == 0 {
      self.scrollViewDidEndDecelerating(collectionView)
    }

    if let todayIndexPath = self.todayIndexPath {
      dayCell.isToday = (todayIndexPath.section == indexPath.section && todayIndexPath.item + firstDayIndex == indexPath.item)
    }

    return dayCell
  }


  // MARK: - UIScrollViewDelegate

  public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
    self.calculateDate()
  }

  public func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
    self.calculateDate()
  }

  internal func calculateDate() {
    let cvBounds = self.daysCollectionView.bounds

    var page = self.direction == .Horizontal ? Int(round(self.daysCollectionView.contentOffset.x / cvBounds.size.width)) : Int(round(self.daysCollectionView.contentOffset.y / cvBounds.size.height))

    page = page > 0 ? page : 0

    let monthsOffsetComponents = NSDateComponents()
    monthsOffsetComponents.month = page

    guard let delegate = self.delegate else {
      return
    }

    guard let yearDate = self.gregorianCalendar.dateByAddingComponents(monthsOffsetComponents, toDate: self.startOfMonthCache, options: NSCalendarOptions()) else {
      return
    }

    let month = self.gregorianCalendar.component(NSCalendarUnit.Month, fromDate: yearDate)

    let monthName = NSDateFormatter().monthSymbols[(month - 1) % 12]

    let year = self.gregorianCalendar.component(NSCalendarUnit.Year, fromDate: yearDate)

    self.headerView.monthLabel.text = monthName.capitalizedString + " " + String(year)

    self.displayDate = yearDate

    delegate.calendarView?(self, didScrollToMonth: yearDate)
  }


  // MARK: - UICollectionViewDelegate

  private var currentDateSelected: NSDate?

  public func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
    let currentMonthInfo: MonthInfo = monthInfos[indexPath.section]!
    let firstDayInMonth = currentMonthInfo.firstWeekdayIndex

    let offsetComponents = NSDateComponents()
    offsetComponents.month = indexPath.section
    offsetComponents.day = indexPath.item - firstDayInMonth

    if let dateSelected = self.gregorianCalendar.dateByAddingComponents(offsetComponents, toDate: startOfMonthCache, options: NSCalendarOptions()) {

      currentDateSelected = dateSelected

      // Optional protocol method (the delegate can "object")
      if let canSelectFromDelegate = delegate?.calendarView?(self, canSelectDate: dateSelected) {
        return canSelectFromDelegate
      }

      return true // can select any date by default
    }

    return false // date is out of scope
  }

  public func selectDate(date : NSDate) {
    guard let indexPath = self.indexPathForDate(date) else {
      return
    }

    guard self.daysCollectionView.indexPathsForSelectedItems()?.contains(indexPath) == false else {
      return
    }

    self.daysCollectionView.selectItemAtIndexPath(indexPath, animated: false, scrollPosition: .None)

    selectedIndexPaths.append(indexPath)
    selectedDates.append(date)
  }

  public func deselectDate(date: NSDate) {
    guard let indexPath = self.indexPathForDate(date) else {
      return
    }

    guard self.daysCollectionView.indexPathsForSelectedItems()?.contains(indexPath) == true else {
      return
    }

    self.daysCollectionView.deselectItemAtIndexPath(indexPath, animated: false)

    guard let index = selectedIndexPaths.indexOf(indexPath) else {
      return
    }

    selectedIndexPaths.removeAtIndex(index)
    selectedDates.removeAtIndex(index)
  }

  public func indexPathForDate(date : NSDate) -> NSIndexPath? {
    let distanceFromStartComponent = self.gregorianCalendar.components( [.Month, .Day], fromDate:startOfMonthCache, toDate: date, options: NSCalendarOptions() )

    guard let currentMonthInfo: MonthInfo = monthInfos[distanceFromStartComponent.month] else {
      return nil
    }

    let item = distanceFromStartComponent.day + currentMonthInfo.firstWeekdayIndex
    let indexPath = NSIndexPath(forItem: item, inSection: distanceFromStartComponent.month)

    return indexPath
  }



  public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    guard let dateBeingSelectedByUser = currentDateSelected else {
      return
    }

    delegate?.calendarView?(self, didSelectDate: dateBeingSelectedByUser)

    // Update model
    selectedIndexPaths.append(indexPath)
    selectedDates.append(dateBeingSelectedByUser)
  }

  public func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
    guard let dateBeingSelectedByUser = currentDateSelected else {
      return
    }

    guard let index = selectedIndexPaths.indexOf(indexPath) else {
      return
    }

    delegate?.calendarView?(self, didDeselectDate: dateBeingSelectedByUser)

    selectedIndexPaths.removeAtIndex(index)
    selectedDates.removeAtIndex(index)
  }

  public func reloadData() {
    self.daysCollectionView.reloadData()
  }

  public func setDisplayDate(date: NSDate, animated: Bool) {
    if let displayDate = self.displayDate {

      // skip is we are trying to set the same date
      guard date.compare(displayDate) != NSComparisonResult.OrderedSame else {
        return
      }

      // check if the date is within range
      guard date.compare(startDateCache) == NSComparisonResult.OrderedDescending &&
        date.compare(endDateCache) == NSComparisonResult.OrderedAscending else {
        return
      }

      let difference = self.gregorianCalendar.components([NSCalendarUnit.Month], fromDate: startOfMonthCache, toDate: date, options: NSCalendarOptions())

      if direction == .Horizontal {
        let distance: CGFloat = CGFloat(difference.month) * self.daysCollectionView.bounds.size.width
        self.daysCollectionView.setContentOffset(CGPoint(x: distance, y: 0.0), animated: animated)
      } else {
        let distance: CGFloat = CGFloat(difference.month) * self.daysCollectionView.bounds.size.height
        self.daysCollectionView.setContentOffset(CGPoint(x: 0.0, y: distance), animated: animated)
      }

      self.calculateDate()

    }
  }

}
