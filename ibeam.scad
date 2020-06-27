/*
 * I-Beams
 *
 * Copyright (C) 2020 Kent Forschmiedt
 */
 
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

/* [Options] */

$fa = 1.1;
$fs = 1.2;

/*
 * grommet - Put a screw grommet in something.
 *
 * h - height
 * r - radius
 * thickness - grommet wall
 *
 * This will punch a hole through any number of objects
 */
module grommet(h, r, thickness, offset=[0,0,0])
{
    if ($children == 0) {
        translate(offset)
        difference() {
            cylinder(h=h, r=r+thickness, center=true);
            cylinder(h=h+1, r=r, center=true);
        }
    } else {
        difference() {
            union() {
                translate(offset)
                    cylinder(h=h, r=r+thickness, center=true);
                children();
            }
            translate(offset)
                cylinder(h=h+1, r=r, center=true);
        }
    }
}

/*
 * iBeam - simple I-beam
 *
 * size - width, height, length
 * thickness - rail thickness
 * rot - degrees: optionally rotate beam around length axis
 *
 * Z and Y are swapped, so length is in the Y axis
 *
 * For larger beams, it would be nice to round the
 * ends of the rails.
 */
function iBeamPoints(size, thickness) = [ for (e = [
            [0,0], [0,size[1]], [thickness,size[1]],
            [thickness, (size[1]+thickness)/2],
            [size[0]-thickness,(size[1]+thickness)/2],
            [size[0]-thickness, size[1]],[size[0], size[1]],
            [size[0],0], [size[0]-thickness,0],
            [size[0]-thickness, (size[1]-thickness)/2],
            [thickness, (size[1]-thickness)/2],
            [thickness,0],[0,0] ]) e - [size[0]/2, size[1]/2] ];

module iBeam(size, thickness, rot=0)
{
    width = size[0];
    height = size[1];
    length = size[2];
    rotate([90,rot,0])
    translate([0,0,-length/2])
    linear_extrude(length)
        polygon(iBeamPoints(size, thickness));
}

/*
 * uBeam - Curved I-beam
 *
 * size - width, height, length
 * thickness - rail thickness
 * angle - degrees of arc to extrude
 * rot - degrees: optionally rotate beam around length axis
 *
 * Z and Y are swapped, so length is in the Y axis
 *
 * For larger beams, it would be nice to round the
 * ends of the rails.
 */
module uBeam(size, thickness, angle=180, rot=0)
{
    rotate_extrude(angle=angle)
        translate([size[2], 0, 0])
        rotate([0,0,rot])
        polygon(iBeamPoints(size, thickness));
}

/*
 * sqBeam - a hollow box beam
 *
 * size - w, h, l
 * thickness - wall of box
 * plug - bool, leaves 1/3 solid
 *
 * Z and Y are swapped, so length is in the Y axis
 *
 * A rounded corner version would be good
 */
module sqBeam(size, thickness, plug=false)
{
    width = size[0];
    height = size[1];
    length = size[2];
    relief = Relief;
    
    translate([0, length/2, 0])
    difference() {
        cube([width+2*thickness, length, height+2*thickness], center=true);    
        translate([0,plug? length-JointInsertDepth : 0, 0])
        cube([width+2*relief, length+1, height+2*relief], center=true);
    }
}

/*
 * beamAnchor - anchor bracket plate for beams
 *
 * size - [w, h, l]
 * angle - rotation of bracket
 * thickness - bracket wall thickness
 *
 * interior size is increased by Relief
 */
module beamAnchor(size, angle, thickness)
{
    width = size[0];
    height = size[1];
    length = size[2];
    relief = Relief;
    dgrom = ScrewSize;    // #6 == 3.5, #8 == 4.2
    
    rotate([0, 0, -angle])
        sqBeam([width, height, length], thickness, plug=true);

    w1 = length * sin(angle);
    l1 = length * cos(angle);
    translate([w1/2, l1/2, -height/2-thickness - 2*relief])
        grommet(h=2*thickness, r=dgrom/2, thickness=thickness,
                offset=[-(abs(w1) + BracketMargin)/2, 0, 0]) 
        grommet(h=2*thickness, r=dgrom/2, thickness=thickness,
                offset=[(abs(w1) + BracketMargin)/2, 0, 0]) 
        cube([abs(w1) + 2.5*BracketMargin, abs(l1) + BracketMargin/2, 2*thickness], center=true);
}

/*
 * _beamJunc
 */
module _beamJunc(size, angles, thickness, lengths=[])
{
    width = size[0];
    height = size[1];
    length = size[2];

    union() {
        sqBeam([width, height, length], thickness, plug=true);
        for (a = angles) {
            rotate([0, 0, a])
            translate([0,-.001, 0])
                sqBeam([width, height, length], thickness, plug=true);
        }
    }
}


module _headPlate(size, angle, thickness, joint=false)
{
    width = size[0];
    height = size[1];
    length = size[2];
    wsize = width+thickness;
    
    hull() {
        rotate([0, 0, -angle/2])
        translate([-wsize/2, 0, 0])
          cube([wsize, length, thickness], center=false);
        rotate([0, 0, angle/2])
        translate([-wsize/2, 0, 0])
          cube([wsize, length, thickness], center=false);
        if (joint) {
            rotate([0, 0, 180-angle/2])
            translate([-wsize/2,.1,0])
                cube([wsize, length, thickness], center=false);
        }
    }
}

module _juncPlate(size, angles, thickness)
{
    width = size[0];
    height = size[1];
    length = size[2];
    wsize = width+thickness;
    
    hull() {
        translate([-wsize/2, 0, 0])
          cube([wsize, length, thickness], center=false);
        for (a = angles) {
            rotate([0, 0, a])
            translate([-wsize/2, 0, 0])
                cube([wsize, length, thickness], center=false);
        }
    }
}

/*
 * beamJunction - Join n ends together
 */
module beamJunction(size, angles, thickness, lengths=[], axleRadius=-1)
{
    width = size[0];
    height = size[1];
    length = size[2];
    relief = Relief;

    plateThickness = 2*thickness;
    
    zoff = height / 2
         + relief           // Surface of centered beam
         + 2* thickness     // plate is 2 * thickness, uncentered
         + relief;          // put top of plate below bottom of beam

    // axle bushing
    l1 = length * cos(angles[0]);
    bushingThickness = 2*thickness;
    gheight = height + 3*thickness;
    axleZoff = -thickness + 4*relief;    //
    axleYoff = (abs(l1) + height/2 + AxleYAdj);

    if (axleRadius > 0) {
        grommet(h=gheight, r=axleRadius, thickness=bushingThickness,
                offset=[0, axleYoff, axleZoff])
        {
            rotate([0, 0, -angles[0]/2])
            union() {
                _beamJunc(size, angles, thickness, lengths=lengths);
                translate([0, 0, -zoff])
                    // Does not include extended legs!
                    _juncPlate(size, angles, plateThickness);
            }
        }
    } else {
        rotate([0,0,-angles[0]/2])
        union() {
            _beamJunc(size, angles, thickness, lengths=lengths);
            translate([0,0, -zoff])
                _juncPlate(size, angles, plateThickness);
        }
    }
}

module axle(h, r)
{
    rotate([90, 0, 0])
    cylinder(h=h, r=r, center=true);
}

module axleEnds(r)
{
    for (yoff = [0, 6*r])
        translate([6*r, yoff, 0])
        difference() {
            cylinder(h=6, r=2*r, center=true);
            translate([0,0,1.5])
            cylinder(h=4, r=r+2*Relief, center=true);
        }
}

module beamEye(size, thickness)
{
    width = size[0];
    height = size[1];
    length = size[2];
    relief = Relief;
    rgrom = AxleRadius;
    gthick = width + 2* thickness;

    grommet(h=gthick, r=rgrom, thickness=gthick/2-rgrom,
                offset=[0, 0, 0]) 
    sqBeam([width, height, length], thickness, plug=true);
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

        translate([-10, rb/2*cosa + 8, 0])
        sqBeam([3, 3, 15], 2.5, plug=true);

        translate([10, rb/2*cosa + 8, 0])
        sqBeam([3, 3, 15], 2.5, plug=true);
    }
}

if (DrawEmblem)
    Emblem(BeamWidth, BeamHeight, BeamRadius, BeamArc, BeamThickness);

if (DrawArch) {
    Arch(BeamWidth, BeamHeight, BeamRadius, BeamArc, BeamThickness);    
}

if (DrawEyes)
    beamEye([BeamWidth, BeamHeight, 30], BeamThickness);

if (DrawBeam) {
    iBeam([BeamWidth, BeamHeight, Length], BeamThickness, rot=0);
}

if (DrawUBeam) {
    uBeam([BeamWidth, BeamHeight, BeamRadius], BeamThickness, angle=BeamArc, rot=BeamRotate);
}

if (DrawHead) {
    translate([Length, -Length-10, 0])
    beamJunction([BeamWidth, BeamHeight, Length], angles=[HeadAngle],
                 thickness=BracketThickness, axleRadius=AxleRadius);
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
    beamAnchor([BeamWidth, BeamHeight, Length], HeadAngle/2, BracketThickness);
}

if (DrawRAnchor) {
    translate([-Length-15, -Length-10, 0])
    beamAnchor([BeamWidth, BeamHeight, Length], -HeadAngle/2, BracketThickness);
}

if (DrawAxle) {
    translate([-20, 0, 0])
    axle(AxleSize, AxleRadius - 4 * Relief);
}

if (DrawAxleEnds) {
    axleEnds(AxleRadius - 4 * Relief);
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