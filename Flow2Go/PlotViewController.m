//
//  PlotViewController.m
//  Flow2Go
//
//  Created by Christian Hansen on 03/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "PlotViewController.h"
#import "FCSFile.h"
#import "GateCalculator.h"
#import "Gate.h"
#import "GraphPoint.h"
#import "Plot.h"
#import "PlotDataCalculator.h"
#import "GateTableViewController.h"
#import "PlotDetailTableViewController.h"
#import "PlotHelper.h"
#import "AddGateTableViewController.h"
#import "GatesContainerView.h"


@interface PlotViewController () <AddGateTableViewControllerDelegate, GateTableViewControllerDelegate, UIPopoverControllerDelegate>
{
    NSInteger _xParIndex;
    NSInteger _yParIndex;
    PlotType _currentPlotType;
}

@property (nonatomic, strong) GateCalculator *parentGateCalculator;
@property (nonatomic, strong) CPTXYGraph *graph;
@property (nonatomic, strong) CPTXYPlotSpace *plotSpace;
@property (nonatomic, strong) FCSFile *fcsFile;
@property (nonatomic, strong) PlotDataCalculator *plotData;
@property (nonatomic, strong) NSMutableArray *displayedGates;
@property (nonatomic, strong) PlotHelper *plotHelper;
@property (nonatomic, strong) UIPopoverController *detailPopoverController;
@property (weak, nonatomic) IBOutlet UISegmentedControl *plotTypeSegmentedControl;


@end

@implementation PlotViewController

#define X_AXIS_SHEET 1
#define Y_AXIS_SHEET 2

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [UIBarButtonItem.alloc initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                        target:self
                                                                                        action:@selector(doneTapped)];
    if (!self.plot)
    {
        NSLog(@"plot was nil");
        return;
    }
    self.fcsFile = [self.delegate fcsFileForPlot:self.plot];
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
    [self _setControlsVisible:YES];
    [self _createGraphAndConfigurePlotSpace];
    [self _insertScatterPlot];
    [self _reloadPlotDataAndLayout];
    self.gatesContainerView.delegate = self;
    [self.gatesContainerView performSelector:@selector(redrawGates) withObject:nil afterDelay:0.05];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.detailPopoverController dismissPopoverAnimated:YES];
    [self _setControlsVisible:NO];
    [self _grabImageOfPlot];
    [super viewWillDisappear:animated];
}


- (void)viewDidDisappear:(BOOL)animated
{
    [self.plotData cleanUpPlotData];
    [super viewDidDisappear:animated];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)_setControlsVisible:(BOOL)visible
{
    CGFloat alpha = 0.0f;
    if (visible) alpha = 1.0f;
    [self.navigationController setNavigationBarHidden:!visible animated:YES];
    self.navigationController.navigationBar.alpha = 0.0;

    [UIView animateWithDuration:0.3 animations:^{
        self.navigationController.navigationBar.alpha = alpha;
        self.xAxisButton.alpha = alpha * 0.3;
        self.yAxisButton.alpha = alpha * 0.3;
    } completion:nil];
}


- (void)_configureButtons
{
    UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
    [infoButton addTarget:self action:@selector(_toggleInfo:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *infoBarButton = [UIBarButtonItem.alloc initWithCustomView: infoButton];
    UIBarButtonItem *addGateButton = [UIBarButtonItem.alloc initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(_addGateButtonTapped:)];
    self.navigationItem.leftBarButtonItems = @[addGateButton, infoBarButton];
    self.plotTypeSegmentedControl.selectedSegmentIndex = self.plot.plotType.integerValue;
    [self.yAxisButton setTransform:CGAffineTransformMakeRotation(-M_PI / 2)];
}


- (void)_removeSubviews
{
    for (UIView *aSubView in self.view.subviews)
    {
        [aSubView removeFromSuperview];
    }
}

- (void)_grabImageOfPlot
{
    UIImage *newImage = [self.graph imageOfLayer];
    [self.plot setImage:newImage];
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
    // if UIUserInterfaceIdiomPhone:
    [self presentViewController:gateNavigationVC animated:YES completion:nil];
    [gateTVC setEditing:editOn animated:NO];
}


#pragma mark - Actions

- (IBAction)plotTypeChanged:(UISegmentedControl *)sender
{
    self.plot.plotType = [NSNumber numberWithInteger:sender.selectedSegmentIndex];
    [self.plot.managedObjectContext save];
    [self _reloadPlotDataAndLayout];
    [self.gatesContainerView redrawGates];
}


- (void)doneTapped
{
    [self _removeSubviews];
    [self.detailPopoverController dismissPopoverAnimated:YES];
    [self.delegate plotViewController:self didTapDoneForPlot:self.plot];
}


- (void)_toggleInfo:(UIButton *)sender
{
    UINavigationController *plotNavigationVC = [self.storyboard instantiateViewControllerWithIdentifier:@"plotDetailTableViewController"];
    PlotDetailTableViewController *plotTVC = (PlotDetailTableViewController *)plotNavigationVC.topViewController;
    id delegate = self.delegate;
    plotTVC.delegate = delegate;
    
    plotTVC.plot = self.plot;
    
    //[plotTVC setEditing:NO animated:NO];
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
        self.detailPopoverController.delegate = self;
        [self.detailPopoverController presentPopoverFromRect:sender.frame inView:self.navigationController.navigationBar permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
    else if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        [self presentViewController:plotNavigationVC animated:NO completion:nil];
    }
}


- (void)_addGateButtonTapped:(id)sender
{
    AddGateTableViewController *addGateTVC = [self.storyboard instantiateViewControllerWithIdentifier:@"addGateTableViewController"];
    addGateTVC.delegate = self;
    
    if (self.detailPopoverController.isPopoverVisible)
    {
        [self.detailPopoverController dismissPopoverAnimated:YES];
    }
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        self.detailPopoverController = [UIPopoverController.alloc initWithContentViewController:addGateTVC];
        [self.detailPopoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        self.detailPopoverController.delegate = self;
    }
    else if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        [self presentViewController:addGateTVC animated:NO completion:nil];
    }
}


#pragma mark - Add Gate Table View Controller Delegate
- (PlotType)addGateTableViewControllerCurrentPlotType:(id)sender
{
    return self.plot.plotType.integerValue;
}


- (void)addGateTableViewController:(id)sender didSelectGate:(GateType)gateType
{
    [self.detailPopoverController dismissPopoverAnimated:YES];
    Gate *newGate = [Gate createChildGateInPlot:self.plot type:gateType vertices:nil];
    [newGate.managedObjectContext save];
    [self.displayedGates addObject:newGate];
    [self.gatesContainerView insertNewGate:gateType gateTag:self.displayedGates.count - 1];
}


#pragma mark - Popover Controller Delegate
- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
    id object = popoverController.contentViewController;
    if ([object isKindOfClass:UINavigationController.class])
    {
        UINavigationController *navigationController = (UINavigationController *)object;
        return !navigationController.topViewController.editing;
    }
    return YES;
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
                                                      cancelButtonTitle:nil
                                                 destructiveButtonTitle:nil
                                                      otherButtonTitles:nil];
    axisPickerSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    axisPickerSheet.tag = axisNumber;
    
    for (NSUInteger parIndex = 0; parIndex < [self.fcsFile.text[@"$PAR"] integerValue]; parIndex++)
    {
        [axisPickerSheet addButtonWithTitle:[self _titleForParameter:parIndex + 1]];
    }
    //[axisPickerSheet addButtonWithTitle:nil];
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
    }
    else if (actionSheet.tag == Y_AXIS_SHEET)
    {
        self.plot.yParNumber = [NSNumber numberWithInteger:buttonIndex];
    }
    [self _reloadPlotDataAndLayout];
    [self.gatesContainerView redrawGates];
    [self.plot.managedObjectContext save];
}


#pragma mark - Graph and Plots
#pragma mark Insert Graph and Scatter plot
- (void)_createGraphAndConfigurePlotSpace
{    
    self.graph = [CPTXYGraph.alloc initWithFrame:self.graphHostingView.bounds];
    [self.graph applyTheme:[CPTTheme themeNamed:kCPTSlateTheme]];
    self.graphHostingView.hostedGraph = _graph;
    self.graph.paddingLeft = 0.0f;
    self.graph.paddingRight = 0.0f;
    self.graph.paddingTop = 0.0f;
    self.graph.paddingBottom = 0.0f;
    self.graph.plotAreaFrame.paddingLeft = 100.0;
    self.graph.plotAreaFrame.paddingRight = 20.0;
    self.graph.plotAreaFrame.paddingBottom = 70.0;
    self.graph.plotAreaFrame.paddingTop = 40.0;
    self.graph.plotAreaFrame.borderLineStyle = nil;
    
    self.plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
    self.plotSpace.allowsUserInteraction = YES;
    self.plotSpace.delegate = self;
}


- (void)_insertScatterPlot
{    
    CPTScatterPlot *scatterPlot = [CPTScatterPlot.alloc init];
    scatterPlot.dataSource = self;
    scatterPlot.delegate = self;
    scatterPlot.identifier = @"Scatter Plot 1";
    scatterPlot.plotSymbolMarginForHitDetection = 5.0;
    scatterPlot.borderWidth = 2.0f;
    scatterPlot.borderColor = [self _currentThemeLineColor];
    
    [self.graph addPlot:scatterPlot toPlotSpace:self.graph.defaultPlotSpace];
}


- (void)_insertBarPlot
{
    CPTBarPlot *barPlot = [CPTBarPlot.alloc init];
    barPlot.dataSource = self;
    barPlot.delegate = self;
    barPlot.identifier = @"Bar Plot 1";
    barPlot.borderWidth = 2.0f;
    barPlot.borderColor = [self _currentThemeLineColor];
    
    [self.graph addPlot:barPlot toPlotSpace:self.graph.defaultPlotSpace];
}


#pragma mark Reloading plot
- (void)_reloadPlotDataAndLayout
{
    [self preparePlotData];
    [self _updateAxisTitleButtons];
    [self _configureLineAndSymbol];
    [self _updateAxisAndAxisLabels];
    [self.graph reloadData];
    [self _adjustPlotRangeToFitData];
}


- (void)preparePlotData
{
    _xParIndex = self.plot.xParNumber.integerValue - 1;
    _yParIndex = self.plot.yParNumber.integerValue - 1;
    _currentPlotType = self.plot.plotType.integerValue;
    self.plot.xAxisType = [NSNumber numberWithInteger:[self.fcsFile axisTypeForParameterIndex:self.plot.xParNumber.integerValue - 1]];
    self.plot.yAxisType = [NSNumber numberWithInteger:[self.fcsFile axisTypeForParameterIndex:self.plot.yParNumber.integerValue - 1]];
    
    Gate *parentGate = (Gate *)self.plot.parentNode;
    
    if (parentGate
        && self.parentGateCalculator == nil)
    {
        NSLog(@"Loading parent gate data");
        self.parentGateCalculator = GateCalculator.alloc.init;
        self.parentGateCalculator.eventsInside = calloc(parentGate.cellCount.integerValue, sizeof(NSUInteger *));
        self.parentGateCalculator.numberOfCellsInside = parentGate.cellCount.integerValue;
        memcpy(self.parentGateCalculator.eventsInside, [parentGate.subSet bytes], [parentGate.subSet length]);
    }
    [self.plotData cleanUpPlotData];
    self.plotData = nil;
    self.plotData = [PlotDataCalculator plotDataForFCSFile:self.fcsFile
                                                insidePlot:self.plot
                                                    subset:self.parentGateCalculator.eventsInside
                                               subsetCount:self.parentGateCalculator.numberOfCellsInside];
}


- (void)_updateAxisTitleButtons
{
    [self.xAxisButton setTitle:[self _titleForParameter:self.plot.xParNumber.integerValue] forState:UIControlStateNormal];
    if (self.plot.plotType.integerValue == kPlotTypeHistogram)
    {
        [self.yAxisButton setTitle:NSLocalizedString(@"Count #", nil) forState:UIControlStateNormal];
    }
    else
    {
        [self.yAxisButton setTitle:[self _titleForParameter:self.plot.yParNumber.integerValue] forState:UIControlStateNormal];
    }
}


- (void)_configureLineAndSymbol
{
    CPTScatterPlot *scatterPlot = (CPTScatterPlot *)[self.graph plotWithIdentifier:@"Scatter Plot 1"];
    
    if (self.plot.plotType.integerValue == kPlotTypeDot
        || self.plot.plotType.integerValue == kPlotTypeDensity)
    {
        scatterPlot.dataLineStyle = nil;
        scatterPlot.plotSymbol = nil;
        //scatterPlot.interpolation = CPTScatterPlotInterpolationHistogram;
        scatterPlot.areaFill = nil;

    }
    else if (self.plot.plotType.integerValue == kPlotTypeHistogram)
    {
        CPTMutableLineStyle *histogramLineStyle = [CPTMutableLineStyle lineStyle];
        histogramLineStyle.lineWidth = 1.5;
        CPTColor *lineColor = [CPTColor blackColor];
        histogramLineStyle.lineColor = [CPTColor blackColor];
        scatterPlot.dataLineStyle = histogramLineStyle;
        CPTMutableLineStyle *histogramSymbolLineStyle = [CPTMutableLineStyle lineStyle];
        histogramSymbolLineStyle.lineColor = lineColor;
        scatterPlot.interpolation = CPTScatterPlotInterpolationCurved;
        CPTColor *gradientBeginColor = [CPTColor colorWithCGColor:[self _currentThemeLineColor]];       
        CPTGradient *areaGradient = [CPTGradient gradientWithBeginningColor:gradientBeginColor endingColor:[CPTColor clearColor]];
        areaGradient.angle = -90.0;
        CPTFill *areaGradientFill = [CPTFill fillWithGradient:areaGradient];
        scatterPlot.areaFill      = areaGradientFill;
        scatterPlot.areaBaseValue = [[NSDecimalNumber zero] decimalValue];
    }
}


- (void)_updateAxisAndAxisLabels
{
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
    CPTXYAxis *x = axisSet.xAxis;
    CPTXYAxis *y = axisSet.yAxis;
    CPTColor *themeColor = [CPTColor colorWithCGColor:[self _currentThemeLineColor]];
    
    NSNumberFormatter *logarithmicLabelFormatter = NSNumberFormatter.alloc.init;
    [logarithmicLabelFormatter setGeneratesDecimalNumbers:NO];
    //[logarithmicLabelFormatter setNumberStyle:kCFNumberFormatterScientificStyle];
    [logarithmicLabelFormatter setNumberStyle:kCFNumberFormatterDecimalStyle];
    [logarithmicLabelFormatter setExponentSymbol:@"e"];
    
    NSNumberFormatter *linearLabelFormatter = NSNumberFormatter.alloc.init;
    [linearLabelFormatter setGeneratesDecimalNumbers:NO];
    [linearLabelFormatter setNumberStyle:kCFNumberFormatterDecimalStyle];
        
    CPTMutableLineStyle *minorTickLineStyle = [x.minorTickLineStyle mutableCopy];
    minorTickLineStyle.lineColor = themeColor;
    
    CPTMutableTextStyle *labelTextStyle = [x.labelTextStyle mutableCopy];
    labelTextStyle.color = themeColor;
    x.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
    x.preferredNumberOfMajorTicks = 10;
    x.minorTickLineStyle = minorTickLineStyle;
    x.tickDirection = CPTSignNegative;
    x.labelTextStyle = labelTextStyle;
    x.axisLineStyle = nil;
    

    y.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
    y.preferredNumberOfMajorTicks = 10;
    y.minorTickLineStyle = minorTickLineStyle;
    y.tickDirection = CPTSignNegative;
    y.labelTextStyle = labelTextStyle;
    y.axisLineStyle = nil;
    
    x.orthogonalCoordinateDecimal = CPTDecimalFromString(@"0");
    x.title = nil;
    x.axisConstraints = [CPTConstraints constraintWithLowerOffset:0.0f];
    
    y.orthogonalCoordinateDecimal = CPTDecimalFromString(@"0");
    y.title = nil;
    y.axisConstraints = [CPTConstraints constraintWithLowerOffset:0.0f];
    
    switch (self.plot.xAxisType.integerValue)
    {
        case kAxisTypeLinear:
            self.plotSpace.xScaleType = CPTScaleTypeLinear;
            x.labelFormatter = linearLabelFormatter;
            break;
            
        case kAxisTypeLogarithmic:
            self.plotSpace.xScaleType = CPTScaleTypeLog;
            x.labelFormatter = logarithmicLabelFormatter;
            break;
            
        default:
            break;
    }
    
    if (self.plot.plotType.integerValue == kPlotTypeHistogram)
    {
        self.plotSpace.yScaleType = CPTScaleTypeLinear;
        y.labelFormatter = linearLabelFormatter;
        
        return;
    }
    
    switch (self.plot.yAxisType.integerValue)
    {
        case kAxisTypeLinear:
            self.plotSpace.yScaleType = CPTScaleTypeLinear;
            y.labelFormatter = linearLabelFormatter;
            break;
            
        case kAxisTypeLogarithmic:
            self.plotSpace.yScaleType = CPTScaleTypeLog;
            y.labelFormatter = logarithmicLabelFormatter;
            break;
            
        default:
            break;
    }
}

NSDecimal CPDecimalFromString(NSString *stringRepresentation)
{
    NSDecimal result;
    NSScanner *theScanner = [NSScanner.alloc initWithString:stringRepresentation];
    [theScanner scanDecimal:&result];
    
    return result;
}

- (void)_adjustPlotRangeToFitData
{
    CPTMutablePlotRange *xRange = [self.plotSpace.xRange mutableCopy];
    xRange.location = CPDecimalFromString([NSString stringWithFormat:@"%f", self.fcsFile.ranges[_xParIndex].minValue]);
    xRange.length = CPDecimalFromString([NSString stringWithFormat:@"%f", self.fcsFile.ranges[_xParIndex].maxValue-self.fcsFile.ranges[_xParIndex].minValue]);
    self.plotSpace.xRange = xRange;
    
    CPTMutablePlotRange *yRange = [self.plotSpace.yRange mutableCopy];

    if (self.plot.plotType.integerValue == kPlotTypeHistogram)
    {
        yRange.location = CPDecimalFromString([NSString stringWithFormat:@"%f", 0.0]);
        yRange.length = CPDecimalFromString([NSString stringWithFormat:@"%f", self.plotData.countForMaxBin * 1.1]);
        self.plotSpace.yRange = yRange;
        return;
    }
    yRange.location = CPDecimalFromString([NSString stringWithFormat:@"%f", self.fcsFile.ranges[_yParIndex].minValue]);
    yRange.length = CPDecimalFromString([NSString stringWithFormat:@"%f", self.fcsFile.ranges[_yParIndex].maxValue-self.fcsFile.ranges[_yParIndex].minValue]);
    self.plotSpace.yRange = yRange;
}


- (CGColorRef)_currentThemeLineColor
{
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
    return axisSet.xAxis.majorTickLineStyle.lineColor.cgColor;
}


- (NSString *)_titleForParameter:(NSInteger)parNumber
{
    NSString *unitName = self.fcsFile.calibrationUnitNames[[NSString stringWithFormat:@"%i", parNumber]];
    if (!unitName) 
    {
        return [FCSFile parameterShortNameForParameterIndex:parNumber - 1 inFCSFile:self.fcsFile];
    }
    return [[FCSFile parameterShortNameForParameterIndex:parNumber - 1 inFCSFile:self.fcsFile] stringByAppendingFormat:@" %@", unitName];
}


#pragma mark - CPT Plot Data Source
- (NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    if (self.plotData)
    {
        return self.plotData.numberOfPoints;
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
            return self.plotData.points[index].xVal;
            break;
            
        case CPTCoordinateY:
            return self.plotData.points[index].yVal;
            break;
            
        default:
            break;
    }
    return 0.0;
}

#pragma mark - Scatter Plot Delegate
static CPTPlotSymbol *plotSymbol;

#define COLOR_LEVELS 15
#define PLOTSYMBOL_SIZE 2.0

#pragma mark - Scatter Plot Datasource
-(CPTPlotSymbol *)symbolForScatterPlot:(CPTScatterPlot *)plot recordIndex:(NSUInteger)index
{
    if (_currentPlotType == kPlotTypeDensity)
    {
        if (!self.plotHelper)
        {
            self.plotHelper = [PlotHelper coloredPlotSymbols:COLOR_LEVELS ofSize:CGSizeMake(PLOTSYMBOL_SIZE, PLOTSYMBOL_SIZE)];
        }
        
        NSInteger cellCount = self.plotData.points[index].count;
        if (cellCount > 0)
        {
            NSInteger colorLevel = COLOR_LEVELS * (float)cellCount / (float)self.plotData.countForMaxBin;
            if (colorLevel > -1
                && colorLevel < COLOR_LEVELS)
            {
                return self.plotHelper.plotSymbols[colorLevel];
            }
        }
    }
    else if (_currentPlotType == kPlotTypeDot)
    {
        if (!plotSymbol)
        {
            plotSymbol = [CPTPlotSymbol ellipsePlotSymbol];
            plotSymbol.fill = [CPTFill fillWithColor:[CPTColor colorWithComponentRed:0.0 green:0.0 blue:0.0 alpha:1.0]];
            plotSymbol.lineStyle = nil;
            plotSymbol.size = CGSizeMake(PLOTSYMBOL_SIZE, PLOTSYMBOL_SIZE);
        }
        return plotSymbol;
    }
    return nil;
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
        viewPoint = [aView.layer convertPoint:viewPoint fromLayer:self.plotSpace.graph.plotAreaFrame.plotArea];
        
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


#pragma mark - Gates Container View Delegate
- (void)gatesContainerView:(GatesContainerView *)gatesContainerView didModifyGateNo:(NSUInteger)gateNo gateType:(GateType)gateType vertices:(NSArray *)updatedVertices
{
    if (updatedVertices.count == 0)
    {
        return;
    }
    
    NSArray *gateVertices = [self gateVerticesFromViewVertices:updatedVertices inView:gatesContainerView plotSpace:self.plotSpace];
    Gate *modifiedGate = self.displayedGates[gateNo];
    
    GateCalculator *gateContents = [GateCalculator eventsInsideGateWithVertices:gateVertices
                                                                       gateType:gateType
                                                                        fcsFile:self.fcsFile
                                                                     insidePlot:self.plot
                                                                         subSet:self.parentGateCalculator.eventsInside
                                                                    subSetCount:self.parentGateCalculator.numberOfCellsInside];
    
    modifiedGate.subSet = [NSData dataWithBytes:(NSUInteger *)gateContents.eventsInside length:sizeof(NSUInteger)*gateContents.numberOfCellsInside];
    modifiedGate.cellCount = [NSNumber numberWithInteger:gateContents.numberOfCellsInside];
    modifiedGate.vertices = gateVertices;
    
    [self.plot.managedObjectContext save];
}


- (void)gatesContainerView:(GatesContainerView *)gatesContainerView didTapGate:(NSUInteger)gateNo inRect:(CGRect)rect
{
    [self showDetailPopoverForGate:self.displayedGates[gateNo] inRect:rect editMode:NO];
}


- (void)gatesContainerView:(GatesContainerView *)gatesContainerView didDoubleTapGate:(NSUInteger)gateNo
{
    Gate *tappedGate = self.displayedGates[gateNo];
    [self.delegate plotViewController:self didSelectGate:tappedGate forPlot:self.plot];

}


#pragma mark - Mark View Datasource
- (NSUInteger)numberOfGatesInGatesContainerView:(GatesContainerView *)gatesContainerView
{
    self.displayedGates = [[self.plot childGatesForXPar:self.plot.xParNumber.integerValue
                                               andYPar:self.plot.yParNumber.integerValue] mutableCopy];
    return self.displayedGates.count;
}


- (GateType)gatesContainerView:(GatesContainerView *)gatesContainerView gateTypeForGateNo:(NSUInteger)gateNo
{
    Gate *gate = self.displayedGates[gateNo];
    return gate.type.integerValue;
}


- (NSArray *)gatesContainerView:(GatesContainerView *)gatesContainerView verticesForGate:(NSUInteger)gateNo
{
    Gate *gate = self.displayedGates[gateNo];

    if (gate.xParNumber.integerValue == self.plot.xParNumber.integerValue)
    {
        return [self viewVerticesFromGateVertices:gate.vertices
                                           inView:self.gatesContainerView
                                        plotSpace:self.plotSpace];
    }
    else
    {
        return [self viewVerticesFromGateVertices:[GraphPoint switchXandYForGraphpoints:gate.vertices]
                                           inView:self.gatesContainerView
                                        plotSpace:self.plotSpace];
    }
}


#pragma mark - Gate Table View Controller delegate
- (void)didTapNewPlot:(GateTableViewController *)sender
{
    [self.detailPopoverController dismissPopoverAnimated:YES];
    [self.delegate plotViewController:self didSelectGate:sender.gate forPlot:self.plot];
}


- (void)didTapDeleteGate:(GateTableViewController *)sender
{
    if (self.detailPopoverController.isPopoverVisible)
    {
        [self.detailPopoverController dismissPopoverAnimated:YES];
    }
    else if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
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
        [self.gatesContainerView redrawGates];
    }
    [self.delegate plotViewController:self didDeleteGate:gateToBeDeleted];
}

@end
