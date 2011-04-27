//
//  ChartListViewController.m
//  PlotCreator
//
//  Created by honcheng on 4/24/11.
//  Copyright 2011 honcheng. All rights reserved.
//

#import "ChartListViewController.h"
#import "PieChartViewController.h"
#import "PieChartViewController2.h"
#import "LineChartViewController.h"

@implementation ChartListViewController


#pragma mark -
#pragma mark Initialization

- (id)init
{
	self = [super init];
	if (self)
	{
		
		UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,150,30)];
		[titleLabel setBackgroundColor:[UIColor clearColor]];
		[titleLabel setTextColor:[UIColor whiteColor]];
		[titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue-CondensedBold" size:20]];
		[titleLabel setText:@"iOSPlot"];
		[self.navigationItem setTitleView:titleLabel];
		[titleLabel release];
		[titleLabel setTextAlignment:UITextAlignmentCenter];
	}
	return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Override to allow orientations other than the default portrait orientation.
    return YES;
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 3;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		[cell.textLabel setFont:[UIFont fontWithName:@"HelveticaNeue-CondensedBold" size:20]];
		[cell setSelectionStyle:UITableViewCellSelectionStyleGray];
		[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
	}
    
    if (indexPath.row==0)
	{
		[cell.textLabel setText:@"Pie Chart with arrows"];
	}
	else if (indexPath.row==1)
	{
		[cell.textLabel setText:@"Pie Chart without arrows"];
	}
	else if (indexPath.row==2)
	{
		[cell.textLabel setText:@"Line Chart"];
	}
    
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	if (indexPath.row==0)
	{
		PieChartViewController *detailViewController = [[PieChartViewController alloc] init];
		[self.navigationController pushViewController:detailViewController animated:YES];
		[detailViewController release];
	}
    else if (indexPath.row==1)
	{
		PieChartViewController2 *detailViewController = [[PieChartViewController2 alloc] init];
		[self.navigationController pushViewController:detailViewController animated:YES];
		[detailViewController release];
	}
	else if (indexPath.row==2)
	{
		LineChartViewController *detailViewController = [[LineChartViewController alloc] init];
		[self.navigationController pushViewController:detailViewController animated:YES];
		[detailViewController release];
	}
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
