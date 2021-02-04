class Class implements Comparable<Class> {
  String ID;
  String courseName ;
  String instructor;
  String mode;
  String room ;
  String days;
  String time ;
  int timehour ;
  String displayText ;
  Set<Character> dayset = new HashSet<Character>();
  int dayEarliestPosition = -1 ;
  Set<Attendee> attendees = new HashSet<Attendee>();
  Set<Class> edges = new HashSet<Class>(); //see also global Edges owned by a pair of classes
  int infectedCount = 0 ;
  float X = 0, Y = 0, Z = 0 ;
  // ALEXIS:
  float PolarX = 0, PolarY = 0, PolarZ = 0 ;  // These are Cartesian coordinates Xlated from Polar coordinates.
  float PolarAngle = 0 ; //temporary angle around circle in degrees
  float PolarRadius = 0 ;  // temporary radius between 0.0 amd 1.0
  //Convert PolarAngle, PolarRadius TO PolarX, PolarY in setAngleRadiusZ()
  
  Class (String ID, String courseName, String instructor, String mode, String room, 
      String days, String time) {
    this.ID = ID.trim() ;
    this.courseName = courseName.trim();
    this.instructor = instructor.trim() ;
    this.mode = mode.trim() ;
    this.room = room.trim() ;
    this.days = days.trim() ;
    if (time == null || time.trim().equals("")) {
      time = this.time = "00:00";
    } else {
      time = this.time = time.trim() ;
    }
    timehour = Integer.parseInt(time.split(":")[0]);
    for (int i = 0 ; i < days.length() ; i++) {
      char c = days.charAt(i);
      dayset.add(c);
      boolean inlist = false ;
      for (int j = 0 ; j < DaysOrderedList.length ; j++) {
        if (DaysOrderedList[j] == c) {
          if (dayEarliestPosition < 0) {
            dayEarliestPosition = j ;
          }
          inlist = true ;
          break ;
        }
      }
      if (! inlist) {
        if (dayEarliestPosition < 0) {
          dayEarliestPosition = DaysOrderedList.length ;
        }
        DaysOrderedList = append(DaysOrderedList, c);
      }
    }
    DaysInWeek.addAll(dayset);
    displayText = courseName + "\n" + room + ":" + days + ":" + timehour + "\n" ;
  }
  void addAttendee(Attendee attendeeObject) {
    attendees.add(attendeeObject);
  }
  Edge addEdge(Class peer) {
    Edge tmpedge = null ;
    if (! peer.equals(this)) {
      edges.add(peer);
      peer.edges.add(this);
      tmpedge = new Edge(this, peer);
      EdgeStudents enrolled = Edges.get(tmpedge);
      if (enrolled == null) {
        enrolled = new EdgeStudents(0, 0);
        Edges.put(tmpedge, enrolled);
      }
    }
    return tmpedge;
  }
  /*
  void setAnyInfected(boolean anyInfected) {
    this.anyInfected = anyInfected ;
  }
  */
  public boolean equals(Object obj) {
    if (obj instanceof Class) {
      Class cobj = (Class) obj ;
      return (this.ID.equals(cobj.ID));
    }
    return false ;
  }
  public int hashCode() {
    return ID.hashCode();
  }
  public int compareTo(Class obj) {
    /* Primary sort key is time of class, secondary is room number. */
    /* Added 7/11/2020 primary sorting on course major and then its connections. */
    /*
    String mycoursename = null, objname = null ;
    mycoursename = (courseName.length() >= 3) ? courseName.substring(0,3) : courseName ;
    objname = (obj.courseName.length() >= 3) ? obj.courseName.substring(0,3) 
      : obj.courseName ;
    int scmp = mycoursename.compareTo(objname);
    int mycnxn = edges.size();
    int objcnxn = obj.edges.size();
    if (scmp != 0) {
      return -1 ;
    } else if (mycnxn > objcnxn) {
      return -1 ;      // sort more connections first
    } else if (mycnxn < objcnxn) {
      return 1 ;
    } else */ if (this.dayEarliestPosition < obj.dayEarliestPosition) {
      return -1 ;
    } else if (this.dayEarliestPosition > obj.dayEarliestPosition) {
      return 1 ;
    } else if (this.timehour < obj.timehour) {
      return -1 ;
    } else if (this.timehour > obj.timehour) {
      return 1 ;
    }
    return this.room.compareTo(obj.room);
  }
  void setXYZ(float x, float y, float z) {
    X = x ;
    Y = y ;
    Z = z ;
  }
  // ALEXIS:
  void setAngleRadiusZ(float angleInDegrees, float unitRadius, float Z) {
    // Store these in float PolarAngle, PolarRadius, PolarZ
    PolarAngle = angleInDegrees;
    PolarRadius = unitRadius;
    PolarZ = Z;
    
    // Convert those first two into PolarX, PolarY
    float[] polarToCart = polarToCartesian(PolarRadius, radians(PolarAngle));
    int[] cartToPhys = cartesianToPhysical(polarToCart[1], polarToCart[0]);
    PolarX = cartToPhys[0];
    PolarY = cartToPhys[1];
    
    // subtract width/2 and height/2 from those answers (possibly)
    PolarX -= width/2;
    PolarY -= height/2;
  }
  
  void toPShape()
  {
    PShape course = createShape(SPHERE, 50);
    if(isCartesian)
    {
      course.translate(X, Y, Z);
    }
    else
    {
      course.translate(PolarX, PolarY, PolarZ);
    }
    bigshape.addChild(course);
    bigshape.setFill(color(0, 255, 255));
  }
  
  void display() {
    final float mididiscord = 40.0 ;
    final float midiaccord = 100.0 ;
    push(); 
    // ALEXIS if global cartesian do the following translate(X,Y,Z), else translate(PolarX, PolarY, PolarZ)
    if(isCartesian)
    {
      translate(X,Y,Z);
    }
    else
    {
      translate(PolarX, PolarY, PolarZ);
    }
    stroke(255);
    fill(255);
    textSize(18 * ratio1080p);
    float percentInfected = (float)infectedCount / attendees.size();
    float percentNot = 1.0 - percentInfected ;
    int rred = (int)(percentInfected * 192.0);
    int bblue = (int)(percentNot * 255.0);
    notes[0] += round(percentNot * midiaccord);
    notes[2] += round(percentInfected * mididiscord);
    numClasses += 1 ;
    fill(rred, 255, bblue, 255);
    stroke(rred, 255, bblue, 255);
    if (xbackwards) {
      rotateX(PI);
    }
    if (ybackwards) {
      rotateY(PI);
    }
    if (zbackwards) {
      rotateZ(PI);
    }
    /*
    if (zeye < 0) {  // reorient text when behind it
      rotateY(PI);
    }
    */
    
    if(!isCartesian)
    {
      text(displayText+"S="+attendees.size()+";E=" + edges.size() + ";I="+infectedCount,0,0,0);
    }
    pop();
    if (! hideLines) {
      push();
      for (Class c : edges) {
        Edge savedEdge = new Edge(this, c);
        EdgeStudents savedCount = Edges.get(savedEdge);
        if (savedCount != null) {
          strokeWeight(savedCount.strokeWeight);
          percentInfected = (float)(savedCount.infectedStudents) / savedCount.students ;
          percentNot = 1.0 - percentInfected ;
          notes[1] += round(percentNot * midiaccord);
          notes[3] += round(percentInfected * mididiscord);
          numEdges += 1 ;
          rred = (int)(percentInfected * 192.0);
          if (rred > 0) {
            stroke(rred+63, 0, 0, 255);
          } else {
            bblue = (int)(percentNot * 255.0);
            stroke(0, 0, bblue, 20);
          }
          strokeWeight(2);
          if(isCartesian)
          {
            line(X, Y, Z, c.X, c.Y, c.Z);
          }
          else
          {
            line(PolarX, PolarY, PolarZ, c.PolarX, c.PolarY, c.PolarZ);
          }
        }
      }
      pop();
    }
  }
}
