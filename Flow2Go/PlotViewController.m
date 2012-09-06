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
#import "DensityPlotData.h"
#import "GateTableViewController.h"
#import "PlotDetailTableViewController.h"

@interface PlotViewController () <GateTableViewControllerDelegate, UIPopoverControllerDelegate>
{
    NSInteger _xParIndex;
    NSInteger _yParIndex;
}

@property (nonatomic, strong) GateCalculator *parentGateCalculator;
@property (nonatomic, strong) CPTXYGraph *graph;
@property (nonatomic, strong) CPTScatterPlot *scatterPlot;
@property (nonatomic, strong) CPTXYPlotSpace *plotSpace;
@property (nonatomic, strong) FCSFile *fcsFile;
@property (nonatomic, strong) DensityPlotData *densityPlotData;
@property (nonatomic, strong) UIPopoverController *detailPopoverController;

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
    
    self.title = self.plot.name;
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
    [self.markView performSelector:@selector(reloadPaths) withObject:nil afterDelay:0.05];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.detailPopoverController dismissPopoverAnimated:YES];
    [super viewWillDisappear:animated];
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
    UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
    [infoButton addTarget:self action:@selector(_toggleInfo:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem  = [UIBarButtonItem.alloc initWithCustomView: infoButton];
}

- (void)doneTapped
{
    [self _removeSubviews];
    [self.detailPopoverController dismissPopoverAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)_removeSubviews
{
    for (UIView *aSubView in self.view.subviews)
    {
        [aSubView removeFromSuperview];
    }
}


- (void)_toggleInfo:(id)sender
{
    UINavigationController *plotNavigationVC = [self.storyboard instantiateViewControllerWithIdentifier:@"plotDetailTableViewController"];
    PlotDetailTableViewController *plotTVC = (PlotDetailTableViewController *)plotNavigationVC.topViewController;
    plotTVC.delegate = self.delegate;
    plotTVC.plot = self.plot;
    [plotTVC setEditing:NO animated:NO];
    if (self.detailPopoverController.isPopoverVisible)
    {
        UINavigationController *navigationController = (UINavigationController *)self.detailPopoverController.contentViewController;
        if (!navigationController.topViewController.editing)
        {
            [self.detailPopoverController dismissPopoverAnimated:YES];
        }
        return;
    }
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        self.detailPopoverController = [UIPopoverController.alloc initWithContentViewController:plotNavigationVC];
        [self.detailPopoverController presentPopoverFromBarButtonItem:self.navigationItem.leftBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        self.detailPopoverController.delegate = self;
    }
    else if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        [self presentViewController:plotNavigationVC animated:NO completion:nil];
    }
}

#pragma mark - Popover Controller Delegate
- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
    UINavigationController *navigationController = (UINavigationController *)popoverController.contentViewController;
    return !navigationController.topViewController.editing;
}

#pragma mark - Axis Picking
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
                                                      cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
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
    if (buttonIndex <= 0)
    {
        return;
    }
    if (actionSheet.tag == X_AXIS_SHEET)
    {
        self.plot.xParNumber = [NSNumber numberWithInteger:buttonIndex];
        _xParIndex = self.plot.xParNumber.integerValue - 1;
        [self.xAxisButton setTitle:self.plot.xParName forState:UIControlStateNormal];
    }
    else if (actionSheet.tag == Y_AXIS_SHEET)
    {
        self.plot.yParNumber = [NSNumber numberWithInteger:buttonIndex];
        _yParIndex = self.plot.yParNumber.integerValue - 1;
        [self.yAxisButton setTitle:self.plot.yParName forState:UIControlStateNormal];
    }
    [self _updateAxisAndPlotRange];
#warning refactor to have central place where data is prepared after changes
    [self prepareDataForPlot];
    
    [self.graph reloadData];
    [self.markView reloadPaths];
    [self.plot.managedObjectContext save];
}


- (void)_insertGraph
{    
    self.graph = [CPTXYGraph.alloc initWithFrame:self.graphHostingView.bounds];
    [self.graph applyTheme:[CPTTheme themeNamed:kCPTSlateTheme]];
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
    }
    
    self.densityPlotData = [DensityPlotData densityForPointsygonInFcsFile:self.fcsFile
                                                               insidePlot:self.plot
                                                                   subSet:self.parentGateCalculator.eventsInside
                                                              subSetCount:self.parentGateCalculator.numberOfCellsInside];
    [self.graph reloadData];
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
    if (self.densityPlotData)
    {
        return self.densityPlotData.numberOfPoints;
    }
    else if (self.parentGateCalculator)
    {
        return self.parentGateCalculator.numberOfCellsInside;
    }

    return self.fcsFile.noOfEvents;
}

- (double)doubleForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    switch (fieldEnum)
    {
        case CPTCoordinateX:
            if (self.densityPlotData)
            {
                return self.densityPlotData.points[index].xVal;

            }
            if (self.parentGateCalculator)
            {
                return (double)self.fcsFile.event[self.parentGateCalculator.eventsInside[index]][_xParIndex];
            }
            return (double)self.fcsFile.event[index][_xParIndex];
            break;
            
        case CPTCoordinateY:
            if (self.densityPlotData)
            {
                return self.densityPlotData.points[index].yVal;

            }
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

static NSArray *plotSymbols;

#pragma mark - Scatter Plot Datasource
-(CPTPlotSymbol *)symbolForScatterPlot:(CPTScatterPlot *)plot recordIndex:(NSUInteger)index
{
    if (self.densityPlotData)
    {
        if (!plotSymbols)
        {
            plotSymbols = [self plotSymbols];
        }
        
        //NSInteger cellCount = self.densityPlotData.points[index].count;
        NSInteger cellCount = self.densityPlotData.points[index].count;
        
        if (cellCount == 0) {
            return nil;
        }
        if (cellCount < self.densityPlotData.countForMaxBin * 0.01) {
            return plotSymbols[0];
        }
        if (cellCount < self.densityPlotData.countForMaxBin * 0.2) {
            return plotSymbols[1];
        }
        if (cellCount < self.densityPlotData.countForMaxBin * 0.5) {
            return plotSymbols[2];
        }
        if (cellCount < self.densityPlotData.countForMaxBin * 0.7) {
            return plotSymbols[3];
        }
        if (cellCount >= self.densityPlotData.countForMaxBin * 0.85) {
            return plotSymbols[4];
        }
    }
    
    if (!plotSymbol)
    {
        plotSymbol = [CPTPlotSymbol ellipsePlotSymbol];
        plotSymbol.fill = [CPTFill fillWithColor:[CPTColor colorWithComponentRed:0.7 green:0.7 blue:0.7 alpha:1.0]];
        plotSymbol.lineStyle = nil;
        plotSymbol.size = CGSizeMake(2.0, 2.0);
    }
    return plotSymbol;
    
}

#define COLOR_LEVELS 4

- (NSArray *)plotSymbols
{
    NSMutableArray *symbols = NSMutableArray.array;

    CPTPlotSymbol *blueSymbol = [CPTPlotSymbol ellipsePlotSymbol];
    blueSymbol.fill = [CPTFill fillWithColor:[CPTColor colorWithComponentRed:0.0 green:0.0 blue:1.0 alpha:1.0]];
    blueSymbol.lineStyle = nil;
    blueSymbol.size = CGSizeMake(4.0, 4.0);
        
    CPTPlotSymbol *greenSymbol = [CPTPlotSymbol ellipsePlotSymbol];
    greenSymbol.fill = [CPTFill fillWithColor:[CPTColor colorWithComponentRed:50.0/255.0 green:205.0/255.0 blue:50.0/255.0 alpha:1.0]];
    greenSymbol.lineStyle = nil;
    greenSymbol.size = CGSizeMake(4.0, 4.0);
    
    CPTPlotSymbol *yellowSymbol = [CPTPlotSymbol ellipsePlotSymbol];
    yellowSymbol.fill = [CPTFill fillWithColor:[CPTColor colorWithComponentRed:1.0 green:1.0 blue:0.0 alpha:1.0]];
    yellowSymbol.lineStyle = nil;
    yellowSymbol.size = CGSizeMake(4.0, 4.0);
    
    CPTPlotSymbol *orangeSymbol = [CPTPlotSymbol ellipsePlotSymbol];
    orangeSymbol.fill = [CPTFill fillWithColor:[CPTColor colorWithComponentRed:1.0 green:165.0/255.0 blue:0.0 alpha:1.0]];
    orangeSymbol.lineStyle = nil;
    orangeSymbol.size = CGSizeMake(4.0, 4.0);
    
    CPTPlotSymbol *redSymbol = [CPTPlotSymbol ellipsePlotSymbol];
    redSymbol.fill = [CPTFill fillWithColor:[CPTColor colorWithComponentRed:1.0 green:0.0 blue:0.0 alpha:1.0]];
    redSymbol.lineStyle = nil;
    redSymbol.size = CGSizeMake(4.0, 4.0);
    
    [symbols addObject:blueSymbol];
    [symbols addObject:greenSymbol];
    [symbols addObject:yellowSymbol];
    [symbols addObject:orangeSymbol];
    [symbols addObject:redSymbol];
    
    return symbols;
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
- (void)didDrawPathWithPoints:(NSArray *)pathPoints infoButton:(UIButton *)infoButton sender:(id)sender
{ 
    NSArray *gateVertices = [self gateVerticesFromViewVertices:pathPoints inView:sender plotSpace:self.plotSpace];
    
    GateCalculator *gateContents = [GateCalculator eventsInsidePolygon:gateVertices
                                                               fcsFile:self.fcsFile
                                                            insidePlot:self.plot
                                                                subSet:self.parentGateCalculator.eventsInside
                                                           subSetCount:self.parentGateCalculator.numberOfCellsInside];
       
    Gate *gate = [Gate createChildGateInPlot:self.plot
                                        type:kGateTypePolygon
                                    vertices:gateVertices];
    gate.subSet = [NSData dataWithBytes:(NSUInteger *)gateContents.eventsInside length:sizeof(NSUInteger)*gateContents.numberOfCellsInside];
    gate.cellCount = [NSNumber numberWithInteger:gateContents.numberOfCellsInside];

    [self.plot.managedObjectContext save];
    
    [self showDetailPopoverForGate:gate inRect:infoButton.frame editMode:YES];
}


- (void)didTapInfoButtonForPath:(UIButton *)buttonWithTagNumber
{
    NSArray *displayedGates = [self.plot childGatesForXPar:self.plot.xParNumber.integerValue
                                                   andYPar:self.plot.yParNumber.integerValue];
    [self showDetailPopoverForGate:displayedGates[buttonWithTagNumber.tag] inRect:buttonWithTagNumber.frame editMode:NO];
}


- (void)showDetailPopoverForGate:(Gate *)gate inRect:(CGRect)anchorFrame editMode:(BOOL)editOn
{
    UINavigationController *gateNavigationVC = [self.storyboard instantiateViewControllerWithIdentifier:@"gateDetailTableViewController"];
    GateTableViewController *gateTVC = (GateTableViewController *)gateNavigationVC.topViewController;
    gateTVC.delegate = self;
    gateTVC.gate = gate;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        if (self.detailPopoverController.isPopoverVisible)
        {
            [self.detailPopoverController dismissPopoverAnimated:YES];
        }
        self.detailPopoverController = [UIPopoverController.alloc initWithContentViewController:gateNavigationVC];
        [self.detailPopoverController presentPopoverFromRect:anchorFrame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        self.detailPopoverController.delegate = self;
        [gateTVC setEditing:editOn animated:NO];
        
        return;
    }
    [self presentViewController:gateNavigationVC animated:YES completion:nil];
    [gateTVC setEditing:editOn animated:NO];
}


#pragma mark - Mark View Datasource
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


#pragma mark - Gate Table View Controller delegate
- (void)didTapNewPlot:(GateTableViewController *)sender
{
    
    [self.detailPopoverController dismissPopoverAnimated:YES];
    
    [self.delegate didSelectGate:sender.gate forPlot:self.plot];
}

- (void)didTapDeleteGate:(GateTableViewController *)sender
{
    if (self.detailPopoverController.isPopoverVisible) {
        [self.detailPopoverController dismissPopoverAnimated:YES];
    }
    else if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    Gate *gateToBeDeleted = sender.gate;
    
    BOOL success = [gateToBeDeleted deleteInContext:gateToBeDeleted.managedObjectContext];
    [self.plot.managedObjectContext save];
    if (!success)
    {
        UIAlertView *alertView = [UIAlertView.alloc initWithTitle:NSLocalizedString(@"Error", nil)
                                                          message:[NSLocalizedString(@"Could not delete gate \"", nil) stringByAppendingFormat:@"%@\"", gateToBeDeleted.name]
                                                         delegate:nil
                                                cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                otherButtonTitles: nil];
        [alertView show];
    }
    else
    {
        [self.markView reloadPaths];
    }
    [self.delegate didDeleteGate:gateToBeDeleted];
}

@end
