//
//  AnAppTableViewCell.m
//  peekMyApps
//
//  Created by Julio Carrettoni on 11/28/14.
//  Copyright (c) 2014 Julio Carrettoni. All rights reserved.
//

#import "AnAppTableViewCell.h"

@implementation AnAppTableViewCell {
    __weak IBOutlet UILabel *appName;
    __weak IBOutlet UIImageView *icon;
}

- (void)awakeFromNib {
    // Initialization code
}

- (void) setAppInfo:(NSDictionary*) appInfo {
    appName.text = (appInfo[@"name"]?:appInfo[@"id"]);
    icon.image = appInfo[@"icon"];
    
    if (appInfo[@"trackViewUrl"]) {
        self.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    }
    else {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
