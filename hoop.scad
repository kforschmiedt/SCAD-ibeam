/*
 * hoop.scad
 *
 * Hoops and goalposts
 * flames
 */

use <beamlib.scad>

 /* [Beam] */
BeamWidth = 10;
BeamHeight = 10;
BeamThickness = 1.8;
Length = 30;
BeamRotate = 0;
Relief = 0.15;

/* [Arch] */
BeamRadius = 44;
BeamArc = 80;
SmBeamSize = 3.6;
SmBeamThick = 1.2;

/* [Hoop] */
Radius = 44;
Thickness = 2.5;
PinLength = 20;
PinSpacing = 60;

/* [SVG] */
SVGFile = "C:\\Users\\kentf\\Downloads\\file.svg";
SVGScale = 0.099;
SVGFlip = false;

/* [Options] */
$fa = 2;

/* [Selection] */
DrawHoop = false;
DrawArch = false;
DrawMedallion = false;
DrawSquirrel = false;
DrawSVG = false;

function AngleFromChord(r, chord) = 2*asin(chord/(2*r));

module hoop(
    radius,
    thickness,
    pin_thick=SmBeamThick,
    pin_length,
    pin_spacing
    )
{    
    difference() {
        rotate_extrude(angle=360)
        translate([radius, 0, 0])
        scale([.75,1,1])
            circle(r=.75*thickness,$fn=50);
        
        translate([0,0,thickness])
        linear_extrude(height=thickness, center=true)
            circle(r=radius+thickness);
        
        translate([0,0,-thickness])
        linear_extrude(height=thickness, center=true)
            circle(r=radius+thickness);
    }

    int_angle = AngleFromChord(radius, pin_spacing);
    //echo("Int_angle: ", int_angle);
    yoff = radius * cos(int_angle/2) + pin_length/2;
    
    translate([-pin_spacing/2, -yoff, 0])
        iBeam([thickness,thickness,pin_length], SmBeamThick);
    translate([pin_spacing/2, -yoff, 0])
        iBeam([thickness,thickness,pin_length], SmBeamThick);


}


module Arch(
    beamsize,
    r, 
    arc,
    leg_length,
    thickness,
    pin_size,
    pin_length,
    pin_spacing,
    relief=0.15,
    rot=0
    )
{
    width = beamsize;
    height = beamsize;
    
    variant = 1;
    
    if (variant == 0) {
        // left arc
        translate([-r/2, 0, 0])
            rotate([0,0,90])
            uBeam([width, height, r/2], thickness, angle=90, rot=BeamRotate);
        // right arc
        translate([r/2, 0, 0])
            uBeam([width, height, r/2], thickness, angle=90, rot=BeamRotate);
        // cross span
        translate([0, r/2, 0])
            rotate([0, 0, 90])
            iBeam([width, height, r+.002], thickness);
        // left descender
        translate([-r, -r/2, 0])
            iBeam([width, height, leg_length+.002], thickness);
        // right descender
        translate([r, -r/2, 0])
            iBeam([width, height, leg_length+.002], thickness);
    } else if (variant == 1) {

        rfrac = 8;

        a = arc;
        cosa = cos(a);
        sina = sin(a);        
        int_radius = r/rfrac - width/2;
        rb = r / sina;
        
        // left arc
        translate([-(rfrac-1)*r/rfrac, 0, 0])
            rotate([0,0,180-a])
            uBeam([width, height, r/rfrac], thickness, angle=a, rot=BeamRotate);
        // right arc
        translate([(rfrac-1)*r/rfrac, 0, 0])
            uBeam([width, height, r/rfrac], thickness, angle=a, rot=BeamRotate);

        // left riser
        translate([-r+width/2+int_radius, 0, 0])
        rotate([0,0,-a])
        translate([-width/2-int_radius, rb/2 ,0]) 
            iBeam([width, height, rb + .002], thickness, rot=BeamRotate);

        // right riser
        translate([r-width/2-int_radius, 0, 0]) 
        rotate([0,0,a])
        translate([width/2+int_radius, rb/2 ,0]) 
            iBeam([width, height, rb + .002], thickness, rot=BeamRotate);        

        // left descender
        translate([-r, -leg_length/2, 0])
            iBeam([width, height, leg_length+.002], thickness);
        // right descender
        translate([r, -leg_length/2, 0])
            iBeam([width, height, leg_length+.002], thickness);

        // sockets for emblem
        for (xoff = [-pin_spacing/2, pin_spacing/2])
            translate([xoff, -10, 0])
            sqBeam([pin_size, pin_size, pin_length],
                   (beamsize - pin_size)/2,
                   relief=1.5*relief, plug=false);
    }
}


module Emblem(file, size, scale, rotate=[0,0,0])
{
    xsize = size[0]; // 72;
    ysize = size[1]; // 64;
    height = size[2];
    
    xscale = scale;
    yscale = scale;
    zscale = 1;
    
    // these only matter for preview
    xoff = 0;
    yoff = -9;
    
    union() {
        rotate(rotate)
        translate([-xsize/2+xoff, -ysize/2+yoff, 0 /* -height/2 */])
//       resize([xsize, ysize, height], auto=[false, false, false])
        scale([xscale, yscale, zscale])
        linear_extrude(height=height)
            import(file);
    }
}

module Medallion(r,
                 thickness,
                 pin_thick,
                 pin_length,
                 pin_spacing,
                 rot=0)
{
    int_angle = AngleFromChord(r, pin_spacing);
    //echo("Int_angle: ", int_angle);
    // this serves until pin intersects past 45 degrees
    yoff = r * cos(int_angle/2) + pin_length/2 - thickness;

    translate([0,0,-thickness/2])
    linear_extrude(height=thickness)
        circle(r=r);
    // mounting pins
    translate([-pin_spacing/2, -yoff, 0])
        iBeam([thickness,thickness,pin_length], pin_thick);
    translate([pin_spacing/2, -yoff, 0])
        iBeam([thickness,thickness,pin_length], pin_thick);
}


if (DrawHoop) {
    hoop(Radius,
         Thickness,
         pin_thick=SmBeamThick,
         pin_length=PinLength,
         pin_spacing=PinSpacing);
}

if (DrawArch) {
    Arch(BeamWidth,
         BeamRadius,
         BeamArc,
         Length,
         BeamThickness,
         pin_size=SmBeamSize,
         pin_length=PinLength,
         pin_spacing=PinSpacing,
         relief=Relief);    
}

if (DrawMedallion)
    Medallion(BeamRadius,
           SmBeamSize,
           SmBeamThick,
           PinLength,
           PinSpacing);

if (DrawSquirrel) {
    Emblem("data/Squirrel-Silhouette-2.svg", [72, 64, 1.6], 0.1);
}

if (DrawSVG) {
    Emblem(SVGFile, [72, 64, 1.6], SVGScale, rotate=[0,SVGFlip?180:0,0]);
}
