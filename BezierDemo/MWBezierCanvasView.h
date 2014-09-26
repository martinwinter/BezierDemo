//
//  MWBezierCanvasView.h
//  BezierDemo
//
//  Created by Martin Winter on 17.03.14.
//  Copyright (c) 2014 Martin Winter Ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>


/**
 This class demonstrates the use of De Casteljau’s algorithm to draw Bézier curves.
 */
@interface MWBezierCanvasView : NSView

@property NSMutableArray *bezierCurves;

- (void)updateT:(CGFloat)t;

@end
