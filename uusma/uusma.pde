import themidibus.*; //Import the library

MidiBus midiBus; // The MidiBus

ArrayList<Note> notes; // A bunch of notes
ArrayList<ControllerChange> controllerChanges; // A bunch of cc's

//JSONObject mainJson, noteJson, ccJson;

ArrayList<Config> configs;

int last, pieceLast, delta, pieceDelta, 
  configRefreshDelayTime, playPieceRefreshDelay, playCompositionRefreshDelay, mainJsonCheckDelay;
Integer currentMovmentDelay, compositionJmpCounter, compositionCurrentRow;
String currentMovmentName;
float compositionDelta, compositionLast;
Float currentCompositionDelay;
IntDict jmpStack;

// Default Main config
String mainConfig = 
  "\"USE_CONFIG_REFRESH\": true," + 
  "\"CONFIG_REFRESH_DELAY\": 10000," +
  "\"MIDI_OUTPUT_DEVICE\": [\"Microsoft GS Wavetable Synth\"]," +
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
  "\"COMPOSITION_CLEAR_JMP_STACK_ON_EOF\": false," + 
  "\"CONFIG\": [\"main.json\", \"note.json\", \"cc.json\"]," + 
  "\"NAME\": \"\"," + 
  "\"PARENT\": \"\"";

// Default Note config
String noteConfig = 
  "\"CHANNEL_MAX\": 16," +
  "\"CHANNEL_MIN\": 1," + 
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
  "\"GEN_NB_NOTES_MAX\": 5," +
  "\"GEN_NB_NOTES_MIN\": 0," +
  "\"USE_SAME_CHANNEL_FOR_CURRENT_LOOP\": true," +
  "\"USE_GEN_DELAY\": true," +
  "\"CHANNEL\": 0," + 
  "\"NOTE\": true";

// Default CC config
String ccConfig = 
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
  "\"CC_SET_LIST\": []," +
  "\"CC_CHANNELS_BANKS\": []," + 
  "\"CC\": false";

void setup() {
  size(400, 400);
  background(0);
  
  configs = new ArrayList<Config>();
    
  LoadConfig(true); // Load main, note and cc config file from json files or default string config 

  MidiBus.list(); // List all available Midi devices on STDOUT. This will show each device's index and name.

  midiBus = new MidiBus(this); // Create a new MidiBus
  
  // Add output devices to midiBus
  for(int i = 0; i < configs.get(0).getConfig().getJSONArray("MIDI_OUTPUT_DEVICE").size(); i++) {
    
    Object output = configs.get(0).getConfig().getJSONArray("MIDI_OUTPUT_DEVICE").get(i);
    
    if(output instanceof Integer)
      midiBus.addOutput((int)output);
    else if (output instanceof String) 
      midiBus.addOutput((String)output);
  }
  
  jmpStack = new IntDict();
  
  notes = new ArrayList<Note>();
  controllerChanges = new ArrayList<ControllerChange>();
  
  last = millis();
  
  configRefreshDelayTime = configs.get(0).getConfig().getInt("CONFIG_REFRESH_DELAY");
  playPieceRefreshDelay = configs.get(0).getConfig().getInt("PIECE_REFRESH_DELAY");
  playCompositionRefreshDelay = configs.get(0).getConfig().getInt("COMPOSITION_REFRESH_DELAY");
  
  mainJsonCheckDelay = configs.get(0).getConfig().getInt("ON_FALSE_CONFIG_REFRESH_DELAY");
}

void draw() {
    
  // Calculate the delta time, the time since last loop
  int current = millis();
  delta = current - last;
  last = current;
  
  JSONObject defaultConf = configs.get(0).getConfig();
  
  if(defaultConf.getBoolean("USE_CONFIG_REFRESH")) {

    configRefreshDelayTime = configRefreshDelayTime - delta;
    
    if(configRefreshDelayTime <= 0) {
      LoadConfig(false);
      configRefreshDelayTime = defaultConf.getInt("CONFIG_REFRESH_DELAY");
    }
  } else {
    mainJsonCheckDelay = mainJsonCheckDelay - delta;
    if(mainJsonCheckDelay <= 0) {
      //CheckConfigRefreshSettings();
      mainJsonCheckDelay = defaultConf.getInt("ON_FALSE_CONFIG_REFRESH_DELAY");
    }
  }
  
  if(defaultConf.getBoolean("PLAY_PIECE")) {
    
    playPieceRefreshDelay = playPieceRefreshDelay - delta;
    
    if(playPieceRefreshDelay <= 0) {
      PlayPiece();
      playPieceRefreshDelay = defaultConf.getInt("PIECE_REFRESH_DELAY");
    }  
  }
  
  if(defaultConf.getBoolean("PLAY_COMPOSITION")) {
    
    playCompositionRefreshDelay = playCompositionRefreshDelay - delta;
    
    if(playCompositionRefreshDelay <= 0) {
      PlayComposition ();
      playCompositionRefreshDelay = defaultConf.getInt("COMPOSITION_REFRESH_DELAY");
    }  
  }
  
  for(int i = 0; i < notes.size(); i++) { // Loop all notes and check time and delay values

    if(notes.get(i).IsPlaying()) { // If the note is playing
    
      // Sub time value with delta time
      notes.get(i).time = notes.get(i).time - delta;
      
      if(notes.get(i).time <= 0) { // Is time zero or below, then stop the note
        notes.get(i).Stop();
        notes.remove(i); // Remove note from ArrayList of notes
        i--;
      }
    } else { // If the note is not playing
    
      // Sub delay value with delta time
      notes.get(i).delay = notes.get(i).delay - delta;
      
      if(notes.get(i).delay <= 0) { // If delay is zero or below, then play the note
        notes.get(i).Play();
      }
    }
  }
  
  for(int i = 0; i < controllerChanges.size(); i++) {
    controllerChanges.get(i).delay = controllerChanges.get(i).delay - delta;
    
    if(controllerChanges.get(i).delay <= 0) {
      controllerChanges.get(i).Change();
      controllerChanges.remove(i);     
      i--;
    }
  }
    
  for(int i = 0; i < configs.size(); i++) {
    if(configs.get(i).delay > 0)
      configs.get(i).delay = configs.get(i).delay - delta;
    
    if(configs.get(i).delay <= 0) {
      
      Boolean NOTE = (Boolean)getValue(configs.get(i), "NOTE");
      
      if(NOTE)
        CreateNotes(configs.get(i));
        
      Boolean CC = (Boolean)getValue(configs.get(i), "CC");
      
      if(CC)
        CreateCC(configs.get(i));
      
      int GEN_NOTE_DELAY_MIN = (int)getValue(configs.get(i), "GEN_NOTE_DELAY_MIN");        
      int GEN_NOTE_DELAY_MAX = (int)getValue(configs.get(i), "GEN_NOTE_DELAY_MAX");
      
      configs.get(i).delay = int(random(GEN_NOTE_DELAY_MIN, GEN_NOTE_DELAY_MAX));
    }
  }
  
  if(configs.get(0).getConfig().getBoolean("USE_MAIN_LOOP_DELAY"))
    delay(int(random(configs.get(0).getConfig().getInt("MAIN_LOOP_DELAY_MIN"), configs.get(0).getConfig().getInt("MAIN_LOOP_DELAY_MAX")))); //Main loop delay
}

void delay(int time) {
  int current = millis();
  while (millis () < current+time) Thread.yield();
}

void CreateNotes(Config conf) {
  
  JSONObject jo = conf.getConfig(); 
    
  Integer channel = conf.getChannel() != null && conf.getChannel() != 0 ? conf.getChannel() : null;
      
  // How many new Notes should be generated on this loop
  int GEN_NB_NOTES_MIN = (int)getValue(conf, "GEN_NB_NOTES_MIN");  
  int GEN_NB_NOTES_MAX = (int)getValue(conf, "GEN_NB_NOTES_MAX");
  
  int newNumberOfNotes = int(random(GEN_NB_NOTES_MIN, GEN_NB_NOTES_MAX));
  
  if(channel == null) { // Change the channel for every new note  || !jo.getBoolean("USE_SAME_CHANNEL_FOR_CURRENT_LOOP")
    
    int CHANNEL_MIN = (int)getValue(conf, "CHANNEL_MIN");
    int CHANNEL_MAX = (int)getValue(conf, "CHANNEL_MAX");
    println(CHANNEL_MIN + " " + CHANNEL_MAX);
    channel = int(random(CHANNEL_MIN, CHANNEL_MAX));
  }
    
  while(newNumberOfNotes > 0) {
                  
    int PITCH_MIN = (int)getValue(conf, "PITCH_MIN");
    int PITCH_MAX = (int)getValue(conf, "PITCH_MAX");
    
    int VELOCITY_MIN = (int)getValue(conf, "VELOCITY_MIN");
    int VELOCITY_MAX = (int)getValue(conf, "VELOCITY_MAX");
    
    int NOTE_TIME_MIN = (int)getValue(conf, "NOTE_TIME_MIN");
    int NOTE_TIME_MAX = (int)getValue(conf, "NOTE_TIME_MAX");
    
    int NOTE_DELAY_MIN = (int)getValue(conf, "NOTE_DELAY_MIN");
    int NOTE_DELAY_MAX = (int)getValue(conf, "NOTE_DELAY_MAX");
    
    // Create a new Note
    Note newNote = new Note(channel, 
      int(random(PITCH_MIN, PITCH_MAX)), // Generate a random pitch value for the new note, 
      int(random(VELOCITY_MIN, VELOCITY_MAX)), // Generate a random velocity value for the new note
      int(random(NOTE_TIME_MIN, NOTE_TIME_MAX)), 
      int(random(NOTE_DELAY_MIN, NOTE_DELAY_MAX)));
    notes.add(newNote);
    
    newNumberOfNotes--;
  }
}

void CreateCC(Config conf) {
  
  JSONObject jo = conf.getConfig(); 
        
  // How many new CC should be generated on this loop  
  int CC_GEN_NB_MIN = (int)getValue(conf, "CC_GEN_NB_MIN");
  int CC_GEN_NB_MAX = (int)getValue(conf, "CC_GEN_NB_MAX");

  int newNumberOfCC = int(random(CC_GEN_NB_MIN, CC_GEN_NB_MAX));
  
  while(newNumberOfCC > 0) {
    
    int channel = 0;
    int number = 0;
    int value = 0;
          
    JSONArray ccsl = (JSONArray)getValue(conf, "CC_SET_LIST");
   
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
          int CC_GEN_VALUE_MIN = (int)getValue(conf, "CC_GEN_VALUE_MIN"); 
          int CC_GEN_VALUE_MAX = (int)getValue(conf, "CC_GEN_VALUE_MAX");
          value = int(random(CC_GEN_VALUE_MIN, CC_GEN_VALUE_MAX));
        }
      } else if (ccslv instanceof JSONObject) { 
        channel = ((JSONObject)ccslv).getInt("channel");
        number = ((JSONObject)ccslv).getInt("number");
                  
        if(((JSONObject)ccslv).size() > 2) {
          int v_min = ((JSONObject)ccslv).getInt("value_min");
          int v_max = ((JSONObject)ccslv).getInt("value_max");
          value = int(random(v_min, v_max));
        } else {
          int CC_GEN_VALUE_MIN = (int)getValue(conf, "CC_GEN_VALUE_MIN");
          int CC_GEN_VALUE_MAX = (int)getValue(conf, "CC_GEN_VALUE_MAX");
          value = int(random(CC_GEN_VALUE_MIN, CC_GEN_VALUE_MAX));
        }
      }
      println("Using cc set list: channel:" + channel + ":number:" + number + ":value:" + value);        
      
    } else {
      int CC_GEN_CHANNEL_MIN = (int)getValue(conf, "CC_GEN_CHANNEL_MIN");
      int CC_GEN_CHANNEL_MAX = (int)getValue(conf, "CC_GEN_CHANNEL_MAX");
      channel = int(random(CC_GEN_CHANNEL_MIN, CC_GEN_CHANNEL_MAX));
      
      int CC_GEN_NUMBER_MIN = (int)getValue(conf, "CC_GEN_NUMBER_MIN");
      int CC_GEN_NUMBER_MAX = (int)getValue(conf, "CC_GEN_NUMBER_MAX");
      number = int(random(CC_GEN_NUMBER_MIN, CC_GEN_NUMBER_MAX));
      
      int CC_GEN_VALUE_MIN = (int)getValue(conf, "CC_GEN_VALUE_MIN");
      int CC_GEN_VALUE_MAX = (int)getValue(conf, "CC_GEN_VALUE_MAX");
      value = int(random(CC_GEN_VALUE_MIN, CC_GEN_VALUE_MAX));
    }
    
    if(!couldNotGetValuesFromCCSetList) {
      
      int CC_GEN_DELAY_MIN = (int)getValue(conf, "CC_GEN_DELAY_MIN");
      int CC_GEN_DELAY_MAX = (int)getValue(conf, "CC_GEN_DELAY_MAX");
      
      ControllerChange cc = new ControllerChange(channel, number, value, int(random(CC_GEN_DELAY_MIN, CC_GEN_DELAY_MAX)));
      controllerChanges.add(cc);
    } else {
      println("Could not get values from cc set list");
    }
    
    newNumberOfCC--;
  }
}

Object getParentValue(JSONObject jo, String keyname) {
    
  if(!jo.isNull("PARENT") && !jo.getString("PARENT").equals("")) {
    for(Config conf: configs) {
      if(conf.getName() != null && conf.getName().equals(jo.getString("PARENT"))) {
        if(!conf.getConfig().isNull(keyname)) {
          return conf.getConfig().get(keyname);
        } else if(conf.getParent() != null) {
          return getParentValue(conf.getConfig(), keyname);
        }
        
      } else if(conf.getChannel() != null && conf.getChannel() == Integer.parseInt(jo.getString("PARENT"))) {
        if(!conf.getConfig().isNull(keyname)) {
          return conf.getConfig().get(keyname);
        } else if(conf.getParent() != null) {
          return getParentValue(conf.getConfig(), keyname);
        }
      }
    }
  }
  
  if(!configs.get(0).getConfig().isNull(keyname))
    return configs.get(0).getConfig().get(keyname);
  
  return null;
}


void CheckConfigRefreshSettings(){
    try {
    JSONObject json = loadJSONObject("main.json");
    
    if(!configs.get(0).getConfig().getBoolean("PLAY_PIECE") && !configs.get(0).getConfig().getBoolean("PLAY_COMPOSITION")) {
      if(json.get("USE_CONFIG_REFRESH") != null && json.getBoolean("USE_CONFIG_REFRESH") != configs.get(0).getConfig().getBoolean("USE_CONFIG_REFRESH")) {
        println("USE_CONFIG_REFRESH:change:from:" + configs.get(0).getConfig().getBoolean("USE_CONFIG_REFRESH") + ":to:" + json.getBoolean("USE_CONFIG_REFRESH"));
        configs.get(0).getConfig().setBoolean("USE_CONFIG_REFRESH", json.getBoolean("USE_CONFIG_REFRESH"));
      }
    }
    
    if(json.get("PLAY_PIECE") != null && json.getBoolean("PLAY_PIECE") != configs.get(0).getConfig().getBoolean("PLAY_PIECE")) {
      println("PLAY_PIECE:change:from:" + configs.get(0).getConfig().getBoolean("PLAY_PIECE") + ":to:" + json.getBoolean("PLAY_PIECE"));
      configs.get(0).getConfig().setBoolean("PLAY_PIECE", json.getBoolean("PLAY_PIECE"));
    }
    
    if(json.get("PLAY_COMPOSITION") != null && json.getBoolean("PLAY_COMPOSITION") != configs.get(0).getConfig().getBoolean("PLAY_COMPOSITION")) {
      println("PLAY_COMPOSITION:change:from:" + configs.get(0).getConfig().getBoolean("PLAY_COMPOSITION") + ":to:" + json.getBoolean("PLAY_COMPOSITION"));
      configs.get(0).getConfig().setBoolean("PLAY_COMPOSITION", json.getBoolean("PLAY_COMPOSITION"));
    } 
  } catch(Exception e) {
  }
}

void PlayComposition() {
  try {
    String[] composition = loadStrings(configs.get(0).getConfig().getString("CURRENT_COMPOSITION"));
    if(composition.length > 0)
      ParseComposition(composition);
  } catch(Exception e) {
    println(e);
  }
}

void PlayPiece() {
  try {
    JSONObject json = loadJSONObject(configs.get(0).getConfig().getString("CURRENT_PIECE"));
    ParseJsonPiece(json);
  } catch(Exception e) {
  }
}

void LoadConfig(boolean init) {
  if(init) {
    
    // Create default config as index 0 in configs list
    Config c = new Config(parseJSONObject("{" + mainConfig + "," + noteConfig + "," + ccConfig + "}"));
    configs.add(c);
    
    Boolean mainexist = true; // Set to false is main.json do not exist
    
    try {
      loadJSONObject("main.json");
    } catch (Exception e) {
      // Could not find main.json, create main.json using default main config
      saveJSONObject(parseJSONObject("{" + mainConfig + "}"), "data/main.json");
      mainexist = false; // main.json did not exist, set to false
    }
    
    try {
      loadJSONObject("note.json"); // Check if note.json exist
    } catch (Exception e) {
      if(!mainexist) // Create default Note config json file if note.json and main.json do not exist
        saveJSONObject(parseJSONObject("{" + noteConfig + "}"), "data/note.json");
    }
    
    try {
      loadJSONObject("cc.json"); // Check if cc.json exist
    } catch (Exception e) {
      if(!mainexist) // Create default CC config json file if cc.json and main.json do not exist
        saveJSONObject(parseJSONObject("{" + ccConfig + "}"), "data/cc.json");
    }
  }
  
  //ArrayList<Config> newconfs = new ArrayList<Config>();
  
  //for(int counter = 0; counter < 2; counter++) {
    for(int confIndex = 0; confIndex < configs.size(); confIndex++) {
    
      Config con = configs.get(confIndex);
    //for(Config con: configs) {
      
      if(!con.getConfig().isNull("CONFIG")) {    
        for(int i = 0; i < con.getConfig().getJSONArray("CONFIG").size(); i++) {
          Object o = configs.get(0).getConfig().getJSONArray("CONFIG").get(i);
          
          JSONObject jo = null;
          if(o instanceof JSONObject) {
            jo = (JSONObject)o;
          } else if (o instanceof String) {
            try {
              jo = loadJSONObject((String)o);
            } catch(Exception e) {
              println("Could not find config file: " + (String)o);
            }
          }
          
          if(jo != null) {
           
            String name = GetName(jo);
            Integer channel = GetChannel(jo);
            
            if(name != null || channel != null) {
              
              Boolean match = false;
              
              for(Config conf: configs) {
                String confName = GetName(conf.getConfig());
                Integer confChannel = GetChannel(conf.getConfig());
                
                if(DoParsConfig(name, channel, confName, confChannel)) {
                  ParseJsonConfig(jo, conf.getConfig());
                  match = true;
                }
              }
              
              if(!match) {
                Config c = new Config(jo);
                
                ParseJsonConfig(jo, c.getConfig());
                
                configs.add(c);
              }
                          
            } else {
              ParseJsonConfig(jo, configs.get(0).getConfig());
            }
            
            //println(jo);
          }
        }
      }
    }
  //}
  
  //for(Config n: newconfs)
  //  configs.add(n);
  
  //LoadConfigJson(mainJson, mainJson.getString("MAIN_CONFIG") , init, "data/main.json");
  //if(init) // Do it twice if init to get changes to MAIN_CONFIG, NOTE_CONFIG, and CC_CONFIG
  //  LoadConfigJson(mainJson, mainJson.getString("MAIN_CONFIG") , false, "data/main.json");
    
  //LoadConfigJson(noteJson, mainJson.getString("NOTE_CONFIG") , init, "data/note.json");
  //LoadConfigJson(ccJson, mainJson.getString("CC_CONFIG") , init, "data/cc.json");
}

Boolean DoParsConfig(String name, Integer channel, String confName, Integer confChannel) {
  if(name != null && channel != null && confName != null && confName.equals(name) && confChannel != null && confChannel == channel)
    return true;
  else if(name == null && channel != null && confName == null && confChannel != null && confChannel == channel)
    return true;
  else if(name != null && channel == null && confName != null && confName.equals(name) && confChannel == null)
    return true;
  
  return false;
}

String GetName(JSONObject conf) {
  if(!conf.isNull("NAME") && !conf.getString("NAME").equals("")) {
      return conf.getString("NAME");
  }

  return null;
}

Integer GetChannel(JSONObject conf) {
  if(!conf.isNull("CHANNEL")) {
      return conf.getInt("CHANNEL");
  }
  
  return null;
}

Object getValue(Config config, String valueName) {
  return config.getConfig().isNull(valueName) ? getParentValue(config.getConfig(), valueName) : config.getConfig().get(valueName);
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
  
  Boolean useCompositionInMarkdown = configs.get(0).getConfig().getBoolean("USE_COMPOSITION_IN_MARKDOWN");
  
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
      
      if(configs.get(0).getConfig().getBoolean("COMPOSITION_CLEAR_JMP_STACK_ON_EOF")) {
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
    ParseJsonConfig(json, configs.get(0).getConfig());
  json = movement.getJSONObject("note");
  if(json != null)
    ParseJsonConfig(json, configs.get(0).getConfig());
  json = movement.getJSONObject("cc");
  if(json != null)
    ParseJsonConfig(json, configs.get(0).getConfig());
  
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
    } else if(cv instanceof JSONObject && jv instanceof JSONObject && !(""+(JSONObject)cv).equals(""+(JSONObject)jv)) {
      config.setJSONObject(name, (JSONObject)jv);
      println(name + ":change:from:" + (JSONObject)cv + ":to:" + (JSONObject)jv);
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
          
          if(config.isNull(ns))
            v = (Integer)getParentValue(config, ns);
          else
            v = config.getInt(ns);
                   
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
      midiBus.sendNoteOn(channel-1, pitch, velocity); // Send a Midi noteOn
      println("PLAY:NOTE:channel:" + this.channel + ":pitch:" + this.pitch + ":velocity:" + this.velocity + ":time:" + this.time + ":init_time:" + this.init_time + ":delay:" + this.delay + ":init_delay:" + this.init_delay);
    }
    
    playing = true;
  }
  
  void Stop() {
    if(playing) {
      midiBus.sendNoteOff(channel-1, pitch, velocity); // Send a Midi nodeOff
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
    midiBus.sendControllerChange(channel-1, number, value);
    changed = true;
  }
  
  boolean IsChanged() {
    return changed;
  }
  
  void SetChanged(boolean changed) {
    this.changed = changed;
  }
}

class Config {
  int delay;
  private JSONObject jsonConfig;
  
  Config() {
    this.jsonConfig = new JSONObject();
  }
  
  Config(JSONObject jsonConfig) {
    this.jsonConfig = jsonConfig;
  }
  
  JSONObject getConfig() {
    return jsonConfig;
  }
  
  void setConfig(JSONObject jsonConfig) {
    this.jsonConfig = jsonConfig;
  }
  
  Integer getChannel() {
    if(!this.jsonConfig.isNull("CHANNEL")) {
        return this.jsonConfig.getInt("CHANNEL");
    }
  
    return null;
  }
  
  String getName() {
    if(!this.jsonConfig.isNull("NAME") && !this.jsonConfig.getString("NAME").equals("")) {
        return this.jsonConfig.getString("NAME");
    }

    return null;
  }
  
  String getParent() {
    if(!this.jsonConfig.isNull("PARENT") && !this.jsonConfig.getString("PARENT").equals(""))
      return this.jsonConfig.getString("PARENT");
    
    return null;
  }
}
