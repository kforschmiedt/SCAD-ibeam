/*
 * hoop.scad
 *
 * Copyright (C) Kent Forschmiedt 2020, All Rights Reserved
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
SVGFile = "data\\Squirrel-Silhouette-2.svg";
SVGx = 30;
SVGy = 0;
SVGz = 1.6;
SVGScale = 0.099;
SVGFlip = false;
SVGGrommetX = 1.1;
SVGGrommetY = 1.1;
SVGGrommetR = .6;

/* [Options] */
$fa = 2.2;
$fn = 1.2;

/* [Selection] */
DrawHoop = false;
DrawArch = false;
DrawMedallion = false;
DrawSquirrel = false;
DrawSVG = false;

module _dummy() {}

SVGSize = [SVGx, SVGy, SVGz];

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

function _auto(n) = ((n)!=-1);
function _aval(n) = ((n<0)?0:(n));

module Emblem(file, size, rotate=[0,0,0], gradius=0, grx=0, gry=0)
{
    rsize=[_aval(size[0]),_aval(size[1]),_aval(size[2])];
    rauto=[_auto(size[0]),_auto(size[1]),_auto(size[2])];
    
    grommet(h=rsize[2], r=gradius, offset=[grx, gry, rsize[2]/2]) {
        rotate(rotate)
        resize(rsize, auto=rauto)
        linear_extrude(height=1)
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
    Emblem("data/Squirrel-Silhouette-2.svg", [72, 64, 1.6], grx=SVGGrommetX, gry=SVGGrommetY, gradius=SVGGrommetR);
}

if (DrawSVG) {
    Emblem(SVGFile, SVGSize, rotate=[0,SVGFlip?180:0,0], grx=SVGGrommetX, gry=SVGGrommetY, gradius=SVGGrommetR);
}
