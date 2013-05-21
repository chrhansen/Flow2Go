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
#import "MKSKSubscriptionProduct.h"

@interface FGStoreViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *restoreButton;

@end

@implementation FGStoreViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    //    [[MKStoreManager sharedManager] removeAllKeychainData];
    [self _addObservings];
    [self _addNoiseBackground];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [MKStoreManager sharedManager];
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productsFetchedFailed:) name:kProductFetchedFailedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productsFetched:) name:kSubscriptionsPurchasedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productsFetched:) name:kSubscriptionsInvalidNotification object:nil];
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
    [[MKStoreManager sharedManager] buyFeature:[[MKStoreManager sharedManager].purchasableObjects[productIndex] productIdentifier] onComplete:^(NSString *purchasedFeature, NSData *purchasedReceipt, NSArray *availableDownloads) {
        NSAssert([NSThread isMainThread], @"WTF! completion handler not on main thread");
        [self reloadProductWithIdentifier:purchasedFeature];
    } onCancelled:^{
        NSAssert([NSThread isMainThread], @"WTF! completion handler not on main thread");
    }];
}


- (IBAction)restoreTapped:(id)sender
{
    [[MKStoreManager sharedManager] restorePreviousTransactionsOnComplete:^{
        NSAssert([NSThread isMainThread], @"WTF! completion handler not on main thread");
        [self.collectionView reloadItemsAtIndexPaths:[self.collectionView indexPathsForVisibleItems]];
    } onError:^(NSError *error) {
        NSAssert([NSThread isMainThread], @"WTF! completion handler not on main thread");
        [self _presentErrorMessage:error.localizedDescription];
    }];
}


- (IBAction)doneTapped:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}


- (void)_presentErrorMessage:(NSString *)errorMessage
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                        message:errorMessage
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                              otherButtonTitles: nil];
    [alertView show];
}


#pragma mark Store updates
- (void)productsFetched:(NSNotification *)notification
{
    NSNumber *isProductsAvailable = notification.object;
    if (isProductsAvailable.boolValue) {
        [self.collectionView reloadData];
    }
}

- (void)productsFetchedFailed:(NSNotification *)notification
{
    [self postInternetErrorNotification];
}


- (void)postInternetErrorNotification
{
    [FGHUDMessage showHUDMessage:NSLocalizedString(@"Could not get products, are you connected to the internet?", nil) inView:self.view];
}

- (void)reloadProductWithIdentifier:(NSString *)productIdentifier
{
    if (!productIdentifier) return;
    NSUInteger row = [[[MKStoreManager sharedManager] purchasableObjects] indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        SKProduct *product = (SKProduct *)obj;
        if (product.productIdentifier == productIdentifier) {
            *stop = YES;
            return YES;
        }
        return NO;
    }];
    [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:row inSection:0]]];
}

- (void)configureCell:(UICollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    SKProduct *product = [[[MKStoreManager sharedManager] purchasableObjects] objectAtIndex:indexPath.row];
    FGStoreCell *storeCell = (FGStoreCell *)cell;
    storeCell.titleLabel.text = product.localizedTitle;
    storeCell.descriptionLabel.text = product.localizedDescription;
    [storeCell.descriptionLabel sizeToFit];
    if ([MKStoreManager isFeaturePurchased:product.productIdentifier]) {
        [storeCell.buyButton setTitle:NSLocalizedString(@"Purchased", nil) forState:UIControlStateNormal];
        [storeCell.buyButton setEnabled:NO];
    } else {
        MKSKSubscriptionProduct *subscriptionProduct = [[MKStoreManager sharedManager] subscriptionProducts][product.productIdentifier];
        if (subscriptionProduct) {
            NSString *duration;
            if (subscriptionProduct.subscriptionDays == 7) {
                duration = NSLocalizedString(@"week", nil);
            } else if (subscriptionProduct.subscriptionDays == 30) {
                duration = NSLocalizedString(@"month", nil);
            }
            NSString *subscriptionPriceTitle = [product.priceAsString stringByAppendingFormat:@"/%@", duration];
            [storeCell.buyButton setTitle:subscriptionPriceTitle forState:UIControlStateNormal];
        } else {
            [storeCell.buyButton setTitle:product.priceAsString forState:UIControlStateNormal];
        }
        storeCell.buyButton.tag = indexPath.row;
        [storeCell.buyButton setEnabled:YES];

        if (storeCell.buyButton.allTargets.count == 0) {
            [storeCell.buyButton addTarget:self action:@selector(buyButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    storeCell.mainImageView.image = [self imageForProductIdentifier:product.productIdentifier];
}


- (UIImage *)imageForProductIdentifier:(NSString *)productIdentifier
{
    UIImage *image;
    if ([productIdentifier isEqualToString:InAppIdentifierFCSFiles]) {
        image = [UIImage imageNamed:@"FCS_FILES_UNLIMITED"];
    } 
    return image;
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
