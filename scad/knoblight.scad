include <openscad-bits/lib.scad>
include <openscad-bits/lib/pcbs.scad>
use <openscad-bits/lib.scad>

$fn = 32;

knob_chamfer = 1;
knob_radius = 55.4 / 2;
knob_height = 19;
knob_angle = 15;
knob_rotation = [ 0, -knob_angle, 0 ];
knob_rotation_inversed = [ 0, knob_angle, 0 ];

base_height = 12;

bottom_plate_thickness = 1.5;

body_top_thickness = 2.5;

module wemos_d1_mini_esp8266_origin()
{
    translate([ 23, 0, bottom_plate_thickness ]) rotate([ 0, 0, 90 ]) children();
}

module rotary_encoder_origin()
{
    knob_origin() translate([ 0, 0, -body_top_thickness ]) children();
}

module knob()
{
    difference()
    {
        knob_origin() difference()
        {
            union()
            {
                $fn = 360;
                translate([ 0, 0, knob_height - knob_chamfer ]) hull()
                {
                    linear_extrude(height = thin) circle(r = knob_radius);
                    translate([ 0, 0, knob_chamfer ]) linear_extrude(height = thin) offset(delta = -knob_chamfer)
                        circle(r = knob_radius);
                }

                cylinder(h = knob_height - knob_chamfer, r = knob_radius);
            }

            translate([ knob_radius / 2, 0, knob_height + 50 / 2 - 1 ]) sphere(r = 50 / 2);
        }
        rotary_encoder_origin() rotary_encoder(body_top_thickness, cutout = true);
    }
}

module knob_origin()
{
    base_origin() translate([ 0, 0, base_height + 0.5 ]) children();
}

module base()
{
    difference()
    {
        clip(zmin = 0) base_origin() translate([ 0, 0, -tan(knob_angle) * knob_radius * 2 ]) difference()
        {
            $fn = 360;
            cylinder(h = base_height + (tan(knob_angle) * knob_radius * 2), r = knob_radius);
            cylinder(h = base_height + (tan(knob_angle) * knob_radius * 2) - 4, r = knob_radius - 4);
        }

        rotary_encoder_origin() rotary_encoder(body_top_thickness, cutout = true);
        translate([ -4, 0, 0 ]) wemos_d1_mini_esp8266_origin() cube([ wemos_d1_mini_esp8266_width + 2, 10, 8 ], true);
        translate([ knob_radius, 0, 0 ]) cube([ 10, 12, 17 ], true);
        bottom_plate();
    }
}

module base_origin()
{
    translate([ 0, 0, sin(knob_angle) * knob_radius ]) rotate(knob_rotation) children();
}

module bottom_plate()
{
    linear_extrude(bottom_plate_thickness)
    {
        projection() clip(zmax = thin) clip(zmin = 0) base_origin()
            translate([ 0, 0, -tan(knob_angle) * knob_radius * 2 ])
                cylinder(h = base_height + (tan(knob_angle) * knob_radius * 2) - 4, r = knob_radius - 2);

        projection() wemos_d1_mini_esp8266_origin() wemos_d1_mini_esp8266_supports();
    }

    wemos_d1_mini_esp8266_origin() wemos_d1_mini_esp8266_supports();
}

if ($preview)
{
    clip(ymin = 0) // uncomment if you want to see the inside
    {
        knob();
        base();
    }
    render() bottom_plate();

    rotary_encoder_origin() rotary_encoder(body_top_thickness);
    wemos_d1_mini_esp8266_origin() wemos_d1_mini_esp8266();
}
else
{
    translate([ knob_radius * 2 + 10, 0, -19.42 ]) rotate(knob_rotation_inversed) knob();
    translate([ 0, 0, 18.95 ]) rotate([ 180, 0, 0 ]) rotate(knob_rotation_inversed) base();
    translate([ 0, knob_radius * 2 + 10, 0 ]) bottom_plate();
}