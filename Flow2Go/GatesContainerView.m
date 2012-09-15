//
//  GatesContainerView.m
//  Shapes
//
//  Created by Christian Hansen on 13/09/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "GatesContainerView.h"
#import "SingleGateView.h"
#import "PolygonGateView.h"


@interface GatesContainerView ()

@property (nonatomic, strong) GateView *selectedGateView;
@property (nonatomic, strong) GateView *creatingGateView;

@end


@implementation GatesContainerView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _addGestures];
    }
    return self;
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _addGestures];
    }
    return self;
}


- (void)removeGateViews
{
    for (UIView *aView in self.subviews)
    {
        if ([aView isKindOfClass:GateView.class])
        {
            [aView removeFromSuperview];
        }
    }
    [self setNeedsDisplay];
}


- (void)redrawGates
{
    [self removeGateViews];
    
    NSUInteger gateCount = [self.delegate numberOfGatesInGatesContainerView:self];

    for (NSUInteger gateNo = 0; gateNo < gateCount; gateNo++)
    {
        GateType gateType = [self.delegate gatesContainerView:self gateTypeForGateNo:gateNo];
        NSArray *vertices = [self.delegate gatesContainerView:self verticesForGate:gateNo];
        
        [self _insertExistingGate:gateType gateTag:gateNo vertices:vertices];
    }

    // attach infoButton and identifier to each gate
    //
    // add gate as subview
}


- (void)_insertExistingGate:(GateType)gateType gateTag:(NSInteger)tagNumber vertices:(NSArray *)vertices
{
    switch (gateType)
    {
        case kGateTypeSingleRange:
//            [self addSubview:[SingleGateView.alloc initWithLeftEdge:[vertices[0] floatValue]
//                                                          rightEdge:[vertices[1] floatValue]
//                                                                  y:[vertices[2] floatValue]
//                                                            gateTag:tagNumber]];
            break;
            
        case kGateTypePolygon:
            [self addSubview:[PolygonGateView.alloc initWithFrame:self.bounds
                                              polygonGateVertices:vertices
                                                          gateTag:tagNumber]];
            break;
            
        default:
            break;
    }
}


- (void)insertNewGate:(GateType)gateType gateTag:(NSInteger)tagNumber
{
    GateView *newGateView = nil;
    switch (gateType)
    {
        case kGateTypeSingleRange:
            newGateView = [SingleGateView.alloc initWithLeftEdge:self.center.x*0.8
                                                       rightEdge:self.center.x*1.2
                                                               y:self.center.y
                                                         gateTag:tagNumber];
            [self addSubview:newGateView];
            [self _reportGateChangeForGateView:newGateView];
            break;
            
        case kGateTypePolygon:
            newGateView = [PolygonGateView.alloc initWithFrame:self.bounds
                                           polygonGateVertices:nil
                                                       gateTag:tagNumber];
            self.creatingGateView = newGateView;
            [self addSubview:newGateView];
            // report gate change/insert is carried out after the user has tracked a polygon path.
            
            break;
            
        default:
            break;
    }
}


- (void)_reportGateChangeForGateView:(GateView *)gateView
{
    switch (gateView.gateType)
    {
        case kGateTypePolygon:
            [self.delegate gatesContainerView:self didModifyGateNo:gateView.gateTag gateType:gateView.gateType vertices:gateView.vertices];
            
            break;
            
        case kGateTypeSingleRange:
            [self.delegate gatesContainerView:self didModifyGateNo:gateView.tag gateType:gateView.gateType vertices:@[[NSNumber numberWithFloat:gateView.frame.origin.x], [NSNumber numberWithFloat:gateView.frame.origin.x+gateView.frame.size.width], [NSNumber numberWithFloat:gateView.center.y]]];
            
            break;
        default:
            break;
    }
}




#pragma mark - Gesture recognizers
- (void)_addGestures
{
    UITapGestureRecognizer *tapRecognizer = [UITapGestureRecognizer.alloc initWithTarget:self action:@selector(tapDetected:)];
    UIPanGestureRecognizer *panRecognizer = [UIPanGestureRecognizer.alloc initWithTarget:self action:@selector(panDetected:)];
    UIPinchGestureRecognizer *pinchRecognizer = [UIPinchGestureRecognizer.alloc initWithTarget:self action:@selector(pinchDetected:)];
    
    [self addGestureRecognizer:tapRecognizer];
    [self addGestureRecognizer:panRecognizer];
    [self addGestureRecognizer:pinchRecognizer];
    
    panRecognizer.delegate = self;
    pinchRecognizer.delegate = self;
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}


- (void)tapDetected:(UITapGestureRecognizer *)tapGesture
{
    if (self.creatingGateView)
    {
        return;
    }
    CGPoint tapPoint = [tapGesture locationInView:self];
    GateView *tappedGateView = nil;
    
    for (UIView *aView in self.subviews)
    {
        if (tappedGateView == nil
            && [aView isKindOfClass:GateView.class])
        {
            GateView *gateView = (GateView *)aView;
            CGPoint convertedPoint = [self convertPoint:tapPoint toView:gateView];

            if ([gateView gateContainsPoint:convertedPoint])
            {
                tappedGateView = gateView;
                [(GateView *)aView setSelectedState];
            }
            else
            {
                [(GateView *)aView unSelect];
            }
        }
        else
        {
            if ([aView isKindOfClass:GateView.class])
            {
                [(GateView *)aView unSelect];
            }
        }
    }
    self.selectedGateView = tappedGateView;
}


- (void)panDetected:(UIPanGestureRecognizer *)panGesture
{
    if (self.creatingGateView)
    {
        CGPoint location = [panGesture locationInView:self.creatingGateView];
        
        switch (panGesture.state)
        {
            case UIGestureRecognizerStateBegan:
                [self.creatingGateView panBegan:location];
                break;
                
            case UIGestureRecognizerStateChanged:
                [self.creatingGateView panChanged:location];
                break;
                
            case UIGestureRecognizerStateEnded:
                [self.creatingGateView panEnded:location];
                [self _reportGateChangeForGateView:self.creatingGateView];
                self.creatingGateView = nil;
                break;
                
            default:
                break;
        }
    }
    else if (self.selectedGateView)
    {
        CGPoint tranlation;
        CGPoint viewPosition;
        
        switch (panGesture.state)
        {
            case UIGestureRecognizerStateBegan:
            case UIGestureRecognizerStateChanged:
                tranlation = [panGesture translationInView:self];
                viewPosition = self.selectedGateView.center;
                viewPosition.x += tranlation.x;
                viewPosition.y += tranlation.y;
                self.selectedGateView.center = viewPosition;
                
                break;
                
            case UIGestureRecognizerStateEnded:
                [self _reportGateChangeForGateView:self.selectedGateView];
                NSLog(@"Notify delegate that a gate has moved");
                break;
                
            default:
                break;
        }
    }
    
    [panGesture setTranslation:CGPointZero inView:self];
}


- (void)pinchDetected:(UIPinchGestureRecognizer *)pinchRecognizer
{
    if (self.creatingGateView)
    {
        return;
    }
    
    if (self.selectedGateView)
    {
        CGFloat scale = pinchRecognizer.scale;
        
        switch (pinchRecognizer.state)
        {
            case UIGestureRecognizerStateBegan:
            case UIGestureRecognizerStateChanged:
                if ([self.selectedGateView isKindOfClass:SingleGateView.class])
                {
                    [(SingleGateView *)self.selectedGateView updateWithPinch:scale];
                }
                break;
                
            case UIGestureRecognizerStateEnded:
                // [self.delegate markView:self changedBoundsForGate:gate];
                NSLog(@"Notify delegate that a gate has resized");
                break;
                
            default:
                break;
                
        }
        pinchRecognizer.scale = 1.0;
    }
}



/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
