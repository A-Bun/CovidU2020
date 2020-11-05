// Added 6/2020 to move camera and rotate world when these keys are held down.

// Added 3D navigation
// xeye=809.0 yeye=547.0 zeye=2008.0  xeye=737.0 yeye=547.0 zeye=2808.0
// xeye=1061.0 yeye=633.0 zeye=3708.0
float initxeye=1061.0*ratio1080p ;
float inityeye=633.0*ratio1080p ;
float initzeye=3708.0*ratio1080p ;
float xeye, yeye, zeye ;
float worldxrotate = 0, worldyrotate = 0, worldzrotate = 0 ;
float degree = radians(1.0), around = TWO_PI ;
boolean xbackwards = false, ybackwards = false, zbackwards = false ;

void moveCameraRotateWorldKeys() {
  if (keyPressed) {
    if (key == 'u') {
      zeye += 10 ;
      // println("DEBUG u " + zeye + ", minZ: " + minimumZ + ", maxZ: " + maximumZ);
    } else if (key == 'U') {
      zeye += 100 ;
      // println("DEBUG U " + zeye + ", minZ: " + minimumZ + ", maxZ: " + maximumZ);
    } else if (key == 'd') {
      zeye -= 10 ;
      // println("DEBUG d " + zeye + ", minZ: " + minimumZ + ", maxZ: " + maximumZ);
    } else if (key == 'D') {
      zeye -= 100 ;
      // println("DEBUG D " + zeye + ", minZ: " + minimumZ + ", maxZ: " + maximumZ);
    } else if (key == 'n') {
      yeye -= 1 ;
    } else if (key == 'N') {
      yeye -= 10 ;
    } else if (key == 's') {
      yeye += 1 ;
    } else if (key == 'S') {
      yeye += 10 ;
    } else if (key == 'w') {
      xeye -= 1 ;
    } else if (key == 'W') {
      xeye -= 10 ;
    } else if (key == 'e') {
      xeye += 1 ;
    } else if (key == 'E') {
      xeye += 10 ;
    } else if (key == 'x') {
      worldxrotate += degree ;
      if (worldxrotate >= around) {
        worldxrotate = 0 ;
      }
    } else if (key == 'X') {
      worldxrotate -= degree ;
      if (worldxrotate < -around) {
        worldxrotate = 0 ;
      }
    } else if (key == 'y') {
      worldyrotate += degree ;
      if (worldyrotate >= around) {
        worldyrotate = 0 ;
      }
    } else if (key == 'Y') {
      worldyrotate -= degree ;
      if (worldyrotate < -around) {
        worldyrotate = 0 ;
      }
    } else if (key == 'z') {
      worldzrotate += degree ;
      if (worldzrotate >= around) {
        worldzrotate = 0 ;
      }
    } else if (key == 'Z') {
      worldzrotate -= degree ;
      if (worldzrotate < -around) {
        worldzrotate = 0 ;
      }
    } else if (mousePressed && key == ' ') {
      xeye = mouseX ;
      yeye = mouseY ;
    }
  }
  // Make sure 6th parameter -- focus in the Z direction -- is far, far away
  // towards the horizon. Otherwise, ortho() does not work.
  //camera(xeye, yeye,  zeye, xeye, yeye,  zeye-signum(zeye-minimumZ)*maximumZ*2 , 0,1,0);
  camera(xeye, yeye,  zeye, xeye, yeye,  0,  // Look towards the Z=0 plane.
    0,1,0);
  if (worldxrotate != 0 || worldyrotate != 0 || worldzrotate != 0) {
    translate(width/2, height/2, depth/4);  // rotate from the middle of the world
    if (worldxrotate != 0) {
      rotateX(worldxrotate);
      //xbackwards = (worldxrotate < -PI || worldxrotate > PI);
    //} else {
      //xbackwards = false ;
    }
    if (worldyrotate != 0) {
      rotateY(worldyrotate);
      //ybackwards = (worldyrotate < -PI || worldyrotate > PI);
    //} else {
      //ybackwards = false ;
    }
    if (worldzrotate != 0) {
      rotateZ(worldzrotate);
      //zbackwards = (worldzrotate < -PI || worldzrotate > PI);
    //} else {
      //zbackwards = false ;
    }
    translate(-width/2, -height/2, -depth/4); // Apply the inverse of the above translate.
    // Do not use pushMatrix()-popMatrix() instead of the inverse translate,
    // because popMatrix() would discard the rotations.
  //} else {
    //  xbackwards = ybackwards = zbackwards = false ;
  }
}
