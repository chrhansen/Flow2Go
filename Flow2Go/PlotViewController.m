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

@property (nonatomic, strong) Plot *plot;
@property (nonatomic, strong) GateCalculator *gateCalculator;
@property (nonatomic, strong) CPTXYGraph *graph;
@property (nonatomic, strong) CPTScatterPlot *scatterPlot;
@property (nonatomic, strong) CPTXYPlotSpace *plotSpace;
@property (nonatomic, strong) FCSFile *fcsFile;
@property (nonatomic, strong) NSOperationQueue *parseQueue;
@property (nonatomic, strong) Measurement *measurement;
@property (nonatomic) NSUInteger numberOfEventsToPlot;
@property (nonatomic, strong) UIActionSheet *xAxisActionSheet;
@property (nonatomic, strong) UIActionSheet *yAxisActionSheet;

@end

@implementation PlotViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.navigationItem.rightBarButtonItem = [UIBarButtonItem.alloc initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                        target:self
                                                                                        action:@selector(doneTapped)];
    self.markView.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self _insertGraph];
    [self _insertScatterPlot];
    [self.markView drawPaths];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    self.xAxisActionSheet = [UIActionSheet.alloc initWithTitle:nil
                                                      delegate:self
                                             cancelButtonTitle:nil
                                        destructiveButtonTitle:nil
                                             otherButtonTitles:nil];
    [self _showAxisPicker:self.xAxisActionSheet fromButton:sender];
}


- (IBAction)yAxisTapped:(id)sender
{
    self.yAxisActionSheet = [UIActionSheet.alloc initWithTitle:nil
                                                      delegate:self
                                             cancelButtonTitle:nil
                                        destructiveButtonTitle:nil
                                             otherButtonTitles:nil];
    [self _showAxisPicker:self.yAxisActionSheet fromButton:sender];
}


- (void)_showAxisPicker:(UIActionSheet *)actionSheet fromButton:(UIButton *)axisButton
{
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    
    for (NSUInteger parIndex = 0; parIndex < [self.fcsFile.text[@"$PAR"] integerValue]; parIndex++)
    {
        [actionSheet addButtonWithTitle:[FCSFile parameterNameForParameterIndex:parIndex inFCSFile:self.fcsFile]];
    }
    [actionSheet showFromRect:axisButton.frame inView:graphView animated:YES];
}


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex < 0)
    {
        return;
    }
    if (actionSheet == self.xAxisActionSheet)
    {
        self.plot.xParNumber = [NSNumber numberWithInteger:buttonIndex + 1];
        _xParIndex = self.plot.xParNumber.integerValue - 1;
        self.plot.xParName = [FCSFile parameterShortNameForParameterIndex:buttonIndex
                                                                inFCSFile:self.fcsFile];
    }
    else if (actionSheet == self.yAxisActionSheet)
    {
        self.plot.yParNumber = [NSNumber numberWithInteger:buttonIndex + 1];
        _yParIndex = self.plot.yParNumber.integerValue - 1;
        self.plot.yParName = [FCSFile parameterShortNameForParameterIndex:buttonIndex
                                                                inFCSFile:self.fcsFile];
    }
    [self.graph reloadData];
    [self.plot.managedObjectContext save];
}


- (void)_insertGraph
{
    self.graph = [CPTXYGraph.alloc initWithFrame:graphView.frame];
    CPTTheme *theme = [CPTTheme themeNamed:kCPTDarkGradientTheme];
    [self.graph applyTheme:theme];
    
    CPTGraphHostingView *newHostingView = [CPTGraphHostingView.alloc initWithFrame:graphView.bounds];
    newHostingView.hostedGraph = _graph;
    [graphView addSubview:newHostingView];
    newHostingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    [graphView sendSubviewToBack:newHostingView];

}

- (void)_insertScatterPlot
{    
    // Add plot space for horizontal bar charts
    self.plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
    self.plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInteger(0) length:CPTDecimalFromInteger(1024)];
    self.plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInteger(0) length:CPTDecimalFromInteger(1024)];
    self.plotSpace.allowsUserInteraction = YES;
    self.plotSpace.delegate = self;
    
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
    CPTXYAxis *x = axisSet.xAxis;
    x.axisLineStyle = nil;
    x.majorTickLineStyle = nil;
    x.minorTickLineStyle = nil;
    x.majorIntervalLength = CPTDecimalFromString(@"200");
    x.orthogonalCoordinateDecimal = CPTDecimalFromString(@"0");
    x.title = @"";
    x.titleOffset = 45.0f;
    x.titleLocation = CPTDecimalFromFloat(500.0f);
    x.labelRotation = M_PI/4;
    x.axisConstraints = [CPTConstraints constraintWithLowerOffset:45.0f];
    
    CPTXYAxis *y = axisSet.yAxis;
    y.axisLineStyle = nil;
    y.majorTickLineStyle = nil;
    y.minorTickLineStyle = nil;
    y.majorIntervalLength = CPTDecimalFromString(@"200");
    y.orthogonalCoordinateDecimal = CPTDecimalFromString(@"0");
    y.title = @"";
    y.titleOffset = 50.0f;
    y.titleLocation = CPTDecimalFromFloat(500.0f);
    y.axisConstraints = [CPTConstraints constraintWithLowerOffset:50.0f];

    
    CPTScatterPlot *scatterPlot = [CPTScatterPlot.alloc init];
    scatterPlot.dataSource = self;
    scatterPlot.delegate = self;
    scatterPlot.identifier = @"Scatter Plot 1";
    scatterPlot.dataLineStyle = nil;
    scatterPlot.plotSymbolMarginForHitDetection = 5.0;
    
    [self.graph addPlot:scatterPlot toPlotSpace:self.plotSpace];
}


- (void)showPlot:(Plot *)plot forMeasurement:(Measurement *)aMeasurement
{
    if (!plot)
    {
        NSLog(@"plot was nil");
        plot = [Plot createEntity];
    }
    self.plot = plot;
    
    [self _setAxisIfNeeded];
    
    self.fcsFile = [self.delegate fcsFile:self];
    
    Gate *parentGate = (Gate *)self.plot.parentNode;
    
    if (parentGate)
    {
        self.gateCalculator = [GateCalculator gateWithVertices:parentGate.vertices
                                                      onEvents:self.fcsFile
                                                        xParam:self.plot.xParNumber.integerValue - 1
                                                        yParam:self.plot.yParNumber.integerValue - 1];
        self.numberOfEventsToPlot = parentGate.cellCount.integerValue;
    }
    else
    {
        self.numberOfEventsToPlot = self.fcsFile.noOfEvents;
    }
    [self.graph reloadData];
}


- (void)_setAxisIfNeeded
{
    if (self.plot.xParNumber.integerValue < 1)
    {
        self.plot.xParNumber = [NSNumber numberWithInteger:1];
        NSLog(@"setting default x-axis");
    }
    if (self.plot.yParNumber.integerValue < 1)
    {
        self.plot.yParNumber = [NSNumber numberWithInteger:2];
        NSLog(@"setting default y-axis");
    }
    [self.plot.managedObjectContext save];
    _xParIndex = self.plot.xParNumber.integerValue - 1;
    _yParIndex = self.plot.yParNumber.integerValue - 1;
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
            if (self.plot.parentNode)
            {
                return (double)self.fcsFile.event[self.gateCalculator.eventsInside[index]][_xParIndex];
            }
            return (double)self.fcsFile.event[index][_xParIndex];
            break;
            
        case CPTCoordinateY:
            if (self.plot.parentNode)
            {
                return (double)self.fcsFile.event[self.gateCalculator.eventsInside[index]][_yParIndex];
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

- (CGPoint)convertYAxis:(CGPoint)aPoint inView:(UIView *)aView
{
    aPoint.y = aView.frame.size.height - aPoint.y;
    return aPoint;
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
        viewPoint = [self convertYAxis:viewPoint inView:aView];
        [viewVertices addObject:[NSValue valueWithCGPoint:viewPoint]];
    }
    [viewVertices removeLastObject];
    return viewVertices;
}


- (NSArray *)gateVerticesFromViewVertices:(NSArray *)vertices inView:(UIView *)aView plotSpace:(CPTPlotSpace *)plotSpace
{
    NSMutableArray *gateVertices = NSMutableArray.array;
    double graphPoint[2];
    
    for (NSValue *aValue in vertices)
    {
        CGPoint pathPoint = aValue.CGPointValue;
        [self.plotSpace doublePrecisionPlotPoint:graphPoint
                            forPlotAreaViewPoint:[self convertYAxis:pathPoint inView:aView]];
        GraphPoint *gateVertex = [GraphPoint pointWithX:(double)graphPoint[0]
                                                   andY:(double)graphPoint[1]];
        [gateVertices addObject:gateVertex];
        
    }
    [gateVertices addObject:gateVertices[0]];
    
    return gateVertices;
}


#pragma mark - Mark View Delegate
- (void)didDrawPath:(CGPathRef)pathRef withPoints:(NSArray *)pathPoints insideRect:(CGRect)boundingRect sender:(id)sender
{
    NSArray *gateVertices = [self gateVerticesFromViewVertices:pathPoints inView:sender plotSpace:self.plotSpace];
    
    GateCalculator *gateContents = [GateCalculator gateWithVertices:gateVertices
                                                           onEvents:self.fcsFile
                                                             xParam:self.plot.xParNumber.integerValue - 1
                                                             yParam:self.plot.yParNumber.integerValue - 1];
    NSLog(@"gateContents count: %i", gateContents.numberOfCellsInside);
    
    UILabel *numberLabel = (UILabel *)[self.view viewWithTag:99];
    numberLabel.textColor = UIColor.whiteColor;
    numberLabel.text = [NSString stringWithFormat:@"%i cells", gateContents.numberOfCellsInside];

    
    Gate *gate = [Gate createChildGateInPlot:self.plot
                                        type:kGateTypePolygon
                                    vertices:gateVertices];
    gate.cellCount = [NSNumber numberWithInteger:gateContents.numberOfCellsInside];

    [self.plot.managedObjectContext save];
}


- (void)didDoubleTapPathNumber:(NSUInteger)pathNumber
{
    Gate *gate = [self.plot.childNodes objectAtIndex:pathNumber];
    [self.delegate didSelectGate:gate forPlot:self.plot];
}


#pragma mark Mark View Datasource
- (NSUInteger)numberOfPathsInMarkView:(id)sender
{
    return self.plot.childNodes.count;
}


- (NSArray *)verticesForPath:(NSUInteger)pathNo inView:(id)sender
{
    Gate *gate = [self.plot.childNodes objectAtIndex:pathNo];
    return [self viewVerticesFromGateVertices:gate.vertices
                                       inView:self.markView
                                    plotSpace:self.plotSpace];
}

@end
