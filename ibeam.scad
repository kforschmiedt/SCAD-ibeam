/*
 * I-Beams
 *
 * Copyright (C) 2020 Kent Forschmiedt
 */

use <beamlib.scad>

/* [Beam] */
BeamWidth = 10;
BeamHeight = 10;
BeamThickness = 1.8;
Length = 30;
Length2 = 60;
BeamRadius = 44;
BeamArc = 180;
BeamRotate = 0;

/* [Bracket] */
HeadAngle = 60;
JointInsertDepth = 20;
BracketMargin = 20;
BracketThickness = 1.2;
ScrewSize = 3.5;        // #6 == 3.5, #8 == 4.2
Relief = 0.15;
AxleYAdj = -18;

/* [Axle] */
AxleRadius = 3;
AxleSize = 150;         // try 80

/* [Pad] */
PadThickness = 1.5;

/* [Selection] */
DrawBeam = true;
DrawUBeam = false;
DrawHead = false;
DrawLJoint = false;
DrawRJoint = false;
DrawJunc = false;
DrawLAnchor = false;
DrawRAnchor = false;
DrawAxle = false;
DrawAxleEnds = false;
DrawEyes = false;
DrawWasher = false;
DrawBushing=false;
DrawSquirrel = false;
DrawEmblem = false;
DrawArch = false;
DrawPad = false;
DrawPadBase = false;

/* [Options] */

$fa = 1.1;
$fs = 1.2;

/*
 * beamAnchor - anchor bracket plate for beams
 *
 * size - [w, h, l]
 * angle - rotation of bracket
 * thickness - bracket wall thickness
 * relief - socket oversize
 * margin - bracket extension beyond boundary of socket
 * dscrew - diameter of screw #6 == 3.5, #8 == 4.2
 *
 * interior size is increased by Relief
 */
module beamAnchor(size, angle, thickness, relief=.15, margin=20, dscrew=3.5)
{
    width = size[0];
    height = size[1];
    length = size[2];
    
    rotate([0, 0, -angle])
        sqBeam([width, height, length], thickness, plug=true);

    w1 = length * sin(angle);
    l1 = length * cos(angle);
    translate([w1/2, l1/2, -height/2-thickness - 2*relief])
        grommet(h=2*thickness, r=dscrew/2, thickness=thickness,
                offset=[-(abs(w1) + margin)/2, 0, 0]) 
        grommet(h=2*thickness, r=dscrew/2, thickness=thickness,
                offset=[(abs(w1) + margin)/2, 0, 0]) 
        cube([abs(w1) + 2.5*margin, abs(l1) + margin/2, 2*thickness], center=true);
}


module axle(h, r)
{
    rotate([90, 0, 0])
    cylinder(h=h, r=r, center=true);
}

module axleEnds(r, relief=0.15)
{
    for (yoff = [0, 6*r])
        translate([6*r, yoff, 0])
        difference() {
            cylinder(h=6, r=2*r, center=true);
            translate([0,0,1.5])
            cylinder(h=4, r=r+2*relief, center=true);
        }
}

module squirrel() {    

    height = 3;
    xsize = 72;
    ysize = 64;
    yoff = -6;
    
    union() {
        translate([-xsize/2, -ysize/2+yoff, 0])
        resize([xsize, ysize, 0], auto=[true, false, false])
        linear_extrude(height=height)
            import("Squirrel-Silhouette-2.svg");
    }
}

module Emblem(width, height, r, arc, thickness, rot=0)
{
    translate([0,r+r,0]) {
        linear_extrude(height=3)
            circle(r=r - width/2 + .001);

        translate([-10, -r, 1.5])
            iBeam([3,3,20], 1);
        translate([10, -r, 1.5])
            iBeam([3,3,20], 1);

    }
}

module Arch(width, height, r, arc, thickness, rot=0)
{
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
            iBeam([width, height, r+.002], thickness);
        // right descender
        translate([r, -r/2, 0])
            iBeam([width, height, r+.002], thickness);
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
        translate([-r, -r/2, 0])
            iBeam([width, height, r+.002], thickness);
        // right descender
        translate([r, -r/2, 0])
            iBeam([width, height, r+.002], thickness);

        // sockets for emblem
        translate([-10, (rb-17)*cosa, 0])
        sqBeam([3, 3, 30*cosa], 2.5, plug=true);

        translate([10, (rb-17)*cosa, 0])
        sqBeam([3, 3, 30*cosa], 2.5, plug=true);
    }
}

module Pad(r, thickness, rim=true, screwsize=0, texture=false) {
    couplerHeight = 15;

    texangle = 80;
    texheight = 2.2;
    texbase = 2 * texheight * tan(texangle/2);
    texoff = 0;
    sqr3 = sqrt(3);
    
    // triangle for texture
    texpoints = [ [-texbase/2, -texheight/2],
                  [texbase/2, -texheight/2],
                  [0, texheight/2] ];
    crosshatch = [-35, 35];
    
    // grommet is no-op when screwsize == 0
    grommet(h=thickness, r=screwsize/2, thickness=thickness,
                offset=[.5*r, .5*r, thickness/2]) 
    grommet(h=thickness, r=screwsize/2, thickness=thickness,
                offset=[-.5*r, -.5*r, thickness/2]) 
    difference() {
        linear_extrude(height=2*thickness)
            circle(r);
        
        // Subtract half of disk, with or without rim
        translate([0,0,thickness])
        linear_extrude(height=thickness+1)
            circle(r-(rim?thickness:-.001));

        //subtract texture
        if (texture)
            for (x = [-r-8: 2*texbase: r+8], a = crosshatch)
                translate([x, 0, texoff])
                rotate([90,0,a])
                translate([0,0,-1.25*r])
                linear_extrude(2.5*r)
                    polygon(texpoints);
    }

    // put rim on face
    difference() {
        linear_extrude(height=thickness)
            circle(r);
        translate([0,0,-.5])
        linear_extrude(height=thickness+1)
            circle(r-thickness);
    }
    
    // socket
    translate([0,0,thickness - .001])
        rotate([90,0,0])
        sqBeam([BeamWidth, BeamHeight, couplerHeight + .001],
                thickness, plug=false);

    // radial braces
    basex = BeamWidth/2 + thickness;
    points = [ [basex, thickness],
               [r-thickness+.001, thickness],
               [r-thickness+.001, 2*thickness],
               [basex, thickness + couplerHeight],
               [basex, thickness] ];

    for (a = [0: 90: 360]) {
        rotate([90,0,a])
        translate([0,0,-thickness/2])
        linear_extrude(thickness)
            polygon(points);
    }
}

if (DrawPad) {
        Pad(BeamRadius, PadThickness, texture = true);
}

if (DrawPadBase)
        Pad(BeamRadius, PadThickness, screwsize=3.5, rim=false);

if (DrawEmblem)
    Emblem(BeamWidth, BeamHeight, BeamRadius, BeamArc, BeamThickness);

if (DrawArch) {
    Arch(BeamWidth, BeamHeight, BeamRadius, BeamArc, BeamThickness);    
}

if (DrawEyes)
    beamEye([BeamWidth, BeamHeight, AxleRadius, 30], BeamThickness);

if (DrawBeam) {
    iBeam([BeamWidth, BeamHeight, Length], BeamThickness, rot=0);
}

if (DrawUBeam) {
    uBeam([BeamWidth, BeamHeight, BeamRadius], BeamThickness, angle=BeamArc, rot=BeamRotate);
}

if (DrawHead) {
    translate([Length, -Length-10, 0])
    beamJunction([BeamWidth, BeamHeight, Length], angles=[HeadAngle],
                 thickness=BracketThickness, axleRadius=AxleRadius,
                 axleYoffset=AxleYAdj);
}

if (DrawLJoint) {
    translate([Length+10, Length, 0])
    beamJunction([BeamWidth, BeamHeight, Length], angles=[-HeadAngle,180],
                 thickness=BracketThickness);
}

if (DrawRJoint) {
    translate([Length, 3*Length+10, 0])
    beamJunction([BeamWidth, BeamHeight, Length], angles=[HeadAngle,180],
                 thickness=BracketThickness);
}

if (DrawJunc) {
    beamJunction([BeamWidth, BeamHeight, Length], angles=[60, 210],
                 thickness=BracketThickness, axleRadius=AxleRadius);
}

if (DrawLAnchor) {
    translate([-Length-30, Length, 0])
    beamAnchor([BeamWidth, BeamHeight, Length], HeadAngle/2, BracketThickness,
                Relief, BracketMargin, ScrewSize);
}

if (DrawRAnchor) {
    translate([-Length-15, -Length-10, 0])
    beamAnchor([BeamWidth, BeamHeight, Length], -HeadAngle/2, BracketThickness,
                Relief, BracketMargin, ScrewSize);
}

if (DrawAxle) {
    translate([-20, 0, 0])
    axle(AxleSize, AxleRadius - 4 * Relief);
}

if (DrawAxleEnds) {
    axleEnds(AxleRadius - 4 * Relief, relief=Relief);
}

if (DrawWasher) {
    grommet(h=2*BracketThickness, r=AxleRadius, thickness=5*BracketThickness);
}

if (DrawBushing) {
    grommet(h=50, r=AxleRadius, thickness=3*BracketThickness);
}

if (DrawSquirrel) {
    squirrel();
}