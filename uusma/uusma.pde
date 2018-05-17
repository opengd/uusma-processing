import themidibus.*; //Import the library

MidiBus midiBus; // The MidiBus

ArrayList<Note> notes; // A bunch of notes
ArrayList<ControllerChange> controllerChanges; // A bunch of cc's

ArrayList<Config> configs;

int last, delta, configRefreshDelayTime, mainJsonCheckDelay;

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
  "\"PIECE\": \"piece.json\"," +
  "\"PLAY_COMPOSITION\": false," +
  "\"COMPOSITION_REFRESH_DELAY\": 1000," +
  "\"COMPOSITION\": \"composition.md\"," +
  "\"USE_COMPOSITION_IN_MARKDOWN\": true," +
  "\"ON_FALSE_CONFIG_REFRESH_DELAY\": 10000," +
  "\"COMPOSITION_CLEAR_JMP_STACK_ON_EOF\": false," + 
  "\"CONFIG\": [\"main.json\", \"note.json\", \"cc.json\"]," + 
  "\"NAME\": \"\"," + 
  "\"PARENT_NAME\": \"\"," +
  "\"REMOVE\": false";

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
  "\"NOTE\": true," +
  "\"PARENT_CHANNEL\": 0";

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
  
  notes = new ArrayList<Note>();
  controllerChanges = new ArrayList<ControllerChange>();
  
  last = millis();
  
  configRefreshDelayTime = configs.get(0).getConfig().getInt("CONFIG_REFRESH_DELAY");
  
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
      CheckConfigRefreshSettings();
      mainJsonCheckDelay = defaultConf.getInt("ON_FALSE_CONFIG_REFRESH_DELAY");
    }
  }
    
  for(Config conf: configs) {
    if(!conf.getConfig().isNull("PLAY_PIECE") && conf.getConfig().getBoolean("PLAY_PIECE")) {
      
      conf.playPieceRefreshDelay = conf.playPieceRefreshDelay - delta;
      
      if(conf.playPieceRefreshDelay <= 0) {
        PlayPiece(conf);
        conf.playPieceRefreshDelay = (int)getValue(conf, "PIECE_REFRESH_DELAY");
      }  
    }
    
    if(!conf.getConfig().isNull("PLAY_COMPOSITION") && conf.getConfig().getBoolean("PLAY_COMPOSITION")) {
      
      conf.playCompositionRefreshDelay = conf.playCompositionRefreshDelay - delta;
      
      if(conf.playCompositionRefreshDelay <= 0) {
        PlayComposition(conf);
        conf.playCompositionRefreshDelay = (int)getValue(conf, "COMPOSITION_REFRESH_DELAY");
      }  
    }
    
    if(conf.delay > 0)
      conf.delay = conf.delay - delta;
    
    if(conf.delay <= 0) {
      
      Boolean NOTE = (Boolean)getValue(conf, "NOTE");
      
      if(NOTE)
        CreateNotes(conf);
        
      Boolean CC = (Boolean)getValue(conf, "CC");
      
      if(CC)
        CreateCC(conf);
      
      int GEN_NOTE_DELAY_MIN = (int)getValue(conf, "GEN_NOTE_DELAY_MIN");        
      int GEN_NOTE_DELAY_MAX = (int)getValue(conf, "GEN_NOTE_DELAY_MAX");
      
      conf.delay = int(random(GEN_NOTE_DELAY_MIN, GEN_NOTE_DELAY_MAX));
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
 
  if(defaultConf.getBoolean("USE_MAIN_LOOP_DELAY"))
    delay(int(random(defaultConf.getInt("MAIN_LOOP_DELAY_MIN"), defaultConf.getInt("MAIN_LOOP_DELAY_MAX")))); //Main loop delay
}

void delay(int time) {
  int current = millis();
  while (millis () < current+time) Thread.yield();
}

void CreateNotes(Config conf) {
      
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
    
  if(!jo.isNull("PARENT_NAME") && !jo.getString("PARENT_NAME").equals("")) {
    for(Config conf: configs) {
      if(conf.getName() != null && conf.getName().equals(jo.getString("PARENT_NAME"))) {
        if(!conf.getConfig().isNull(keyname)) {
          return conf.getConfig().get(keyname);
        } else if(conf.getParentName() != null || conf.getParentChannel() != null) {
          return getParentValue(conf.getConfig(), keyname);
        }
      } 
    }
  }
  
  if(!jo.isNull("PARENT_CHANNEL") && jo.getInt("PARENT_CHANNEL") > 0) {
    for(Config conf: configs) {
      if(conf.getChannel() != null && conf.getChannel() == jo.getInt("PARENT_CHANNEL")) {
        if(!conf.getConfig().isNull(keyname)) {
          return conf.getConfig().get(keyname);
        } else if(conf.getParentChannel() != null || conf.getParentName() != null) {
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
      for(Config con: configs) {   
        if(!con.getConfig().isNull("CONFIG")) {    
          for(int i = 0; i < con.getConfig().getJSONArray("CONFIG").size(); i++) {
            Object o = con.getConfig().getJSONArray("CONFIG").get(i);

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
              
              if(name == null && channel == null) {
                ParseJsonConfig(jo, configs.get(0).getConfig());
              }              
            }
          }
        }
      }     
  } catch(Exception e) {
    println(e);
  }
}

void PlayComposition(Config conf) {
  
  if(!conf.getConfig().isNull("CURRENT_COMPOSITION")) {
    try {
      String[] composition = loadStrings(conf.getConfig().getString("CURRENT_COMPOSITION"));
      if(composition.length > 0)
        ParseComposition(composition, conf);
    } catch(Exception e) {
      println(e);
    }
  }
}

void PlayPiece(Config conf) {
  if(!conf.getConfig().isNull("CURRENT_PIECE")) {
    try {
      JSONObject json = loadJSONObject(conf.getConfig().getString("CURRENT_PIECE"));
      ParseJsonPiece(json, conf);
    } catch(Exception e) {
    }
  }
}

void LoadConfig(boolean init) {
  if(init) {
    
    // Create default config as index 0 in configs list
    Config c = new Config(parseJSONObject("{" + mainConfig + "," + noteConfig + "," + ccConfig + "}"));
    configs.add(c);
    c.playPieceRefreshDelay = (int)getValue(c, "PIECE_REFRESH_DELAY");
    c.playCompositionRefreshDelay = (int)getValue(c, "COMPOSITION_REFRESH_DELAY");
    
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
  
  for(int confIndex = 0; confIndex < configs.size(); confIndex++) {
    Config con = configs.get(confIndex);    
    confIndex = CreateConfig(con, confIndex);
  }
  
  println("configs:size:" + configs.size());
  
  for(Config con: configs)
    println(con.getConfig());
  
  if(configs.size() == 0) // If 0 config have been removed, create default config again 
    LoadConfig(true);
  
}

int CreateConfig(Config con, int confIndex) {
  
  if(!con.getConfig().isNull("CONFIG")) {    
    for(int i = 0; i < con.getConfig().getJSONArray("CONFIG").size(); i++) {
      Object o = con.getConfig().getJSONArray("CONFIG").get(i);
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
          
          //for(Config conf: configs) {
          for(int innerIdex = 0; innerIdex < configs.size(); innerIdex++) {
            Config conf = configs.get(innerIdex);
            
            String confName = GetName(conf.getConfig());
            Integer confChannel = GetChannel(conf.getConfig());
            
            if(DoParsConfig(name, channel, confName, confChannel)) {
              ParseJsonConfig(jo, conf.getConfig());
              println("**********DoParsConfig**********");
              println(name + ":" + confName);
              println(channel + ":" + confChannel);
              println(jo);
              println("**************************");
              
              if(conf.toRemove()) { // If the REMOVE is set, then remove the config from list of configs
                configs.remove(innerIdex);
                innerIdex--;
                confIndex--;
                println("REMOVE config");
              }
              else 
                match = true;
            }
          }
          
          if(!match) {
            Config c = new Config(jo);
            
            ParseJsonConfig(jo, c.getConfig());
            if(!c.toRemove()) {
              c.playPieceRefreshDelay = (int)getValue(c, "PIECE_REFRESH_DELAY");
              c.playCompositionRefreshDelay = (int)getValue(c, "COMPOSITION_REFRESH_DELAY");
              
              configs.add(c);
            }
            
            confIndex = CreateConfig(c, confIndex);
          }
                      
        } else {
          ParseJsonConfig(jo, configs.get(0).getConfig());
        }
        
        //println(jo);
      }
    }
  }
  
  return confIndex;
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

void ParseComposition(String[] composition, Config conf) {
  
  String currentMacro = null;
  
  Boolean insideComposition = false;
  
  Boolean useCompositionInMarkdown = (Boolean)getValue(conf, "USE_COMPOSITION_IN_MARKDOWN");
  
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
      
      if(conf.currentCompositionDelay == null && time >= 0) {
        conf.compositionDelta = 0;
        conf.compositionLast = millis() * 0.001;
        
        if(conf.compositionCurrentRow != null) {
          conf.currentCompositionDelay = (float)abs(time - conf.compositionCurrentRow);
        } else {
          conf.currentCompositionDelay = (float)time;
        }
        
        conf.compositionCurrentRow = time;
        println("currentCompositionDelay: " + conf.currentCompositionDelay);
        println("compositionCurrentRow: " + conf.compositionCurrentRow);
      }
      
      if(conf.currentCompositionDelay != null) {
        float m = millis() * 0.001;
        conf.compositionDelta = m - conf.compositionLast;
        conf.compositionLast = m;
        
        conf.currentCompositionDelay = conf.currentCompositionDelay - conf.compositionDelta;
        //println("currentCompositionDelay: " + currentCompositionDelay);
      }
      
      if(time >= 0 && conf.currentCompositionDelay <= 0 && time == conf.compositionCurrentRow && list.length > 1) {
        try {
          JSONObject json = loadJSONObject(currentMacro);
          
          for(int i = 1; i < list.length; i++) {
            
            // Check for comments
            String comCheck = list[i].substring(0, 1);
            if(comCheck.equals("#")) 
              break;
           
            ParseMovment(json, list[i], conf);
          }              
        } catch(Exception e) {}
        
        conf.currentCompositionDelay = null;
      } else if (time == -1 && conf.currentCompositionDelay == null && list.length > 1 && list[0].toLowerCase().equals("jmp")) {          
        
        int jmpTo = 0;
        try {
          jmpTo = Integer.parseInt(list[1]);
        } catch(NumberFormatException ex) {
          println("Could not parse jump time value: " + list[1]);
          continue;
        }
                
        if(conf.jmpStack.hasKey("" + jmpTo)) { 
          conf.jmpStack.set("" + jmpTo, conf.jmpStack.get("" + jmpTo)-1);
        } else {
          int jmpValue = 1;
          
          if(list.length > 2) {
            try {
              jmpValue = Integer.parseInt(list[2]);
            } catch(NumberFormatException ex) {
              jmpValue = 1;
            }
          }
          
          conf.jmpStack.set("" + jmpTo, jmpValue);
        }
        
        if(conf.jmpStack.get("" + jmpTo) == 0) {
          conf.jmpStack.remove("" + jmpTo);
        } else {
          conf.currentCompositionDelay = (float)jmpTo;
          conf.compositionCurrentRow = jmpTo;
          println("jmpTo:" + jmpTo + ":currentJmpStackCounter:" + conf.jmpStack.get("" + jmpTo));
        }             
      }
    }
    //println("(rowIndex+1): " + (rowIndex+2) + ":composition.length:" + composition.length);
    if((conf.currentCompositionDelay == null || conf.currentCompositionDelay <= 0) && (rowIndex+1) == composition.length) {
      conf.compositionCurrentRow = null;
      conf.currentCompositionDelay = null;
      println("EOF");
      
      if((Boolean)getValue(conf, "COMPOSITION_CLEAR_JMP_STACK_ON_EOF")) {
        conf.jmpStack.clear();
        println("JMP Stack cleared");
      }
      
    } else if(conf.currentCompositionDelay != null && conf.currentCompositionDelay <= 0) {
      conf.compositionCurrentRow = null;
      conf.currentCompositionDelay = null;
    }
  }
}

void ParseJsonPiece(JSONObject piece, Config conf) {
  java.util.Set pieceKeys = piece.keys();
  
  if(pieceKeys.size() > 0 && conf.currentMovmentDelay == null) {
    conf.currentMovmentDelay = GetNextMovmentDelay(pieceKeys, conf.currentMovmentDelay);
    conf.currentMovmentName = "" + conf.currentMovmentDelay;
    
    println("currentMovmentName: " + conf.currentMovmentName);
    
    conf.pieceDelta = 0;
    conf.pieceLast = millis();
  }
  
  int m = millis();
  conf.pieceDelta = m - conf.pieceLast;
  conf.pieceLast = m;
  
  if(pieceKeys.size() > 0) {
    
    conf.currentMovmentDelay = conf.currentMovmentDelay - conf.pieceDelta;
    //println("currentMovmentDelay: " + currentMovmentDelay);
    
    if(conf.currentMovmentDelay <= 0) {
      
      ParseMovment(piece, conf.currentMovmentName, conf);
      
      int currentDelay = Integer.parseInt(conf.currentMovmentName);
      int next = GetNextMovmentDelay(pieceKeys, currentDelay);
       
      conf.currentMovmentDelay = (next < currentDelay) ? next : abs(next - currentDelay);
      
      conf.currentMovmentName = "" + next;
      
      println("new:movment:name:" + conf.currentMovmentName + ":delay:" + conf.currentMovmentDelay);
    }
  } 
}

void ParseMovment(JSONObject piece, String movmentName, Config conf) {
  
  JSONObject movement = (JSONObject)piece.get(movmentName);
  
  println("parse:movment:" + movmentName);
  
  JSONObject json = movement.getJSONObject("main");
  if(json != null)
    ParseJsonConfig(json, conf.getConfig());
  json = movement.getJSONObject("note");
  if(json != null)
    ParseJsonConfig(json, conf.getConfig());
  json = movement.getJSONObject("cc");
  if(json != null)
    ParseJsonConfig(json, conf.getConfig());
  
  JSONArray ja = movement.getJSONArray("macro");
  if(ja != null && ja.size() > 0) {
    
    for(int i = 0; i < ja.size(); i++) {
      JSONObject macro = ja.getJSONObject(i);
      
      if(macro.getString("source") != null) {
        try {
          JSONObject mo = loadJSONObject(macro.getString("source"));
          JSONArray doMacros = macro.getJSONArray("do");
          for(int m = 0; m < doMacros.size(); m++) {
            ParseMovment(mo, doMacros.getString(m), conf);
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
    
    if(cv == null) { // If vars not in conf get parent or default value if it exist
      cv = getValue(new Config(config), name);
      println("null: " + name + ":" + cv);
    }
    
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
  int delay, playCompositionRefreshDelay, playPieceRefreshDelay, pieceDelta, pieceLast;
  private JSONObject jsonConfig;
  
  Integer currentMovmentDelay, compositionJmpCounter, compositionCurrentRow;
  String currentMovmentName;
  float compositionDelta, compositionLast;
  Float currentCompositionDelay;
  IntDict jmpStack;
  
  Config() {
    this.jsonConfig = new JSONObject();
    this.jmpStack = new IntDict();
  }
  
  Config(JSONObject jsonConfig) {
    this.jsonConfig = jsonConfig;
    this.jmpStack = new IntDict();
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
  
  String getParentName() {
    if(!this.jsonConfig.isNull("PARENT_NAME") && !this.jsonConfig.getString("PARENT_NAME").equals(""))
      return this.jsonConfig.getString("PARENT_NAME");
    
    return null;
  }
  
  Integer getParentChannel() {
    if(!this.jsonConfig.isNull("PARENT_CHANNEL"))
      return this.jsonConfig.getInt("PARENT_CHANNEL");
    
    return null;
  }
  
  Boolean toRemove() {
    if(!this.jsonConfig.isNull("REMOVE"))
      return this.jsonConfig.getBoolean("REMOVE");
    
    return false;
  }
}
