//
//  AkaCalendarViewFlowLayout.swift
//  AkaCalendar
//
//  Created by Yoann Cribier on 13/05/2016.
//  Copyright © 2016 Yoann Cribier. All rights reserved.
//

import UIKit

class AkaCalendarViewFlowLayout: UICollectionViewFlowLayout {

  override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    return super.layoutAttributesForElementsInRect(rect)?.map { attributes in
      let attributes = attributes.copy() as! UICollectionViewLayoutAttributes
      self.applyLayoutAttributes(attributes)

      return attributes
    }
  }

  override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
    if let attributes = super.layoutAttributesForItemAtIndexPath(indexPath) {
      let attributes = attributes.copy() as! UICollectionViewLayoutAttributes
      self.applyLayoutAttributes(attributes)

      return attributes
    }

    return nil
  }

  override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
    return true
  }

  func applyLayoutAttributes(attributes: UICollectionViewLayoutAttributes) {
    guard attributes.representedElementKind == nil else {
      return
    }

    if let collectionView = self.collectionView {
      let stride = (self.scrollDirection == .Horizontal) ? collectionView.bounds.size.width : collectionView.bounds.size.height

      let offset = CGFloat(attributes.indexPath.section) * stride

      var xCellOffset = CGFloat(attributes.indexPath.item % 7) * self.itemSize.width
      var yCellOffset = CGFloat(attributes.indexPath.item / 7) * self.itemSize.height

      if (self.scrollDirection == .Horizontal) {
        xCellOffset += offset;
      } else {
        yCellOffset += offset
      }

      attributes.frame = CGRectMake(xCellOffset, yCellOffset, self.itemSize.width, self.itemSize.height)
    }
  }

}
