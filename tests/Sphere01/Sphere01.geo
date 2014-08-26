//
// gmsh geometry for a sphere.
// 

radius = 100;     // Sphere radius.
height = 0;       // Sphere height.
meshSize_NP = 5;  // Mesh size at north pole.
meshSize_EQ = 5;  // Mesh size along equator.
meshSize_SP = 5;  // Mesh size at south pole.

ORIGIN = newp;
Point(ORIGIN) = { 0.0 , 0.0 , 0.0 , meshSize_EQ };
NP = newp;
Point(NP)     = { 0.0 , 0.0 , radius , meshSize_NP };
SP = newp;
Point(SP)     = { 0.0 , 0.0 , -radius , meshSize_SP };
EQ0 = newp;
Point(EQ0)    = { radius , 0.0 , 0.0 , meshSize_EQ };
EQ90 = newp;
Point(EQ90)   = { 0.0 , radius , 0.0 , meshSize_EQ };
EQ180 = newp;
Point(EQ180)  = { -radius , 0.0 , 0.0 , meshSize_EQ };
EQ270 = newp;
Point(EQ270)  = { 0.0 , -radius , 0.0 , meshSize_EQ };

ARC_EQ1 = newl;
Circle(ARC_EQ1)   = { EQ0   , ORIGIN , EQ90  };
ARC_EQ2 = newl;
Circle(ARC_EQ2)   = { EQ90  , ORIGIN , EQ180 };
ARC_EQ3 = newl;
Circle(ARC_EQ3)   = { EQ180 , ORIGIN , EQ270 };
ARC_EQ4 = newl;
Circle(ARC_EQ4)   = { EQ270 , ORIGIN , EQ0   };
ARC_NP0 = newl;
Circle(ARC_NP0)   = { NP    , ORIGIN , EQ0   };
ARC_NP90 = newl;
Circle(ARC_NP90)  = { EQ90  , ORIGIN , NP    };
ARC_NP180 = newl;
Circle(ARC_NP180) = { EQ180 , ORIGIN , NP    };
ARC_NP270 = newl;
Circle(ARC_NP270) = { NP    , ORIGIN , EQ270 };
ARC_SP0 = newl;
Circle(ARC_SP0)   = { EQ0   , ORIGIN , SP    };
ARC_SP90 = newl;
Circle(ARC_SP90)  = { SP    , ORIGIN , EQ90  };
ARC_SP180 = newl;
Circle(ARC_SP180) = { SP    , ORIGIN , EQ180 };
ARC_SP270 = newl;
Circle(ARC_SP270) = { EQ270 , ORIGIN , SP    };

LL_NPEQ1 = newll;
Line Loop(LL_NPEQ1) = { -ARC_NP90 , -ARC_NP0 , -ARC_EQ1 };
RS_NPEQ1 = news;
Ruled Surface(RS_NPEQ1) = { -LL_NPEQ1 };
LL_NPEQ2 = newll;
Line Loop(LL_NPEQ2) = { -ARC_NP180 , -ARC_EQ2 , ARC_NP90 };
RS_NPEQ2 = news;
Ruled Surface(RS_NPEQ2) = { -LL_NPEQ2 };
LL_NPEQ3 = newll;
Line Loop(LL_NPEQ3) = { -ARC_EQ3 , ARC_NP180 , ARC_NP270 };
RS_NPEQ3 = news;
Ruled Surface(RS_NPEQ3) = { -LL_NPEQ3 };
LL_NPEQ4 = newll;
Line Loop(LL_NPEQ4) = { -ARC_EQ4 , ARC_NP0 , -ARC_NP270 };
RS_NPEQ4 = news;
Ruled Surface(RS_NPEQ4) = { -LL_NPEQ4 };
LL_SPEQ1 = newll;
Line Loop(LL_SPEQ1) = { -ARC_SP90 , -ARC_SP0 , ARC_EQ1 };
RS_SPEQ1 = news;
Ruled Surface(RS_SPEQ1) = { -LL_SPEQ1 };
LL_SPEQ2 = newll;
Line Loop(LL_SPEQ2) = { ARC_EQ2 , ARC_SP90 , -ARC_SP180 };
RS_SPEQ2 = news;
Ruled Surface(RS_SPEQ2) = { -LL_SPEQ2 };
LL_SPEQ3 = newll;
Line Loop(LL_SPEQ3) = { ARC_SP180 , ARC_EQ3 , ARC_SP270 };
RS_SPEQ3 = news;
Ruled Surface(RS_SPEQ3) = { -LL_SPEQ3 };
LL_SPEQ4 = newll;
Line Loop(LL_SPEQ4) = { -ARC_SP270 , ARC_EQ4 , ARC_SP0 };
RS_SPEQ4 = news;
Ruled Surface(RS_SPEQ4) = { -LL_SPEQ4 };

Physical Surface("Sphere01") = { RS_NPEQ1 , RS_NPEQ2 , RS_NPEQ3 , RS_NPEQ4 , RS_SPEQ1 , RS_SPEQ2 , RS_SPEQ3 , RS_SPEQ4 };
