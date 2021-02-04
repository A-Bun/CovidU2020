import javax.sound.midi.* ;  // Get everything in the Java MIDI (Musical Instrument Digital Interface) package.
// MIDI docs:
// http://midi.teragonaudio.com/tech/midispec.htm TYPES OF CONTROL_CHANGE (effects)
// http://midi.teragonaudio.com/tutr/gm.htm TYPES OF PROGRAM_CHANGE (INSTRUMENTS)
// https://docs.oracle.com/javase/8/docs/api/javax/sound/midi/ShortMessage.html
final int midiDeviceIndex = 0 ;  // setupMIDI() checks for number of devices. Use one for output.
// MIDI OUTPUT DEVICE SELECTION:
// NOTE: A final variable is in fact a constant that cannot be changed.
MidiDevice.Info[] midiDeviceInfo = null ;
// See javax.sound.midi.MidiSystem and javax.sound.midi.MidiDevice
MidiDevice device = null ;
// See javax.sound.midi.MidiSystem and javax.sound.midi.MidiDevice
Receiver receiver = null ;
// javax.sound.midi.Receiver receives your OUTPUT MIDI messages (counterintuitive?)
// SEE https://www.midi.org/specifications/item/gm-level-1-sound-set but start at 0, not 1

void setupMIDI() {
  // MIDI:
  println("DELAY MIDI 1");
  // 1. FIND OUT WHAT MIDI DEVICES ARE AVAILABLE FOR VARIABLE midiDeviceIndex.
  midiDeviceInfo = MidiSystem.getMidiDeviceInfo();
  for (int i = 0 ; i < midiDeviceInfo.length ; i++) {
    println("MIDI DEVICE NUMBER " + i + " Name: " + midiDeviceInfo[i].getName()
      + ", Vendor: " + midiDeviceInfo[i].getVendor()
      + ", Description: " + midiDeviceInfo[i].getDescription());
  }
  // 2. OPEN ONE OF THE MIDI DEVICES UP FOR OUTPUT.
  println("DELAY MIDI 2");
  try {
    device = MidiSystem.getMidiDevice(midiDeviceInfo[midiDeviceIndex]);
    device.open();  // Make sure to close it before this sketch terminates!!!
    // There should be a way to schedule a method when Processing closes this
    // sketch, so we can close the device there, but it is not documented for Processing 3.
    receiver = device.getReceiver();
    // NOTE: Either of the above method calls can throw MidiUnavailableException
    // if there is no available device or if it does not have a Receiver to
    // which we can send messages. The catch clause intercepts those error messages.
    // See https://www.midi.org/specifications/item/gm-level-1-sound-set, use programNumber variable
    /*
    for (int m = 0 ; m < musicians.length ; m++) {
      musicians[m] = new Musician(m * 4, 1, 127, m);
      ShortMessage noteMessage = new ShortMessage() ;
      noteMessage.setMessage(ShortMessage.PROGRAM_CHANGE, m, 73 , 0); // to channel m
      receiver.send(noteMessage, -1L);  // send it now
      println("DELAY MIDI 3");
    }
    */
    ShortMessage noteMessage = new ShortMessage() ;
    noteMessage.setMessage(ShortMessage.PROGRAM_CHANGE, 0, 89 , 0); // warm pad 89 channel 0
    receiver.send(noteMessage, -1L);  // send it now
    noteMessage = new ShortMessage() ;
    noteMessage.setMessage(ShortMessage.PROGRAM_CHANGE, 1, 91 , 0); // choir pad 91 channel 1
    receiver.send(noteMessage, -1L);  // send it now
    noteMessage = new ShortMessage() ;
    noteMessage.setMessage(ShortMessage.PROGRAM_CHANGE, 2, 56 , 0); // trumpet pad 56 channel 2
    receiver.send(noteMessage, -1L);  // send it now
    noteMessage = new ShortMessage() ;
    noteMessage.setMessage(ShortMessage.PROGRAM_CHANGE, 3, 121 , 0); // breath noise 121 channel 3
    receiver.send(noteMessage, -1L);  // send it now
      
    for (int c = 0 ; c < 4 ; c++) {
      noteMessage = new ShortMessage() ;
      noteMessage.setMessage(ShortMessage.CONTROL_CHANGE, c, 93 , 127); // chorus
      receiver.send(noteMessage, -1L);  // send it now
    }
    println("DELAY MIDI 4");
  } catch (MidiUnavailableException mx) {
    System.err.println("MIDI UNAVAILABLE"); // Error messages go here.
    device = null ;
    receiver = null ; // Do not try to use them.
    // exit();
  } catch (InvalidMidiDataException dx) {
    System.err.println("MIDI ERROR 3: " + dx.getMessage()); // Error messages go here.
  }
  println("DELAY MIDI 5, width = " + width + ", height = " + height); 
}

final int sweetPitch = 36 ;  //  C
final int sweetFifth = 55 ;  // F
final int minorThird = 63 ;  // D#
final int tritone = 78 ;     // F# 
final int [] pitch = { sweetPitch, sweetFifth, minorThird, tritone };
final int [] notes = new int [4]; // 0 and 2 for Class accord, discord
float numClasses = 0 ;              // 1 and 3 for person accord, discord
float numEdges = 0 ;

void clearNoteVariables() {
  Arrays.fill(notes, 0);
  numClasses = numEdges = 0 ;
}

void playMIDI() {
  try {
   final float bias = 3.0 ;
   for (int c = 0 ; c < notes.length ; c++) {
     ShortMessage newMessage = new ShortMessage() ;
     int velocity = 0 ;
     switch (c) {
       case 0:
         velocity = min(round(notes[c] / bias / numClasses),127);
         break ;
       case 2:
         velocity = min(round(notes[c] * bias / numClasses),127);
         break ;
       case 1:
         velocity = min(round(notes[c] / bias / numEdges),127);
         break ;
       case 3:
         velocity = min(round(notes[c] * bias / numEdges),127);
         break ;
     }
     newMessage.setMessage(ShortMessage.NOTE_ON, c, pitch[c],
         max(velocity-20,0));
     receiver.send(newMessage, -1L); 
   }
  } catch (InvalidMidiDataException dx) {
      System.err.println("MIDI ERROR 1: " + dx.getMessage()); // Error messages go here.
  }
  clearNoteVariables();
}

void silenceMIDI() {
  try {
    clearNoteVariables();
    for (int c = 0 ; c < notes.length ; c++) {
      ShortMessage newMessage = new ShortMessage() ;
      newMessage.setMessage(ShortMessage.NOTE_OFF, c, pitch[c], 0);
      receiver.send(newMessage, -1L);
    }
  } catch (InvalidMidiDataException dx) {
      System.err.println("MIDI ERROR 2: " + dx.getMessage()); // Error messages go here.
  } 
}
