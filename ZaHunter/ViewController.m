//
//  ViewController.m
//  ZaHunter
//
//  Created by Kristen L. Fisher on 5/29/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "mapItem.h"

@interface ViewController () <CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate>
@property CLLocationManager *myLocationManager;
@property NSMutableArray *customMapItems;
@property NSArray *sortedArray;
@property CLLocation *userLocation;
@property double time;
@property (weak, nonatomic) IBOutlet UITableView *myTableView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.time = 0;
    self.userLocation = [[CLLocation alloc]init];
    self.myLocationManager = [[CLLocationManager alloc] init];
    self.customMapItems = [[NSMutableArray alloc]init];
    self.myLocationManager.delegate = self;
    [self.myLocationManager startUpdatingLocation];
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"%@", error);
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    for (CLLocation *location in locations)
    {
        if (location.verticalAccuracy < 1000 && location.horizontalAccuracy < 1000)
        {
            [self.myLocationManager stopUpdatingLocation];
            [self findPizzaNearUser:location];
            self.userLocation = location;
            break;
        }
    }
}

- (void)findPizzaNearUser:(CLLocation *)location
{
    MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc]init];
    request.naturalLanguageQuery = @"Pizza";
    request.region = MKCoordinateRegionMake(location.coordinate, MKCoordinateSpanMake(0.05, 0.05));
    MKLocalSearch *search = [[MKLocalSearch alloc]initWithRequest:request];
    [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error)
         {
            NSArray *tempArray = response.mapItems;
             for (MKMapItem *item in tempArray) {
                 mapItem *customMapItem = [[mapItem alloc]init];
                 customMapItem.name = item.name;
                 customMapItem.mapItem = item;
                 customMapItem.distance = [item.placemark.location distanceFromLocation:self.userLocation];
                 [self.customMapItems addObject:customMapItem];
             }
             NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]initWithKey: @"distance" ascending: YES];
             self.sortedArray = [self.customMapItems sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
             [self.myTableView reloadData];
             [self getDirectionsTo:[MKMapItem mapItemForCurrentLocation] from:[self.sortedArray objectAtIndex:0]];
             [self getDirectionsTo:[self.sortedArray objectAtIndex:0] from:[self.sortedArray objectAtIndex:1]];
             [self getDirectionsTo:[self.sortedArray objectAtIndex:1] from:[self.sortedArray objectAtIndex:2]];
             [self getDirectionsTo:[self.sortedArray objectAtIndex:2] from:[self.sortedArray objectAtIndex:3]];
        }];
}

-(void)getDirectionsTo:(MKMapItem*)sourceItem from:(MKMapItem *)destinationItem
{
    MKDirectionsRequest *request = [[MKDirectionsRequest alloc] init];
    request.source = sourceItem;
    request.destination = destinationItem;
    request.transportType = MKDirectionsTransportTypeWalking;

    MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error)
     {
         NSArray *routes = response.routes;
         MKRoute *route = routes.firstObject;
         NSLog(@"%f", self.time);
         self.time += route.expectedTravelTime/60 + 50;
     }];
}

#pragma mark - UITableViewDelegate Methods
-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 4;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    mapItem *item = [self.sortedArray objectAtIndex:indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: @"PizzaCellID"];
    cell.textLabel.text = item.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%f Miles", item.distance * 0.00062];
    return cell;
}

@end


//      [MKMapItem mapItemForCurrentLocation];
