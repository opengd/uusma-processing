import themidibus.*; //Import the library

MidiBus midiBus; // The MidiBus

ArrayList<Note> notes; // A bunch of notes
ArrayList<ControllerChange> controllerChanges; // A bunch of cc's

JSONObject mainJson, noteJson, ccJson;

int last, pieceLast, delta, pieceDelta, 
  genLoopDelay, configRefreshDelayTime, playPieceRefreshDelay, playCompositionRefreshDelay, mainJsonCheckDelay;
Integer currentMovmentDelay, compositionJmpCounter, compositionCurrentRow;
String currentMovmentName;
float compositionDelta, compositionLast;
Float currentCompositionDelay;

// Default Main config
String mainConfig = "{\"USE_CONFIG_REFRESH\": true," + 
    "\"CONFIG_REFRESH_DELAY\": 10000," +
    "\"MIDI_OUTPUT_DEVICE\": \"Microsoft GS Wavetable Synth\"," +
    "\"MAIN_LOOP_DELAY_MAX\": 2000," +
    "\"MAIN_LOOP_DELAY_MIN\": 100," +
    "\"USE_MAIN_LOOP_DELAY\": true," +
    "\"PLAY_PIECE\": true," +
    "\"PIECE_REFRESH_DELAY\": 1000," +
    "\"CURRENT_PIECE\": \"piece.json\"," +
    "\"PLAY_COMPOSITION\": true," +
    "\"COMPOSITION_REFRESH_DELAY\": 1000," +
    "\"CURRENT_COMPOSITION\": \"composition.md\"," +
    "\"USE_COMPOSITION_IN_MARKDOWN\": true" +
    "}";

// Default Note config
String noteConfig = "{\"CHANNEL_MAX\": 6," +
    "\"CHANNEL_MIN\": 0," + 
    "\"PITCH_MAX\": 82," +
    "\"PITCH_MIN\": 32," +
    "\"VELOCITY_MAX\": 127," +
    "\"VELOCITY_MIN\": 32," +
    "\"NOTE_TIME_MAX\": 10000," +
    "\"NOTE_TIME_MIN\": 2000," +
    "\"NOTE_DELAY_MAX\": 10000," +
    "\"NOTE_DELAY_MIN\": 2000," +
    "\"GEN_NOTE_DELAY_MAX\": 10000," +
    "\"GEN_NOTE_DELAY_MIN\": 0," +
    "\"GEN_NB_NOTES_MAX\": 20," +
    "\"GEN_NB_NOTES_MIN\": 0," +
    "\"USE_SAME_CHANNEL_FOR_CURRENT_LOOP\": true," +
    "\"USE_GEN_DELAY\": true" +
    "}";

// Default CC config
String ccConfig = "{\"USE_CC_GEN\": true," +
    "\"CC_GEN_NB_MAX\": 20," +
    "\"CC_GEN_NB_MIN\": 1," +
    "\"CC_GEN_CHANNEL_MAX\": 1," +
    "\"CC_GEN_CHANNEL_MIN\": 0," +
    "\"CC_GEN_NUMBER_MAX\": 48," +
    "\"CC_GEN_NUMBER_MIN\": 48," +
    "\"CC_GEN_VALUE_MAX\": 127," +
    "\"CC_GEN_VALUE_MIN\": 0," +
    "\"CC_GEN_DELAY_MAX\": 10000," +
    "\"CC_GEN_DELAY_MIN\": 0" +
    "}";

void setup() {
  size(400, 400);
  background(0);
    
  LoadConfig(true); // Load main, note and cc config file from json files or default string config 

  MidiBus.list(); // List all available Midi devices on STDOUT. This will show each device's index and name.

  midiBus = new MidiBus(this, -1, mainJson.getString("MIDI_OUTPUT_DEVICE")); // Create a new MidiBus
    
  notes = new ArrayList<Note>();
  controllerChanges = new ArrayList<ControllerChange>();
  
  last = millis();
  
  genLoopDelay = 0; //int(random(GEN_NOTE_DELAY_MIN, GEN_NOTE_DELAY_MAX));
  
  configRefreshDelayTime = mainJson.getInt("CONFIG_REFRESH_DELAY");
  playPieceRefreshDelay = mainJson.getInt("PIECE_REFRESH_DELAY");
  playCompositionRefreshDelay = mainJson.getInt("COMPOSITION_REFRESH_DELAY");
  
  mainJsonCheckDelay = 5000;
}

void draw() {
    
  // Calculate the delta time, the time since last loop
  int current = millis();
  delta = current - last;
  last = current;
  
  if(mainJson.getBoolean("USE_CONFIG_REFRESH")) {

    configRefreshDelayTime = configRefreshDelayTime - delta;
    
    if(configRefreshDelayTime <= 0) {
      LoadConfig(false);
      configRefreshDelayTime = mainJson.getInt("CONFIG_REFRESH_DELAY");
    }
  } else {
    mainJsonCheckDelay = mainJsonCheckDelay - delta;
    if(mainJsonCheckDelay <= 0) {
      CheckConfigRefreshSettings();
      mainJsonCheckDelay = 5000;
    }
  }
  
  if(mainJson.getBoolean("PLAY_PIECE")) {
    
    playPieceRefreshDelay = playPieceRefreshDelay - delta;
    
    if(playPieceRefreshDelay <= 0) {
      PlayPiece();
      playPieceRefreshDelay = mainJson.getInt("PIECE_REFRESH_DELAY");
    }  
  }
  
  if(mainJson.getBoolean("PLAY_COMPOSITION")) {
    
    playCompositionRefreshDelay = playCompositionRefreshDelay - delta;
    
    if(playCompositionRefreshDelay <= 0) {
      PlayComposition ();
      playCompositionRefreshDelay = mainJson.getInt("COMPOSITION_REFRESH_DELAY");
    }  
  }
  
  for(int i = 0; i < notes.size(); i++) { // Loop all notes and check time and delay values
    if(notes.get(i).IsPlaying()) { // If the note is playing
    
      // Sub time value with delta time
      notes.get(i).time = notes.get(i).time - delta;
      
      if(notes.get(i).time <= 0) { // Is time zero or below, then stop the note
        notes.get(i).Stop();
        notes.remove(i); // Remove note from ArrayList of notes
      }
    } else { // If the note is not playing
    
      // Sub delay value with delta time
      notes.get(i).delay = notes.get(i).delay - delta;
      
      if(notes.get(i).delay <= 0) { // If delay is zero or below, then play the note
        notes.get(i).Play();
      }
    }
  }
  
  // If using generate note delay, calculate new by sub delta time
  if(noteJson.getBoolean("USE_GEN_DELAY") && genLoopDelay > 0) {
    genLoopDelay = genLoopDelay - delta;
  }
  
  // If generate note delay is zero or below, or not using generate note delay
  // then generate some notes
  if(genLoopDelay <= 0 || !noteJson.getBoolean("USE_GEN_DELAY")) {  
  
    int channel = int(random(noteJson.getInt("CHANNEL_MIN"), noteJson.getInt("CHANNEL_MAX")));
    
    // How many new Notes should be generated on this loop
    int newNumberOfNotes = int(random(noteJson.getInt("GEN_NB_NOTES_MIN"), noteJson.getInt("GEN_NB_NOTES_MAX")));
    
    while(newNumberOfNotes > 0) {
      
      if(!noteJson.getBoolean("USE_SAME_CHANNEL_FOR_CURRENT_LOOP")) { // Change the channel for every new note
        channel = int(random(noteJson.getInt("CHANNEL_MIN"), noteJson.getInt("CHANNEL_MAX")));
      }
    
      int pitch = int(random(noteJson.getInt("PITCH_MIN"), noteJson.getInt("PITCH_MAX"))); // Generate a random pitch value for the new note
      int velocity = int(random(noteJson.getInt("VELOCITY_MIN"), noteJson.getInt("VELOCITY_MAX"))); // Generate a random velocity value for the new note
      
      // Create a new Note
      Note newNote = new Note(channel, 
        pitch, 
        velocity, 
        int(random(noteJson.getInt("NOTE_TIME_MIN"), noteJson.getInt("NOTE_TIME_MAX"))), 
        int(random(noteJson.getInt("NOTE_DELAY_MIN"), noteJson.getInt("NOTE_DELAY_MAX"))));
      notes.add(newNote);
      
      newNumberOfNotes--;
    }
    
    if(noteJson.getBoolean("USE_GEN_DELAY")) // If using generate note delay, get a new delay value
      genLoopDelay = int(random(noteJson.getInt("GEN_NOTE_DELAY_MIN"), noteJson.getInt("GEN_NOTE_DELAY_MAX")));
  
  }

  for(int i = 0; i < controllerChanges.size(); i++) {
    controllerChanges.get(i).delay = controllerChanges.get(i).delay - delta;
    
    if(controllerChanges.get(i).delay <= 0) {
      controllerChanges.get(i).Change();
      controllerChanges.remove(i);
    }
  }
  
  if(ccJson.getBoolean("USE_CC_GEN")) {
        
    // How many new CC should be generated on this loop
    int newNumberOfCC = int(random(ccJson.getInt("CC_GEN_NB_MIN"), ccJson.getInt("CC_GEN_NB_MAX")));
    
    while(newNumberOfCC > 0) {
      
      int channel = int(random(ccJson.getInt("CC_GEN_CHANNEL_MIN"), ccJson.getInt("CC_GEN_CHANNEL_MAX")));
      int number = int(random(ccJson.getInt("CC_GEN_NUMBER_MIN"), ccJson.getInt("CC_GEN_NUMBER_MAX")));
      int value = int(random(ccJson.getInt("CC_GEN_VALUE_MIN"), ccJson.getInt("CC_GEN_VALUE_MAX")));
      
      ControllerChange cc = new ControllerChange(channel, number, value, int(random(ccJson.getInt("CC_GEN_DELAY_MIN"), ccJson.getInt("CC_GEN_DELAY_MAX"))));
      controllerChanges.add(cc);
      
      newNumberOfCC--;
    }
  }
  
  if(mainJson.getBoolean("USE_MAIN_LOOP_DELAY"))
    delay(int(random(mainJson.getInt("MAIN_LOOP_DELAY_MIN"), mainJson.getInt("MAIN_LOOP_DELAY_MAX")))); //Main loop delay
}

void delay(int time) {
  int current = millis();
  while (millis () < current+time) Thread.yield();
}

void CheckConfigRefreshSettings(){
    try {
    JSONObject json = loadJSONObject("main.json");
    
    if(json.get("USE_CONFIG_REFRESH") != null && json.getBoolean("USE_CONFIG_REFRESH") != mainJson.getBoolean("USE_CONFIG_REFRESH")) {
      println("USE_CONFIG_REFRESH:change:from:" + mainJson.getBoolean("USE_CONFIG_REFRESH") + ":to:" + json.getBoolean("USE_CONFIG_REFRESH"));
      mainJson.setBoolean("USE_CONFIG_REFRESH", json.getBoolean("USE_CONFIG_REFRESH"));
    }
    
    if(json.get("PLAY_PIECE") != null && json.getBoolean("PLAY_PIECE") != mainJson.getBoolean("PLAY_PIECE")) {
      println("PLAY_PIECE:change:from:" + mainJson.getBoolean("PLAY_PIECE") + ":to:" + json.getBoolean("PLAY_PIECE"));
      mainJson.setBoolean("PLAY_PIECE", json.getBoolean("PLAY_PIECE"));
    }
    
    if(json.get("PLAY_COMPOSITION") != null && json.getBoolean("PLAY_COMPOSITION") != mainJson.getBoolean("PLAY_COMPOSITION")) {
      println("PLAY_COMPOSITION:change:from:" + mainJson.getBoolean("PLAY_COMPOSITION") + ":to:" + json.getBoolean("PLAY_COMPOSITION"));
      mainJson.setBoolean("PLAY_COMPOSITION", json.getBoolean("PLAY_COMPOSITION"));
    } 
  } catch(Exception e) {
  }
}

void PlayComposition() {
  try {
    String[] composition = loadStrings(mainJson.getString("CURRENT_COMPOSITION"));
    if(composition.length > 0)
      ParseComposition(composition);
  } catch(Exception e) {
    println(e);
  }
}

void PlayPiece() {
  try {
    JSONObject json = loadJSONObject(mainJson.getString("CURRENT_PIECE"));
    ParseJsonPiece(json);
  } catch(Exception e) {
  }
}

void LoadConfig(boolean init) {
  
  JSONObject json;
  
  if(init) {
      mainJson = parseJSONObject(mainConfig);
      noteJson = parseJSONObject(noteConfig);     
      ccJson = parseJSONObject(ccConfig);
  }
  
  try {
    json = loadJSONObject("main.json");
    ParseJsonConfig(json, mainJson);
  } catch(Exception e) {
    if(init) {
      saveJSONObject(mainJson, "data/main.json");
    }
  }
  
  try {
    json = loadJSONObject("note.json");
    ParseJsonConfig(json, noteJson);
  } catch(Exception e) {
    if(init) {
      saveJSONObject(noteJson, "data/note.json");
    }
  }
  
  try {
    json = loadJSONObject("cc.json");
    ParseJsonConfig(json, ccJson);
  } catch(Exception e) {
    if(init) {
      saveJSONObject(ccJson, "data/cc.json");
    }
  }
}

void ParseComposition(String[] composition) {
  
  String currentMacro = null;
  
  Boolean insideComposition = false;
  
  Boolean useCompositionInMarkdown = mainJson.getBoolean("USE_COMPOSITION_IN_MARKDOWN");
  
  for(int rowIndex = 0; rowIndex < composition.length; rowIndex++) {
    //println(rowIndex + " : " + composition[rowIndex]);
    String[] unclean = split(composition[rowIndex], ' ');
    
    StringList clean = new StringList();
    
    for(String s: unclean)
      if(s.length() > 0) 
        clean.append(s);
    
    String[] list = clean.array();    
    
    if(useCompositionInMarkdown && list.length > 1 && list[0].equals("```") && list[1].toLowerCase().equals("composition") && !insideComposition) {
      insideComposition = true;
      //println("insideComposition: " + insideComposition);
    } else if (useCompositionInMarkdown && list.length > 0 && list[0].equals("```") && insideComposition) {
      insideComposition = false;
      //println("insideComposition: " + insideComposition);
    } else if((insideComposition || !useCompositionInMarkdown) && list.length > 0 && list[0].equals("macro")) {
      currentMacro = list[1];
    } else if (list.length > 0 && (insideComposition || !useCompositionInMarkdown)){
            
      int time;
      
      try {
        time = Integer.parseInt(list[0]);
      } catch (NumberFormatException ex) {
        time = -1;
      }
      
      if(currentCompositionDelay == null && time >= 0) {
        compositionDelta = 0;
        compositionLast = millis() * 0.001;
        
        if(compositionCurrentRow != null) {
          currentCompositionDelay = (float)abs(time - compositionCurrentRow);
        } else {
          currentCompositionDelay = (float)time;
        }
        
        compositionCurrentRow = time;
        println("currentCompositionDelay: " + currentCompositionDelay);
        println("compositionCurrentRow: " + compositionCurrentRow);
      }
      
      if(currentCompositionDelay != null) {
        float m = millis() * 0.001;
        compositionDelta = m - compositionLast;
        compositionLast = m;
        
        currentCompositionDelay = currentCompositionDelay - compositionDelta;
        //println("currentCompositionDelay: " + currentCompositionDelay);
      }
      
      if(time >= 0 && currentCompositionDelay <= 0 && time == compositionCurrentRow && list.length > 1) {
        try {
          JSONObject json = loadJSONObject(currentMacro);
          
          for(int i = 1; i < list.length; i++) {
            
            // Check for comments
            String comCheck = list[i].substring(0, 1);
            if(comCheck.equals("#")) 
              break;
           
            ParseMovment(json, list[i]);
          }              
        } catch(Exception e) {}
        
        currentCompositionDelay = null;
      } else if (time == -1 && currentCompositionDelay == null && list.length > 1 && list[0].equals("jmp")) {          
        if(compositionJmpCounter != null)
          compositionJmpCounter--;
        
        if(compositionJmpCounter == null || compositionJmpCounter > 0) {
          int jmpTo = 0;
          try {
            jmpTo = Integer.parseInt(list[1]);
          } catch(NumberFormatException ex) {
            println("Could not parse jump time value: " + list[1]);
            continue;
          }
                              
          currentCompositionDelay = (float)jmpTo;
          compositionCurrentRow = jmpTo;
                    
          if(compositionJmpCounter == null) {       
            if(list.length > 2)
              try {
                compositionJmpCounter = Integer.parseInt(list[2]);
              } catch(NumberFormatException ex) {
                compositionJmpCounter = 1;
              }
              
            else
              compositionJmpCounter = 1;
          }
          println("jmpTo:" + jmpTo + ":compositionJmpCounter:" + compositionJmpCounter);
        } else if (compositionJmpCounter != null && compositionJmpCounter <= 0) {
          compositionJmpCounter = null;
        }
      }
    }
      //println("(rowIndex+1): " + (rowIndex+2) + ":composition.length:" + composition.length);
      if(currentCompositionDelay == null && (rowIndex+1) == composition.length) {
        compositionCurrentRow = null;
        println("EOF");
      }
  }
}

void ParseJsonPiece(JSONObject piece) {
  java.util.Set pieceKeys = piece.keys();
  
  if(pieceKeys.size() > 0 && currentMovmentDelay == null) {
    currentMovmentDelay = GetNextMovmentDelay(pieceKeys, currentMovmentDelay);
    currentMovmentName = "" + currentMovmentDelay;
    
    println("currentMovmentName: " + currentMovmentName);
    
    pieceDelta = 0;
    pieceLast = millis();
  }
  
  int m = millis();
  pieceDelta = m - pieceLast;
  pieceLast = m;
  
  if(pieceKeys.size() > 0) {
    
    currentMovmentDelay = currentMovmentDelay - pieceDelta;
    //println("currentMovmentDelay: " + currentMovmentDelay);
    
    if(currentMovmentDelay <= 0) {
      
      ParseMovment(piece, currentMovmentName);
      
      int currentDelay = Integer.parseInt(currentMovmentName);
      int next = GetNextMovmentDelay(pieceKeys, currentDelay);
       
      currentMovmentDelay = (next < currentDelay) ? next : abs(next - currentDelay);
      
      currentMovmentName = "" + next;
      
      println("new:movment:name:" + currentMovmentName + ":delay:" + currentMovmentDelay);
    }
  } 
}

void ParseMovment(JSONObject piece, String movmentName) {
  JSONObject movement = (JSONObject)piece.get(movmentName);
  
  println("parse:movment:" + movmentName);
  
  JSONObject json = movement.getJSONObject("main");
  if(json != null)
    ParseJsonConfig(json, mainJson);
  json = movement.getJSONObject("note");
  if(json != null)
    ParseJsonConfig(json, noteJson);
  json = movement.getJSONObject("cc");
  if(json != null)
    ParseJsonConfig(json, ccJson);
  
  JSONArray ja = movement.getJSONArray("macro");
  if(ja != null && ja.size() > 0) {
    
    for(int i = 0; i < ja.size(); i++) {
      JSONObject macro = ja.getJSONObject(i);
      
      if(macro.getString("source") != null) {
        try {
          JSONObject mo = loadJSONObject(macro.getString("source"));
          JSONArray doMacros = macro.getJSONArray("do");
          for(int m = 0; m < doMacros.size(); m++) {
            ParseMovment(mo, doMacros.getString(m));
          }
        } catch(Exception e) {
        }
      }
    }    
  }
}

int GetNextMovmentDelay(java.util.Set movments, Integer current) {
  
  Integer next = null;
  
  if(current != null)
    next = current;
  
  for(Object j: movments) {
    int n = Integer.parseInt((String)j);
    if(movments.size() == 1) {
      return n;
    } else if(current == null && next == null) {
      next = n;
    } else if(current == null && n < next) {
      next = n;
    } else if (current != null && n > current && n < next) {
      next = n;
    } else if (current != null && n > current) {
      next = n;
    }
  }
  
  if(next == null || next == current)
    next = GetNextMovmentDelay(movments, null);
  
  return next;
}

void ParseJsonConfig(JSONObject json, JSONObject config) {
  java.util.Set theKeys = json.keys();
  
  for(Object j: theKeys) {      
    String name = (String)j;
    
    //println(name);
    
    Object jv = json.get(name);      
    Object cv = config.get(name);
    
    if(cv instanceof Integer && jv instanceof Integer && (int)cv != (int)jv) {
      config.setInt(name, (int)jv);
      println(name + ":change:from:" + (int)cv + ":to:" + (int)jv);
    } else if(cv instanceof Boolean && jv instanceof Boolean && (boolean)cv != (boolean)jv) {
      config.setBoolean(name, (boolean)jv);
      println(name + ":change:from:" + (boolean)cv + ":to:" + (boolean)jv);
    } else if(cv instanceof Float && jv instanceof Float && (float)cv != (float)jv) {
      config.setFloat(name, (float)jv);
      println(name + ":change:from:" + (float)cv + ":to:" + (float)jv);
    } else if (cv instanceof String && jv instanceof String && !((String)cv).equals((String)jv)) {
      config.setString(name, (String)jv);
      println(name + ":change:from:" + (String)cv + ":to:" + (String)jv);
    }           
  }
}

class Note {
  
  int channel, pitch, velocity, time, delay;
  boolean playing = false;
  
  Note(int channel, int pitch, int velocity, int time, int delay) {
    this.channel = channel;
    this.pitch = pitch;
    this.velocity = velocity;
    this.time = time;
    this.delay = delay;
  }
  
  void Play() {
    if(!playing) {
      midiBus.sendNoteOn(channel, pitch, velocity); // Send a Midi noteOn
    }
    
    playing = true;
  }
  
  void Stop() {
    if(playing) {
      midiBus.sendNoteOff(channel, pitch, velocity); // Send a Midi nodeOff
    }
    
    playing = false;
  }
  
  boolean IsPlaying() {
    return playing;
  }
}

class ControllerChange {
  int channel, number, value, delay;
  boolean changed = false;
  
  ControllerChange(int channel, int number, int value, int delay) {
    this.channel = channel;
    this.number = number;
    this.value = value;
    this.delay = delay;
  }
  
  void Change() {
    midiBus.sendControllerChange(channel, number, value);
    changed = true;
  }
  
  boolean IsChanged() {
    return changed;
  }
  
  void SetChanged(boolean changed) {
    this.changed = changed;
  }
  
}
