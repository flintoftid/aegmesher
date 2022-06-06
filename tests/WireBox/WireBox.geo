//
// UOY Enclosure Test Case - Version 1.
//
//
// Notation:
//
//        x      y     z
// -------------------------
// low:   Back   Left  Down
// high:  Front  Right Up
//

// AEG MEsher only support Gmsh version 2.x meshes.
Mesh.MshFileVersion = 2.0;

// Which elements are present?
isA2 = 1; // Cube of RAM in left back corner of floor.
isA1 = 1; // Cube of RAM in centre of floor.
isPA = 1; // Short probe at port-A.
isPB = 1; // Short probe at port-B.
isSW = 0; // Straight wire - requires PA and PB, inconsistent with CW.
isCW = 1; // Curve wire - requires PA and PB, inconsistent with SW.
isCF = 0; // Closed front face - inconsistent with GP.
isGP = 1; // Front plate with large aperures - inconsistent with CF.

// Primary geometrical parameters.
EN_depth = 0.500;              // Depth of enclosure (x-direction).
EN_width = 0.600;              // Width of enclosure (y-direction).
EN_height = 0.300;             // Height of enclosure (z-direction).
EN_flangeSize = 0.030;         // Size of flange on front face of enclosure.
EN_portAOffsety = 0.165;       // Distance of port-A from left wall of enclosure.
EN_portBOffsety = 0.100;       // Distance of port-B from right wall of enclosure.
Pn_probeLength = 0.022;        // Length of short probe.
Pn_probeRadius = 3.5e-3;       // Radius of short probe (unused).
CW_centreLineHeight = 0.075;   // Distance of centreline of curved wire from top of enclosure.
An_cubeSide = 0.100;           // Side length of cube of RAM.
GP_squareSide = 0.180;         // Side length of square aperture in GP plate.
GP_circleRadius = 0.050;       // Radius of circular aperture in GP plate.
GP_squareOffsety = 0.060;      // Distance from left wall of enclosure to left side of square aperture.
GP_squareOffsetz = 0.060;      // Distance bottom wall of enclosure to bottom side of square aperture.
GP_circleOffsety = 0.100;      // Distance from right wall of enclosure to rightmost point of circular aperture.
GP_circleOffsetz = 0.080;      // Distance from bottom wall of enclosure to lowest point of circular aperture.

// Mesh control.
EN_meshSize = 3e-2;           // Global mesh size for enclosure.
An_meshSize = 1e-2;           // Mesh size for RAM.
Pn_meshSize = 5e-3;           // Mesh size for probes/wires near feed points.
isIncludeIntersecting = 1;    // Include intersecting surfaces in all intersecting physical groups.

//////////////////////////////
// RAM Cube in corner (A2). //        
//////////////////////////////
   
// Meshed as the outer surface of the cube.

If ( isA2 == 1 )

  // Down face.
  A2_P_BLD = newp;
  Point(A2_P_BLD) = { 0.000 , 0.000 , 0.000 , An_meshSize  };
  A2_P_BRD = newp;
  Point(A2_P_BRD) = { 0.000 , An_cubeSide , 0.000 , An_meshSize  };
  A2_P_FRD = newp;
  Point(A2_P_FRD) = { An_cubeSide , An_cubeSide , 0.000 , An_meshSize  };
  A2_P_FLD = newp;
  Point(A2_P_FLD) = { An_cubeSide , 0.000 , 0.000 , An_meshSize  };

  A2_L_BD = newl;
  Line(A2_L_BD) = { A2_P_BLD , A2_P_BRD };
  A2_L_RD = newl;
  Line(A2_L_RD) = { A2_P_BRD , A2_P_FRD };
  A2_L_FD = newl;
  Line(A2_L_FD) = { A2_P_FRD , A2_P_FLD };
  A2_L_LD = newl;
  Line(A2_L_LD) = { A2_P_FLD , A2_P_BLD };

  A2_LL_D = newll;
  Line Loop(A2_LL_D) = { A2_L_BD:A2_L_LD };

  A2_S_D = news;
  Plane Surface(A2_S_D) = { A2_LL_D };

  // Up face.
  A2_P_BLU = newp;
  Point(A2_P_BLU) = { 0.000 , 0.000 , An_cubeSide , An_meshSize  };
  A2_P_BRU = newp;
  Point(A2_P_BRU) = { 0.000 , An_cubeSide , An_cubeSide , An_meshSize  };
  A2_P_FRU = newp;
  Point(A2_P_FRU) = { An_cubeSide , An_cubeSide , An_cubeSide , An_meshSize  };
  A2_P_FLU = newp;
  Point(A2_P_FLU) = { An_cubeSide , 0.000 , An_cubeSide , An_meshSize  };

  A2_L_BU = newl;
  Line(A2_L_BU) = { A2_P_BLU , A2_P_BRU };
  A2_L_RU = newl;
  Line(A2_L_RU) = { A2_P_BRU , A2_P_FRU };
  A2_L_FU = newl;
  Line(A2_L_FU) = { A2_P_FRU , A2_P_FLU };
  A2_L_LU = newl;
  Line(A2_L_LU) = { A2_P_FLU , A2_P_BLU };

  A2_LL_U = newll;
  Line Loop(A2_LL_U) = { -A2_L_LU:-A2_L_BU };

  A2_S_U = news;
  Plane Surface(A2_S_U) = { A2_LL_U };

  // Back face.
  A2_L_BL = newl;
  Line(A2_L_BL) = { A2_P_BLD , A2_P_BLU };
  A2_L_BR = newl;
  Line(A2_L_BR) = { A2_P_BRD , A2_P_BRU };
 
  A2_LL_B = newll;
  Line Loop(A2_LL_B) = { A2_L_BL , A2_L_BU , -A2_L_BR , -A2_L_BD };

  A2_S_B = news;
  Plane Surface(A2_S_B) = { A2_LL_B };

  // Front face.
  A2_L_FL = newl;
  Line(A2_L_FL) = { A2_P_FLD , A2_P_FLU };
  A2_L_FR = newl;
  Line(A2_L_FR) = { A2_P_FRD , A2_P_FRU };

  A2_LL_F = newll;
  Line Loop(A2_LL_F) = { -A2_L_FL , -A2_L_FD , A2_L_FR , A2_L_FU };

  A2_S_F = news;
  Plane Surface(A2_S_F) = { A2_LL_F };

  // Left face.
  A2_LL_L = newll;
  Line Loop(A2_LL_L) = { -A2_L_LD , A2_L_FL , A2_L_LU , -A2_L_BL };
 
  A2_S_L = news;
  Plane Surface(A2_S_L) = { A2_LL_L };
 
  // Right face.
  A2_LL_R = newll;
  Line Loop(A2_LL_R) = { A2_L_BR , A2_L_RU , -A2_L_FR , -A2_L_RD };

  A2_S_R = news;
  Plane Surface(A2_S_R) = { A2_LL_R };

  Physical Surface( "A2" ) = { A2_S_B , A2_S_F , A2_S_L , A2_S_R , A2_S_D , A2_S_U };  

EndIf

//////////////////////////////
// RAM Cube in centre (A1). //        
//////////////////////////////

// Meshed as the outer surface of the cube.

If ( isA1 == 1 )

  // Down face.
  A1_P_BLD = newp;
  Point(A1_P_BLD) = { EN_depth / 2 - An_cubeSide / 2 , EN_width / 2 - An_cubeSide / 2  , 0.000 , An_meshSize  };
  A1_P_BRD = newp;
  Point(A1_P_BRD) = { EN_depth / 2 - An_cubeSide / 2 , EN_width / 2 + An_cubeSide / 2 , 0.000 , An_meshSize  };
  A1_P_FRD = newp;
  Point(A1_P_FRD) = { EN_depth / 2 + An_cubeSide / 2 , EN_width / 2 + An_cubeSide / 2 , 0.000 , An_meshSize  };
  A1_P_FLD = newp;
  Point(A1_P_FLD) = { EN_depth / 2 + An_cubeSide / 2 , EN_width / 2 - An_cubeSide / 2 , 0.000 , An_meshSize  };

  A1_L_BD = newl;
  Line(A1_L_BD) = { A1_P_BLD , A1_P_BRD };
  A1_L_RD = newl;
  Line(A1_L_RD) = { A1_P_BRD , A1_P_FRD };
  A1_L_FD = newl;
  Line(A1_L_FD) = { A1_P_FRD , A1_P_FLD };
  A1_L_LD = newl;
  Line(A1_L_LD) = { A1_P_FLD , A1_P_BLD };

  A1_LL_D = newll;
  Line Loop(A1_LL_D) = { A1_L_BD:A1_L_LD };

  A1_S_D = news;
  Plane Surface(A1_S_D) = { A1_LL_D };

  // Up face.
  A1_P_BLU = newp;
  Point(A1_P_BLU) = { EN_depth / 2 - An_cubeSide / 2 , EN_width / 2 - An_cubeSide / 2 , An_cubeSide , An_meshSize  };
  A1_P_BRU = newp;
  Point(A1_P_BRU) = { EN_depth / 2 - An_cubeSide / 2 , EN_width / 2 + An_cubeSide / 2 , An_cubeSide , An_meshSize  };
  A1_P_FRU = newp;
  Point(A1_P_FRU) = { EN_depth / 2 + An_cubeSide / 2 , EN_width / 2 + An_cubeSide / 2 , An_cubeSide , An_meshSize  };
  A1_P_FLU = newp;
  Point(A1_P_FLU) = { EN_depth / 2 + An_cubeSide / 2 , EN_width / 2 - An_cubeSide / 2 , An_cubeSide , An_meshSize  };

  A1_L_BU = newl;
  Line(A1_L_BU) = { A1_P_BLU , A1_P_BRU };
  A1_L_RU = newl;
  Line(A1_L_RU) = { A1_P_BRU , A1_P_FRU };
  A1_L_FU = newl;
  Line(A1_L_FU) = { A1_P_FRU , A1_P_FLU };
  A1_L_LU = newl;
  Line(A1_L_LU) = { A1_P_FLU , A1_P_BLU };

  A1_LL_U = newll;
  Line Loop(A1_LL_U) = { -A1_L_LU:-A1_L_BU };

  A1_S_U = news;
  Plane Surface(A1_S_U) = { A1_LL_U };

  // Back face.
  A1_L_BL = newl;
  Line(A1_L_BL) = { A1_P_BLD , A1_P_BLU };
  A1_L_BR = newl;
  Line(A1_L_BR) = { A1_P_BRD , A1_P_BRU };

  A1_LL_B = newll;
  Line Loop(A1_LL_B) = { A1_L_BL , A1_L_BU , -A1_L_BR , -A1_L_BD };

  A1_S_B = news;
  Plane Surface(A1_S_B) = { A1_LL_B };

  // Front face.
  A1_L_FL = newl;
  Line(A1_L_FL) = { A1_P_FLD , A1_P_FLU };
  A1_L_FR = newl;
  Line(A1_L_FR) = { A1_P_FRD , A1_P_FRU };

  A1_LL_F = newll;
  Line Loop(A1_LL_F) = { -A1_L_FL , -A1_L_FD , A1_L_FR , A1_L_FU };

  A1_S_F = news;
  Plane Surface(A1_S_F) = { A1_LL_F };

  // Left face.
  A1_LL_L = newll;
  Line Loop(A1_LL_L) = { -A1_L_LD , A1_L_FL , A1_L_LU , -A1_L_BL };

  A1_S_L = news;
  Plane Surface(A1_S_L) = { A1_LL_L };

  // Right face.
  A1_LL_R = newll;
  Line Loop(A1_LL_R) = { A1_L_BR , A1_L_RU , -A1_L_FR , -A1_L_RD };

  A1_S_R = news;
  Plane Surface(A1_S_R) = { A1_LL_R };
 
  Physical Surface( "A1" ) = { A1_S_B , A1_S_F , A1_S_L , A1_S_R , A1_S_D , A1_S_U };  

EndIf

///////////////////////////
// Probe at port-A (PA). //
///////////////////////////

// Meshed as the axis of the wire.

If ( isPA == 1 )

  PA_P_U = newp;
  Point(PA_P_U) = { EN_depth / 2 , EN_portAOffsety , EN_height , Pn_meshSize }; 
  PA_P_D = newp;
  Point(PA_P_D) = { EN_depth / 2 , EN_portAOffsety , EN_height - Pn_probeLength , Pn_meshSize  };  
  PA_L = newl;
  Line(PA_L) = { PA_P_U , PA_P_D }; 

  Physical Line( "PA" ) = { PA_L };  

EndIf

///////////////////////////
// Probe at port-B (PB). //
///////////////////////////

// Meshed as the axis of the wire.

If ( isPB == 1 )

  PB_P_U = newp;
  Point(PB_P_U) = { EN_depth / 2 ,  EN_width - EN_portBOffsety , EN_height , Pn_meshSize }; 
  PB_P_D = newp;
  Point(PB_P_D) = { EN_depth / 2 ,  EN_width - EN_portBOffsety , EN_height - Pn_probeLength , Pn_meshSize  };  
  PB_L = newl;
  Line(PB_L) = { PB_P_U , PB_P_D }; 

  Physical Line( "PB" ) = { PB_L };  

EndIf

/////////////////////////////////////////////////
// Straight wire from probe A to probe B (SW). //
/////////////////////////////////////////////////

// Meshed as the axis of the wire.

If ( isSW == 1 )

  SW_P_MID_D = newp;
  Point(SW_P_MID_D) =  { EN_depth / 2 , 0.5 * ( EN_portAOffsety + EN_width - EN_portBOffsety ) , EN_height - Pn_probeLength , Pn_probeLength / 2  };
  SW_L_L = newl;
  Line(SW_L_L) = { PA_P_D , SW_P_MID_D };
  SW_L_R = newl;
  Line(SW_L_R) = { SW_P_MID_D , PB_P_D };
  SW_P_MID_U = newp;
  Point(SW_P_MID_U) =  { EN_depth / 2 , 0.5 * ( EN_portAOffsety + EN_width - EN_portBOffsety ) , EN_height , Pn_probeLength / 2  };
  Physical Line( "SW" ) = { SW_L_L , SW_L_R };  

EndIf

///////////////////////////////////////////////
// Curved wire from probe A to probe B (SW). //
///////////////////////////////////////////////

// Meshed as the axis of the wire.

If ( isCW == 1 )

  curveRadius = ( EN_width - EN_portAOffsety - EN_portBOffsety ) / 6;

  CW_P_MID_U = newp;
  Point(CW_P_MID_U) =  { EN_depth / 2 , 0.5 * ( EN_portAOffsety + EN_width - EN_portBOffsety ) , EN_height , Pn_probeLength / 2  };

  CW_P_C1 = newp;
  Point(CW_P_C1) =  { EN_depth / 2 , EN_portAOffsety + 1 * curveRadius , EN_height - CW_centreLineHeight , Pn_meshSize };
  CW_P_C2 = newp;
  Point(CW_P_C2) =  { EN_depth / 2 , EN_portAOffsety + 3 * curveRadius , EN_height - CW_centreLineHeight , Pn_meshSize };
  CW_P_C3 = newp;
  Point(CW_P_C3) =  { EN_depth / 2 , EN_portAOffsety + 5 * curveRadius , EN_height - CW_centreLineHeight , Pn_meshSize };
  
  CW_P_1 = newp;
  Point(CW_P_1) =  { EN_depth / 2 , EN_portAOffsety + 0 * curveRadius , EN_height - CW_centreLineHeight , Pn_meshSize };
  CW_P_2 = newp;
  Point(CW_P_2) =  { EN_depth / 2 , EN_portAOffsety + 1 * curveRadius , EN_height - CW_centreLineHeight - curveRadius , Pn_meshSize };  
  CW_P_3 = newp;
  Point(CW_P_3) =  { EN_depth / 2 , EN_portAOffsety + 2 * curveRadius , EN_height - CW_centreLineHeight , Pn_meshSize };
  CW_P_4 = newp;
  Point(CW_P_4) =  { EN_depth / 2 , EN_portAOffsety + 3 * curveRadius , EN_height - CW_centreLineHeight + curveRadius , Pn_meshSize };
  CW_P_5 = newp;
  Point(CW_P_5) =  { EN_depth / 2 , EN_portAOffsety + 4 * curveRadius , EN_height - CW_centreLineHeight , Pn_meshSize };
  CW_P_6 = newp;
  Point(CW_P_6) =  { EN_depth / 2 , EN_portAOffsety + 5 * curveRadius , EN_height - CW_centreLineHeight - curveRadius , Pn_meshSize };
  CW_P_7 = newp;
  Point(CW_P_7) =  { EN_depth / 2 , EN_portAOffsety + 6 * curveRadius , EN_height - CW_centreLineHeight , Pn_meshSize };
  
  CW_L_1 = newl;
  Line(CW_L_1) = { PA_P_D , CW_P_1 };
  CW_L_2 = newl;
  Circle(CW_L_2) = { CW_P_1 , CW_P_C1 , CW_P_2 };
  CW_L_3 = newl;
  Circle(CW_L_3) = { CW_P_2 , CW_P_C1 , CW_P_3 };
  CW_L_4 = newl;
  Circle(CW_L_4) = { CW_P_3 , CW_P_C2 , CW_P_4 };
  CW_L_5 = newl;
  Circle(CW_L_5) = { CW_P_4 , CW_P_C2 , CW_P_5 };
  CW_L_6 = newl;
  Circle(CW_L_6) = { CW_P_5 , CW_P_C3 , CW_P_6 };
  CW_L_7 = newl;
  Circle(CW_L_7) = { CW_P_6 , CW_P_C3 , CW_P_7 };
  CW_L_8 = newl;
  Line(CW_L_8) = { CW_P_7 , PB_P_D };
  
  Physical Line( "CW" ) = { CW_L_1:CW_L_8 };  

EndIf

/////////////////////
// Enclosure (EN). //
/////////////////////

// Meshed as a zero-thickness surface.

// Flange
EN_FLANGE_P_FLD = newp;
Point(EN_FLANGE_P_FLD) = { EN_depth , EN_flangeSize , EN_flangeSize , EN_meshSize  };
EN_FLANGE_P_FLU = newp;
Point(EN_FLANGE_P_FLU) = { EN_depth , EN_flangeSize , EN_height - EN_flangeSize , EN_meshSize  };
EN_FLANGE_P_FRU = newp;
Point(EN_FLANGE_P_FRU) = { EN_depth , EN_width - EN_flangeSize , EN_height - EN_flangeSize , EN_meshSize  };
EN_FLANGE_P_FRD = newp;
Point(EN_FLANGE_P_FRD) = { EN_depth , EN_width - EN_flangeSize , EN_flangeSize , EN_meshSize  };

EN_FLANGE_L_FD = newl;
Line(EN_FLANGE_L_FD) = { EN_FLANGE_P_FLD , EN_FLANGE_P_FRD };
EN_FLANGE_L_FR = newl;
Line(EN_FLANGE_L_FR) = { EN_FLANGE_P_FRD , EN_FLANGE_P_FRU };
EN_FLANGE_L_FU = newl;
Line(EN_FLANGE_L_FU) = { EN_FLANGE_P_FRU , EN_FLANGE_P_FLU };
EN_FLANGE_L_FL = newl;
Line(EN_FLANGE_L_FL) = { EN_FLANGE_P_FLU , EN_FLANGE_P_FLD };
  
EN_FLANGE_LL_F = newll;
Line Loop(EN_FLANGE_LL_F) = { EN_FLANGE_L_FD:EN_FLANGE_L_FL };

// Down face.
EN_P_BLD = newp;
Point(EN_P_BLD) = { 0.000 , 0.000 , 0.000 , EN_meshSize  };
EN_P_BRD = newp;
Point(EN_P_BRD) = { 0.000 , EN_width , 0.000 , EN_meshSize  };
EN_P_FRD = newp;
Point(EN_P_FRD) = { EN_depth , EN_width , 0.000 , EN_meshSize  };
EN_P_FLD = newp;
Point(EN_P_FLD) = { EN_depth , 0.000 , 0.000 , EN_meshSize  };

EN_L_BD = newl;
If( isA2 == 0 )
  Line(EN_L_BD) = { EN_P_BLD , EN_P_BRD };
EndIf
If( isA2 == 1 )
  Line(EN_L_BD) = { A2_P_BRD , EN_P_BRD };
EndIf
EN_L_RD = newl;
Line(EN_L_RD) = { EN_P_BRD , EN_P_FRD };
EN_L_FD = newl;
Line(EN_L_FD) = { EN_P_FRD , EN_P_FLD };
  EN_L_LD = newl;
If( isA2 == 0 )
  Line(EN_L_LD) = { EN_P_FLD , EN_P_BLD };
EndIf
If( isA2 == 1 )
  Line(EN_L_LD) = { EN_P_FLD , A2_P_FLD };
EndIf

EN_LL_D = newll;
If( isA2 == 0 )
  Line Loop(EN_LL_D) = { EN_L_BD:EN_L_LD };
EndIf
If( isA2 == 1 )
  Line Loop(EN_LL_D) = { EN_L_BD:EN_L_LD , -A2_L_FD , -A2_L_RD };
EndIf

EN_S_D = news;
If( isA1 == 0 )
  Plane Surface(EN_S_D) = { EN_LL_D };
EndIf
If( isA1 == 1 )
  Plane Surface(EN_S_D) = { EN_LL_D , A1_LL_D };
EndIf

// Up face.
EN_P_BLU = newp;
Point(EN_P_BLU) = { 0.000 , 0.000 , EN_height , EN_meshSize  };
EN_P_BRU = newp;
Point(EN_P_BRU) = { 0.000 , EN_width , EN_height , EN_meshSize  };
EN_P_FRU = newp;
Point(EN_P_FRU) = { EN_depth , EN_width , EN_height , EN_meshSize  };
EN_P_FLU = newp;
Point(EN_P_FLU) = { EN_depth , 0.000 , EN_height , EN_meshSize  };

EN_L_BU = newl;
Line(EN_L_BU) = { EN_P_BLU , EN_P_BRU };
EN_L_RU = newl;
Line(EN_L_RU) = { EN_P_BRU , EN_P_FRU };
EN_L_FU = newl;
Line(EN_L_FU) = { EN_P_FRU , EN_P_FLU };
EN_L_LU = newl;
Line(EN_L_LU) = { EN_P_FLU , EN_P_BLU };

EN_LL_U = newll;
Line Loop(EN_LL_U) = { -EN_L_LU:-EN_L_BU };

EN_S_U = news;
Plane Surface(EN_S_U) = { EN_LL_U };

If ( isPA == 1 )
  Point{PA_P_U} In Surface {EN_S_U};
EndIf

If ( isPB == 1 )
  Point{PB_P_U} In Surface {EN_S_U};
EndIf

If ( isSW == 1 )
  Point{SW_P_MID_U} In Surface {EN_S_U};
EndIf

If ( isCW == 1 )
  Point{CW_P_MID_U} In Surface {EN_S_U};
EndIf

// Back face.
EN_L_BR = newl;
Line(EN_L_BR) = { EN_P_BRD , EN_P_BRU };
EN_L_BL = newl;
If( isA2 == 0 )
  Line(EN_L_BL) = { EN_P_BLD , EN_P_BLU };
EndIf
If( isA2 == 1 )
  Line(EN_L_BL) = { A2_P_BLU , EN_P_BLU };
EndIf

EN_LL_B = newll;
If( isA2 == 0 )
  Line Loop(EN_LL_B) = { EN_L_BL , EN_L_BU , -EN_L_BR , -EN_L_BD };
EndIf
If( isA2 == 1 )
  Line Loop(EN_LL_B) = { EN_L_BL , EN_L_BU , -EN_L_BR , -EN_L_BD , A2_L_BR , -A2_L_BU };
EndIf

EN_S_B = news;
Plane Surface(EN_S_B) = { EN_LL_B };
  
// Front face.
EN_L_FL = newl;
Line(EN_L_FL) = { EN_P_FLD , EN_P_FLU };
EN_L_FR = newl;
Line(EN_L_FR) = { EN_P_FRD , EN_P_FRU };

EN_LL_F = newll;
Line Loop(EN_LL_F) = { -EN_L_FL , -EN_L_FD , EN_L_FR , EN_L_FU };

EN_S_F = news;
Plane Surface(EN_S_F) = { EN_LL_F , EN_FLANGE_LL_F };

// Left face.
EN_LL_L = newll;
If( isA2 == 0 )
  Line Loop(EN_LL_L) = { -EN_L_LD , EN_L_FL , EN_L_LU , -EN_L_BL };
EndIf
If( isA2 == 1 )
  Line Loop(EN_LL_L) = { -EN_L_LD , EN_L_FL , EN_L_LU , -EN_L_BL , -A2_L_LU , -A2_L_FL };
EndIf

EN_S_L = news;
Plane Surface(EN_S_L) = { EN_LL_L };

// Right face.
EN_LL_R = newll;
Line Loop(EN_LL_R) = { EN_L_BR , EN_L_RU , -EN_L_FR , -EN_L_RD };

EN_S_R = news;
Plane Surface(EN_S_R) = { EN_LL_R };

If( isIncludeIntersecting == 0 )
  Physical Surface( "EN" ) = { EN_S_B , EN_S_F , EN_S_L , EN_S_R , EN_S_D , EN_S_U };  
EndIf

If( isIncludeIntersecting == 1 )
  fred = { EN_S_B , EN_S_F , EN_S_L , EN_S_R , EN_S_D , EN_S_U };
  If( isA1 == 1 )
    fred += A1_S_D;  
  EndIf
  If( isA2 == 1 )
    fred += { A2_S_D , A2_S_B , A2_S_L };  
  EndIf
  Physical Surface( "EN" ) = { fred[] }; 
EndIf

////////////////////////////////////////
// Front panel with closed face (CF). //
////////////////////////////////////////

// Meshed as a zero-thickness surface.

If ( isCF == 1 )

  CF_S = news;
  Plane Surface(CF_S) = { EN_FLANGE_LL_F };
  Physical Surface( "CF" ) = { CF_S };  

EndIf

////////////////////////////////////////////
// Front panel with large apertures (GP). //
////////////////////////////////////////////

// Meshed as a zero-thickness surface.

If ( isGP == 1 )
    
  GP_SQUARE_P_FLD = newp;
  Point(GP_SQUARE_P_FLD) = { EN_depth , GP_squareOffsety , GP_squareOffsetz , EN_meshSize  };
  GP_SQUARE_P_FLU = newp;
  Point(GP_SQUARE_P_FLU) = { EN_depth , GP_squareOffsety , GP_squareOffsetz + GP_squareSide , EN_meshSize  };
  GP_SQUARE_P_FRU = newp;
  Point(GP_SQUARE_P_FRU) = { EN_depth , GP_squareOffsety + GP_squareSide ,  GP_squareOffsetz + GP_squareSide , EN_meshSize  };
  GP_SQUARE_P_FRD = newp;
  Point(GP_SQUARE_P_FRD) = { EN_depth , GP_squareOffsety + GP_squareSide , GP_squareOffsetz , EN_meshSize  };

  GP_SQUARE_L_FD = newl;
  Line(GP_SQUARE_L_FD) = { GP_SQUARE_P_FLD , GP_SQUARE_P_FRD };
  GP_SQUARE_L_FR = newl;
  Line(GP_SQUARE_L_FR) = { GP_SQUARE_P_FRD , GP_SQUARE_P_FRU };
  GP_SQUARE_L_FU = newl;
  Line(GP_SQUARE_L_FU) = { GP_SQUARE_P_FRU , GP_SQUARE_P_FLU };
  GP_SQUARE_L_FL = newl;
  Line(GP_SQUARE_L_FL) = { GP_SQUARE_P_FLU , GP_SQUARE_P_FLD };

  GP_SQUARE_LL_F = newll;
  Line Loop(GP_SQUARE_LL_F) = { GP_SQUARE_L_FD:GP_SQUARE_L_FL };
  
  GP_CIRCLE_P_CENTRE = newp;
  Point(GP_CIRCLE_P_CENTRE) = { EN_depth , EN_width - GP_circleOffsety - GP_circleRadius , GP_circleOffsetz +  GP_circleRadius , EN_meshSize };
  GP_CIRCLE_P_L = newp;
  Point(GP_CIRCLE_P_L) = { EN_depth , EN_width - GP_circleOffsety - 2 * GP_circleRadius , GP_circleOffsetz +  GP_circleRadius , EN_meshSize };
  GP_CIRCLE_P_R = newp;
  Point(GP_CIRCLE_P_R) = { EN_depth , EN_width - GP_circleOffsety , GP_circleOffsetz +  GP_circleRadius , EN_meshSize };
  GP_CIRCLE_P_U = newp;
  Point(GP_CIRCLE_P_U) = { EN_depth , EN_width - GP_circleOffsety - GP_circleRadius , GP_circleOffsetz + 2 * GP_circleRadius , EN_meshSize };
  GP_CIRCLE_P_D = newp;
  Point(GP_CIRCLE_P_D) = { EN_depth , EN_width - GP_circleOffsety - GP_circleRadius , GP_circleOffsetz , EN_meshSize };

  GP_CIRCLE_L_LD = newl;
  Circle(GP_CIRCLE_L_LD) = { GP_CIRCLE_P_L , GP_CIRCLE_P_CENTRE , GP_CIRCLE_P_D };
  GP_CIRCLE_L_RD = newl;
  Circle(GP_CIRCLE_L_RD) = { GP_CIRCLE_P_D , GP_CIRCLE_P_CENTRE , GP_CIRCLE_P_R };
  GP_CIRCLE_L_RU = newl;
  Circle(GP_CIRCLE_L_RU) = { GP_CIRCLE_P_R , GP_CIRCLE_P_CENTRE , GP_CIRCLE_P_U };
  GP_CIRCLE_L_LU = newl;
  Circle(GP_CIRCLE_L_LU) = { GP_CIRCLE_P_U , GP_CIRCLE_P_CENTRE , GP_CIRCLE_P_L };
 
  GP_CIRCLE_LL_F = newll;
  Line Loop(GP_CIRCLE_LL_F) = { GP_CIRCLE_L_LD:GP_CIRCLE_L_LU };
  
  GP_S = news;
  Plane Surface(GP_S) = { EN_FLANGE_LL_F , GP_SQUARE_LL_F , GP_CIRCLE_LL_F };
  Physical Surface( "GP" ) = { GP_S };  

EndIf


