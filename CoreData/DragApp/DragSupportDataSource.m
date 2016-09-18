/*
 
 File: DragSupportDataSource.m
 
 Abstract: Custom that handles Drag and Drop for table views by acting as a datasource. 
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Computer, Inc. ("Apple") in consideration of your agreement to the
 following terms, and your use, installation, modification or
 redistribution of this Apple software constitutes acceptance of these
 terms.  If you do not agree with these terms, please do not use,
 install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the 
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Computer,
 Inc. may be used to endorse or promote products derived from the Apple
 Software without specific prior written permission from Apple.  Except
 as expressly stated in this notice, no other rights or licenses, express
 or implied, are granted by Apple herein, including but not limited to
 any patent rights that may be infringed by your derivative works or by
 other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright ¬© 2005 Apple Computer, Inc., All Rights Reserved
 
 */

#import "DragSupportDataSource.h"


@implementation DragSupportDataSource

//************************* init stuff ***************************/
#pragma mark --------- init stuff


- (id)init {
    self = [super init];
    if (self != nil) {
        registeredTableViews = [[NSMutableSet alloc] init];        
    }
    return self;    
}

- (void) dealloc {
    [registeredTableViews release];
    [super dealloc];
}

//************************* table view data source necessities ***************************/
#pragma mark --------- datasource methods


// We use this method as a way of registering for drag types for all the table views that will depend on us to implement D&D. Instead of setting up innumerable outlets, simply depend on the fact that every table view will ask its datasource for number of rows.
- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
        
    // this is potentially slow if there are lots of table views
    if ([registeredTableViews containsObject:aTableView] == NO) {
        [aTableView registerForDraggedTypes:
            [NSArray arrayWithObjects:NSStringPboardType, nil]];
        [registeredTableViews addObject:aTableView]; //Cache the table views that have "registered" with us.
    }
    
    return 0; // return 0 so the table view will fall back to getting data from its binding
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
    return nil;  // return nil so the table view will fall back to getting data from its binding 
}


// put the managedobject's ID on the pasteboard as an URL
- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard {
    BOOL success = NO;
    
    NSDictionary *infoForBinding = [tv infoForBinding:NSContentBinding];
    if (infoForBinding != nil) {
        NSArrayController *arrayController = [infoForBinding objectForKey:NSObservedObjectKey];
        
        NSArray *objects = [[arrayController arrangedObjects] objectsAtIndexes:rowIndexes];
        NSMutableArray *objectIDs = [NSMutableArray array];
        unsigned int i, count = [objects count];
        for (i = 0; i < count; i++) {
            NSManagedObject *item = [objects objectAtIndex:i];
            NSManagedObjectID *objectID = [item objectID];
            NSURL *representedURL = [objectID URIRepresentation];
            [objectIDs addObject:representedURL];
        }
        [pboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
        [pboard addTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
        success = [pboard setString:[objectIDs componentsJoinedByString:@", "] forType:NSStringPboardType];        
    }
        
    return success;
}

//************************* actual drag and drop work ***************************/
#pragma mark --------- drag and drop work


- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation {
	
	// Avoid drag&drop on self. This might be interersting to enable in light of ordered relationships
    return ([info draggingSource] != tableView) ? NSDragOperationCopy : NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation {
    
	BOOL success = NO;
    NSString *urlStrings = [[info draggingPasteboard] stringForType:NSStringPboardType];
    
    // get to the arraycontroller feeding the destination table view
    NSDictionary *destinationContentBindingInfo = [tableView infoForBinding:NSContentBinding];
    if (destinationContentBindingInfo != nil) {
        
        NSArrayController *destinationArrayController = [destinationContentBindingInfo objectForKey:NSObservedObjectKey];
        NSArrayController *sourceArrayController = nil;
        
        // check for the arraycontroller feeding the source table view
        NSDictionary *contentSetBindingInfo = [destinationArrayController infoForBinding:NSContentSetBinding];
        if (contentSetBindingInfo != nil) {
            sourceArrayController = [contentSetBindingInfo objectForKey:NSObservedObjectKey];  
        }

        // there should be exactly one item selected in the source controller, otherwise the destination controller won't be able to manipulate the relationship when we do addObject:
        if ((sourceArrayController != nil) && ([[sourceArrayController selectedObjects] count] == 1)) {
            NSManagedObjectContext *context = [destinationArrayController managedObjectContext];
            NSEntityDescription *destinationControllerEntity = [NSEntityDescription entityForName:[destinationArrayController entityName] inManagedObjectContext:context];
			
            NSArray *items = [urlStrings componentsSeparatedByString:@", "];
            NSMutableArray *itemsToAdd = [NSMutableArray array];
            
            unsigned int i, count = [items count];
            for (i = 0; i < count; i++) {
                NSString *urlString = [items objectAtIndex:i];
                
                // take the URL and get the managed object - assume all controllers using the same context
                NSURL *url = [NSURL URLWithString:urlString];
				NSManagedObjectID *objectID = [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation:url];
				if (objectID != nil) {
					id object = [context objectRegisteredForID:objectID];
					
					// make sure objects match the entity expected by the destination controller, and not already there
					if ((object != nil) && ([object entity] == destinationControllerEntity) && 
                        !([[destinationArrayController arrangedObjects] containsObject:object])) {
						[itemsToAdd addObject:object];
					}
				}
            }
            
			if ([itemsToAdd count] > 0) {
				[destinationArrayController addObjects:itemsToAdd];
				success = YES;
			}
        }
    }
    
    return success;   
}




@end
