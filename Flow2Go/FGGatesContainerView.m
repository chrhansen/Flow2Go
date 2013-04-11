//
//  GatesContainerViewNew.m
//  Flow2Go
//
//  Created by Christian Hansen on 15/09/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "FGGatesContainerView.h"
#import "FGPolygon.h"
#import "FGSingleRange.h"
#import "FGRectangle.h"
#import "FGEllipse.h"
#import <QuartzCore/QuartzCore.h>

@interface FGGatesContainerView () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSMutableArray *gateGraphics;
@property (nonatomic, strong) FGGateGraphic *creatingGraphic;
@property (nonatomic, strong) FGGateGraphic *modifyingGraphic;
@property (nonatomic) NSInteger simultaneousGestures;

@end

@implementation FGGatesContainerView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.gateGraphics = NSMutableArray.array;
        [self _addGestures];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.gateGraphics = NSMutableArray.array;
        [self _addGestures];
        self.layer.drawsAsynchronously = YES;
    }
    return self;
}


- (void)redrawGates
{
    [self removeGateViews];
    
    NSUInteger gateCount = [self.delegate numberOfGatesInGatesContainerView:self];
    
    for (NSUInteger gateNo = 0; gateNo < gateCount; gateNo++) {
        FGGateType gateType = [self.delegate gatesContainerView:self gateTypeForGateNo:gateNo];
        NSArray *vertices = [self.delegate gatesContainerView:self verticesForGate:gateNo];
        
        [self _insertExistingGate:gateType gateTag:gateNo vertices:vertices];
    }
}



- (void)removeGateViews
{
    [self.gateGraphics removeAllObjects];
    [self setNeedsDisplay];
}

#define HIDE_SHOW_ANIMATION_DURATION 0.2

- (void)setHidden:(BOOL)hidden animated:(BOOL)animated
{
    CGFloat alpha = hidden ? 0.0f : 1.0f;
    if (animated) {
        [UIView animateWithDuration:HIDE_SHOW_ANIMATION_DURATION animations:^{
            self.alpha = alpha;
        }];
    } else {
        self.alpha = alpha;
    }

}

- (void)_insertExistingGate:(FGGateType)gateType gateTag:(NSInteger)tagNumber vertices:(NSArray *)vertices
{
    FGGateGraphic *existingGateGraphic = nil;
    switch (gateType)
    {
        case kGateTypeSingleRange:
            existingGateGraphic = [FGSingleRange.alloc initWithVertices:vertices];
            existingGateGraphic.gateTag = tagNumber;
            [self.gateGraphics addObject:existingGateGraphic];
            break;
            
        case kGateTypePolygon:
            existingGateGraphic = [FGPolygon.alloc initWithVertices:vertices];
            existingGateGraphic.gateTag = tagNumber;
            [self.gateGraphics addObject:existingGateGraphic];
            break;
            
        case kGateTypeRectangle:
            existingGateGraphic = [FGRectangle.alloc initWithVertices:vertices];
            existingGateGraphic.gateTag = tagNumber;
            [self.gateGraphics addObject:existingGateGraphic];
            break;
            
        case kGateTypeEllipse:
            existingGateGraphic = [FGEllipse.alloc initWithVertices:vertices];
            existingGateGraphic.gateTag = tagNumber;
            [self.gateGraphics addObject:existingGateGraphic];
            break;

        default:
            break;
    }
}


- (void)insertNewGate:(FGGateType)gateType gateTag:(NSInteger)tagNumber
{
    CGFloat leftBound = 0.4 * self.bounds.size.width / 2;
    CGFloat rightBound = 0.6 * self.bounds.size.width / 2;
    CGFloat halfHeight = self.bounds.size.height / 2;
    
    FGGateGraphic *newGateGraphic = nil;
    
    switch (gateType)
    {
        case kGateTypeSingleRange:
            newGateGraphic = [FGSingleRange.alloc initWithVertices:@[[NSValue valueWithCGPoint:CGPointMake(leftBound, halfHeight)], [NSValue valueWithCGPoint:CGPointMake(rightBound, halfHeight)]]];
            newGateGraphic.gateTag = tagNumber;
            [self.gateGraphics addObject:newGateGraphic];
            [self.delegate gatesContainerView:self didModifyGateNo:newGateGraphic.gateTag gateType:newGateGraphic.gateType vertices:[newGateGraphic getPathPoints]];
            break;
            
        case kGateTypePolygon:
            self.creatingGraphic = FGPolygon.alloc.init;
            self.creatingGraphic.gateTag = tagNumber;
            [self.gateGraphics addObject:self.creatingGraphic];
            // report gate change/insert to delegate is carried out after the user has drawin a polygon path.
            break;
            
        case kGateTypeRectangle:
            newGateGraphic = [FGRectangle.alloc initWithBoundsOfContainerView:self.bounds];
            newGateGraphic.gateTag = tagNumber;
            [self.gateGraphics addObject:newGateGraphic];
            [self.delegate gatesContainerView:self didModifyGateNo:newGateGraphic.gateTag gateType:newGateGraphic.gateType vertices:[newGateGraphic getPathPoints]];
            break;
            
        case kGateTypeEllipse:
            newGateGraphic = [FGEllipse.alloc initWithBoundsOfContainerView:self.bounds];
            newGateGraphic.gateTag = tagNumber;
            [self.gateGraphics addObject:newGateGraphic];
            [self.delegate gatesContainerView:self didModifyGateNo:newGateGraphic.gateTag gateType:newGateGraphic.gateType vertices:[newGateGraphic getPathPoints]];
            break;
        default:
            break;
    }
    [self setNeedsDisplay];
}


- (void)drawRect:(CGRect)rect
{
    for (FGGateGraphic *gateGraphic in self.gateGraphics)
    {
        [gateGraphic.fillColor setFill];
        [gateGraphic.path fillWithBlendMode:kCGBlendModeNormal alpha:0.3];
        [gateGraphic.strokeColor setStroke];
        [gateGraphic.path stroke];
        if (gateGraphic.hooks) {
            [gateGraphic.hookColor setFill];
            [gateGraphic.hookColor setStroke];
            for (UIBezierPath *hook in gateGraphic.hooks) {
                [hook fillWithBlendMode:kCGBlendModeNormal alpha:0.3];
                [hook stroke];
            }
        }
    }
}



#pragma mark - Gesture Recognizer 
#pragma mark Gesture Setup methods
- (void)_addGestures
{
    UITapGestureRecognizer *singleTapRecognizer = [UITapGestureRecognizer.alloc initWithTarget:self action:@selector(tapDetected:)];

    UITapGestureRecognizer *doubleTapRecognizer = [UITapGestureRecognizer.alloc initWithTarget:self action:@selector(doubleTapDetected:)];
    doubleTapRecognizer.numberOfTapsRequired = 2;
    
    UIPanGestureRecognizer *panRecognizer = [UIPanGestureRecognizer.alloc initWithTarget:self action:@selector(panDetected:)];
    UIPinchGestureRecognizer *pinchRecognizer = [UIPinchGestureRecognizer.alloc initWithTarget:self action:@selector(pinchDetected:)];
    
    UILongPressGestureRecognizer *longPressRecognizer = [UILongPressGestureRecognizer.alloc initWithTarget:self action:@selector(longPressDetected:)];
    
    UIRotationGestureRecognizer *rotationRecognizer = [UIRotationGestureRecognizer.alloc initWithTarget:self action:@selector(rotationDetected:)];
    
    [singleTapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
    
    [self addGestureRecognizer:singleTapRecognizer];
    [self addGestureRecognizer:doubleTapRecognizer];
    [self addGestureRecognizer:panRecognizer];
    [self addGestureRecognizer:pinchRecognizer];
    [self addGestureRecognizer:longPressRecognizer];
    [self addGestureRecognizer:rotationRecognizer];
    
    panRecognizer.delegate = self;
    pinchRecognizer.delegate = self;
    singleTapRecognizer.delegate = self;
    rotationRecognizer.delegate = self;
    
    self.simultaneousGestures = 0;
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return YES;
}


- (FGGateGraphic *)_gateAtTapPoint:(CGPoint)tapPoint
{
    for (FGGateGraphic *aGate in self.gateGraphics)
    {
        if ([aGate isContentsUnderPoint:tapPoint])
        {
            return aGate;
        }
    }
    return nil;
}


- (void)_toggleLongPressActionForGate:(FGGateGraphic *)gateGraphic
{
    if (gateGraphic)
    {
        if (!gateGraphic.hooks)
        {
            [gateGraphic showDragableHooks];
        }
        else
        {
            [gateGraphic hideDragableHooks];
        }
        [self setNeedsDisplay];
    }
}

#pragma mark Gesture Action Methods
- (void)tapDetected:(UITapGestureRecognizer *)tapGesture
{
    if (self.creatingGraphic)
    {
        return;
    }
    
    CGPoint tapPoint = [tapGesture locationInView:self];
    FGGateGraphic *tappedGate = [self _gateAtTapPoint:tapPoint];
    if (tappedGate)
    {
        CGRect rect = CGRectMake(tapPoint.x, tapPoint.y, 1.0f, 1.0f);
        [self.delegate gatesContainerView:self didTapGate:tappedGate.gateTag inRect:rect];
    }
}


- (void)doubleTapDetected:(UITapGestureRecognizer *)doubleTapGesture
{
    CGPoint tapPoint = [doubleTapGesture locationInView:self];
    FGGateGraphic *tappedGate = [self _gateAtTapPoint:tapPoint];
    if (tappedGate != nil) {
        [self.delegate gatesContainerView:self didDoubleTapGate:tappedGate.gateTag];
    }
}


- (void)panDetected:(UIPanGestureRecognizer *)panGesture
{
    CGPoint location = [panGesture locationInView:self];
    if (self.creatingGraphic)
    {
        CGPoint location = [panGesture locationInView:self];
        
        switch (panGesture.state)
        {
            case UIGestureRecognizerStateBegan:
                [self.creatingGraphic panBeganAtPoint:location];
                [self setNeedsDisplayInRect:self.creatingGraphic.path.bounds];
                break;
                
            case UIGestureRecognizerStateChanged:
                [self.creatingGraphic panChangedToPoint:location];
                [self setNeedsDisplayInRect:self.creatingGraphic.path.bounds];
                break;
                
            case UIGestureRecognizerStateEnded:
                [self.creatingGraphic panEndedAtPoint:location];
                [self.delegate gatesContainerView:self didModifyGateNo:self.creatingGraphic.gateTag gateType:self.creatingGraphic.gateType vertices:[self.creatingGraphic getPathPoints]];
                [self setNeedsDisplayInRect:self.creatingGraphic.path.bounds];
                self.creatingGraphic = nil;
                break;
                
            default:
                break;
        }
    }
    else
    {
        CGPoint tranlation = [panGesture translationInView:self];
        switch (panGesture.state)
        {
            case UIGestureRecognizerStateBegan:
                self.simultaneousGestures += 1;
                self.modifyingGraphic = [self _gateAtTapPoint:location];
                break;
                
            case UIGestureRecognizerStateChanged:
                [self.modifyingGraphic.path applyTransform:CGAffineTransformMakeTranslation(tranlation.x, tranlation.y)];
                break;
                
            case UIGestureRecognizerStateEnded:
            case UIGestureRecognizerStateFailed:
            case UIGestureRecognizerStateCancelled:
                self.simultaneousGestures -= 1;
                if (self.modifyingGraphic != nil
                    && self.simultaneousGestures == 0) {
                    [self.modifyingGraphic.path applyTransform:CGAffineTransformMakeTranslation(tranlation.x, tranlation.y)];
                    [self.delegate gatesContainerView:self didModifyGateNo:self.modifyingGraphic.gateTag gateType:self.modifyingGraphic.gateType vertices:[self.modifyingGraphic getPathPoints]];
                    self.modifyingGraphic = nil;
                }
                break;
                
            default:
                break;
        }
        if (self.modifyingGraphic) [self setNeedsDisplay];
    }
    [panGesture setTranslation:CGPointZero inView:self];
}


- (void)pinchDetected:(UIPinchGestureRecognizer *)pinchRecognizer
{
    if (self.creatingGraphic)
    {
        return;
    }
    
    else
    {
        CGPoint location = [pinchRecognizer locationInView:self];
        
        switch (pinchRecognizer.state)
        {
            case UIGestureRecognizerStateBegan:
                self.simultaneousGestures += 1;
                self.modifyingGraphic = [self _gateAtTapPoint:location];
                
                CGPoint touch1 = [pinchRecognizer locationOfTouch:0 inView:self];
                CGPoint touch2 = [pinchRecognizer locationOfTouch:1 inView:self];
                [self.modifyingGraphic pinchWithCentroid:location withScale:pinchRecognizer.scale touch1:touch1 touch2:touch2];
                
//                [self.modifyingGraphic pinchBeganAtLocation:location withScale:pinchRecognizer.scale];
                break;
                
            case UIGestureRecognizerStateChanged:
            {
                CGPoint touch1 = [pinchRecognizer locationOfTouch:0 inView:self];
                CGPoint touch2 = [pinchRecognizer locationOfTouch:1 inView:self];
                [self.modifyingGraphic pinchWithCentroid:location withScale:pinchRecognizer.scale touch1:touch1 touch2:touch2];
                
                
//                [self.modifyingGraphic pinchChangedAtLocation:location withScale:pinchRecognizer.scale];
            }
                break;
                
            case UIGestureRecognizerStateEnded:
            case UIGestureRecognizerStateFailed:
            case UIGestureRecognizerStateCancelled:
                self.simultaneousGestures -= 1;
                if (self.modifyingGraphic != nil
                    && self.simultaneousGestures == 0)
                {
                    CGPoint touch1 = [pinchRecognizer locationOfTouch:0 inView:self];
                    CGPoint touch2 = [pinchRecognizer locationOfTouch:1 inView:self];
                    [self.modifyingGraphic pinchWithCentroid:location withScale:pinchRecognizer.scale touch1:touch1 touch2:touch2];

                    
//                    [self.modifyingGraphic pinchEndedAtLocation:location withScale:pinchRecognizer.scale];
                    [self.delegate gatesContainerView:self didModifyGateNo:self.modifyingGraphic.gateTag gateType:self.modifyingGraphic.gateType vertices:[self.modifyingGraphic getPathPoints]];
                    self.modifyingGraphic = nil;
                }
                break;
                
            default:
                break;
                
        }
        [self setNeedsDisplay];
        pinchRecognizer.scale = 1.0f;
    }
}

- (void)rotationDetected:(UIRotationGestureRecognizer *)rotationGesture
{
    if (self.creatingGraphic) {
        return;
    } else {
        CGPoint location = [rotationGesture locationInView:self];
        
        switch (rotationGesture.state) {
            case UIGestureRecognizerStateBegan:
                self.simultaneousGestures += 1;
                self.modifyingGraphic = [self _gateAtTapPoint:location];
                [self.modifyingGraphic rotationBeganAtLocation:location withAngle:rotationGesture.rotation];
                break;
                
            case UIGestureRecognizerStateChanged:
                [self.modifyingGraphic rotationChangedAtLocation:location withAngle:rotationGesture.rotation];
                break;
                
            case UIGestureRecognizerStateEnded:
            case UIGestureRecognizerStateFailed:
            case UIGestureRecognizerStateCancelled:
                self.simultaneousGestures -= 1;
                if (self.modifyingGraphic != nil
                    && self.simultaneousGestures == 0) {
                    [self.modifyingGraphic rotationEndedAtLocation:location withAngle:rotationGesture.rotation];
                    [self.delegate gatesContainerView:self didModifyGateNo:self.modifyingGraphic.gateTag gateType:self.modifyingGraphic.gateType vertices:[self.modifyingGraphic getPathPoints]];
                    self.modifyingGraphic = nil;
                }
                break;
                
            default:
                break;
                
        }
        [self setNeedsDisplay];
        rotationGesture.rotation = 0.0f;
    }
}


- (void)longPressDetected:(UILongPressGestureRecognizer *)longPressGesture
{
    switch (longPressGesture.state)
    {
        case UIGestureRecognizerStateBegan:
            [self _toggleLongPressActionForGate:[self _gateAtTapPoint:[longPressGesture locationInView:self]]];
            break;
            
        default:
            break;
    }
}

@end
