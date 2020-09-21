/**
    PhotoArchitecture2018Parson.CartesianPolar tab, D. Parson,
    adapted from SoundToWavePixels on 5/18/2018
    Copied into CSC220F19MIDIassn3 10/16/2019.
    Fixed some bugs on 11/10/2019.
**/

/**
 *  cartesianToPhysical maps a location in the Cartesian coordinate
 *  space -1.0, -1.0 through 1.0, 1.0 to the physical space
 *  0, 0 through width-1, height-1. If either input coordinate
 *  lies outside of the -1.0..1.0 range, cartesianToPhysical returns
 *  a pair of coordinates that lie outside the central clipping
 *  circle. This latter condition is not an error.
**/
/* DEBUG VARIABLES
double debugsumx = 0.0 ;
double debugsumy = 0.0 ;
double debugcountsum = 0.0 ;
double debugminx = 0.0, debugmaxx = 0.0 ;
*/
int [] cartesianToPhysical(float cartesianX, float cartesianY) {
  int [] result = new int[2];
  int mywidth = width ;  // locate centered rectangle for clipping
  int myheight = height ;
  int xoffset = 0, yoffset = 0 ;
  /* CHANGED 5/2018
  if (cartesianX < -1.0 || cartesianX > 1.0 || cartesianY < -1.0
      || cartesianY > 1.0) {
    result[0] = result[1] = -1 ;
    return result ;
  }
  */
  // Update summer 2015 cartesian is in the centered square in a rectangular display.
  if (mywidth > myheight) {
      // normally this is the case
    xoffset = (mywidth - myheight) / 2 ;
    mywidth = myheight ;
  } else {
    yoffset = (myheight - mywidth) / 2 ;
    myheight = mywidth ;
  }
  result[0] = (int)(Math.round(((cartesianX + 1.0) / 2.0) * mywidth + xoffset));
  if (result[0] == (mywidth + xoffset)) {
    result[0] -= 1 ;
  }
  result[1] = /* my */ height - (int)(Math.round(((cartesianY + 1.0) / 2.0) * myheight + yoffset));
  // Physical requires Y == 0 to be at the top.
  if (result[1] == myheight + yoffset) {
    result[1] -= 1 ;
  }
  //debugsumx = debugsumx + result[0]; debugsumy = debugsumy + result[1] ; debugcountsum = debugcountsum + 1.0 ;println("DEBUG cartesianToPhysical 1, " + width + "," +height + "     " + debugminx + "," + debugmaxx + "     " + result[0] + "," + result[1]);
  return result ;
}

/**
 *  physicalToCartesian maps a location in the physical display coordinate
 *  space 0, 0 through width-1, height-1 to the Cartesian space
 *  -1.0, -1.0 through 1.0, 1.0. If either input coordinate
 *  lies outside of the 0, 0 through width-1, height-1 range, this function
 *  returns coordinates outside the -1.0,-1.0 THRU 1.0,1.0 range.
 *  The latter condition for out of range data is not an error.
**/
float [] physicalToCartesian(int physX, int physY) {
  // Update summer 2015 cartesian is in the centered square in a rectangular display.
  float [] result = new float[2];
  int mywidth = width ;  // locate centered rectangle for clipping
  int myheight = height ;
  int xoffset = 0, yoffset = 0 ;
  if (mywidth > myheight) {
      // normally this is the case
    xoffset = (mywidth - myheight) / 2 ;
    mywidth = myheight ;
  } else {
    yoffset = (myheight - mywidth) / 2 ;
    myheight = mywidth ;
  }
  physX -= xoffset ; // summer 2015
  physY -= yoffset ; // summer 2015
  if (physX == mywidth) {
    physX = mywidth - 1 ;  // same as cartesian 1.0
  }
  if (physY == myheight) {
    physY = myheight - 1 ;  // same as cartesian 1.0
  }
  /* DROPPED 5/2018
  if (physX < 0 || physX >= mywidth || physY < 0
      || physY >= myheight) {
    result[0] = result[1] = -2.0 ;
    return result ;
  }
  */
  result[0] = ((float)(physX) / (float) mywidth * 2.0) - 1.0 ;
  result[1] = -(((float)(physY) / (float) myheight * 2.0) - 1.0) ;
  return result ;
}

/**
 *  cartesianToPolar maps a location in the Cartesian coordinate
 *  space -1.0, -1.0 through 1.0, 1.0 to the unit circle centered
 *  at 0,0 with a radius of 1.0. The return value stores the
 *  polar radius in [0] and the angle in radians in [1].
 *  If either input coordinate
 *  lies outside of the -1.0..1.0 range, cartesianToPolar returns
 *  the corresponding results, and the calling code must check to
 *  determine whether the returned radius exceeds 1.0, requiring
 *  clipping.
**/
float [] cartesianToPolar(float cartesianX, float cartesianY) {
  float [] result = new float[2];
  float radius = (float) Math.sqrt(cartesianX * cartesianX + cartesianY * cartesianY);
  float angleInRadians = (float) Math.atan2(cartesianY, cartesianX);
  result[0] = radius ;
  result[1] = angleInRadians ;
  return result ;
}

/**
 *  cartesianToPolar maps a location in the polar coordinate unit
 *  circle 0.0, radius=0.0 upto 1.0, angle=2 * PI to the Cartesian
 *  coordinates centered at 0.0,0.0. The returned result, with
 *  Cartesian X in [0] and Y in [1], may lie outside the range
 *  of -1.0, -1.0 through 1.0, 1.0. The caller must verify that
 *  the return values are not outside the clipping boundary.
**/
float [] polarToCartesian(float radius, float angleInRadians) {
  float [] result = new float[2];
  result[0] = (float)(radius * Math.cos(angleInRadians));
  result[1] = (float)(radius * Math.sin(angleInRadians));
  return result ;
}
