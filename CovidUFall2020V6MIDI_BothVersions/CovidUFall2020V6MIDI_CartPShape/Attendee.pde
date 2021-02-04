class Attendee {
  /*
      ID is unique faculty name or student ID.
      isStudent True for students, False for faculty.
      infectStatus is one of 'pre', 'infected', or 'post'
      infectDate is null if not infected, else a week number
          0 through 15, for start of that academic week; modeling
          1 week from successful exposure to contagious per WHO comments;
          modeling length of contagious as 3 weeks per WHO comments.
      ageRiskBin is True for 15% of the faculty, estimating 15%
          of faculty being older than 60 or having underlying condition;
          it is True for 1.5% of students as a low-ball guess.
      Field isCheater is True or False, % and R0cheaters set on cmd line
          See method makeCheater()
      Internal set field "classes" is initially empty, populated via addClass().
  */
  String ID, infectStatus ;
  boolean isStudent, ageRiskBin, preInfected = false ;
  Class [] myCheatSections = null ;  // sections in which I cheat.
  Integer infectDate ;
  int sessionsToInfect = 0, communitySessionsToInfect = 0 ;
  int stopSpreadingIt = -1 ;  // week to stop spreading covid-19
  Set<Class> classes = new HashSet<Class>();
  Attendee(String ID, boolean isStudent, String infectStatus, Integer infectDate,
      boolean ageRiskBin) {
    this.ID = ID ;
    this.isStudent = isStudent ;
    this.infectStatus = infectStatus ;
    this.infectDate = infectDate ;
    this.ageRiskBin = ageRiskBin ;
  }
  void addClass(Class classObject) {
    classes.add(classObject);
  }
  void setInfectStatus(String infectStatus, Integer week, boolean preInfected) {
    /**
     Re-initialize infectStatus, one of 'pre', 'infected', or 'post'.
     Parameter week used to set infectDate only when infectStatus is 'infected'.
    **/
    this.preInfected = preInfected ;
    if ("infected".equals(infectStatus) && ! "infected".equals(this.infectStatus)) {
      this.infectStatus = "infected";
      this.infectDate = week ;
      stopSpreadingIt = week.intValue()+IncubationWeeks ;
      sessionsToInfect = 0 ;
      sessionsToInfect = int(R0);
      float R0fraction = R0 - int(R0);
      if (R0fraction > 0 && R0fraction > random(0.0, 1.0)) {
        sessionsToInfect += 1 ;
      }
      communitySessionsToInfect = 0 ;
      if (myCheatSections != null) {
        communitySessionsToInfect = int(R0cheaters) ;
        R0fraction = R0cheaters - int(R0cheaters);
        if (R0fraction > 0 && R0fraction > random(0.0, 1.0)) {
          communitySessionsToInfect += 1;
        }
      }
      if ((! ageRiskBin) && random(0.0, 1.0) < Asymptomatic) {
        stopSpreadingIt = week+InfectiousWeeks ;
      }
      for (Class from : classes) {
        from.infectedCount += 1 ;
        /*
        if (from.courseName.startsWith("community")) {
          COMMUNITYINFECTED += 1 ;
        }
        */
        for (Class to : classes) {
          Edge cnxn = new Edge(from, to);
          if (from == cnxn.vertex1) {
            // do not use an edge twice!
            EdgeStudents count = Edges.get(cnxn);
            if (count != null) {
              count.infectedStudents += 1;
            }
          }
        }
      }
      TOTALINFECTED += 1 ;
      if (ageRiskBin) {
        if (isStudent) {
          ATRISKSTUDENTSINFECTED += 1;
        } else {
          ATRISKFACULTYINFECTED += 1 ;
        }
      }
      if (isStudent) {
        ALLSTUDENTSINFECTED += 1;
      } else {
        ALLFACULTYINFECTED += 1 ;
      }
    } else if (! "infected".equals(infectStatus)) {
      this.infectStatus = infectStatus ;
      stopSpreadingIt = -1 ;
      sessionsToInfect = 0 ;
      if ("pre".equals(infectStatus)) {
        infectDate = null ;
      }
    }
  }
  void spreadInfection(int week) {
    Class [] clstype = new Class [0] ;
    Attendee [] attype = new Attendee [0] ;
    if ("infected".equals(infectStatus) && week > infectDate) {
      Class [] clsss = classes.toArray(clstype);
      for (int ses = 0 ; ses < sessionsToInfect ; ses++) {
        int cindex = int(random(0.0,clsss.length-.001));
        Class cls = null ;
        try {
          cls = clsss[cindex];
        } catch (ArrayIndexOutOfBoundsException xxx) {
          println("ArrayIndexOutOfBoundsException: " + xxx.getMessage() + " who " + ID);
          throw(xxx) ;
        }
        Attendee [] targets = cls.attendees.toArray(attype);
        /* R0 means exactly that many if available; search until we hit one */
        for (int contact = 0 ; contact < 100 ; contact++) {
          int tindex = int(random(0.0,targets.length-.001));
          if ("pre".equals(targets[tindex].infectStatus)) {
            targets[tindex].setInfectStatus("infected",week,false);
            break ;
          // July 20, 2020: Do not consider people who are not in the room
          // because they are out dead (risk+infected) or out sick until post.
          } else if (SkipAbsentAttendees
              && ((("post".equals(targets[tindex].infectStatus)
                  || "infected".equals(targets[tindex].infectStatus))
                && targets[tindex].ageRiskBin)
              || ("infected".equals(targets[tindex].infectStatus)
                && random(0.0,1.0) > Asymptomatic))) {
            continue ; 
          } else if (SkipAbsentAttendees) {
            break ;
          }
        }
      }
      if (myCheatSections != null) {
        for (int ses = 0 ; ses < communitySessionsToInfect ; ses++) {
          int cix = int(random(0,myCheatSections.length));
          Class cls = myCheatSections[cix];
          Attendee [] targets = cls.attendees.toArray(attype);
          /* R0 means exactly that many if available; search until we hit one */
          for (int contact = 0 ; contact < 100 ; contact++) {
            int tindex = int(random(0.0,targets.length-.001));
            if ("pre".equals(targets[tindex].infectStatus)) {
              targets[tindex].setInfectStatus("infected",week,false);
              COMMUNITYINFECTED++ ;
              break;
            // July 20, 2020: Do not consider people who are not in the room
            // because they are out dead (risk+infected) or out sick until post.
            } else if ((("post".equals(targets[tindex].infectStatus)
                    || "infected".equals(targets[tindex].infectStatus))
                  && targets[tindex].ageRiskBin)
                || ("infected".equals(targets[tindex].infectStatus)
                  && random(0.0,1.0) > Asymptomatic)) {
              continue ; 
            } else {
              break ;
            }
          }
        }
      }
    }
  }
  void checkRecovery(int week) {
    if ("infected".equals(infectStatus) && week > stopSpreadingIt) {
      setInfectStatus("post",week,false);
    }
  }
  void setAgeRiskBin(boolean ageRiskBin) {
    this.ageRiskBin = ageRiskBin ;
  }
  void makeCheater(boolean isCheater) {
    myCheatSections = (isCheater) ? new Class [1] : null ;
    for (int i = 0 ; i < Community.length ; i++) {
      if (classes.contains(Community[i])) {
        classes.remove(Community[i]);
        Community[i].attendees.remove(this);
      }
    }
    if (isCheater && Community != null && Community.length > 0) {
      // Just wrap around to make sure each Communinty gets someone.
      addClass(Community[CommunityNewStudentIndex]);
      Community[CommunityNewStudentIndex].addAttendee(this);
      myCheatSections[0] = Community[CommunityNewStudentIndex] ;
      CommunityNewStudentIndex = (CommunityNewStudentIndex + 1) % Community.length ;
      if (random(0,1) < 0.5) {
        // half the cheaters cheat in two Communities
        addClass(Community[CommunityNewStudentIndex]);
        Community[CommunityNewStudentIndex].addAttendee(this);
        myCheatSections = (Class []) append(myCheatSections,Community[CommunityNewStudentIndex]);
        CommunityNewStudentIndex = (CommunityNewStudentIndex + 1) % Community.length ;
      }
      // Community[0] is the off-campus party
      for (int tp = 0 ; tp < numTownParties && tp < Community.length ; tp++) {
        if (Community[tp].attendees.size() < cheatersPerTownParty
            && ! classes.contains(Community[tp])) {
          addClass(Community[tp]);
          Community[tp].addAttendee(this);
          myCheatSections = (Class []) append(myCheatSections,Community[tp]);
          break ;
        }
      }
    }
  }
}
