include<openscad-screw-holes/screw_holes.scad>;

$fn=32;
arm_y_distance = 25;
plate_z = 2;
plate_rounding = 7;
arm_rounding = 2;

screw_driver_handle_padding = 3;
arm_thickness = 3;
arm_offset = 0;
plate_y = arm_y_distance + arm_thickness *2;
plate_padding_x = 3;
plate_padding_y = 5;

main_outer_side = 12.99;
grid_spacing = 40.88;
screw_m = M3;
screw_type = ISO14581;

// [<shaft_width>, <handle_width>]
arms = [
    [3.5, 14],
    [7.5, 18],
    [7.5, 18],
    [7.5, 18],
    [11, 39.8]
];

// calculate arm_length
lengths = [for (arm = arms) each arm[1]];
arm_length = max(lengths) + screw_driver_handle_padding;


// calculate arm width
function sum_arm_widths(arms, i=0) = i>=len(arms) ? 0 : (arms[i][1]) + sum_arm_widths(arms, i+1);

_plate_x = sum_arm_widths(arms);
//- arms[len(arms) -1][1] + arms[len(arms) -1][0] + 2 * arm_thickness + 2 * arm_thickness;
screw_hole_distance_units = floor((_plate_x - 10 + plate_padding_x * 2)/ grid_spacing);
screw_hole_spacing = grid_spacing * screw_hole_distance_units;

module rounded_cube(size, r, double_sided = true) {
    translate([r, r, 0]) hull() {
        if(double_sided) {
            translate([0, 0, 0]) cylinder(r=r, h=size[2]);
        } else {
            translate([-r, -r, 0]) cube([size[0], r, size[2]]);
        }
        translate([size[0] - r * 2, 0, 0]) cylinder(r=r, h=size[2]);
        translate([0, size[1] - r * 2, 0]) cylinder(r=r, h=size[2]);
        translate([size[0] - r * 2, size[1] - r * 2, 0]) cylinder(r=r, h=size[2]);
    }
}


module draw_fillet(arms, idx) {
    arm_width = arms[idx][0] + 2 * arm_thickness;
    difference() {
        union() {
            // +y fillet
            translate([-3, 3, 0]) rotate([90, 0, 0]) difference() {
                cube([arm_width + 6, 3, arm_thickness]);
            }
            // -y fillet
            translate([-3, -3, 0]) rotate([90, 0, 0]) difference() {
                cube([arm_width + 6, 3, arm_thickness]);
            }

            // +x fillet
            translate([-3, - 3, 0]) rotate([0, 0, 0]) difference() {
                translate([0, -3, 0]) cube([3, arm_thickness + 6, arm_thickness]);
            }
            //-x fillet
            translate([arm_width, -3, 0]) rotate([0, 0, 0]) difference() {
                translate([0, -3, 0]) cube([3, arm_thickness + 6, arm_thickness]);
            }
        }
        union() {
            // +y fillet
            translate([-3, 3, 0]) rotate([90, 0, 0]) difference() {
                translate([0, 3, 0]) rotate([0, 90, 0]) cylinder(r=3, h=arm_width + 6);
            }
            // -y fillet
            translate([-3, -3, 0]) rotate([90, 0, 0]) difference() {
                translate([0, 3, 3]) rotate([0, 90, 0]) cylinder(r=3, h=arm_width + 6);
            }

            // +x fillet
            translate([-3, -3, 0]) rotate([0, 0, 0]) difference() {
                translate([0, 6, 3]) rotate([90, 0, 0]) cylinder(r=3, h=arm_thickness + 6);
            }
            //-x fillet
            translate([arm_width, -3, 0]) rotate([0, 0, 0]) difference() {
                translate([3, 6, 3]) rotate([90, 0, 0]) cylinder(r=3, h=arm_thickness + 6);
            }
        }
    }    
}

module draw_arm(arms, idx) {
        arm_width = arms[idx][0] + 2 * arm_thickness;
        rotate([90, 0, 0]) difference() {
            rounded_cube([arm_width, arm_length, arm_thickness], arm_rounding, double_sided=false);
            translate([arm_width / 2, arm_length - (arm_width / 4) - (arms[idx][0] / 2), 0]) cylinder(d=arms[idx][0], h=20);
        }
        draw_fillet(arms, idx);
}

module draw_arms(arms, idx=0) {
    if (idx < len(arms)) {
        arm_width = arms[idx][0] + 2 * arm_thickness;
        translate([(arms[idx][1] / 2)- (arm_width / 2), 0, 0]) union() {
            // top arm
            translate([0, arm_thickness + arm_offset, 0]) draw_arm(arms, idx);
            // bottom arm
            translate([0, plate_y - arm_offset, 0]) draw_arm(arms, idx);
        }
        translate([arms[idx][1], 0, 0])
        draw_arms(arms, idx + 1);
    }
//        if(idx + 1 == len(arms)) {
//            translate([(arms[idx][1]) / 2, 0, 0])  difference() {
//                draw_arms(arms, idx + 1);
//            }
//        } else {
//            translate([(arms[idx][1]), 0, 0])  difference() {
//                draw_arms(arms, idx + 1);
//            }
//        }
//    }
}


module bbox() { 

    // a 3D approx. of the children projection on X axis 
    module xProjection() 
        translate([0,1/2,-1/2]) 
            linear_extrude(1) 
                hull() 
                    projection() 
                        rotate([90,0,0]) 
                            linear_extrude(1) 
                                projection() children(); 

    // a bounding box with an offset of 1 in all axis
    module bbx()  
        minkowski() { 
            xProjection() children(); // x axis
            rotate(-90)               // y axis
                xProjection() rotate(90) children(); 
            rotate([0,-90,0])         // z axis
                xProjection() rotate([0,90,0]) children(); 
        } 
    
    // offset children() (a cube) by -1 in all axis
    module shrink()
        intersection() {
            translate([ 1, 1, 1]) children();
            translate([-1,-1,-1]) children();
        }

    shrink() bbx() children(); 
}


// arms
translate([0, 0, plate_z]) draw_arms(arms);

// base plate
difference() {
    translate([0 - plate_padding_x, 0 - plate_padding_y, 0]) rounded_cube([_plate_x + plate_padding_x * 2 , plate_y + plate_padding_y * 2, plate_z], plate_rounding);

    // screw holes
    translate([((_plate_x - screw_hole_spacing) / 2), plate_y / 2, plate_z]) rotate([180, 0, 0]) screw_hole(screw_type, screw_m, plate_z);
    translate([ + ((_plate_x - screw_hole_spacing) / 2) + screw_hole_spacing, plate_y / 2, plate_z]) rotate([180, 0, 0]) screw_hole(screw_type, screw_m, plate_z);
}

// module screw_holes(count=20) {
//     if(count > 0) {
//         color("blue") cylinder(d=3, h=10);
//         translate([grid_spacing, 0, 0]) screw_holes(count - 1);
//     }
// }

// intersection() {
//     translate([0, plate_y / 2, 0]) screw_holes();
//     bbox() draw_arms(arms);
// }