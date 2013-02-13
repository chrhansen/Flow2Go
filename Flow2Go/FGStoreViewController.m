//
//  FGStoreViewController.m
//  Flow2Go
//
//  Created by Christian Hansen on 13/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGStoreViewController.h"
#import "MKStoreManager.h"
#import "FGStoreCell.h"
#import "SKProduct+PriceAsString.h"

@interface FGStoreViewController ()
@property (weak, nonatomic) IBOutlet UIBarButtonItem *restoreButton;

@end

@implementation FGStoreViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self _addObservings];
    [MKStoreManager sharedManager];
    [self _addNoiseBackground];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.collectionView reloadData];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)_addObservings
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productsFetched:) name:kProductFetchedNotification object:nil];
}


- (void)_addNoiseBackground
{
    KGNoiseRadialGradientView *collectionNoiseView = [[KGNoiseRadialGradientView alloc] initWithFrame:self.collectionView.bounds];
    collectionNoiseView.backgroundColor            = [UIColor colorWithWhite:0.7032 alpha:1.000];
    collectionNoiseView.alternateBackgroundColor   = [UIColor colorWithWhite:0.7051 alpha:1.000];
    collectionNoiseView.noiseOpacity = 0.07;
    collectionNoiseView.noiseBlendMode = kCGBlendModeNormal;
    self.collectionView.backgroundView = collectionNoiseView;
}


- (void)buyButtonTapped:(id)sender
{
    NSInteger productIndex = [(UIButton *)sender tag];
    [[MKStoreManager sharedManager] buyFeature:[MKStoreManager sharedManager].purchasableObjects[productIndex] onComplete:^(NSString *purchasedFeature, NSData *purchasedReceipt, NSArray *availableDownloads) {
        NSLog(@"Purchased feature: %@", purchasedFeature);
    } onCancelled:^{
        NSLog(@"User cancelled purchase");

    }];
}


- (IBAction)restoreTapped:(id)sender
{
    [[MKStoreManager sharedManager] restorePreviousTransactionsOnComplete:^{
        NSLog(@"purchases restored");
    } onError:^(NSError *error) {
        NSLog(@"could not restore: %@", error.localizedDescription);
    }];
}


- (IBAction)doneTapped:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark Store updates
- (void)productsFetched:(NSNotification *)notification
{
    NSNumber *isProductsAvailable = notification.object;
    if (isProductsAvailable.boolValue) {
        [self.collectionView reloadData];
    }
}



- (void)configureCell:(UICollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    SKProduct *product = [[[MKStoreManager sharedManager] purchasableObjects] objectAtIndex:indexPath.row];
    FGStoreCell *storeCell = (FGStoreCell *)cell;
    storeCell.titleLabel.text = product.localizedTitle;
    storeCell.descriptionLabel.text = product.localizedDescription;
    [storeCell.descriptionLabel sizeToFit];
    [storeCell.buyButton setTitle:product.priceAsString forState:UIControlStateNormal];
    storeCell.buyButton.tag = indexPath.row;
    if (storeCell.buyButton.allTargets.count == 0) {
        [storeCell.buyButton addTarget:self action:@selector(buyButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
}




#pragma mark UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)sender
{
    
}

#pragma mark - Table view data source
#pragma mark - UICollectionView Datasource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [[MKStoreManager sharedManager] purchasableObjects].count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Store Cell";
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    if (cell) [self configureCell:cell atIndexPath:indexPath];
    return cell;
}


@end
