//
// UOY Blade Antenna - Parameters changed to reduce meshing time.
//
// Symmetry plane in y-z plane.
//

Printf( "*** WARNING - Dimensions require validation against physical antenna! ***" );

// Geometrical parameters.
bladeHeight = 0.303;         // Height of blade, excluding feed height. [m].
bladeLength = 0.250;         // Length of blade [m].
cornerRadius = 0.02;         // Radius of blade upper corners [m].
taperHeightAtFeed = 1e-2;    // Taper height at feed point [m].
tiltAngleDeg = 0;            // Angle of tilt of blade, negative for downwards tilt [degrees].
chordLength = 0.263;         // Length of chord of segment cut from back edge of blade [m].
segmentHeight = 0.015;       // Height of segment cut from back edge of blade [m].
gpLength = 0.37;             // Length of ground plane [m].
gpHalfWidth = 0.15;          // Width of ground plane [m].
blockWidth = 1e-2;           // Feed block width [m].
blockHeight = 2e-2;          // Feed block height [m].
blockLength = 1e-2;          // Feed block length [m].
feedWireLength = 1e-2;       // Length of feed wire [m].
dielRadius = 0.015;          // Radius of dielectric cylinder [m].
dielCentreFromGPEdge = 0.04; // Centre of dielectric intersection with ground plane [m].
dielCentreBelowTop = 0.114;  // Distance of dielectric intersection with blade below top of blade [m].

// Meshing parameters.
globalMeshSize = 2e-2;       // Global mesh size ~ lambda/10 [m].
feedMeshSize = 0.5e-2;       // Mesh size around feed point [m].
dielMeshSize = 0.5e-2;	     // Mesh size on dielectric [m].
numPointTaper = 50;          // Number of points on taper [m].
isGeometricTaperGrading = 1; // Geometric (1) or arithmetic (0) mesh grading along taper.

//
// Blade.
//

// Total height of blade including feed height.
totalHeight = bladeHeight + taperHeightAtFeed;

// Height of end of taper above ground plane. 
taperHeightMax = totalHeight - cornerRadius;

// Ratio for geometric mesh size grading. 
ratio = ( globalMeshSize / feedMeshSize )^( 1 / numPointTaper );

// Difference for arithmetic mesh size grading. 
diff = feedMeshSize / 4;

// Create points for taper noting start (BP1) and end points (BP2).
p = newp;
BP1 = p;
For n In {1:numPointTaper}
   If ( isGeometricTaperGrading == 1 )
      // Geometric mesh grading.
      meshSize = ratio^n * feedMeshSize;
   EndIf
   If ( isGeometricTaperGrading != 1 )
      // Arithmetic mesh grading.
      meshSize = feedMeshSize + (n - 1) * diff;
   EndIf
   y = 0.0 + ( n - 1 ) * bladeLength / numPointTaper;
   z = taperHeightAtFeed * ( taperHeightMax / taperHeightAtFeed )^( y / bladeLength );
   Point(p) = { 0.0 , y , z , meshSize };
   p = newp;
EndFor
BP2 = p;
Point(BP2) = { 0.0 , bladeLength , taperHeightMax , meshSize };

// The taper.
BL1 = newl;
Spline(BL1) = { BP1:BP2 };

// Position of centre of corner at front of blade.
y_frontCornerCentre = bladeLength - cornerRadius;

// Position of centre of corner at back of blade.
y_backCornerCentre = cornerRadius;

// Height of end of chord above ground plane.
z_backStep = totalHeight - cornerRadius - chordLength;

// Radius of circle forming segment arc.
chordRadius = 0.5 * segmentHeight + chordLength^2 / segmentHeight / 8;

// Location of centre of circle forming segment arc.
z_segmentCentre = ( taperHeightMax + z_backStep ) / 2;
y_segmentCentre = -chordRadius + segmentHeight;

// Circular arc corner at top of taper.
BC1 = newp;
Point(BC1) = { 0.0 , y_frontCornerCentre , taperHeightMax , globalMeshSize };
BP3 = newp;
Point(BP3) = { 0.0 , y_frontCornerCentre , totalHeight , globalMeshSize };
BL2 = newl;
Circle(BL2) = { BP2 , BC1 , BP3 };

// Top of blade.
BP4 = newp;
Point(BP4) = { 0.0 , y_backCornerCentre , totalHeight , globalMeshSize };
BL3 = newl;
Line(BL3) = { BP3 , BP4 };

// Circular arc corner at back or blade.
BC2 = newp;
Point(BC2) = { 0.0 , y_backCornerCentre , taperHeightMax , globalMeshSize };
BP5 = newp;
Point(BP5) = { 0.0 , 0.0   , taperHeightMax , globalMeshSize };
BL4 = newl;
Circle(BL4) = { BP4 , BC2 , BP5 };

// Circular segment on the backside of blade.
BC3 = newp;
Point(BC3) = { 0.0, y_segmentCentre , z_segmentCentre , globalMeshSize };
BP6 = newp;
Point(BP6) = { 0.0, 0.0 , z_backStep , 10 * feedMeshSize };
BL5 = newl;
Circle(BL5) = { BP5 , BC3 , BP6 };

// Back step.
BP7 = newp;
Point(BP7) = { 0.0, 0.0 , z_backStep / 2 , feedMeshSize };
BL6 = newl;
Line(BL6) = { BP6 , BP7 };
BL7 = newl;
Line(BL7) = { BP7 , BP1 };

// Tilt blade around x axis.
Rotate { { 1 , 0 , 0 } , { 0 , 0 , 0 } ,  Pi * tiltAngleDeg / 180 } { Line{  BL1 , BL2 ,  BL3 , BL4 , BL5 , BL6 , BL7 }; }

// Blade outer perimeter.
BLL1 = newll;
Line Loop(BLL1) = { BL1 , BL2 ,  BL3 , BL4 , BL5 , BL6 , BL7 };

// Centre line of dielectric in y direction.
y_dielCentre = 0.5 * bladeLength;                                                

// Centre of intersection with blade in z direction.
z_dielCentre = taperHeightMax - dielCentreBelowTop;

// Surface of dielectric's intersection with blade.
BC4 = newp;
Point(BC4)  = { 0.0 , y_dielCentre              , z_dielCentre              , dielMeshSize };
BP8 = newp;
Point(BP8)  = { 0.0 , y_dielCentre + dielRadius , z_dielCentre              , dielMeshSize };
BP9 = newp;
Point(BP9)  = { 0.0 , y_dielCentre              , z_dielCentre + dielRadius , dielMeshSize };
BP10 = newp;
Point(BP10) = { 0.0 , y_dielCentre - dielRadius , z_dielCentre              , dielMeshSize };
BP11 = newp;
Point(BP11) = { 0.0 , y_dielCentre              , z_dielCentre - dielRadius , dielMeshSize };

BL8 = newl;
Circle(BL8)  = { BP8  , BC4 , BP9  };
BL9 = newl;
Circle(BL9)  = { BP9  , BC4 , BP10 };
BL10 = newl;
Circle(BL10) = { BP10 , BC4 , BP11 };
BL11 = newl;
Circle(BL11) = { BP11 , BC4 , BP8  };

BLL2 = newll;
Line Loop(BLL2) = { BL8 , BL9 , BL10 , BL11 };

BS1 = news;
Plane Surface(BS1) = { BLL2 };
Physical Surface( "BladeDielIntSurface" ) = { BS1 };

BS2 = news;
Plane Surface(BS2) = { BLL1 , BLL2 };

Physical Surface( "Blade" ) = { BS2 , BS1 };

//
// Ground plane.
//

// Length of extension of ground plane from back edge of blade to accommodate feed block and wire.
gpBackExtension = blockLength + feedWireLength;

// The ground plane, excluding the part under the feed block.
GP1 = newp;
Point(GP1) = { 0.0         , 0.0                            , 0.0 , feedMeshSize   };
GP2 = newp;
Point(GP2) = { 0.0         , -gpBackExtension + blockLength , 0.0 , feedMeshSize   };
GP3 = newp;
Point(GP3) = { blockWidth  , -gpBackExtension + blockLength , 0.0 , feedMeshSize   };
GP4 = newp;
Point(GP4) = { blockWidth  , -gpBackExtension               , 0.0 , feedMeshSize   };
GP5 = newp;
Point(GP5) = { gpHalfWidth , -gpBackExtension               , 0.0 , globalMeshSize };
GP6 = newp;
Point(GP6) = { gpHalfWidth , gpLength                       , 0.0 , globalMeshSize };
GP7 = newp;
Point(GP7) = { 0.0         , gpLength                       , 0.0 , globalMeshSize };

GL1 = newl;
Line(GL1) = { GP1 , GP2 };
GL2 = newl;
Line(GL2) = { GP2 , GP3 };
GL3 = newl;
Line(GL3) = { GP3 , GP4 };
GL4 = newl;
Line(GL4) = { GP4 , GP5 };
GL5 = newl;
Line(GL5) = { GP5 , GP6 };
GL6 = newl;
Line(GL6) = { GP6 , GP7 };
GL7 = newl;
Line(GL7) = { GP7 , GP1 };

GLL1 = newll;
Line Loop(GLL1) = { GL1:GL7 };
 
// Surface of dielectric's intersection with ground plane.
GC1 = newp;
Point(GC1)  = { gpHalfWidth - dielCentreFromGPEdge              , y_dielCentre              , 0.0 , dielMeshSize };
GP8 = newp;
Point(GP8)  = { gpHalfWidth - dielCentreFromGPEdge + dielRadius , y_dielCentre              , 0.0 , dielMeshSize };
GP9 = newp;
Point(GP9)  = { gpHalfWidth - dielCentreFromGPEdge - dielRadius , y_dielCentre              , 0.0 , dielMeshSize };
GP10 = newp;
Point(GP10) = { gpHalfWidth - dielCentreFromGPEdge              , y_dielCentre + dielRadius , 0.0 , dielMeshSize };
GP11 = newp;
Point(GP11) = { gpHalfWidth - dielCentreFromGPEdge              , y_dielCentre - dielRadius , 0.0 , dielMeshSize };

GL8 = newl;
Circle(GL8)  = { GP8  , GC1 , GP10 };
GL9 = newl;
Circle(GL9)  = { GP10 , GC1 , GP9  };
GL10 = newl;
Circle(GL10) = { GP9  , GC1 , GP11 };
GL11 = newl;
Circle(GL11) = { GP11 , GC1 , GP8  };

GLL2 = newll;
Line Loop(GLL2) = { GL8 , GL9 , GL10 , GL11 };

GS1 = news;
Plane Surface(GS1) = { GLL2 };
Physical Surface( "GroundDielIntSurface" ) = { GS1 };

// Ground plane, excluding part under feed block and dielectric.
GS2 = news;
Plane Surface(GS2) = { GLL1 , GLL2 };

//
// Feed block. 
//

FP1 = newp;
Point(FP1) = { 0.0 , -gpBackExtension               , 0.0                , feedMeshSize };
FP2 = newp;
Point(FP2) = { 0.0 , -gpBackExtension + blockLength , taperHeightAtFeed  , feedMeshSize };

FL1 = newl;
Line(FL1) = { GP2 , FP1 };
FL2 = newl;
Line(FL2) = { FP1 , GP4 };
FLL1 = newll;
Line Loop(FLL1) = { GL3 , -FL2 , -FL1 , GL2 };
FS1 = news;
Plane Surface(FS1) = { FLL1 };
feed[] = Extrude { 0 , 0 , blockHeight } { Surface{ FS1 }; };

// All six sides.
Physical Surface("FeedBlock") = { feed[0] , FS1 , feed[2] , feed[3] , feed[4] , feed[5] };

// Excluding face in symmetry plane.
// Physical Surface("FeedBlock") = { feed[0] , FS1 , feed[2] , feed[3] , feed[5] };

// Part of ground plane under feed block.
Physical Surface("GroundFeedIntSurface") = { FS1 };

// Entire ground plane.
Physical Surface("GroundPlane") = { FS1 , GS1 , GS2 };

//
// Feed wire.
//

WL1 = newl;
Line(WL1) = { BP1 , FP2 };
Physical Line("FeedLine") = { WL1 };

//
// Dielectric.
//

extr1[] = Extrude { { 0 , 1 , 0 } , { gpHalfWidth - dielCentreFromGPEdge - dielRadius , y_dielCentre , 0.0 } , -Pi / 6 }{ Surface{ GS1 }; };

extr2[] = Extrude { -gpHalfWidth + dielCentreFromGPEdge + dielRadius , 0.0 , z_dielCentre - dielRadius }{ Surface{ extr1[0] }; };

extr3[] = Extrude { { 0 , 1 , 0 } , { 0.0 , y_dielCentre , z_dielCentre - dielRadius } , -Pi / 3 } { Surface{ extr2[0] }; };

// [FIXME] There was a an off by one bug older gmsh causing the array extr3 to be wrong.
// extr3[0] looked like garbage while extr3[6] shouldn't exist? 
Physical Surface("Dielectric") = { BS1 , GS1 , 
                                   extr1[2] , extr1[3] , extr1[4] , extr1[5] , 
                                   extr2[2] , extr2[3] , extr2[4] , extr2[5] , 
                                   extr3[2] , extr3[3] , extr3[4] , extr3[5] };
