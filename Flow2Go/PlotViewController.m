//
//  PlotViewController.m
//  Flow2Go
//
//  Created by Christian Hansen on 03/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "PlotViewController.h"
#import "FCSFile.h"
#import "FCSGraphView.h"
#import "GateCalculator.h"
#import "Gate.h"
#import "GraphPoint.h"
#import "Plot.h"

@interface PlotViewController () {
    NSInteger _xParIndex;
    NSInteger _yParIndex;
}

@property (nonatomic, strong) GateCalculator *parentGateCalculator;
@property (nonatomic, strong) CPTXYGraph *graph;
@property (nonatomic, strong) CPTScatterPlot *scatterPlot;
@property (nonatomic, strong) CPTXYPlotSpace *plotSpace;
@property (nonatomic, strong) FCSFile *fcsFile;
@property (nonatomic, strong) NSOperationQueue *parseQueue;
@property (nonatomic) NSUInteger numberOfEventsToPlot;

@end

@implementation PlotViewController

#define X_AXIS_SHEET 1
#define Y_AXIS_SHEET 2

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.navigationItem.rightBarButtonItem = [UIBarButtonItem.alloc initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                        target:self
                                                                                        action:@selector(doneTapped)];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self _configureButtons];

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self _insertGraph];
    [self _insertScatterPlot];
    [self _updateAxisAndPlotRange];
    self.markView.delegate = self;
    [self.markView reloadPaths];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)_configureButtons
{
    [self.xAxisButton setTitle:self.plot.xParName forState:UIControlStateNormal];
    [self.yAxisButton setTitle:self.plot.yParName forState:UIControlStateNormal];
}

- (void)doneTapped
{
    [self.parseQueue cancelAllOperations];
    for (UIView *aSubView in self.view.subviews)
    {
        [aSubView removeFromSuperview];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)xAxisTapped:(id)sender
{
    [self _showAxisPicker:X_AXIS_SHEET fromButton:sender];
}


- (IBAction)yAxisTapped:(id)sender
{
    [self _showAxisPicker:Y_AXIS_SHEET fromButton:sender];
}


- (void)_showAxisPicker:(NSInteger)axisNumber fromButton:(UIButton *)axisButton
{
    UIActionSheet *axisPickerSheet = [UIActionSheet.alloc initWithTitle:nil
                                                               delegate:self
                                                      cancelButtonTitle:nil
                                                 destructiveButtonTitle:nil
                                                      otherButtonTitles:nil];
    axisPickerSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    axisPickerSheet.tag = axisNumber;
    
    for (NSUInteger parIndex = 0; parIndex < [self.fcsFile.text[@"$PAR"] integerValue]; parIndex++)
    {
        [axisPickerSheet addButtonWithTitle:[FCSFile parameterNameForParameterIndex:parIndex inFCSFile:self.fcsFile]];
    }
    [axisPickerSheet showFromRect:axisButton.frame inView:self.graphHostingView animated:YES];
}


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex < 0)
    {
        return;
    }
    if (actionSheet.tag == X_AXIS_SHEET)
    {
        self.plot.xParNumber = [NSNumber numberWithInteger:buttonIndex + 1];
        _xParIndex = self.plot.xParNumber.integerValue - 1;
        [self.xAxisButton setTitle:self.plot.xParName forState:UIControlStateNormal];
    }
    else if (actionSheet.tag == Y_AXIS_SHEET)
    {
        self.plot.yParNumber = [NSNumber numberWithInteger:buttonIndex + 1];
        _yParIndex = self.plot.yParNumber.integerValue - 1;
        [self.yAxisButton setTitle:self.plot.yParName forState:UIControlStateNormal];
    }
    [self _updateAxisAndPlotRange];
    [self.graph reloadData];
    [self.markView reloadPaths];
    [self.plot.managedObjectContext save];
}


- (void)_insertGraph
{    
    self.graph = [CPTXYGraph.alloc initWithFrame:self.graphHostingView.bounds];
    [self.graph applyTheme:[CPTTheme themeNamed:kCPTDarkGradientTheme]];
    self.graphHostingView.hostedGraph = _graph;
}

- (void)_insertScatterPlot
{    
    // Add plot space for horizontal bar charts
    self.plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
    self.plotSpace.allowsUserInteraction = YES;
    self.plotSpace.delegate = self;
    
    CPTScatterPlot *scatterPlot = [CPTScatterPlot.alloc init];
    scatterPlot.dataSource = self;
    scatterPlot.delegate = self;
    scatterPlot.identifier = @"Scatter Plot 1";
    scatterPlot.dataLineStyle = nil;
    scatterPlot.plotSymbolMarginForHitDetection = 5.0;
    
    [self.graph addPlot:scatterPlot toPlotSpace:self.plotSpace];
}

- (void)_updateAxisAndPlotRange
{
    NSInteger xParRange = [self.fcsFile rangeOfParameterIndex:self.plot.xParNumber.integerValue - 1];
    NSInteger yParRange = [self.fcsFile rangeOfParameterIndex:self.plot.yParNumber.integerValue - 1];
    
//    NSArray *xAxisComponents = [self.fcsFile amplificationComponentsForParameterIndex:self.plot.xParNumber.integerValue - 1];
//    if ([xAxisComponents[0] integerValue] == 0)
//    {
//        self.plotSpace.xScaleType = CPTScaleTypeLinear;
//    }
//    else
//    {
//        self.plotSpace.xScaleType = CPTScaleTypeLog;
//    }
//    
//    NSArray *yAxisComponents = [self.fcsFile amplificationComponentsForParameterIndex:self.plot.yParNumber.integerValue - 1];
//    if ([yAxisComponents[0] integerValue] == 0)
//    {
//        self.plotSpace.yScaleType = CPTScaleTypeLinear;
//    }
//    else
//    {
//        self.plotSpace.yScaleType = CPTScaleTypeLog;
//    }
    
    self.plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInteger(- xParRange / 20) length:CPTDecimalFromInteger(xParRange + xParRange / 20)];
    self.plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInteger(- yParRange / 20) length:CPTDecimalFromInteger(yParRange + yParRange / 20)];
    
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
    CPTXYAxis *x = axisSet.xAxis;
    x.axisLineStyle = nil;
    x.majorTickLineStyle = nil;
    x.minorTickLineStyle = nil;
    x.majorIntervalLength = CPTDecimalFromInteger(xParRange / 5);
    x.orthogonalCoordinateDecimal = CPTDecimalFromString(@"0");
    x.title = nil;
    x.labelRotation = M_PI/4;
    x.axisConstraints = [CPTConstraints constraintWithLowerOffset:45.0f];
    
    CPTXYAxis *y = axisSet.yAxis;
    y.axisLineStyle = nil;
    y.majorTickLineStyle = nil;
    y.minorTickLineStyle = nil;
    y.majorIntervalLength = CPTDecimalFromInteger(yParRange / 5);
    y.orthogonalCoordinateDecimal = CPTDecimalFromString(@"0");
    y.title = nil;
    y.axisConstraints = [CPTConstraints constraintWithLowerOffset:50.0f];
}


- (void)prepareDataForPlot
{
    if (!self.plot)
    {
        NSLog(@"plot was nil");
        return;
    }        
    self.fcsFile = [self.delegate fcsFile:self];
    [self _setAxisIfNeeded];
    _xParIndex = self.plot.xParNumber.integerValue - 1;
    _yParIndex = self.plot.yParNumber.integerValue - 1;
    
    Gate *parentGate = (Gate *)self.plot.parentNode;
    
    if (parentGate)
    {
        self.parentGateCalculator = [GateCalculator.alloc init];
        self.parentGateCalculator.eventsInside = calloc(parentGate.cellCount.integerValue, sizeof(NSUInteger *));
        self.parentGateCalculator.numberOfCellsInside = parentGate.cellCount.integerValue;
        NSData *data = parentGate.subSet;
        NSUInteger len = [data length];
        
        memcpy(self.parentGateCalculator.eventsInside, [data bytes], len);
        
        self.numberOfEventsToPlot = parentGate.cellCount.integerValue;
    }
    else
    {
        self.numberOfEventsToPlot = self.fcsFile.noOfEvents;
    }
}


- (void)_setAxisIfNeeded
{
    if (self.plot.xParNumber.integerValue < 1)
    {
        self.plot.xParNumber = [NSNumber numberWithInteger:1];
    }
    if (self.plot.yParNumber.integerValue < 1)
    {
        self.plot.yParNumber = [NSNumber numberWithInteger:2];
    }
    [self.plot.managedObjectContext save];
}

#pragma mark - CPT Plot Data Source
- (NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    return self.numberOfEventsToPlot;
}

- (double)doubleForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    switch (fieldEnum)
    {
        case CPTCoordinateX:
            if (self.parentGateCalculator)
            {
                return (double)self.fcsFile.event[self.parentGateCalculator.eventsInside[index]][_xParIndex];
            }
            return (double)self.fcsFile.event[index][_xParIndex];
            break;
            
        case CPTCoordinateY:
            if (self.parentGateCalculator)
            {
                return (double)self.fcsFile.event[self.parentGateCalculator.eventsInside[index]][_yParIndex];
            }
            return (double)self.fcsFile.event[index][_yParIndex];
            break;
            
        default:
            break;
    }
    return 0.0;
}

#pragma mark - Scatter Plot Delegate
static CPTPlotSymbol *plotSymbol;

#pragma mark - Scatter Plot Datasource
-(CPTPlotSymbol *)symbolForScatterPlot:(CPTScatterPlot *)plot recordIndex:(NSUInteger)index
{
    if (!plotSymbol)
    {
        plotSymbol = [CPTPlotSymbol rectanglePlotSymbol];
        plotSymbol.fill = [CPTFill fillWithColor:[CPTColor colorWithComponentRed:0.7 green:0.7 blue:0.7 alpha:1.0]];
        plotSymbol.lineStyle = nil;
        plotSymbol.size = CGSizeMake(1.0, 1.0);
    }
    return plotSymbol;
}


- (NSArray *)viewVerticesFromGateVertices:(NSArray *)gateVertices inView:(UIView *)aView plotSpace:(CPTPlotSpace *)plotSpace
{
    NSMutableArray *viewVertices = NSMutableArray.array;
    double graphPoint[2];
    
    for (GraphPoint *aPoint in gateVertices)
    {
        graphPoint[0] = aPoint.x;
        graphPoint[1] = aPoint.y;
        CGPoint viewPoint = [plotSpace plotAreaViewPointForDoublePrecisionPlotPoint:graphPoint];
        viewPoint = [self.markView.layer convertPoint:viewPoint fromLayer:self.plotSpace.graph.plotAreaFrame.plotArea];
        
        [viewVertices addObject:[NSValue valueWithCGPoint:viewPoint]];
    }
    return viewVertices;
}


- (NSArray *)gateVerticesFromViewVertices:(NSArray *)vertices inView:(UIView *)aView plotSpace:(CPTPlotSpace *)plotSpace
{
    NSMutableArray *gateVertices = NSMutableArray.array;
    double graphPoint[2];
    
    for (NSValue *aValue in vertices)
    {
        CGPoint pathPoint = aValue.CGPointValue;
        pathPoint = [aView.layer convertPoint:pathPoint toLayer:plotSpace.graph.plotAreaFrame.plotArea];
        [self.plotSpace doublePrecisionPlotPoint:graphPoint forPlotAreaViewPoint:pathPoint];
        
        GraphPoint *gateVertex = [GraphPoint pointWithX:(double)graphPoint[0] andY:(double)graphPoint[1]];
        [gateVertices addObject:gateVertex];
    }    
    return gateVertices;
}


#pragma mark - Mark View Delegate
- (void)didDrawPath:(CGPathRef)pathRef withPoints:(NSArray *)pathPoints insideRect:(CGRect)boundingRect sender:(id)sender
{
    NSArray *gateVertices = [self gateVerticesFromViewVertices:pathPoints inView:sender plotSpace:self.plotSpace];
    
    GateCalculator *gateContents = [GateCalculator eventsInsidePolygon:gateVertices
                                                               fcsFile:self.fcsFile
                                                            insidePlot:self.plot
                                                                subSet:self.parentGateCalculator.eventsInside
                                                           subSetCount:self.parentGateCalculator.numberOfCellsInside];
    
    NSLog(@"gateContents count: %i", gateContents.numberOfCellsInside);
    
    UILabel *numberLabel = (UILabel *)[self.view viewWithTag:99];
    numberLabel.textColor = UIColor.whiteColor;
    numberLabel.text = [NSString stringWithFormat:@"%i cells", gateContents.numberOfCellsInside];
    
    Gate *gate = [Gate createChildGateInPlot:self.plot
                                        type:kGateTypePolygon
                                    vertices:gateVertices];
    gate.subSet = [NSData dataWithBytes:(NSUInteger *)gateContents.eventsInside
                                 length:sizeof(NSUInteger)*gateContents.numberOfCellsInside];
    gate.cellCount = [NSNumber numberWithInteger:gateContents.numberOfCellsInside];
    //[gate.managedObjectContext save];
    //gate.parentNode = self.plot;

    [self.plot.managedObjectContext save];
    
}


- (void)didDoubleTapPathNumber:(NSUInteger)pathNumber
{
    Gate *gate = [self.plot.childNodes objectAtIndex:pathNumber];
    [self.delegate didSelectGate:gate forPlot:self.plot];
}


- (void)didDoubleTapAtPoint:(CGPoint)point
{
    NSLog(@"Tapped    point         :%@", NSStringFromCGPoint(point));
    
    point = [self.markView.layer convertPoint:point toLayer:self.plotSpace.graph.plotAreaFrame.plotArea];
    NSLog(@"Plot Area point         :%@", NSStringFromCGPoint(point));

    double graphPoint[2];
    [self.plotSpace doublePrecisionPlotPoint:graphPoint forPlotAreaViewPoint:point];
    NSLog(@"Data point              :{%.1f,%.1f}", graphPoint[0], graphPoint[1]);
    
    point = [self.plotSpace plotAreaViewPointForDoublePrecisionPlotPoint:graphPoint];
    NSLog(@"Back to plot Area point :%@", NSStringFromCGPoint(point));

    
    point = [self.markView.layer convertPoint:point fromLayer:self.plotSpace.graph.plotAreaFrame.plotArea];
    NSLog(@"Back to tapped point    :%@", NSStringFromCGPoint(point));
}


#pragma mark Mark View Datasource
- (NSUInteger)numberOfPathsInMarkView:(id)sender
{
    NSArray *relevantGates = [self.plot childGatesForXPar:self.plot.xParNumber.integerValue
                                          andYPar:self.plot.yParNumber.integerValue];
    return relevantGates.count;
}


- (NSArray *)verticesForPath:(NSUInteger)pathNo inView:(id)sender
{
    NSArray *relevantGates = [self.plot childGatesForXPar:self.plot.xParNumber.integerValue
                                                  andYPar:self.plot.yParNumber.integerValue];
    Gate *gate = relevantGates[pathNo];

    if (gate.xParNumber.integerValue == self.plot.xParNumber.integerValue)
    {
        return [self viewVerticesFromGateVertices:gate.vertices
                                           inView:self.markView
                                        plotSpace:self.plotSpace];
    }
    else
    {
        return [self viewVerticesFromGateVertices:[GraphPoint switchXandYForGraphpoints:gate.vertices]
                                           inView:self.markView
                                        plotSpace:self.plotSpace];
    }
}

@end
