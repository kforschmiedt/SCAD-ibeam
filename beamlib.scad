/*
 * beamlib.scad
 */
 
 _DefaultRelief = .015;
 _JointInsertDepth = 15;
 
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
    } else if (r == 0) {
        children();
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
    linear_extrude(height=length)
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
module sqBeam(size, thickness, plug=false, relief=_DefaultRelief)
{
    width = size[0];
    height = size[1];
    length = size[2];
    
    translate([0, length/2, 0])
    difference() {
        cube([width+2*thickness, length, height+2*thickness], center=true);    
        translate([0,plug? length-_JointInsertDepth : 0, 0])
        cube([width+2*relief, length+1, height+2*relief], center=true);
    }
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
module beamJunction(size, angles, thickness, lengths=[], axleRadius=-1, relief=_DefaultRelief, axleYoffset=0)
{
    width = size[0];
    height = size[1];
    length = size[2];

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
    axleYoff = (abs(l1) + height/2 + axleYoffset);

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


module beamEye(size, thickness, rgrommet, relief=_DefaultRelief)
{
    width = size[0];
    height = size[1];
    length = size[2];
    gthick = width + 2* thickness;

    grommet(h=gthick, r=rgrommet, thickness=gthick/2-rgrommet,
                offset=[0, 0, 0]) 
    sqBeam([width, height, length], thickness, plug=true);
}