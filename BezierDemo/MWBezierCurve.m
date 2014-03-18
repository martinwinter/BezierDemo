//
//  MWBezierCurve.m
//  BezierDemo
//
//  Created by Martin Winter on 17.03.14.
//  Copyright (c) 2014 Martin Winter Ltd. All rights reserved.
//

#import "MWBezierCurve.h"


@interface MWBezierCurve ()

@property NSMutableArray *mutableControlPoints;

@end


CGFloat MWRandomFloatBetweenMinAndMax(CGFloat min, CGFloat max)
{
    u_int32_t unsignedMin = (u_int32_t)min;
    u_int32_t unsignedMax = (u_int32_t)max;
    u_int32_t delta = unsignedMax - unsignedMin;
    u_int32_t randomUnsigned = arc4random_uniform(delta + 1) + min;
    CGFloat randomFloat = (CGFloat)randomUnsigned;
    return randomFloat;
}


CGPoint MWRandomPointInRect(CGRect rect)
{
    CGFloat randomX = MWRandomFloatBetweenMinAndMax(CGRectGetMinX(rect), CGRectGetMaxX(rect));
    CGFloat randomY = MWRandomFloatBetweenMinAndMax(CGRectGetMinY(rect), CGRectGetMaxY(rect));
    CGPoint randomPoint = CGPointMake(randomX, randomY);
    return randomPoint;
}


CGPoint MWPointBetweenPoint1AndPoint2AtT(CGPoint point1, CGPoint point2, CGFloat t)
{
    CGPoint point = CGPointMake(point1.x + t * (point2.x - point1.x), 
                                point1.y + t * (point2.y - point1.y));
    return point;
}


@implementation MWBezierCurve

@dynamic controlPoints;


- (instancetype)initWithDegree:(NSUInteger)degree
{
    if (degree < 1)
    {
        return nil;
    }
    
    self = [super init];
    if (self)
    {
        _degree = degree;
        _mutableControlPoints = [[NSMutableArray alloc] init];
        for (NSUInteger controlPointIndex = 0; controlPointIndex <= degree; ++controlPointIndex)
        {
            [_mutableControlPoints addObject:[NSNull null]];
            [self setControlPoint:CGPointZero 
                          atIndex:controlPointIndex];
        }
    }
    
    return self;
}


- (id)init
{
    return [self initWithDegree:3];
}


- (NSArray *)controlPoints
{
    NSArray *controlPoints = [self.mutableControlPoints copy];
    return controlPoints;
}


- (void)setControlPoint:(CGPoint)controlPoint atIndex:(NSUInteger)index
{
    NSValue *controlPointValue = [NSValue valueWithPoint:controlPoint];
    self.mutableControlPoints[index] = controlPointValue;
}


- (CGPoint)controlPointAtIndex:(NSUInteger)index
{
    NSValue *controlPointValue = self.mutableControlPoints[index];
    CGPoint controlPoint = [controlPointValue pointValue];
    return controlPoint;
}


- (CGPoint)pointBetweenControlPointsAtIndex1:(NSUInteger)index1 
                                   andIndex2:(NSUInteger)index2 
                                        forT:(CGFloat)t
{
    CGPoint point1 = [self controlPointAtIndex:index1];
    CGPoint point2 = [self controlPointAtIndex:index2];
    CGPoint point = MWPointBetweenPoint1AndPoint2AtT(point1, point2, t);
    return point;
}


- (NSArray *)controlPointsForDegree:(NSUInteger)degree andT:(CGFloat)t
{
    if (degree == 0 || degree > self.degree)
    {
        return nil;
    }
    
    if (degree == self.degree || self.degree == 1)
    {
        // Recursive termination.
        return self.controlPoints;
    }

    NSUInteger lowerDegree = self.degree - 1;
    MWBezierCurve *lowerCurve = [[MWBezierCurve alloc] initWithDegree:lowerDegree];
    for (NSUInteger controlPointIndex = 0; controlPointIndex < self.degree; ++controlPointIndex)
    {
        CGPoint lowerControlPoint = [self pointBetweenControlPointsAtIndex1:controlPointIndex 
                                                                  andIndex2:controlPointIndex + 1 
                                                                       forT:t];
        
        [lowerCurve setControlPoint:lowerControlPoint atIndex:controlPointIndex];
    }
    
    // Recursive call.
    return [lowerCurve controlPointsForDegree:degree andT:t];
}


- (void)randomizeWithRect:(CGRect)rect
{
    for (NSUInteger controlPointIndex = 0; controlPointIndex <= self.degree; ++controlPointIndex)
    {
        [self setControlPoint:MWRandomPointInRect(rect) 
                      atIndex:controlPointIndex];
    }
}


@end
