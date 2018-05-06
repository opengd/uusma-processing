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
IntDict jmpStack;

// Default Main config
String mainConfig = "{\"USE_CONFIG_REFRESH\": true," + 
    "\"CONFIG_REFRESH_DELAY\": 10000," +
    "\"MIDI_OUTPUT_DEVICE\": \"Microsoft GS Wavetable Synth\"," +
    "\"MAIN_LOOP_DELAY_MAX\": 2000," +
    "\"MAIN_LOOP_DELAY_MIN\": 100," +
    "\"USE_MAIN_LOOP_DELAY\": true," +
    "\"PLAY_PIECE\": false," +
    "\"PIECE_REFRESH_DELAY\": 1000," +
    "\"CURRENT_PIECE\": \"piece.json\"," +
    "\"PLAY_COMPOSITION\": false," +
    "\"COMPOSITION_REFRESH_DELAY\": 1000," +
    "\"CURRENT_COMPOSITION\": \"composition.md\"," +
    "\"USE_COMPOSITION_IN_MARKDOWN\": true," +
    "\"ON_FALSE_CONFIG_REFRESH_DELAY\": 10000," +
    "\"MAIN_CONFIG\": \"main.json\"," +
    "\"NOTE_CONFIG\": \"note.json\"," +
    "\"CC_CONFIG\": \"cc.json\"," +
    "\"COMPOSITION_CLEAR_JMP_STACK_ON_EOF\": false" +
    "}";

// Default Note config
String noteConfig = "{\"CHANNEL_MAX\": 16," +
    "\"CHANNEL_MIN\": 0," + 
    "\"PITCH_MAX\": 128," +
    "\"PITCH_MIN\": 0," +
    "\"VELOCITY_MAX\": 128," +
    "\"VELOCITY_MIN\": 0," +
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
    "\"CC_GEN_NB_MAX\": 3," +
    "\"CC_GEN_NB_MIN\": 1," +
    "\"CC_GEN_CHANNEL_MAX\": 16," +
    "\"CC_GEN_CHANNEL_MIN\": 0," +
    "\"CC_GEN_NUMBER_MAX\": 120," +
    "\"CC_GEN_NUMBER_MIN\": 0," +
    "\"CC_GEN_VALUE_MAX\": 128," +
    "\"CC_GEN_VALUE_MIN\": 0," +
    "\"CC_GEN_DELAY_MAX\": 10000," +
    "\"CC_GEN_DELAY_MIN\": 0," +
    "\"CC_SET_LIST\": []" +
    "}";

void setup() {
  size(400, 400);
  background(0);
    
  LoadConfig(true); // Load main, note and cc config file from json files or default string config 

  MidiBus.list(); // List all available Midi devices on STDOUT. This will show each device's index and name.

  midiBus = new MidiBus(this, -1, mainJson.getString("MIDI_OUTPUT_DEVICE")); // Create a new MidiBus
  
  jmpStack = new IntDict();
  
  notes = new ArrayList<Note>();
  controllerChanges = new ArrayList<ControllerChange>();
  
  last = millis();
  
  genLoopDelay = 0; //int(random(GEN_NOTE_DELAY_MIN, GEN_NOTE_DELAY_MAX));
  
  configRefreshDelayTime = mainJson.getInt("CONFIG_REFRESH_DELAY");
  playPieceRefreshDelay = mainJson.getInt("PIECE_REFRESH_DELAY");
  playCompositionRefreshDelay = mainJson.getInt("COMPOSITION_REFRESH_DELAY");
  
  mainJsonCheckDelay = mainJson.getInt("ON_FALSE_CONFIG_REFRESH_DELAY");
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
      mainJsonCheckDelay = mainJson.getInt("ON_FALSE_CONFIG_REFRESH_DELAY");
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
      
      int channel = 0;
      int number = 0;
      int value = 0;
      
      JSONArray ccsl = ccJson.getJSONArray("CC_SET_LIST");
      
      Boolean couldNotGetValuesFromCCSetList = false;
           
      if(ccsl != null && ccsl.size() > 0) {
        
        int ccsli = int(random(ccsl.size()));
        
        Object ccslv = ccsl.get(ccsli);
        
        if(ccslv instanceof JSONArray) {
          channel = ((JSONArray)ccslv).getInt(0);
          number = ((JSONArray)ccslv).getInt(1);
          
          if(((JSONArray)ccslv).size() > 2) {
            value = int(random(((JSONArray)ccslv).getInt(2), ((JSONArray)ccslv).getInt(3)));
          } else {
            value = int(random(ccJson.getInt("CC_GEN_VALUE_MIN"), ccJson.getInt("CC_GEN_VALUE_MAX")));
          }
        } else if (ccslv instanceof JSONObject) { 
          channel = ((JSONObject)ccslv).getInt("channel");
          number = ((JSONObject)ccslv).getInt("number");
                    
          if(((JSONObject)ccslv).size() > 2) {
            int v_min = ((JSONObject)ccslv).getInt("value_min");
            int v_max = ((JSONObject)ccslv).getInt("value_max");
            value = int(random(v_min, v_max));
          } else {
            value = int(random(ccJson.getInt("CC_GEN_VALUE_MIN"), ccJson.getInt("CC_GEN_VALUE_MAX")));
          }
        }
        println("Using cc set list: channel:" + channel + ":number:" + number + ":value:" + value);        
        
      } else {      
        channel = int(random(ccJson.getInt("CC_GEN_CHANNEL_MIN"), ccJson.getInt("CC_GEN_CHANNEL_MAX")));
        number = int(random(ccJson.getInt("CC_GEN_NUMBER_MIN"), ccJson.getInt("CC_GEN_NUMBER_MAX")));
        value = int(random(ccJson.getInt("CC_GEN_VALUE_MIN"), ccJson.getInt("CC_GEN_VALUE_MAX")));
      }
      
      if(!couldNotGetValuesFromCCSetList) {
        ControllerChange cc = new ControllerChange(channel, number, value, int(random(ccJson.getInt("CC_GEN_DELAY_MIN"), ccJson.getInt("CC_GEN_DELAY_MAX"))));
        controllerChanges.add(cc);
      } else {
        println("Could not get values from cc set list");
      }
      
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
    
    if(!mainJson.getBoolean("PLAY_PIECE") && !mainJson.getBoolean("PLAY_COMPOSITION")) {
      if(json.get("USE_CONFIG_REFRESH") != null && json.getBoolean("USE_CONFIG_REFRESH") != mainJson.getBoolean("USE_CONFIG_REFRESH")) {
        println("USE_CONFIG_REFRESH:change:from:" + mainJson.getBoolean("USE_CONFIG_REFRESH") + ":to:" + json.getBoolean("USE_CONFIG_REFRESH"));
        mainJson.setBoolean("USE_CONFIG_REFRESH", json.getBoolean("USE_CONFIG_REFRESH"));
      }
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
  if(init) {
    mainJson = parseJSONObject(mainConfig);
    noteJson = parseJSONObject(noteConfig);     
    ccJson = parseJSONObject(ccConfig);
  }
  
  LoadConfigJson(mainJson, mainJson.getString("MAIN_CONFIG") , init, "data/main.json");
  if(init) // Do it twice if init to get changes to MAIN_CONFIG, NOTE_CONFIG, and CC_CONFIG
    LoadConfigJson(mainJson, mainJson.getString("MAIN_CONFIG") , false, "data/main.json");
    
  LoadConfigJson(noteJson, mainJson.getString("NOTE_CONFIG") , init, "data/note.json");
  LoadConfigJson(ccJson, mainJson.getString("CC_CONFIG") , init, "data/cc.json");
}

void LoadConfigJson(JSONObject jsonConfig, String configFilename, boolean init, String saveAs) {
  try {
    JSONObject json = loadJSONObject(configFilename);
    ParseJsonConfig(json, jsonConfig);
  } catch(Exception e) {
    if(init) {
      saveJSONObject(jsonConfig, saveAs);
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
      } else if (time == -1 && currentCompositionDelay == null && list.length > 1 && list[0].toLowerCase().equals("jmp")) {          
        
        int jmpTo = 0;
        try {
          jmpTo = Integer.parseInt(list[1]);
        } catch(NumberFormatException ex) {
          println("Could not parse jump time value: " + list[1]);
          continue;
        }
                
        if(jmpStack.hasKey("" + jmpTo)) { 
          jmpStack.set("" + jmpTo, jmpStack.get("" + jmpTo)-1);
        } else {
          int jmpValue = 1;
          
          if(list.length > 2) {
            try {
              jmpValue = Integer.parseInt(list[2]);
            } catch(NumberFormatException ex) {
              jmpValue = 1;
            }
          }
          
          jmpStack.set("" + jmpTo, jmpValue);
        }
        
        if(jmpStack.get("" + jmpTo) == 0) {
          jmpStack.remove("" + jmpTo);
        } else {
          currentCompositionDelay = (float)jmpTo;
          compositionCurrentRow = jmpTo;
          println("jmpTo:" + jmpTo + ":currentJmpStackCounter:" + jmpStack.get("" + jmpTo));
        }             
      }
    }
    //println("(rowIndex+1): " + (rowIndex+2) + ":composition.length:" + composition.length);
    if((currentCompositionDelay == null || currentCompositionDelay <= 0) && (rowIndex+1) == composition.length) {
      compositionCurrentRow = null;
      currentCompositionDelay = null;
      println("EOF");
      
      if(mainJson.getBoolean("COMPOSITION_CLEAR_JMP_STACK_ON_EOF")) {
        jmpStack.clear();
        println("JMP Stack cleared");
      }
      
    } else if(currentCompositionDelay != null && currentCompositionDelay <= 0) {
      compositionCurrentRow = null;
      currentCompositionDelay = null;
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
    } else if(current == null && next != null && n < next) {
      next = n;
    } else if (current != null && n > current && next != null && n < next) {
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
    } else if(cv instanceof JSONArray && jv instanceof JSONArray && !(""+(JSONArray)cv).equals(""+(JSONArray)jv)) {
      config.setJSONArray(name, (JSONArray)jv);
      println(name + ":change:from:" + (JSONArray)cv + ":to:" + (JSONArray)jv);
    } else if (cv instanceof String && jv instanceof String && !((String)cv).equals((String)jv)) {
      config.setString(name, (String)jv);
      println(name + ":change:from:" + (String)cv + ":to:" + (String)jv);
    } else if (cv instanceof Integer && jv instanceof String && ((String)jv).length() > 0) {
      
      StringList sl = new StringList();
      
      String s = "";
      for(int i = 0; i < ((String)jv).length(); i++) {
        char c = ((String)jv).charAt(i);
        if(c == '+' || c == '-') {
          if(s.length() > 0)
            sl.append(trim(s));
          sl.append(str(c));
          s = "";
        } else {
          s = s + c;
        }
      }
      if(s.length() > 0)
        sl.append(trim(s));
      
      char sign = 0;      
      Integer mem = null;
      
      println(sl);
      
      for(int i = 0; i < sl.size(); i++) {
        String ns = sl.get(i);
        
        if(i > 0 && (ns.equals("+") || ns.equals("-"))) {
          sign = ns.charAt(0);
        } else if (!ns.equals("+") && !ns.equals("-")) {
          
          Integer v = null;
          
          if(!mainJson.isNull(ns)) 
            v = mainJson.getInt(ns);
          else if(!noteJson.isNull(ns)) 
            v = noteJson.getInt(ns);
          else if(!ccJson.isNull(ns)) 
            v = ccJson.getInt(ns);
            
          if(v == null) {
            try {
              v = Integer.parseInt(ns);
            } catch(Exception ex) {
              v = null;
              println(ex);
            }
          }
          
          if(v != null && sign == '+' && mem != null) {
            mem = mem + v;
          } else if (v != null && sign == '-' && mem != null) {
            mem = mem - v;
          } else if (v != null){
            mem = v;
          }
        }
      }
      
      println(mem);
      
      if(mem != null && sl.get(0).equals("+")) {
        mem = (int)cv + mem;
      } else if(mem != null && sl.get(0).equals("-")) {
        mem = (int)cv - mem;
      }  

      if (mem != null) {
        config.setInt(name, mem);
        println(name + ":change:from:" + (int)cv + ":to:" + mem);
      }
    }          
  }
}

class Note {
  
  int channel, pitch, velocity, time, delay, init_delay, init_time;
  boolean playing = false;
  
  Note(int channel, int pitch, int velocity, int time, int delay) {
    this.channel = channel;
    this.pitch = pitch;
    this.velocity = velocity;
    this.time = time;
    this.init_time = time;
    this.delay = delay;
    this.init_delay = delay;
    
    println("NEW:NOTE:channel:" + this.channel + ":pitch:" + this.pitch + ":velocity:" + this.velocity + ":time:" + this.time + ":delay:" + this.delay);
  }
  
  void Play() {
    if(!playing) {
      midiBus.sendNoteOn(channel, pitch, velocity); // Send a Midi noteOn
      println("PLAY:NOTE:channel:" + this.channel + ":pitch:" + this.pitch + ":velocity:" + this.velocity + ":time:" + this.time + ":init_time:" + this.init_time + ":delay:" + this.delay + ":init_delay:" + this.init_delay);
    }
    
    playing = true;
  }
  
  void Stop() {
    if(playing) {
      midiBus.sendNoteOff(channel, pitch, velocity); // Send a Midi nodeOff
      println("STOP:NOTE:channel:" + this.channel + ":pitch:" + this.pitch + ":velocity:" + this.velocity + ":time:" + this.time + ":init_time:" + this.init_time + ":delay:" + this.delay + ":init_delay:" + this.init_delay);
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
