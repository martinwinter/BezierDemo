//
//  MWBezierCanvasView.m
//  BezierDemo
//
//  Created by Martin Winter on 17.03.14.
//  Copyright (c) 2014 Martin Winter Ltd. All rights reserved.
//

#import "MWBezierCanvasView.h"
#import "MWBezierCurve.h"


CGFloat const MWBezierCurveLineWidth = 10.0;
CGFloat const MWControlPointLineWidth = 2.0;
CGFloat const MWControlPointSize = 20.0;
static NSArray *controlPointColors;
static NSArray *controlPointLineColors;


CGRect MWControlPointRectForControlPoint(CGPoint controlPoint)
{
    CGRect controlPointRect = CGRectMake(controlPoint.x - MWControlPointSize / 2.0, 
                                         controlPoint.y - MWControlPointSize / 2.0, 
                                         MWControlPointSize, 
                                         MWControlPointSize);
    return controlPointRect;
}


@interface MWBezierCanvasView ()

@property CGFloat t;
@property CGPoint mouseDownLocation;
@property MWBezierCurve *mouseDownBezierCurve;
@property NSArray *mouseDownControlPoints;
@property NSInteger mouseDownControlPointIndex;

@end


@implementation MWBezierCanvasView


+ (void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        controlPointColors = @[[NSColor orangeColor], 
                               [NSColor yellowColor], 
                               [NSColor greenColor], 
                               [NSColor cyanColor]];

        // Descending order.
        controlPointLineColors = @[[NSColor blackColor], 
                                   [NSColor colorWithCalibratedWhite:0.6 alpha:1.0], 
                                   [NSColor colorWithCalibratedWhite:0.8 alpha:1.0]];
    });
}


- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _bezierCurves = [[NSMutableArray alloc] init];
        self.mouseDownControlPointIndex = -1;
    }
    
    return self;
}


- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    [[NSColor whiteColor] set];
    NSRectFill(dirtyRect);
    
    // Unfortunately, NSBezierPath does not offer quadratic curves, so we need to use CGPath instead.
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    
    for (MWBezierCurve *bezierCurve in self.bezierCurves)
    {
        NSMutableArray *tPoints = [NSMutableArray array];
        
        // Default case for linear curve.
        CGPoint tPoint = MWPointBetweenPoint1AndPoint2AtT([bezierCurve controlPointAtIndex:0], 
                                                          [bezierCurve controlPointAtIndex:1], 
                                                          self.t);
        [tPoints addObject:[NSValue valueWithPoint:tPoint]];
        
        
        //
        // Draw lines between control points, including of lower-degree curves.
        //
        
        if (bezierCurve.degree > 1)
        {
            CGContextSetLineWidth(context, MWControlPointLineWidth);

            for (NSUInteger degree = 1; degree <= bezierCurve.degree; ++degree)
            {
                NSArray *controlPoints = [bezierCurve controlPointsForDegree:degree andT:self.t];
                
                CGContextBeginPath(context);
                CGPoint p0 = [controlPoints[0] pointValue];
                CGContextMoveToPoint(context, p0.x, p0.y);
                CGPoint previousP = p0;

                for (NSUInteger controlPointIndex = 1; controlPointIndex <= degree; ++controlPointIndex)
                {
                    CGPoint p = [controlPoints[controlPointIndex] pointValue];
                    CGContextAddLineToPoint(context, p.x, p.y);

                    CGPoint tPoint = MWPointBetweenPoint1AndPoint2AtT(previousP, p, self.t);
                    [tPoints addObject:[NSValue valueWithPoint:tPoint]];
                    previousP = p;
                }
                // Note: Do _not_ close the path since we do not want a line back to the starting point!
                
                NSColor *controlPointLineColor = controlPointLineColors[bezierCurve.degree - degree];
                [controlPointLineColor set];
                CGContextStrokePath(context);
            }
        }

        
        //
        // Draw Bézier curve.
        //
        
        CGPathRef path = [self pathForBezierCurve:bezierCurve];
        CGContextAddPath(context, path);

        [[NSColor blackColor] set];
        CGContextSetLineWidth(context, MWBezierCurveLineWidth);
        CGContextStrokePath(context);
        
        CGPathRelease(path);
        
        
        CGContextSetLineWidth(context, MWControlPointLineWidth);
        [[NSColor blackColor] setStroke];
        

        //
        // Draw points for t.
        //

        for (NSValue *tPointValue in tPoints)
        {
            CGPoint tPoint = [tPointValue pointValue];
            CGRect tRect = CGRectMake(tPoint.x - MWControlPointSize / 2.0, 
                                      tPoint.y - MWControlPointSize / 2.0, 
                                      MWControlPointSize, 
                                      MWControlPointSize);
            CGContextAddEllipseInRect(context, tRect);
            [[NSColor redColor] setFill];
            CGContextDrawPath(context, kCGPathFillStroke);
        }
        

        //
        // Draw control points.
        //
        
        for (NSUInteger controlPointIndex = 0; controlPointIndex <= bezierCurve.degree; ++controlPointIndex)
        {
            CGPoint controlPoint = [bezierCurve controlPointAtIndex:controlPointIndex];
            CGRect controlPointRect = MWControlPointRectForControlPoint(controlPoint);
            CGContextAddRect(context, controlPointRect);
            
            NSColor *controlPointColor = controlPointColors[controlPointIndex];
            [controlPointColor setFill];
            CGContextDrawPath(context, kCGPathFillStroke);
        }
    }
}


- (CGPathRef)pathForBezierCurve:(MWBezierCurve *)bezierCurve
{
    CGPoint p0 = [bezierCurve controlPointAtIndex:0];
    CGPoint p1 = [bezierCurve controlPointAtIndex:1];

    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, p0.x, p0.y);

    switch (bezierCurve.degree)
    {
        case 1:
        {
            CGPathAddLineToPoint(path, NULL, p1.x, p1.y);
            break;
        }
            
        case 2:
        {
            CGPoint p2 = [bezierCurve controlPointAtIndex:2];
            CGPathAddQuadCurveToPoint(path, NULL, p1.x, p1.y, p2.x, p2.y);
            break;
        }
            
        case 3:
        {
            CGPoint p2 = [bezierCurve controlPointAtIndex:2];
            CGPoint p3 = [bezierCurve controlPointAtIndex:3];
            CGPathAddCurveToPoint(path, NULL, p1.x, p1.y, p2.x, p2.y, p3.x, p3.y);
            break;
        }
            
        default:
        {
            return NULL;
        }
    }
    
    return path;
}


- (void)mouseDown:(NSEvent *)theEvent
{
    CGPoint locationInWindow = [theEvent locationInWindow];
    CGPoint locationInView = [self convertPoint:locationInWindow fromView:nil];
    
    for (MWBezierCurve *bezierCurve in self.bezierCurves)
    {
        for (NSUInteger controlPointIndex = 0; controlPointIndex <= bezierCurve.degree; ++controlPointIndex)
        {
            CGPoint controlPoint = [bezierCurve controlPointAtIndex:controlPointIndex];
            CGRect controlPointRect = MWControlPointRectForControlPoint(controlPoint);
            
            if (CGRectContainsPoint(controlPointRect, locationInView))
            {
                self.mouseDownLocation = locationInView;
                self.mouseDownBezierCurve = bezierCurve;
                self.mouseDownControlPoints = bezierCurve.controlPoints;
                self.mouseDownControlPointIndex = controlPointIndex;
                return;
            }
        }
        
        CGPathRef path = [self pathForBezierCurve:bezierCurve];
        CGPathRef strokedPath = CGPathCreateCopyByStrokingPath(path, 
                                                               NULL, 
                                                               MWBezierCurveLineWidth * 2.0, 
                                                               kCGLineCapButt, 
                                                               kCGLineJoinMiter, 
                                                               0);
        
        if (CGPathContainsPoint(strokedPath, NULL, locationInView, false))
        {
            self.mouseDownLocation = locationInView;
            self.mouseDownBezierCurve = bezierCurve;
            self.mouseDownControlPoints = bezierCurve.controlPoints;
            return;
        }
    }
}


- (void)mouseDragged:(NSEvent *)theEvent
{
    CGPoint locationInWindow = [theEvent locationInWindow];
    CGPoint locationInView = [self convertPoint:locationInWindow fromView:nil];

    CGSize delta = CGSizeMake(locationInView.x - self.mouseDownLocation.x, 
                              locationInView.y - self.mouseDownLocation.y);
    
    if (self.mouseDownControlPointIndex < 0) // Move entire curve.
    {
        MWBezierCurve *bezierCurve = self.mouseDownBezierCurve;
        for (NSUInteger controlPointIndex = 0; controlPointIndex <= bezierCurve.degree; ++controlPointIndex)
        {
            NSValue *controlPointValue = self.mouseDownControlPoints[controlPointIndex];
            CGPoint controlPoint = [controlPointValue pointValue];
            CGPoint proposedControlPoint = CGPointMake(controlPoint.x + delta.width, 
                                                       controlPoint.y + delta.height);
            
            [self.mouseDownBezierCurve setControlPoint:proposedControlPoint 
                                               atIndex:controlPointIndex];
        }
    }
    else // Move one control point only.
    {
        NSValue *controlPointValue = self.mouseDownControlPoints[self.mouseDownControlPointIndex];
        CGPoint controlPoint = [controlPointValue pointValue];
        CGPoint proposedControlPoint = CGPointMake(controlPoint.x + delta.width, 
                                                   controlPoint.y + delta.height);
        
        [self.mouseDownBezierCurve setControlPoint:proposedControlPoint 
                                           atIndex:self.mouseDownControlPointIndex];
    }
    
    [self setNeedsDisplay:YES];
}


- (void)mouseUp:(NSEvent *)theEvent
{
    self.mouseDownLocation = CGPointZero;
    self.mouseDownBezierCurve = nil;
    self.mouseDownControlPoints = nil;
    self.mouseDownControlPointIndex = -1;
}


- (void)updateT:(CGFloat)t
{
    self.t = t;
    [self setNeedsDisplay:YES];
}


@end
