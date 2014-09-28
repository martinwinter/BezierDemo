//
//  MWBezierController.m
//  BezierDemo
//
//  Created by Martin Winter on 17.03.14.
//  Copyright (c) 2014 Martin Winter Ltd. All rights reserved.
//

#import "MWBezierController.h"
#import "MWBezierCanvasView.h"
#import "MWBezierCurve.h"


@interface MWBezierController ()

@property IBOutlet MWBezierCanvasView *canvasView;

@end


@implementation MWBezierController


- (IBAction)addBezierCurve:(id)sender
{
    NSUInteger degree = (NSUInteger)[sender tag];
    MWBezierCurve *bezierCurve = [[MWBezierCurve alloc] initWithDegree:degree];
    [bezierCurve randomizeWithRect:[self.canvasView bounds]];    
    [self.canvasView.bezierCurves addObject:bezierCurve];
    
    [self.canvasView setNeedsDisplay:YES];
}


- (void)setT:(CGFloat)t
{
    _t = t;
    
    [self.canvasView updateT:t];
}


- (void)setFlatness:(CGFloat)flatness
{
    _flatness = flatness;
    
    [self.canvasView updateFlatness:flatness];
}


@end
