void loadData(String classesCSV, String studentsCSV, String coursenumMap) {
  Map<String,String> courseNumAliases = new HashMap<String,String>();
  Map<String,String> CourseNum2Name = new HashMap<String,String>();
  println("DEBUG loadData:"+classesCSV+":"+studentsCSV);
  //Set<String> Rooms = new HashSet<String>();
  Set<Integer> TimeHours = new HashSet<Integer>();
  Class [] ctype = new Class [0];
  int lineno = 1 ;
  String DEBUGFILE = classesCSV ;
  try {
    Scanner coursemap = new Scanner(new File(coursenumMap));
    String [] mhdr = coursemap.nextLine().trim().split(",");
    Map<String, Integer> mlhdrix = new HashMap<String, Integer>();
    for (int i = 0 ; i < mhdr.length ; i++) {
      mlhdrix.put(mhdr[i], i);
    }
    int ClassNbr = mlhdrix.get("Class Nbr");
    int Subject = mlhdrix.get("Subject");
    int Catalog = mlhdrix.get("Catalog");
    int Section = mlhdrix.get("Section");
    while (coursemap.hasNextLine()) {
      String [] inst = coursemap.nextLine().trim().split(",");
      String cnum = inst[ClassNbr].trim();
      String cname = inst[Subject].trim() + inst[Catalog].trim() + "." + inst[Section].trim();
      CourseNum2Name.put(cnum, cname);
    }
    coursemap.close();
    
    Scanner classes = new Scanner(new File(classesCSV));
    String [] chdr = classes.nextLine().trim().split(",");
    Map<String, Integer> clhdrix = new HashMap<String, Integer>();
    for (int i = 0 ; i < chdr.length ; i++) {
      clhdrix.put(chdr[i], i);
    }
    ClassNbr = clhdrix.get("Class Nbr");
    int Name = clhdrix.get("Name");
    int Mode = clhdrix.get("Instruction Type");
    int Room = clhdrix.get("Room");
    int Days = clhdrix.get("Meeting Days");
    int Start = clhdrix.get("Start Time");
    int Status = clhdrix.get("Status");
    lineno = 1 ;
    
    while (classes.hasNextLine()) {
      String [] inst = classes.nextLine().trim().split(",");
      for (int i = 0 ; i < inst.length ; i++) {
        if (inst[i] != null) {
          inst[i] = inst[i].trim();
        }
      }
      lineno += 1;
      String status = inst[Status];
      if ("Active".equals(status) && Session.get(inst[ClassNbr]) == null) {
        Class c = new Class(inst[ClassNbr], CourseNum2Name.get(inst[ClassNbr].trim()),
          inst[Name], inst[Mode], inst[Room], inst[Days], inst[Start]);
        if (facultyNoF2F.contains(c.instructor)
            || random(0.0, 1.0) < facultyRequestingNoF2F) {
          facultyNoF2F.add(c.instructor);
        } else {
          /* ALIASES! Some courses have multiple section numbers, e.g. CSC020 and FAR020.
             Use the c.room+"@"+c.dayEarliestPosition+"@"+c.timehour as the real key.
          */
          //courseName2Class.put(c.courseName, c);
          String roomkey = c.room+"@"+c.dayEarliestPosition+"@"+c.timehour ;
          Class original = roomHourToClass.get(roomkey);
          if (original != null) {
            original.attendees.addAll(c.attendees);
            courseNumAliases.put(c.ID, original.ID);
            // println("MAPPING COURSE ID " + c.ID + " TO " + original.ID);
            continue ;
          } else if (Session.keySet().contains(c.ID)
              || ! "Active".equals(inst[Status].trim())) {
            continue ;
          }
          courseName2Class.put(c.courseName, c);
          Session.put(inst[ClassNbr], c);
          roomHourToClass.put(c.room+"@"+c.dayEarliestPosition+"@"+c.timehour, c);
          deptHourToClass.put(c.courseName+"@"+c.dayEarliestPosition+"@"+c.timehour, c);
          //Rooms.add(c.room);
          TimeHours.add(c.timehour);
          Attendee fac = Faculty.get(inst[Name]) ;
          if (fac == null) {
            fac = new Attendee(inst[Name], false, "pre", null, false);
            Faculty.put(inst[Name], fac);
          }
          fac.addClass(c);
          c.addAttendee(fac);
        }
      }
    }
    classes.close();
   
    lineno = 1 ;
    DEBUGFILE = studentsCSV ;
    Scanner students = new Scanner(new File(studentsCSV));
    String DEBUGLINE = students.nextLine().trim();
    // println("DEBUGLINE 1: " + DEBUGLINE);
    String [] shdr = DEBUGLINE.split(",");
    Map<String, Integer> slhdrix = new HashMap<String, Integer>();
    for (int i = 0 ; i < shdr.length ; i++) {
      // println("DEBUG PUT: " + shdr[i] + "," + i);
      slhdrix.put(shdr[i], i);
    }
    ClassNbr = slhdrix.get("Class Nbr");
    int SID = slhdrix.get("Student ID");
    while (students.hasNextLine()) {
      DEBUGLINE = students.nextLine().trim();
      // println("DEBUGLINE 2: " + DEBUGLINE);
      String [] inst = DEBUGLINE.split(",");
      for (int i = 0 ; i < inst.length ; i++) {
        if (inst[i] != null) {
          inst[i] = inst[i].trim();
        }
      }
      lineno += 1;
      String classno = inst[ClassNbr];
      String alias =  courseNumAliases.get(classno) ;
      if (alias != null) {
        // println("MAPPING Course ID " + classno + " TO " + alias);
        classno = inst[ClassNbr] = alias ;
      }
      String sid = inst[SID];
      Class sess = Session.get(classno);
      if (sess != null) { // not on-line class
        Attendee stu = Students.get(sid);
        if (stu == null) {
          stu = new Attendee(sid, true, "pre", null, false);
        }
        if (studentsNoF2F.contains(sid)
            || random(0.0, 1.0) < studentsRequestingNoF2F) {
          studentsNoF2F.add(sid);
        } else {
          Students.put(sid, stu);
          stu.addClass(sess);
          sess.addAttendee(stu);
        }
      }
    }
    students.close();
    int populationCheat = (cheatersPerMeeting >= 1) ?
      round((((percentCheaters * Students.keySet().size()) / cheatersPerMeeting)) * 1.5)
      : 1 ;
    // 1.5 because half of cheaters go to 2 classes. Set cheatersPerClass to -1 for 
    // one big super-spreader Community Object.
    // half the cheaters cheat a second time, hence the 1.5
    Community = new Class [ populationCheat ];
    for (int i = 0 ; i < populationCheat ; i++) {
      String cname = "community" + (i+100) ;  // make it three digits
      Community[i] = new Class(cname, cname, cname, cname, cname, "MTWHFSA", "00:00");
      Community[i].infectedCount = 0;
      courseName2Class.put(Community[i].courseName, Community[i]);
      deptHourToClass.put(Community[i].courseName+"@"+Community[i].dayEarliestPosition+"@"+Community[i].timehour, Community[i]);
      roomHourToClass.put(Community[i].room+"@"+Community[i].dayEarliestPosition+"@"+Community[i].timehour, Community[i]);
      // Rooms.add(cname);
      Session.put(cname, Community[i]);
      TimeHours.add(Community[i].timehour);
    }
    SortedHours = TimeHours.toArray(new Integer [0]);
    Arrays.sort(SortedHours);
    SortedSessions = Session.values().toArray(ctype);
    Arrays.sort(SortedSessions);
  } catch (java.io.FileNotFoundException xxx) {
    print("ERROR IN loadData: " + xxx.getMessage() + ", FILE " + DEBUGFILE + ", line "
      + lineno);
    //throw(new RuntimeException(xxx));
    exit();
  } finally {
  }
}

Attendee [] initSimulationState(float R0, Integer seed) {
  TOTALINFECTED = 0 ;
  ATRISKFACULTYINFECTED = 0;
  ATRISKSTUDENTSINFECTED = 0;
  ALLFACULTYINFECTED = 0;
  ALLSTUDENTSINFECTED = 0;
  COMMUNITYINFECTED = 0 ;
  Attendee [] attype = new Attendee [0];
  if (seed != null) {
    randomSeed(seed.intValue());
  }
  for (Class c : Session.values()) {
    c.infectedCount = 0;
    c.edges.clear();  // Rebuild graph with changed Community at bottom of this method.
  }
  List<Attendee> people = new LinkedList<Attendee>();
  for (String f : Faculty.keySet()) {
    people.add(Faculty.get(f));
  }
  for (String s : Students.keySet()) {
    people.add(Students.get(s));
  }
  int startInfect = (int)(Math.ceil(R0));
  if (startInfect < 1) {
    startInfect = 1 ;
  }
  if (startInfect < MinimumStartingInfected) {
    startInfect = MinimumStartingInfected;
  }
  
  for (Attendee p : people) {
    p.setInfectStatus("pre",0,false);
    float norm = random(0.0, 1.0);
    if ((p.isStudent && (norm <= StudentsAtRisk))
        || ((! p.isStudent) && (norm <= InstructorsAtRisk))) {
       p.setAgeRiskBin(true);
       if (p.isStudent) {
         ATRISKSTUDENTSINFECTED++;
         ALLSTUDENTSINFECTED++;
       } else {
         ATRISKFACULTYINFECTED++; // DEBUG
         ALLFACULTYINFECTED++;
      }
    } else {
      p.setAgeRiskBin(false);
    }
    if (p.isStudent && percentCheaters > 0.0 && percentCheaters >= random(0.0,1.0)) {
      p.makeCheater(false);  // clean out any Community connections from prior run
      p.makeCheater(true);
    } else {
      p.makeCheater(false);
    }
  }
  while (startInfect > 0) {
    int index = (int)(Math.floor(random(0.0,people.size()-0.001)));
    if ("pre".equals(people.get(index).infectStatus)) {
      people.get(index).setInfectStatus("infected",0,true);
      startInfect -= 1 ;
    }
  }
  int startInfectCheat = 0 ;
  if (R0cheaters > 0 && percentCheaters > 0) {
    startInfectCheat = (int)(Math.ceil(R0cheaters));
    if (startInfectCheat < 1) {
      startInfectCheat = 1 ;
    }
    if (startInfectCheat < MinimumStartingInfected) {
      startInfectCheat = MinimumStartingInfected;
    }
    while (startInfectCheat > 0) {
      int cindex = (int)(random(0, Community.length));
      Class comm = Community[cindex];
      Attendee [] peeps = comm.attendees.toArray(attype);
      int index = (int)((Math.floor(random(0.0, peeps.length-0.001))));
      if ("pre".equals(peeps[index].infectStatus)) {
        peeps[index].setInfectStatus("infected",0,true);
        startInfectCheat -= 1;
      }
    }
  }
  // Rebuild the edge graph because makeup of Community varies run-to-run.
  Edges.clear();
  for (Attendee p : people) {
    for (Class c1 : p.classes) {
      for (Class c2 : p.classes) {
        if (c1.equals(c2)) {
          continue ;
        }
        Edge thisedge = c1.addEdge(c2);  // Add connects both side in Edges table.
        EdgeStudents stdnts = Edges.get(thisedge);
        /*
        if (stdnts == null) {
          stdnts = new EdgeStudents(0,0);
          Edges.put(thisedge, stdnts);
        }
        */
        stdnts.addStudents(1) ; 
        stdnts.infectedStudents = 0 ;
      }
    }
  }
  // println("DEBUG ARS=" + ATRISKSTUDENTSINFECTED + " ARF=" + ATRISKFACULTYINFECTED);
  ATRISKSTUDENTSINFECTED = 0 ;
  ATRISKFACULTYINFECTED = 0 ;
  ALLSTUDENTSINFECTED = 0 ;
  ALLFACULTYINFECTED = 0 ;
  return people.toArray(attype) ;
}

void simState(int week, Attendee [] peopleList) {
  // println("DEBUG WEEK " + week + " attendees=" + peopleList.length + ",F=" + Faculty.keySet().size()
      // + ",S="+Students.keySet().size());
  for (Attendee p : peopleList) {
    p.checkRecovery(week);
    p.spreadInfection(week) ;
  }
}

void advanceState() {
  if (! pauseStates) {
    currentFrame++ ;
    if (currentFrame >= framesInaWeek) {
      currentFrame = 0 ;
      currentWeek++ ;
      if (currentWeek > weeksInCycle) {
        currentWeek = 0 ;
        R0 = R0next ;
        R0cheaters = R0cheatersnext ;
        people = initSimulationState(R0, null);
        if (resetStats) {
          // resetStats is true when start a new value from key for a config param
          zeroWeeklyStats();
          resetStats = false ;
          currentRunWithTheseConfigParameters = 0 ;
        } else {
          currentRunWithTheseConfigParameters++ ;
        }
      } else {
        simState(currentWeek, people);
        advanceStatsPerWeek(currentWeek);
      }
      //println("WEEK = " + currentWeek);
    }
  }
}
