class Edge {
  // Used to track how many students & infected student cross and edge.
  Class vertex1, vertex2 ;
  Edge(Class class1, Class class2) {
    if (class1.compareTo(class2) <= 0) {
      vertex1 = class1 ;  // Use a canonical order.
      vertex2 = class2 ;
    } else {
      vertex1 = class2 ;
      vertex2 = class1 ;
    }
  }
  public boolean equals(Object obj) {
    if (obj instanceof Edge) {
      Edge eobj = (Edge) obj ;
      return (this.vertex1.equals(eobj.vertex1) && this.vertex2.equals(vertex2));
    }
    return false ;
  }
  public int hashCode() {
    return vertex1.hashCode() ^ vertex2.hashCode();
  }
};
class EdgeStudents {
  // Used to track how many students & infected student cross an edge.
  public int students = 0 ;
  public int infectedStudents = 0 ;
  public int strokeWeight = 1 ;
  EdgeStudents(int students, int infectedStudents) {
    this.students = students ;
    this.infectedStudents = infectedStudents ;
  }
  void addStudents(int delta) {
    if (delta < 0) {
      students = infectedStudents = 0 ;
      strokeWeight = 1 ;
    } else {
      students += delta ;
      // avoid the 0 at log(1), use log-base 2 for information-bits scaling
      strokeWeight = (int) max((float)(Math.ceil(Math.log(students+1) / Math.log(2.0))), 1.0);
    }
  }
};
