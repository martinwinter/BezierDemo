//
//  MWBezierCurve.h
//  BezierDemo
//
//  Created by Martin Winter on 17.03.14.
//  Copyright (c) 2014 Martin Winter Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


CGPoint MWPointBetweenPoint1AndPoint2AtT(CGPoint point1, CGPoint point2, CGFloat t);


@interface MWBezierCurve : NSObject

@property (readonly) NSUInteger degree;

/** Returns an immutable copy of the receiver’s control points array. */
@property (readonly) NSArray *controlPoints;

- (instancetype)initWithDegree:(NSUInteger)degree;

- (void)setControlPoint:(CGPoint)controlPoint atIndex:(NSUInteger)index;

- (CGPoint)controlPointAtIndex:(NSUInteger)index;

/** Ignores t if degree equals the receiver’s degree. */
- (NSArray *)controlPointsForDegree:(NSUInteger)degree andT:(CGFloat)t;

/** Randomizes the receiver’s control points so their coordinates lie inside rect. */
- (void)randomizeWithRect:(CGRect)rect;

@end
