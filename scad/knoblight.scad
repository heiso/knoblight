include <openscad-bits/lib.scad>
use <openscad-bits/lib.scad>

thin = 0.00001;
$fn = 360;
inf = 1e10;

knob_chamfer = 1;
knob_radius = 55.4 / 2;
knob_height = 19;
knob_angle = 15;
knob_rotation = [ 0, -knob_angle, 0 ];

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
            cylinder(h = base_height + (tan(knob_angle) * knob_radius * 2), r = knob_radius);
            cylinder(h = base_height + (tan(knob_angle) * knob_radius * 2) - 4, r = knob_radius - 4);
        }

        rotary_encoder_origin() rotary_encoder(body_top_thickness, cutout = true);
        wemos_d1_mini_esp8266_origin() wemos_d1_mini_esp8266(cutout = true);
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
    $fn = 36;
    clip(ymin = 0)
    {
        knob();
        base();
    }
    bottom_plate();

    rotary_encoder_origin() rotary_encoder(body_top_thickness);
    wemos_d1_mini_esp8266_origin() wemos_d1_mini_esp8266();
}
else
{
    knob();
    // base();
    // translate([ -100, 0, 0 ]) bottom_plate();
}