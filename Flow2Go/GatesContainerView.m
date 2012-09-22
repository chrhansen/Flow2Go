//
//  GatesContainerViewNew.m
//  Flow2Go
//
//  Created by Christian Hansen on 15/09/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "GatesContainerView.h"
#import "Polygon.h"
#import "SingleRange.h"
#import "Rectangle.h"
#import "Ellipse.h"

@interface GatesContainerView () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSMutableArray *gateGraphics;
@property (nonatomic, strong) GateGraphic *creatingGraphic;
@property (nonatomic, strong) GateGraphic *modifyingGraphic;
@property (nonatomic) NSInteger simultaneousGestures;

@end

@implementation GatesContainerView

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
    }
    return self;
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
}



- (void)removeGateViews
{
    [self.gateGraphics removeAllObjects];
    [self setNeedsDisplay];
}


- (void)_insertExistingGate:(GateType)gateType gateTag:(NSInteger)tagNumber vertices:(NSArray *)vertices
{
    GateGraphic *existingGateGraphic = nil;
    switch (gateType)
    {
        case kGateTypeSingleRange:
            existingGateGraphic = [SingleRange.alloc initWithVertices:vertices];
            existingGateGraphic.gateTag = tagNumber;
            [self.gateGraphics addObject:existingGateGraphic];
            break;
            
        case kGateTypePolygon:
            existingGateGraphic = [Polygon.alloc initWithVertices:vertices];
            existingGateGraphic.gateTag = tagNumber;
            [self.gateGraphics addObject:existingGateGraphic];
            break;
            
        case kGateTypeRectangle:
            existingGateGraphic = [Rectangle.alloc initWithVertices:vertices];
            existingGateGraphic.gateTag = tagNumber;
            [self.gateGraphics addObject:existingGateGraphic];
            break;
            
        case kGateTypeEllipse:
            existingGateGraphic = [Ellipse.alloc initWithVertices:vertices];
            existingGateGraphic.gateTag = tagNumber;
            [self.gateGraphics addObject:existingGateGraphic];
            break;

        default:
            break;
    }
}


- (void)insertNewGate:(GateType)gateType gateTag:(NSInteger)tagNumber
{
    CGFloat leftBound = 0.4 * self.bounds.size.width / 2;
    CGFloat rightBound = 0.6 * self.bounds.size.width / 2;
    CGFloat halfHeight = self.bounds.size.height / 2;
    
    GateGraphic *newGateGraphic = nil;
    
    switch (gateType)
    {
        case kGateTypeSingleRange:
            newGateGraphic = [SingleRange.alloc initWithVertices:@[[NSValue valueWithCGPoint:CGPointMake(leftBound, halfHeight)], [NSValue valueWithCGPoint:CGPointMake(rightBound, halfHeight)]]];
            newGateGraphic.gateTag = tagNumber;
            [self.gateGraphics addObject:newGateGraphic];
            [self.delegate gatesContainerView:self didModifyGateNo:newGateGraphic.gateTag gateType:newGateGraphic.gateType vertices:[newGateGraphic getPathPoints]];
            break;
            
        case kGateTypePolygon:
            self.creatingGraphic = Polygon.alloc.init;
            self.creatingGraphic.gateTag = tagNumber;
            [self.gateGraphics addObject:self.creatingGraphic];
            // report gate change/insert to delegate is carried out after the user has drawin a polygon path.
            break;
            
        case kGateTypeRectangle:
            newGateGraphic = [Rectangle.alloc initWithBoundsOfContainerView:self.bounds];
            newGateGraphic.gateTag = tagNumber;
            [self.gateGraphics addObject:newGateGraphic];
            [self.delegate gatesContainerView:self didModifyGateNo:newGateGraphic.gateTag gateType:newGateGraphic.gateType vertices:[newGateGraphic getPathPoints]];
            break;
            
        case kGateTypeEllipse:
            newGateGraphic = [Ellipse.alloc initWithBoundsOfContainerView:self.bounds];
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
    for (GateGraphic *gateGraphic in self.gateGraphics)
    {
        [gateGraphic.fillColor setFill];
        [gateGraphic.path fillWithBlendMode:kCGBlendModeNormal alpha:0.3];
        [gateGraphic.strokeColor setStroke];
        [gateGraphic.path stroke];
    }
}



#pragma mark - Gesture Recognizer 
#pragma mark Gesture Setup methods
- (void)_addGestures
{
    UITapGestureRecognizer *tapRecognizer = [UITapGestureRecognizer.alloc initWithTarget:self action:@selector(tapDetected:)];

    UITapGestureRecognizer *doubleTapRecognizer = [UITapGestureRecognizer.alloc initWithTarget:self action:@selector(doubleTapDetected:)];
    doubleTapRecognizer.numberOfTapsRequired = 2;
    
    UIPanGestureRecognizer *panRecognizer = [UIPanGestureRecognizer.alloc initWithTarget:self action:@selector(panDetected:)];
    UIPinchGestureRecognizer *pinchRecognizer = [UIPinchGestureRecognizer.alloc initWithTarget:self action:@selector(pinchDetected:)];
    
    [tapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
    
    [self addGestureRecognizer:tapRecognizer];
    [self addGestureRecognizer:doubleTapRecognizer];
    [self addGestureRecognizer:panRecognizer];
    [self addGestureRecognizer:pinchRecognizer];
    
    panRecognizer.delegate = self;
    pinchRecognizer.delegate = self;
    self.simultaneousGestures = 0;
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}


- (GateGraphic *)_gateAtTapPoint:(CGPoint)tapPoint
{
    for (GateGraphic *aGate in self.gateGraphics)
    {
        if ([aGate isContentsUnderPoint:tapPoint])
        {
            return aGate;
        }
    }
    return nil;
}

#pragma mark Gesture Action Methods
- (void)tapDetected:(UITapGestureRecognizer *)tapGesture
{
    if (self.creatingGraphic)
    {
        return;
    }
    
    CGPoint tapPoint = [tapGesture locationInView:self];
    GateGraphic *tappedGate = [self _gateAtTapPoint:tapPoint];
    if (tappedGate)
    {
        CGRect rect = CGRectMake(tapPoint.x, tapPoint.y, 1.0f, 1.0f);
        [self.delegate gatesContainerView:self didTapGate:tappedGate.gateTag inRect:rect];
    }
}


- (void)doubleTapDetected:(UITapGestureRecognizer *)doubleTapGesture
{
    NSLog(@"double tap recognized!");
    CGPoint tapPoint = [doubleTapGesture locationInView:self];
    GateGraphic *doubleTappedGate = [self _gateAtTapPoint:tapPoint];
    if (doubleTappedGate != nil)
    {
        [self.delegate gatesContainerView:self didDoubleTapGate:doubleTappedGate.gateTag];
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
                break;
                
            case UIGestureRecognizerStateChanged:
                [self.creatingGraphic panChangedToPoint:location];
                break;
                
            case UIGestureRecognizerStateEnded:
                [self.creatingGraphic panEndedAtPoint:location];
                [self.delegate gatesContainerView:self didModifyGateNo:self.creatingGraphic.gateTag gateType:self.creatingGraphic.gateType vertices:[self.creatingGraphic getPathPoints]];
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
                    && self.simultaneousGestures == 0)
                {
                    [self.modifyingGraphic.path applyTransform:CGAffineTransformMakeTranslation(tranlation.x, tranlation.y)];
                    [self.delegate gatesContainerView:self didModifyGateNo:self.modifyingGraphic.gateTag gateType:self.modifyingGraphic.gateType vertices:[self.modifyingGraphic getPathPoints]];
                    self.modifyingGraphic = nil;
                }
                break;
                
            default:
                break;
        }    }
    
    
    [self setNeedsDisplay];
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
                [self.modifyingGraphic pinchBeganAtLocation:location withScale:pinchRecognizer.scale];
                break;
                
            case UIGestureRecognizerStateChanged:
                [self.modifyingGraphic pinchChangedAtLocation:location withScale:pinchRecognizer.scale];
                break;
                
            case UIGestureRecognizerStateEnded:
            case UIGestureRecognizerStateFailed:
            case UIGestureRecognizerStateCancelled:
                self.simultaneousGestures -= 1;
                if (self.modifyingGraphic != nil
                    && self.simultaneousGestures == 0)
                {
                    [self.modifyingGraphic pinchEndedAtLocation:location withScale:pinchRecognizer.scale];
                    [self.delegate gatesContainerView:self didModifyGateNo:self.modifyingGraphic.gateTag gateType:self.modifyingGraphic.gateType vertices:[self.modifyingGraphic getPathPoints]];
                    
                    self.modifyingGraphic = nil;
                }
                break;
                
            default:
                break;
                
        }
        [self setNeedsDisplay];
        pinchRecognizer.scale = 1.0;
    }
}



@end
