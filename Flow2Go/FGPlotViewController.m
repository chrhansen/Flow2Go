//
//  PlotViewController.m
//  Flow2Go
//
//  Created by Christian Hansen on 03/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "FGPlotViewController.h"
#import "FGFCSFile.h"
#import "FGGateCalculator.h"
#import "FGGate+Management.h"
#import "FGGraphPoint.h"
#import "FGPlot+Management.h"
#import "FGPlotDataCalculator.h"
#import "FGGateTableViewController.h"
#import "FGPlotDetailTableViewController.h"
#import "FGPlotHelper.h"
#import "FGAddGateTableViewController.h"
#import "FGGatesContainerView.h"
#import "PopoverView.h"

@interface FGPlotViewController () <AddGateTableViewControllerDelegate, GateTableViewControllerDelegate, UIPopoverControllerDelegate, PopoverViewDelegate>
{
    NSInteger _xParIndex;
    NSInteger _yParIndex;
    FGPlotType _currentPlotType;
}

@property (nonatomic, strong) FGGateCalculator *parentGateCalculator;
@property (nonatomic, strong) CPTXYGraph *graph;
@property (nonatomic, strong) CPTXYPlotSpace *plotSpace;
@property (nonatomic, strong) FGFCSFile *fcsFile;
@property (nonatomic, strong) FGPlotDataCalculator *plotData;
@property (nonatomic, strong) NSMutableArray *displayedGates;
@property (nonatomic, strong) FGPlotHelper *plotHelper;
@property (nonatomic, strong) UIPopoverController *detailPopoverController;
@property (weak, nonatomic) IBOutlet UISegmentedControl *plotTypeSegmentedControl;
@property (nonatomic, strong) PopoverView *popoverView;


@end

@implementation FGPlotViewController

#define X_AXIS_TAG 1
#define Y_AXIS_TAG 2

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [UIBarButtonItem.alloc initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneTapped)];
    if (!self.plot) {
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
    [self _createGraphAndConfigurePlotSpace];
    [self _insertScatterPlot];
    [self _reloadPlotDataAndLayout];
    self.gatesContainerView.delegate = self;
    [self.gatesContainerView performSelector:@selector(redrawGates) withObject:nil afterDelay:0.05];

}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.detailPopoverController dismissPopoverAnimated:YES];
    [self _grabImageOfPlot]; //TODO: downscale image in background thread before adding. (consider thumbnail res. for measurement/and high res for sharing)
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


- (void)showDetailPopoverForGate:(FGGate *)gate inRect:(CGRect)anchorFrame editMode:(BOOL)editOn
{
    UINavigationController *gateNavigationVC = [self.storyboard instantiateViewControllerWithIdentifier:@"gateDetailTableViewController"];
    FGGateTableViewController *gateTVC = (FGGateTableViewController *)gateNavigationVC.topViewController;
    gateTVC.delegate = self;
    gateTVC.gate = gate;
    
    if (IS_IPAD) {
        if (self.detailPopoverController.isPopoverVisible) {
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
    NSNumber *plotType = [NSNumber numberWithInteger:sender.selectedSegmentIndex];
    self.plot.plotType = plotType;
    [self _reloadPlotDataAndLayout];
    [self.gatesContainerView redrawGates];
    NSError *error;
    if(![self.plot.managedObjectContext save:&error]) NSLog(@"Error saving plot when setting plotType: %@", error.localizedDescription);
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
    FGPlotDetailTableViewController *plotTVC = (FGPlotDetailTableViewController *)plotNavigationVC.topViewController;
    id delegate = self.delegate;
    plotTVC.delegate = delegate;
    
    plotTVC.plot = self.plot;
    
    //[plotTVC setEditing:NO animated:NO];
    if (self.detailPopoverController.isPopoverVisible) {
        UINavigationController *navigationController = (UINavigationController *)self.detailPopoverController.contentViewController;
        if (!navigationController.topViewController.editing) {
            [self.detailPopoverController dismissPopoverAnimated:YES];
        }
        return;
    }
    if (IS_IPAD) {
        self.detailPopoverController = [UIPopoverController.alloc initWithContentViewController:plotNavigationVC];
        self.detailPopoverController.delegate = self;
        [self.detailPopoverController presentPopoverFromRect:sender.frame inView:self.navigationController.navigationBar permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        [self presentViewController:plotNavigationVC animated:NO completion:nil];
    }
}


- (void)_addGateButtonTapped:(id)sender
{
    FGAddGateTableViewController *addGateTVC = [self.storyboard instantiateViewControllerWithIdentifier:@"addGateTableViewController"];
    addGateTVC.delegate = self;
    
    if (self.detailPopoverController.isPopoverVisible) [self.detailPopoverController dismissPopoverAnimated:YES];
    
    if (IS_IPAD) {
        self.detailPopoverController = [UIPopoverController.alloc initWithContentViewController:addGateTVC];
        [self.detailPopoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        self.detailPopoverController.delegate = self;
    } else {
        [self presentViewController:addGateTVC animated:NO completion:nil];
    }
}


#pragma mark - Add Gate Table View Controller Delegate
- (FGPlotType)addGateTableViewControllerCurrentPlotType:(id)sender
{
    return self.plot.plotType.integerValue;
}


- (void)addGateTableViewController:(id)sender didSelectGate:(FGGateType)gateType
{
    [self.detailPopoverController dismissPopoverAnimated:YES];
    FGGate *newGate = [FGGate createChildGateInPlot:self.plot type:gateType vertices:nil];
    NSError *error;
    [newGate.managedObjectContext save:&error];
    if (error) NSLog(@"Error creating child gate: %@", error.localizedDescription);
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
    [self _showAxisPicker:X_AXIS_TAG fromButton:sender];
}


- (IBAction)yAxisTapped:(id)sender
{
    [self _showAxisPicker:Y_AXIS_TAG fromButton:sender];
}


- (void)_showAxisPicker:(NSInteger)axisNumber fromButton:(UIButton *)axisButton
{
    NSMutableArray *items = [NSMutableArray array];
    for (NSUInteger parIndex = 0; parIndex < [self.fcsFile.text[@"$PAR"] integerValue]; parIndex++) {
        NSString *title = [self _titleForParameter:parIndex + 1];
        if (title) [items addObject:title];
    }
    CGPoint point;
    switch (axisNumber) {
        case X_AXIS_TAG:
            point = CGPointMake(axisButton.frame.origin.x + axisButton.bounds.size.width / 2.0f, axisButton.frame.origin.y);
            break;
        case Y_AXIS_TAG:
            point = CGPointMake(axisButton.frame.origin.x + axisButton.bounds.size.height / 2.0f, axisButton.frame.origin.y);
            break;
        default:
            break;
    }
    self.popoverView = [PopoverView showPopoverAtPoint:point
                                                inView:self.view
                                             withTitle:nil
                                       withStringArray:items
                                              delegate:self];
    self.popoverView.tag = axisNumber;
}

#pragma mark - PopoverViewDelegate Methods

- (void)popoverView:(PopoverView *)popoverView didSelectItemAtIndex:(NSInteger)index
{
    [popoverView performSelector:@selector(dismiss) withObject:nil afterDelay:0.0f];
    if (index < 0) {
        return;
    }
    NSNumber *parNumber = [NSNumber numberWithInteger:index + 1];
    if (self.popoverView.tag == X_AXIS_TAG) {
        self.plot.xParNumber = parNumber;
    } else if (self.popoverView.tag == Y_AXIS_TAG) {
        self.plot.yParNumber = parNumber;
    }
    [self _reloadPlotDataAndLayout];
    [self.gatesContainerView redrawGates];
    
    NSError *error;
    [self.plot.managedObjectContext save:&error];
    if (error) NSLog(@"Erro saving plot: %@", error.localizedDescription);
}


- (void)axisChanged:(id)sender
{
    NSLog(@"sender: %@", sender);
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex <= 0) {
        return;
    }
    NSNumber *parNumber = [NSNumber numberWithInteger:buttonIndex];
    if (actionSheet.tag == X_AXIS_TAG) {
        self.plot.xParNumber = parNumber;
    } else if (actionSheet.tag == Y_AXIS_TAG) {
        self.plot.yParNumber = parNumber;
    }
    [self _reloadPlotDataAndLayout];
    [self.gatesContainerView redrawGates];
    NSError *error;
    [self.plot.managedObjectContext save:&error];
    if (error) NSLog(@"Erro saving plot: %@", error.localizedDescription);
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
    scatterPlot.borderColor = [CPTColor redColor].cgColor;//[self _currentThemeLineColor];
    
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
    
    FGGate *parentGate = (FGGate *)self.plot.parentNode;
    
    if (parentGate
        && self.parentGateCalculator == nil) {
        NSLog(@"Loading parent gate data");
        self.parentGateCalculator = FGGateCalculator.alloc.init;
        self.parentGateCalculator.eventsInside = calloc(parentGate.cellCount.integerValue, sizeof(NSUInteger *));
        self.parentGateCalculator.numberOfCellsInside = parentGate.cellCount.integerValue;
        memcpy(self.parentGateCalculator.eventsInside, [parentGate.subSet bytes], [parentGate.subSet length]);
    }
    [self.plotData cleanUpPlotData];
    self.plotData = nil;
    self.plotData = [FGPlotDataCalculator plotDataForFCSFile:self.fcsFile
                                                insidePlot:self.plot
                                                    subset:self.parentGateCalculator.eventsInside
                                               subsetCount:self.parentGateCalculator.numberOfCellsInside];
}


- (void)_updateAxisTitleButtons
{
    [self.xAxisButton setTitle:[self _titleForParameter:self.plot.xParNumber.integerValue] forState:UIControlStateNormal];
    if (self.plot.plotType.integerValue == kPlotTypeHistogram) {
        [self.yAxisButton setTitle:NSLocalizedString(@"Count #", nil) forState:UIControlStateNormal];
    } else {
        [self.yAxisButton setTitle:[self _titleForParameter:self.plot.yParNumber.integerValue] forState:UIControlStateNormal];
    }
}


- (void)_configureLineAndSymbol
{
    CPTScatterPlot *scatterPlot = (CPTScatterPlot *)[self.graph plotWithIdentifier:@"Scatter Plot 1"];
    
    if (self.plot.plotType.integerValue == kPlotTypeDot
        || self.plot.plotType.integerValue == kPlotTypeDensity) {
        scatterPlot.dataLineStyle = nil;
        scatterPlot.plotSymbol = nil;
        //scatterPlot.interpolation = CPTScatterPlotInterpolationHistogram;
        scatterPlot.areaFill = nil;

    } else if (self.plot.plotType.integerValue == kPlotTypeHistogram) {
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
    
    switch (self.plot.xAxisType.integerValue) {
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
    
    if (self.plot.plotType.integerValue == kPlotTypeHistogram) {
        self.plotSpace.yScaleType = CPTScaleTypeLinear;
        y.labelFormatter = linearLabelFormatter;
        return;
    }
    
    switch (self.plot.yAxisType.integerValue) {
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
    if (!unitName) {
        return [FGFCSFile parameterShortNameForParameterIndex:parNumber - 1 inFCSFile:self.fcsFile];
    }
    return [[FGFCSFile parameterShortNameForParameterIndex:parNumber - 1 inFCSFile:self.fcsFile] stringByAppendingFormat:@" %@", unitName];
}


#pragma mark - CPT Plot Data Source
- (NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    if (self.plotData) {
        return self.plotData.numberOfPoints;
    } else if (self.parentGateCalculator) {
        return self.parentGateCalculator.numberOfCellsInside;
    }
    return self.fcsFile.noOfEvents;
}


- (double)doubleForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    switch (fieldEnum) {
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
    if (_currentPlotType == kPlotTypeDensity) {
        if (!self.plotHelper) {
            self.plotHelper = [FGPlotHelper coloredPlotSymbols:COLOR_LEVELS ofSize:CGSizeMake(PLOTSYMBOL_SIZE, PLOTSYMBOL_SIZE)];
        }
        NSInteger cellCount = self.plotData.points[index].count;
        if (cellCount > 0) {
            NSInteger colorLevel = COLOR_LEVELS * (float)cellCount / (float)self.plotData.countForMaxBin;
            if (colorLevel > -1
                && colorLevel < COLOR_LEVELS) {
                return self.plotHelper.plotSymbols[colorLevel];
            }
        }
    }
    else if (_currentPlotType == kPlotTypeDot) {
        if (!plotSymbol) {
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
    
    for (FGGraphPoint *aPoint in gateVertices) {
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
    
    for (NSValue *aValue in vertices) {
        CGPoint pathPoint = aValue.CGPointValue;
        pathPoint = [aView.layer convertPoint:pathPoint toLayer:plotSpace.graph.plotAreaFrame.plotArea];
        [self.plotSpace doublePrecisionPlotPoint:graphPoint forPlotAreaViewPoint:pathPoint];        
        FGGraphPoint *gateVertex = [FGGraphPoint pointWithX:(double)graphPoint[0] andY:(double)graphPoint[1]];
        [gateVertices addObject:gateVertex];
    }    
    return gateVertices;
}


#pragma mark - Gates Container View Delegate
- (void)gatesContainerView:(FGGatesContainerView *)gatesContainerView didModifyGateNo:(NSUInteger)gateNo gateType:(FGGateType)gateType vertices:(NSArray *)updatedVertices
{
    if (updatedVertices.count == 0) return;
    
    NSArray *gateVertices = [self gateVerticesFromViewVertices:updatedVertices inView:gatesContainerView plotSpace:self.plotSpace];
    FGGate *modifiedGate = self.displayedGates[gateNo];
    NSLog(@"Starting gate calc");
    FGGateCalculator *gateContents = [FGGateCalculator eventsInsideGateWithVertices:gateVertices
                                                                           gateType:gateType
                                                                            fcsFile:self.fcsFile
                                                                         insidePlot:self.plot
                                                                             subSet:self.parentGateCalculator.eventsInside
                                                                        subSetCount:self.parentGateCalculator.numberOfCellsInside];
    NSLog(@"Finished gate calc");

    modifiedGate.subSet = [NSData dataWithBytes:(NSUInteger *)gateContents.eventsInside length:sizeof(NSUInteger)*gateContents.numberOfCellsInside];
    modifiedGate.cellCount = [NSNumber numberWithInteger:gateContents.numberOfCellsInside];
    modifiedGate.vertices = gateVertices;
    NSError *error;
    [self.plot.managedObjectContext save:&error];
    if (error) NSLog(@"Error updating gate: %@", error.localizedDescription);
}


- (void)gatesContainerView:(FGGatesContainerView *)gatesContainerView didTapGate:(NSUInteger)gateNo inRect:(CGRect)rect
{
    [self showDetailPopoverForGate:self.displayedGates[gateNo] inRect:rect editMode:NO];
}


- (void)gatesContainerView:(FGGatesContainerView *)gatesContainerView didDoubleTapGate:(NSUInteger)gateNo
{
    FGGate *tappedGate = self.displayedGates[gateNo];
    [self.delegate plotViewController:self didSelectGate:tappedGate forPlot:self.plot];
}


#pragma mark - Mark View Datasource
- (NSUInteger)numberOfGatesInGatesContainerView:(FGGatesContainerView *)gatesContainerView
{
    self.displayedGates = [[self.plot childGatesForXPar:self.plot.xParNumber.integerValue
                                                andYPar:self.plot.yParNumber.integerValue] mutableCopy];
    return self.displayedGates.count;
}


- (FGGateType)gatesContainerView:(FGGatesContainerView *)gatesContainerView gateTypeForGateNo:(NSUInteger)gateNo
{
    FGGate *gate = self.displayedGates[gateNo];
    return gate.type.integerValue;
}


- (NSArray *)gatesContainerView:(FGGatesContainerView *)gatesContainerView verticesForGate:(NSUInteger)gateNo
{
    FGGate *gate = self.displayedGates[gateNo];

    if (gate.xParNumber.integerValue == self.plot.xParNumber.integerValue) {
        return [self viewVerticesFromGateVertices:gate.vertices
                                           inView:self.gatesContainerView
                                        plotSpace:self.plotSpace];
    } else {
        return [self viewVerticesFromGateVertices:[FGGraphPoint switchXandYForGraphpoints:gate.vertices]
                                           inView:self.gatesContainerView
                                        plotSpace:self.plotSpace];
    }
}


#pragma mark - Gate Table View Controller delegate
- (void)didTapNewPlot:(FGGateTableViewController *)sender
{
    [self.detailPopoverController dismissPopoverAnimated:YES];
    [self.delegate plotViewController:self didSelectGate:sender.gate forPlot:self.plot];
}


- (void)didTapDeleteGate:(FGGateTableViewController *)sender
{
    if (self.detailPopoverController.isPopoverVisible) {
        [self.detailPopoverController dismissPopoverAnimated:YES];
    } else if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    __block BOOL success = NO;
    NSManagedObjectID *objectID = sender.gate.objectID;
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        FGGate *localGate = (FGGate *)[localContext objectWithID:objectID];
        success = [localGate deleteInContext:localContext];
    } completion:^(BOOL success, NSError *error) {
        if (!success) {
            UIAlertView *alertView = [UIAlertView.alloc initWithTitle:NSLocalizedString(@"Error", nil)
                                                              message:[NSLocalizedString(@"Could not delete gate \"", nil) stringByAppendingFormat:@"%@\"", sender.gate.name]
                                                             delegate:nil
                                                    cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                    otherButtonTitles: nil];
            [alertView show];
        } else {
            [self.gatesContainerView redrawGates];
        }
    }];
}

@end
