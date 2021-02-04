// CovidUFall2020V6MIDI_PolarPShape, D. Parson, June & July 2020
// V2 adds MEAN and MAX for accumulating stats by week.
// CovidUFall2020V3 Attendee.spreadInfection softens application of R0
//  to partially infected classes to account for fewer prospective victims,
//  see Attendee.spreadInfection() July 20, 2020 notes.
// CovidUFall2020V4 make V3 modification optional via SkipAbsentAttendees boolean,
//  and add fractional studentsRequestingNoF2F. Also add MinimumStartingInfected.
// CovidUFall2020V4 adds MIDI data sonification, toggled by 'M' key.
// V5 ads some key commands:
// <     P toggles Pausing the simulation.
// ---
// >     P toggles MIDI sonification.
// >     c schedules dump to CSV file. (This is the main enhancement in V5.)
// V6 adds CartesianPolar tab for using 3D Polar in the future.
// >     F prints out frameRate
// See License.pde tab for the Creative Commons 4.0 open source license.
import java.util.* ;
/********  PRIMARY SIMULATION CONFIG PARAMETERS  **********************/
float R0 = .81  ;        // infection rate in classroom
float R0cheaters = 1.5  ;  // infection rate in careless social & party settings
final float percentCheaters = 0.15 ;  // percentage of Attendees cheating to R0cheaters
final float cheatersPerMeeting = 7 ;  // Limit "class size" of a community session.
// cheatersPerMeeting = 7, -1 means only 1 Community super-spreader object.
// "Two houses on Thursday four on Friday and one on Saturday.
// Crowds range from approximately 35-125 these are the averages I have experienced.
// There were 8 houses 7 houses that regularly held large gatherings and there are often
// a half a dozen smaller one occasional parties and of course holidays and special occasions." impact those numbers
final float cheatersPerTownParty = 80 ; // 80 conservative estimate based on resident responses
final int numTownParties = 6 ;  // 6, a Kutztown policeman told me 7 or 8 big ones, see above.
final float facultyRequestingNoF2F = 0.65 ; //.4 based on mid August, .65 based on September
final float studentsRequestingNoF2F=.0 ;
int MinimumStartingInfected = 1 ;
// (1.0 / 325.0) * 5662.0 = .0031 * 5662 = 17
// 1.0 is based on the fact that 4 CSC students *that we know of* had COVID 2nd half
// of spring semester, cut it in half to avoid hyperbole. 5662 is number students in
// this dataset, but it will be less when studentsRequestingNoF2F > 0, so re-do the math in
// loadData().
// Base MinimumStartingInfected on (numCSCInfect/numCSC)*numAll
/**********************************************************************/
/* Example runs:
  Asymptomatic = .25  The CDC Director estimates that as many as 25% of infected people may be asymptomatic.
  This parameter interacts with InfectiousWeeks.
  S. Whitehead, "CDC Director On Models For The Months To Come: 'This Virus Is Going To Be With Us'".
  https://www.npr.org/sections/health-shots/2020/03/31/824155179/cdc-director-on-models-for-the-months-to-come-this-virus-is-going-to-be-with-us
  WHO:
  For COVID-19, data to date suggest that 80% of infections are mild or asymptomatic,
  15% are severe infection, requiring oxygen and 5% are critical infections, requiring ventilation.

  // Risk updated from 15% to 25% (faculty/staff) and 1.5% to 2.5% (students) per these web sites.
  // July 10, 2020:
  // https://www.kff.org/coronavirus-covid-19/issue-brief/how-many-teachers-are-at-risk-of-serious-illness-if-infected-with-coronavirus/?fbclid=IwAR3kl6Sp4QE-RAhwTOppatFRvY0DPEW_e2Q_bD7jOcmJ35Ah8vspnjJfDJw
  // June 15, 2020
  // https://www.kff.org/coronavirus-covid-19/issue-brief/almost-one-in-four-adult-workers-is-vulnerable-to-severe-illness-from-covid-19/?fbclid=IwAR2bZt9_-w_vAzsGJik8FiLtUETmKCH5Ts9ciT38uex5vg4dIwjQCFSQOJM

  Sept 24, NOT ACCOUNTING FOR ASYMPTOMATIC INFECTIONS:
  R0=.81    R0cheaters=1.15   percentCheaters=.1    facultyRequestingNoF2F=.4       cheatersPerMeeting = 7
  R0=.81    R0cheaters=1.15   percentCheaters=.1    facultyRequestingNoF2F=.65      cheatersPerMeeting = 7
  R0=.81    R0cheaters=1.15   percentCheaters=.15   facultyRequestingNoF2F=.65      cheatersPerMeeting = 7
  R0=.81    R0cheaters=2.00   percentCheaters=.15   facultyRequestingNoF2F=.65      cheatersPerMeeting = 7
  
  July 16:
  R0=.81   R0cheaters=1.1   percentCheaters=.00    facultyRequestingNoF2F=0       cheatersPerMeeting = 7
  R0=.81   R0cheaters=1.1   percentCheaters=.10    facultyRequestingNoF2F=0       cheatersPerMeeting = -1
  R0=.81   R0cheaters=1.1   percentCheaters=.10    facultyRequestingNoF2F=0       cheatersPerMeeting = 7
  R0=.81   R0cheaters=1.1   percentCheaters=.10    facultyRequestingNoF2F=.33     cheatersPerMeeting = 7
*/
/**************  KEYBOARD NAVIGATION **********************************
    x, X, y, Y, z, Z rotate graph around respective axis clockwise & counter.
    u, U, d, D navigate camera Z up from graph and down into graph's front.
    e, E, w, W, n, N, s, S navigate camera right, left, up, down in X,Y
    H toggles hiding the edges (runs faster), h toggles hiding summary states.
    P toggles MIDI sonification.
    c schedules dump to CSV file.
    F prints out frameRate
**********************************************************************/
final float width1080p = 1920 ;
final float height1080p = 1080 ;
float ratio1080p = 1 ;  // scaled for display after size()
// GLOBAL DATABASE
boolean SkipAbsentAttendees = false ;
boolean isCartesian = false; // ALEXIS addition
String classesCSV = "CLASS_SOME_INPERSON_ROOM_16May2020_Encrypt.csv";
String studentsCSV = "ALL_ROSTER_CLASS_STUDENT_ENCRYPT.csv";
String coursenumMap = "CourseNum2Name.csv"; // added 7/2/2020 to tag course name & section
// DEBUGINFECTED = None
int NumberSimsMax = 100   ;  // Run 100 times per UCLA if no seed, else run 1
float R0next = R0 ;
float R0cheatersnext = R0cheaters ;
final int weeksInCycle = 15 ;
int currentWeek = 0 ;
int framesInaWeek = 15 ;  // goes up for 'M' MIDI
int currentFrame = 0 ;
int currentRunWithTheseConfigParameters = 0 ;
int TOTALINFECTED = 0, ATRISKFACULTYINFECTED = 0, ATRISKSTUDENTSINFECTED = 0 ;
int ALLFACULTYINFECTED = 0, ALLSTUDENTSINFECTED = 0 ;
int COMMUNITYINFECTED = 0 ;
// Cheaters visit Community Class, below, where R0cheaters applies.
Map<String,Attendee> Faculty = new HashMap<String,Attendee>(); // faculty name to Attendee
Set<String> facultyNoF2F = new HashSet<String>() ;
Map<String,Attendee> Students = new HashMap<String,Attendee>(); // student ID to Attendee
Set<String> studentsNoF2F = new HashSet<String>() ;
Attendee [] people = null ;
Map<String,Class> Session = new HashMap<String,Class>(); // ClassNbr to Class object
SortedMap<String,Class> courseName2Class = new TreeMap<String,Class>();
Class [] SortedSessions = null ;  // sorted on earliest Day, then Time, then Room number
//String [] SortedRooms = null ;       // lay rooms out in an X,Y grid, times in Z
// int sqrtSortedRooms = 0 ; // set in loadData()
Integer [] SortedHours = null ;
Map<Edge,EdgeStudents> Edges = new HashMap<Edge,EdgeStudents>();  // owned by a pair of classes
Map<String,Class> roomHourToClass = new HashMap<String,Class>();
Map<String,Class> deptHourToClass = new HashMap<String,Class>();
Set<Character> DaysInWeek = new HashSet<Character>(); // M, T, W, H, F, S, etc. from data.
char [] DaysOrderedList = {'M', 'T', 'W', 'H', 'F', 'S'}; // database may have others
// at-risk means at risk for serious complications.
// Risk updated from .15 and .015 per these web sites.
// https://www.kff.org/coronavirus-covid-19/issue-brief/how-many-teachers-are-at-risk-of-serious-illness-if-infected-with-coronavirus/?fbclid=IwAR3kl6Sp4QE-RAhwTOppatFRvY0DPEW_e2Q_bD7jOcmJ35Ah8vspnjJfDJw
// https://www.kff.org/coronavirus-covid-19/issue-brief/almost-one-in-four-adult-workers-is-vulnerable-to-severe-illness-from-covid-19/?fbclid=IwAR2bZt9_-w_vAzsGJik8FiLtUETmKCH5Ts9ciT38uex5vg4dIwjQCFSQOJM
float InstructorsAtRisk = .25  ;// 15% of Faculty, originally 20%, avoid hyperbole.
float StudentsAtRisk = .025 ;   // 1.5% of students low-ball estimate
float HerdImmunity = .05  ;     // 5% past infection at start of simulation
float Asymptomatic = .25;
int IncubationWeeks = 1;
int InfectiousWeeks = 1  ;   // Reduced from 2. asymptomatic infect as many as symptomatic.
Class [] Community = null;        // Reinitialize with cheating students each time.
int CommunityNewStudentIndex = 0 ; // Community[0] is the off-campus party

int MaxPathLen = 0;
int MeanPathLen = 0;
int MedianPathLen = 0 ;
int ModePathLen = 0;
int MaxPeers = 0;
int MeanPeers = 0;
int MedianPeers = 0;
int ModePeers = 0;
int depth = 0 ;        // compute in pixels same as width & height
boolean hideLines = false ;
boolean hideText = false ;
boolean pauseStates = false ;
boolean playMusic = false ;
PrintWriter CSVwriter = null ;
boolean CSVpending = false ;

PShape bigshape = null ;

void setup() {
  //size(1900,1060,P3D);
  fullScreen(P3D);
  frameRate(60);
  ratio1080p = width / width1080p ;
  background(0);
  loadData(sketchPath()+"/"+classesCSV,sketchPath()+"/"+studentsCSV,sketchPath()+"/"+coursenumMap);
  textAlign(CENTER, CENTER);
  fill(255);
  stroke(255);
  textSize(32 * ratio1080p);
  bigshape = createShape(GROUP);
  stroke(color(0, 255, 255));
  
  int depthper = (width/10) * 2 ;
  // ALEXIS: START OF CARTESIAN LAYOUT
    int widthper = width / 10 ; // sqrtSortedRooms ;
    int heightper = height / 10 ; // sqrtSortedRooms ;
    /* Experiment 7/11/2020 */
    /*
    int perside = (int)(java.lang.Math.sqrt(courseName2Class.keySet().size()));
    widthper = width / perside ;
    heightper = height / perside  ;
    depthper = max(widthper,heightper) ;
    */
    
    int znow = 0 ;
    int widthnow = (widthper / 2) - (width/2) ;    // account for translate to center
    int heightnow = (heightper / 2) - (height/2) ;
    for (String r : courseName2Class.keySet()) {
      for (int dix = 0 ; dix < DaysOrderedList.length ; dix++) {
        for (int h : SortedHours) {
          String key = r + "@" + dix + "@" + h ;
          Class c = deptHourToClass.get(key);
          if (c != null && ! c.courseName.startsWith("community")) {
            // sort community to the back
            c.setXYZ(widthnow, heightnow, znow);
            widthnow += widthper ;
            if (widthnow >= width/2) {
              widthnow = (widthper / 2) - (width/2) ;
              heightnow += heightper;
              if (heightnow >= height/2) {
                heightnow = (heightper / 2) - (height/2);
                znow -= depthper ;
                depth++ ;
              }
            }
          }
        }
      }
    }
    // When reorging by matrix, some slip thru the geometry, add them in
    for (Class c : Session.values()) {
      if (c.X == 0 && c.Y == 0 && c.Z == 0 && ! c.courseName.startsWith("community")) {
        c.setXYZ(widthnow, heightnow, znow);
        widthnow += widthper ;
        if (widthnow >= width/2) {
          widthnow = (widthper / 2) - (width/2) ;
          heightnow += heightper;
          if (heightnow >= height/2) {
            heightnow = (heightper / 2) - (height/2);
            znow -= depthper ;
            depth++ ;
          }
        }
      }
    }
    // Do Community last
    for (Class c : Session.values()) {
      if (c.X == 0 && c.Y == 0 && c.Z == 0 && c.courseName.startsWith("community")) {
        c.setXYZ(widthnow, heightnow, znow);
        widthnow += widthper ;
        if (widthnow >= width/2) {
          widthnow = (widthper / 2) - (width/2) ;
          heightnow += heightper;
          if (heightnow >= height/2) {
            heightnow = (heightper / 2) - (height/2);
            znow -= depthper ;
            depth++ ;
          }
        }
      }
    }
   // ALEXIS: END OF CARTESIAN LAYOUT
   
   // ALEXIS: START OF POLAR LAYOUT
    int polarZnow = 0;
    float angleper = 360.0/10.0; //tweak these
    float radiusper = 0.3; //tweak these
    float anglenow = 0;    // account for translate to center //tweak these
    float radiusnow = 1.0; // start at 1.0, the outer edge of the circle
    for (String r : courseName2Class.keySet()) {
      for (int dix = 0 ; dix < DaysOrderedList.length ; dix++) {
        for (int h : SortedHours) {
          String key = r + "@" + dix + "@" + h ;
          Class c = deptHourToClass.get(key);
          if (c != null && ! c.courseName.startsWith("community")) {
            // sort community to the back
            c.setAngleRadiusZ(anglenow, radiusnow, polarZnow);
            c.toPShape();
            anglenow += angleper ;                      // increase the current angle
            if (anglenow >= 359) {                      // if the current angle >= 359
              anglenow = 0;                             // reset the current angle to the starting angle
              radiusnow -= radiusper;                   // decrease the current radius
              if (radiusnow <= 0.1) {                   // if the current radius is <= 0.1
                radiusnow = 1.0;                        // reset the current radius to the starting radius
                polarZnow -= depthper ;                 // decrease the current z
                depth++ ;
              }
            }
          }
        } 
      }
    }
   
    // When reorging by matrix, some slip thru the geometry, add them in
    for (Class c : Session.values()) {
      if (c.PolarX == 0 && c.PolarY == 0 && c.PolarZ == 0 && ! c.courseName.startsWith("community")) {
        c.setAngleRadiusZ(anglenow, radiusnow, polarZnow);
        c.toPShape();
        anglenow += angleper ;
          if (anglenow >= 359) {
            anglenow = 0;
            radiusnow -= radiusper;
            if (radiusnow <= 0.1) {
              radiusnow = 1.0;
              polarZnow -= depthper ;
              depth++ ;
          }
        }
      }
    }
    // Do Community last
    for (Class c : Session.values()) {
      if (c.PolarX == 0 && c.PolarY == 0 && c.PolarZ == 0 && c.courseName.startsWith("community")) {
        c.setAngleRadiusZ(anglenow, radiusnow, polarZnow);
        c.toPShape();
        anglenow += (angleper+9) ;     // changed so community text doesn't overlap in general
          if (anglenow >= 359) {
            anglenow = 0;
            radiusnow -= 0.55;         // changed so community text doesn't overlap in general
            if (radiusnow <= 0.4) {    // changed so community text doesn't overlap when noF2F is 0.65
              radiusnow = 1.0;
              polarZnow -= depthper ;
              depth++ ;
          }
        }
      }
    }
    // ALEXIS: END OF POLAR LAYOUT
        
  int DEBUGMISS1 = 0 ;
  for (Class c : Session.values()) {
    if (c.X == 0 && c.Y == 0 && c.Z == 0) {
      //println("BAD INIT 1 " + c.ID);
      DEBUGMISS1++ ;
    }
  }
  int DEBUGMISS2 = 0 ;
  println("DEBUG 2 SES len " + SortedSessions.length);
  for (Class c : SortedSessions) {
    if (c.X == 0 && c.Y == 0 && c.Z == 0) {
      println("BAD INIT 2 " + c.ID + " room = " + c.room + " time = " + c.timehour);
      DEBUGMISS2++;
    }
  }
  println("DEBUGMISS1 = " + DEBUGMISS1 + ", DEBUGMISS2 = " + DEBUGMISS2);
  people = initSimulationState(R0, 42);
  //xeye = width / 2 ;
 //  yeye = height / 2 ;
  depth = depth * depthper ;
  // zeye = (width*2.7) ;

  xeye=initxeye ; yeye=inityeye ; zeye=initzeye ;  // trial & error
  MinimumStartingInfected = max(1,round((1.0 / 325.0) * Students.keySet().size()));
  setupMIDI();
  println("NUMBER OF SESSIONS " + SortedSessions.length + " , " + Session.keySet().size());
  println("NUMBER OF STUDENTS=" + Students.keySet().size() + ", FACULTY="
    + Faculty.keySet().size() + ", COMMUNITY COUNT = " + Community.length);
  println("MinimumStartingInfected = " + MinimumStartingInfected);
  // println("Java rounds 1.5="+Math.round(1.5));
}

void draw() {
  push();
  background(0);
  fill(255);
  stroke(255);
  textSize(32 * ratio1080p);
  strokeWeight(1);
  moveCameraRotateWorldKeys();
  translate(width/2, height/2, 0 /* depth/2 */);  // 0,0 is at middle of the display
  if(isCartesian == false)
  {
    shape(bigshape, 0, 0);
  }
  for (Class c : SortedSessions) {
    c.display();
    // print("DEBUG EDGES " + c.ID + ":" + c.edges.size());
  }
  pop();
  fill(255);
  stroke(255);
  textSize(28 * ratio1080p);
  advanceState();
  int statsweek = currentWeek ;
  if (statsweek == 0 && currentRunWithTheseConfigParameters == 0) {
    // We need this to bootstrap the MEAN & MAX on the initial pass.
    advanceStatsPerWeek(0);
  }
  if (! hideText) {
    // ??July 19, 2020 subtract 2 from week to show pre-semester community spread
    text("RUNS " + currentRunWithTheseConfigParameters 
      + " WEEK " + (statsweek) + " R0classroom=" + R0 + " R0cheaters=" + R0cheaters
      + " %cheat=" + percentCheaters + " infected=" + TOTALINFECTED
      + " infectedInClass?=" + (TOTALINFECTED-COMMUNITYINFECTED) + "\n"
      + " careless groupsize=" + ((int)cheatersPerMeeting) + " town party size="
      + ((int)cheatersPerTownParty) + " # weekly town parties=" 
      + ((int)numTownParties)
      + " faculty online=" + (facultyRequestingNoF2F*100) + "%\n"
      
     
      + " atriskFacultyInfected=" + ATRISKFACULTYINFECTED
      + "/" + ALLFACULTYINFECTED + ":I"
      + " atriskStudentsInfected=" + ATRISKSTUDENTSINFECTED 
      + "/" + ALLSTUDENTSINFECTED + ":I"
      + " fac=" + Faculty.keySet().size() + " stu=" + Students.keySet().size()
      + " starters = " + MinimumStartingInfected
      + "\nMEAN[" + statsweek + "] infected=" + TOTALINFECTEDMEAN[statsweek] 
      + " infectedInClass?=" + infectedInClassMEAN[statsweek]
      + " atriskFacultyInfected=" + atriskFacultyInfectedMEAN[statsweek] 
      + "/" + allFacultyInfectedMEAN[statsweek] + ":I"
      + " atriskStudentsInfected=" + atriskStudentsInfectedMEAN[statsweek]
      + "/" + allStudentsInfectedMEAN[statsweek] + ":I"
      + "\nMAX[" + statsweek + "] infected=" + TOTALINFECTEDMAX[statsweek] 
      + " infectedInClass?=" + infectedInClassMAX[statsweek]
      + " atriskFacultyInfected=" + atriskFacultyInfectedMAX[statsweek]
      + "/" + allFacultyInfectedMAX[statsweek] + ":I"
      + " atriskStudentsInfected=" + atriskStudentsInfectedMAX[statsweek]
      + "/" + allStudentsInfectedMAX[statsweek] + ":I",
      900*ratio1080p, (height-150), 50);
      // xeye, yeye, (zeye < 0) ? zeye - 1000 : zeye+1000);
  }
  if (playMusic) {
    playMIDI();
  }
  if (CSVpending && statsweek == weeksInCycle) {
    CSVdump();
  }
}

void CSVdump() {
  String fname = sketchPath()+"/COVIDUFall2020V5MIDI_" + year() + "_" + month() + "_"
        + day() + "_" + hour() + "_" + minute() + "_" + second() + ".csv";
  try {
    CSVpending = false ;
    if (CSVwriter == null) {
      CSVwriter = new PrintWriter(fname);
      CSVwriter.println("RUNS,WEEK,Sessions,R0classroom,R0cheaters,%cheat,careless groupsize,"
        + "town party size,weekly town parties,faculty % online,facultyF2F,studentsF2F,starters,"
        + "meaninfected,meaninfectedinclass,maxinfected,maxinfectedinclass,"
        + "meanatriskFacultyInfected,meanatriskStudentsInfected,"
        + "maxatriskFacultyInfected,maxatriskStudentsInfected,"
        + "meanallFacultyInfected,meanallStudentsInfected,"
        + "maxallFacultyInfected,maxallStudentsInfected");
    }
  } catch (java.io.FileNotFoundException fnx) {
    println("ERROR, Cannot create file " + fname);
    return ;
  }
  for (int statsweek = 0 ; statsweek <= weeksInCycle ; statsweek++) {
    CSVwriter.println(""+currentRunWithTheseConfigParameters+","+statsweek+","
      +Session.keySet().size()+","+R0+","
      +R0cheaters+","+percentCheaters+","+((int)cheatersPerMeeting)+","+((int)cheatersPerTownParty)
      +","+((int)numTownParties)+","+facultyRequestingNoF2F+","+Faculty.keySet().size()+","
      +Students.keySet().size()+","+MinimumStartingInfected+","
      +TOTALINFECTEDMEAN[statsweek]+","+infectedInClassMEAN[statsweek]+","
      +TOTALINFECTEDMAX[statsweek]+","+infectedInClassMAX[statsweek]+","
      +atriskFacultyInfectedMEAN[statsweek]+","+atriskStudentsInfectedMEAN[statsweek]+","
      +atriskFacultyInfectedMAX[statsweek]+","+atriskStudentsInfectedMAX[statsweek]+","
      +allFacultyInfectedMEAN[statsweek]+","+allStudentsInfectedMEAN[statsweek]+","
      +allFacultyInfectedMAX[statsweek]+","+allStudentsInfectedMAX[statsweek]);
  }
  CSVwriter.flush();
}

int [] TOTALINFECTEDMEAN = new int [ weeksInCycle+1 ];
int [] TOTALINFECTEDMAX = new int [ weeksInCycle+1 ];
int [] infectedInClassMEAN = new int [ weeksInCycle+1 ]; 
int [] infectedInClassMAX = new int [ weeksInCycle+1 ];
int [] atriskFacultyInfectedMEAN = new int [ weeksInCycle+1 ]; 
int [] atriskFacultyInfectedMAX = new int [ weeksInCycle+1 ];
int [] atriskStudentsInfectedMEAN = new int [ weeksInCycle+1 ]; 
int [] atriskStudentsInfectedMAX = new int [ weeksInCycle+1 ];
int [] allFacultyInfectedMEAN = new int [ weeksInCycle+1 ]; 
int [] allFacultyInfectedMAX = new int [ weeksInCycle+1 ];
int [] allStudentsInfectedMEAN = new int [ weeksInCycle+1 ]; 
int [] allStudentsInfectedMAX = new int [ weeksInCycle+1 ];

void advanceStatsPerWeek(int statsweek) {
  if (currentRunWithTheseConfigParameters == 0) {
    TOTALINFECTEDMEAN[statsweek] = TOTALINFECTED ;
    infectedInClassMEAN[statsweek] = (TOTALINFECTED-COMMUNITYINFECTED) ;
    atriskFacultyInfectedMEAN[statsweek] = ATRISKFACULTYINFECTED ;
    allFacultyInfectedMEAN[statsweek] = ALLFACULTYINFECTED ;
    atriskStudentsInfectedMEAN[statsweek] = ATRISKSTUDENTSINFECTED ;
    allStudentsInfectedMEAN[statsweek] = ALLSTUDENTSINFECTED ;
  } else {
    TOTALINFECTEDMEAN[statsweek] = round(((TOTALINFECTEDMEAN[statsweek] * (statsweek-1.0)) + TOTALINFECTED)
      / statsweek);
    int icm = (TOTALINFECTED-COMMUNITYINFECTED) ;
    infectedInClassMEAN[statsweek] = round(((infectedInClassMEAN[statsweek] * (statsweek-1.0)) + icm)
      / statsweek);
    atriskFacultyInfectedMEAN[statsweek] = round(((atriskFacultyInfectedMEAN[statsweek] * (statsweek-1.0)) 
      + ATRISKFACULTYINFECTED) / statsweek);
    allFacultyInfectedMEAN[statsweek] = round(((allFacultyInfectedMEAN[statsweek] * (statsweek-1.0)) 
      + ALLFACULTYINFECTED) / statsweek);
    atriskStudentsInfectedMEAN[statsweek] = round(((atriskStudentsInfectedMEAN[statsweek] * (statsweek-1.0)) 
      + ATRISKSTUDENTSINFECTED) / statsweek);
    allStudentsInfectedMEAN[statsweek] = round(((allStudentsInfectedMEAN[statsweek] * (statsweek-1.0)) 
      + ALLSTUDENTSINFECTED) / statsweek);
  }
  TOTALINFECTEDMAX[statsweek] = max(TOTALINFECTEDMAX[statsweek],TOTALINFECTED);
  infectedInClassMAX[statsweek] = max(infectedInClassMAX[statsweek], (TOTALINFECTED-COMMUNITYINFECTED));
  atriskFacultyInfectedMAX[statsweek] = max(atriskFacultyInfectedMAX[statsweek], ATRISKFACULTYINFECTED);
  atriskStudentsInfectedMAX[statsweek] = max(atriskStudentsInfectedMAX[statsweek], ATRISKSTUDENTSINFECTED);
  allFacultyInfectedMAX[statsweek] = max(allFacultyInfectedMAX[statsweek], ALLFACULTYINFECTED);
  allStudentsInfectedMAX[statsweek] = max(allStudentsInfectedMAX[statsweek], ALLSTUDENTSINFECTED);
  
}

void zeroWeeklyStats() {
  // Do this only on a change to config parameters at start of new semester.
  Arrays.fill(TOTALINFECTEDMEAN, 0);
  Arrays.fill(TOTALINFECTEDMAX, 0);
  Arrays.fill(infectedInClassMEAN, 0);
  Arrays.fill(infectedInClassMAX, 0);
  Arrays.fill(atriskFacultyInfectedMEAN, 0);
  Arrays.fill(atriskFacultyInfectedMAX, 0);
  Arrays.fill(atriskStudentsInfectedMEAN, 0);
  Arrays.fill(atriskStudentsInfectedMAX, 0);
  Arrays.fill(allFacultyInfectedMEAN, 0);
  Arrays.fill(allFacultyInfectedMAX, 0);
  Arrays.fill(allStudentsInfectedMEAN, 0);
  Arrays.fill(allStudentsInfectedMAX, 0);
  currentRunWithTheseConfigParameters = 0 ;
}

String cmdbuf = "";
boolean resetStats = false ; // set true on new R0, R0cheat or %cheat
void keyPressed() {
  if (key == 'R') {
    xeye=initxeye ; yeye=inityeye ; zeye=initzeye ;  // trial & error
    /*
    xeye = width / 2 ;
    yeye = height / 2 ;
    zeye = (width*2.7) ;
    */
    worldxrotate = worldyrotate = worldzrotate = 0 ;
    cmdbuf = "";
  } else if (key == 'q') {
    println("xeye=" + xeye + " yeye=" + yeye + " zeye=" + zeye);
    cmdbuf = "";
  } else if (key == 'Q') {
    initxeye = xeye ;
    inityeye = yeye ;
    initzeye = zeye ;
    cmdbuf = "";
  } else if (key == 'P') {
    pauseStates = ! pauseStates ;
    cmdbuf = "";
  } else if (key == 'H') {
    hideLines = ! hideLines ;
    cmdbuf = "";
  } else if (key == 'c') {
    CSVpending = true ;
    cmdbuf = "";
    println("CSV dump pending");
  } else if (key == 'F') {
    cmdbuf = "";
    println("frameRate: " + frameRate);
  } else if (key == 'M') {
    playMusic = ! playMusic ;
    if (! playMusic) {
      silenceMIDI();
      framesInaWeek = 15 ;
    } else {
      framesInaWeek = 60 ;
    }
    cmdbuf = "";
  } else if (key == 'h') {
    hideText = ! hideText ;
    cmdbuf = "";
  } else if(key == 'p') { // ALEXIS addition
    isCartesian = ! isCartesian ;
    cmdbuf = "";
    println("cartesian: " + isCartesian);
  } else if (key == 'A') {
    xbackwards = ! xbackwards ;
    cmdbuf = "";
  } else if (key == 'B') {
    ybackwards = ! ybackwards ;
    cmdbuf = "";
  } else if (key == 'C') {
    zbackwards = ! zbackwards ;
    cmdbuf = "";
  } else if (key == 'r' || key == '%') {
    cmdbuf = "" + key ;
  } else if (key != '\n' && cmdbuf.length() > 0) {
    cmdbuf += key ;
  } else if (key == '\n' && cmdbuf.length() > 0) {
    try {
      float value = 0.0 ;
      int eqix = cmdbuf.indexOf("=");
      if (eqix > 0) {
        value = max(Float.parseFloat(cmdbuf.substring(eqix+1)),0.0);
      }
      if (cmdbuf.startsWith("r0=")) {
        R0next = value ;
        resetStats = true ;
      } else if (cmdbuf.startsWith("r0c=")) {
        R0cheatersnext = value ;
        resetStats = true ;
      } else {
        println("UNKNOWN COMMAND: " + cmdbuf);
      }
    } finally {
      cmdbuf = "";
    }
  } else {
    cmdbuf = "";
  }
}
