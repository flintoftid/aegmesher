//
// AEG Mesher: Tutorial Example: UOY AEG Enclosure Test Case
//
//
// Notation:
//
//        x      y     z
// -------------------------
// low:   Back   Left  Down
// high:  Front  Right Up
//

// Primary geometrical parameters.
EN_depth = 0.500;              // Depth of the enclosure (x-direction).
EN_width = 0.600;              // Width of the enclosure (y-direction).
EN_height = 0.300;             // Height of the enclosure (z-direction).
EN_flangeSize = 0.030;         // Size of the flange on front face of the enclosure.
EN_portAOffsety = 0.165;       // Distance of port-A from the left wall of the enclosure.
EN_portBOffsety = 0.100;       // Distance of port-B from the right wall of the enclosure.
Pn_probeLength = 0.022;        // Length of short probe.
An_cubeSide = 0.100;           // Side length of cube of RAM.

// Mesh control.
// If the output mesh is purely for describing the geometry for input to
// AEG Mesher then the mesh sizes can be quite large.
EN_meshSize = 10e-2;           // Global mesh size for enclosure.
An_meshSize = 10e-2;           // Mesh size for RAM.
Pn_meshSize = 10e-2;           // Mesh size for probes/wires near feed points.

//////////////////////////////
// RAM Cube in centre (A1). //        
//////////////////////////////

// For solid objects the mesher requires a group representing the
// closed surface of the object.

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
 
// Only named physical groups are output. This one describes the surface of the RAM cube.
Physical Surface( "A1" ) = { A1_S_B , A1_S_F , A1_S_L , A1_S_R , A1_S_D , A1_S_U };  

///////////////////////////
// Probe at port-A (PA). //
///////////////////////////

// We assume the target solver has a thin wire model and that we do not need to 
// mesh the volume of the wire. The wire is represented by a line along its central axis.

PA_P_U = newp;
Point(PA_P_U) = { EN_depth / 2 , EN_portAOffsety , EN_height , Pn_meshSize }; 
PA_P_D = newp;
Point(PA_P_D) = { EN_depth / 2 , EN_portAOffsety , EN_height - Pn_probeLength , Pn_meshSize  };  
PA_L = newl;
Line(PA_L) = { PA_P_U , PA_P_D }; 

Physical Line( "PA" ) = { PA_L };  

///////////////////////////
// Probe at port-B (PB). //
///////////////////////////

PB_P_U = newp;
Point(PB_P_U) = { EN_depth / 2 ,  EN_width - EN_portBOffsety , EN_height , Pn_meshSize }; 
PB_P_D = newp;
Point(PB_P_D) = { EN_depth / 2 ,  EN_width - EN_portBOffsety , EN_height - Pn_probeLength , Pn_meshSize  };  
PB_L = newl;
Line(PB_L) = { PB_P_U , PB_P_D }; 

Physical Line( "PB" ) = { PB_L };  

/////////////////////////////////////////////////
// Straight wire from probe A to probe B (SW). //
/////////////////////////////////////////////////

SW_P_MID_D = newp;
Point(SW_P_MID_D) =  { EN_depth / 2 , 0.5 * ( EN_portAOffsety + EN_width - EN_portBOffsety ) , EN_height - Pn_probeLength , Pn_meshSize   };
SW_L_L = newl;
Line(SW_L_L) = { PA_P_D , SW_P_MID_D };
SW_L_R = newl;
Line(SW_L_R) = { SW_P_MID_D , PB_P_D };

Physical Line( "SW" ) = { SW_L_L , SW_L_R };  

/////////////////////
// Enclosure (EN). //
/////////////////////

// We assume that the target mesher has a thin PEC sheet model.
// The enlcosure is therefore represented as a zero-thickness surface.

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
Line(EN_L_BD) = { EN_P_BLD , EN_P_BRD };
EN_L_RD = newl;
Line(EN_L_RD) = { EN_P_BRD , EN_P_FRD };
EN_L_FD = newl;
Line(EN_L_FD) = { EN_P_FRD , EN_P_FLD };
EN_L_LD = newl;
Line(EN_L_LD) = { EN_P_FLD , EN_P_BLD };

EN_LL_D = newll;
Line Loop(EN_LL_D) = { EN_L_BD:EN_L_LD };

EN_S_D = news;
Plane Surface(EN_S_D) = { EN_LL_D , A1_LL_D };

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

// Ensure there are mesh nodes to connect to the wires.
Point{PA_P_U} In Surface {EN_S_U};
Point{PB_P_U} In Surface {EN_S_U};

// Back face.
EN_L_BR = newl;
Line(EN_L_BR) = { EN_P_BRD , EN_P_BRU };
EN_L_BL = newl;
Line(EN_L_BL) = { EN_P_BLD , EN_P_BLU };

EN_LL_B = newll;
Line Loop(EN_LL_B) = { EN_L_BL , EN_L_BU , -EN_L_BR , -EN_L_BD };

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
Line Loop(EN_LL_L) = { -EN_L_LD , EN_L_FL , EN_L_LU , -EN_L_BL };

EN_S_L = news;
Plane Surface(EN_S_L) = { EN_LL_L };

// Right face.
EN_LL_R = newll;
Line Loop(EN_LL_R) = { EN_L_BR , EN_L_RU , -EN_L_FR , -EN_L_RD };

EN_S_R = news;
Plane Surface(EN_S_R) = { EN_LL_R };

// Note we include the 'down' face of the cube in the enclosure mesh.
Physical Surface( "EN" ) = { EN_S_B , EN_S_F , EN_S_L , EN_S_R , EN_S_D , EN_S_U , A1_S_D }; 
