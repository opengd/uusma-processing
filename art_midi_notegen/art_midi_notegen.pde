import themidibus.*; //Import the library

MidiBus midiBus; // The MidiBus

ArrayList<Note> notes; // A bunch of notes
ArrayList<ControllerChange> controllerChanges; // A bunch of notes

JSONObject json;

int last;
int delta;

int genLoopDelay;

int configRefreshDelayTime;

// Default Main config
String mainConfig = "{\"USE_CONFIG_REFRESH\": true," + 
    "\"CONFIG_REFRESH_DELAY\": 10000" +
    "}";

// Default Note config
String noteConfig = "{\"CHANNEL_MAX\": 255," +
    "\"CHANNEL_MIN\": 0," + 
    "\"PITCH_MAX\": 100," +
    "\"PITCH_MIN\": 0," +
    "\"VELOCITY_MAX\": 255," +
    "\"VELOCITY_MIN\": 0," +
    "\"NOTE_TIME_MAX\": 10000," +
    "\"NOTE_TIME_MIN\": 2000," +
    "\"NOTE_DELAY_MAX\": 10000," +
    "\"NOTE_DELAY_MIN\": 2000," +
    "\"GEN_NOTE_DELAY_MAX\": 10000," +
    "\"GEN_NOTE_DELAY_MIN\": 0," +
    "\"GEN_NB_NOTES_MAX\": 20," +
    "\"GEN_NB_NOTES_MIN\": 0," +
    "\"MAIN_LOOP_DELAY_MAX\": 2000," +
    "\"MAIN_LOOP_DELAY_MIN\": 100," +
    "\"USE_SAME_CHANNEL_FOR_CURRENT_LOOP\": true," +
    "\"USE_GLOBAL_LOOP_DELAY\": true," +
    "\"USE_GEN_DELAY\": true" +
    "}";

// Default CC config
String ccConfig = "{\"USE_CC_GEN\": true," +
    "\"CC_GEN_NB_MAX\": 2000," +
    "\"CC_GEN_NB_MIN\": 100," +
    "\"CC_GEN_CHANNEL_MAX\": 0," +
    "\"CC_GEN_CHANNEL_MIN\": 127," +
    "\"CC_GEN_NUMBER_MAX\": 10," +
    "\"CC_GEN_NUMBER_MIN\": 0," +
    "\"CC_GEN_VALUE_MAX\": 90," +
    "\"CC_GEN_VALUE_MIN\": 0," +
    "\"CC_GEN_DELAY_MAX\": 10000," +
    "\"CC_GEN_DELAY_MIN\": 0" +
    "}";

// Main config values
boolean USE_CONFIG_REFRESH = true;

int CONFIG_REFRESH_DELAY;

// Note config values
int CHANNEL_MAX;
int CHANNEL_MIN;

int PITCH_MAX;
int PITCH_MIN;

int VELOCITY_MAX;
int VELOCITY_MIN;

int NOTE_TIME_MAX;
int NOTE_TIME_MIN;

int NOTE_DELAY_MAX;
int NOTE_DELAY_MIN;

int GEN_NOTE_DELAY_MAX;
int GEN_NOTE_DELAY_MIN;

int GEN_NB_NOTES_MAX;
int GEN_NB_NOTES_MIN;

int MAIN_LOOP_DELAY_MAX;
int MAIN_LOOP_DELAY_MIN;

boolean USE_SAME_CHANNEL_FOR_CURRENT_LOOP = true;

boolean USE_GLOBAL_LOOP_DELAY = true;

boolean USE_GEN_DELAY = true;

// CC generator values
boolean USE_CC_GEN = true;

int CC_GEN_NB_MAX, CC_GEN_NB_MIN, CC_GEN_CHANNEL_MAX, CC_GEN_CHANNEL_MIN, CC_GEN_NUMBER_MAX, 
  CC_GEN_NUMBER_MIN, CC_GEN_VALUE_MAX, CC_GEN_VALUE_MIN, CC_GEN_DELAY_MAX, CC_GEN_DELAY_MIN;

void setup() {
  size(400, 400);
  background(0);
  
  LoadConfig(true); // Load main, note and cc config file from json files or default string config 

  MidiBus.list(); // List all available Midi devices on STDOUT. This will show each device's index and name.

  midiBus = new MidiBus(this, -1, "Microsoft GS Wavetable Synth"); // Create a new MidiBus with no input device and the default Java Sound Synthesizer as the output device.
    
  notes = new ArrayList<Note>();
  controllerChanges = new ArrayList<ControllerChange>();
  
  last = millis();
  
  genLoopDelay = 0; //int(random(GEN_NOTE_DELAY_MIN, GEN_NOTE_DELAY_MAX));
  
  configRefreshDelayTime = CONFIG_REFRESH_DELAY;
}

void draw() {
    
  // Calculate the delta time, the time since last loop
  delta = millis() - last;
  
  if(USE_CONFIG_REFRESH) {
    configRefreshDelayTime = configRefreshDelayTime - delta;
    
    if(configRefreshDelayTime <= 0) {
      LoadConfig(false);
      configRefreshDelayTime = CONFIG_REFRESH_DELAY;
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
  if(USE_GEN_DELAY && genLoopDelay > 0) {
    genLoopDelay = genLoopDelay - delta;
  }
  
  // If generate note delay is zero or below, or not using generate note delay
  // then generate some notes
  if(genLoopDelay <= 0 || !USE_GEN_DELAY) {  
  
    int channel = int(random(CHANNEL_MIN, CHANNEL_MAX));
    
    // How many new Notes should be generated on this loop
    int newNumberOfNotes = int(random(GEN_NB_NOTES_MIN, GEN_NB_NOTES_MAX));
    
    while(newNumberOfNotes > 0) {
      
      if(!USE_SAME_CHANNEL_FOR_CURRENT_LOOP) { // Change the channel for every new note
        channel = int(random(CHANNEL_MIN, CHANNEL_MAX));
      }
    
      int pitch = int(random(PITCH_MIN, PITCH_MAX)); // Generate a random pitch value for the new note
      int velocity = int(random(VELOCITY_MIN, VELOCITY_MAX)); // Generate a random velocity value for the new note
      
      // Create a new Note
      Note newNote = new Note(channel, pitch, velocity, int(random(NOTE_TIME_MIN, NOTE_TIME_MAX)), int(random(NOTE_DELAY_MIN, NOTE_DELAY_MAX)));
      notes.add(newNote);
      
      newNumberOfNotes--;
    }
    
    if(USE_GEN_DELAY) // If using generate note delay, get a new delay value
      genLoopDelay = int(random(GEN_NOTE_DELAY_MIN, GEN_NOTE_DELAY_MAX));
  
  }

  for(int i = 0; i < controllerChanges.size(); i++) {
    controllerChanges.get(i).delay = controllerChanges.get(i).delay - delta;
    
    if(controllerChanges.get(i).delay <= 0) {
      controllerChanges.get(i).Change();
      controllerChanges.remove(i);
    }
  }
  
  if(USE_CC_GEN) {
        
    // How many new CC should be generated on this loop
    int newNumberOfCC = int(random(CC_GEN_NB_MIN, CC_GEN_NB_MAX));
    
    while(newNumberOfCC > 0) {
      
      int channel = int(random(CC_GEN_CHANNEL_MIN, CC_GEN_CHANNEL_MAX));
      int number = int(random(CC_GEN_NUMBER_MIN, CC_GEN_NUMBER_MAX));
      int value = int(random(CC_GEN_VALUE_MIN, CC_GEN_VALUE_MAX));
      
      ControllerChange cc = new ControllerChange(channel, number, value, int(random(CC_GEN_DELAY_MIN, CC_GEN_DELAY_MAX)));
      controllerChanges.add(cc);
      
      newNumberOfCC--;
    }
  }
  
  if(USE_GLOBAL_LOOP_DELAY)
    delay(int(random(MAIN_LOOP_DELAY_MIN, MAIN_LOOP_DELAY_MAX))); //Main loop delay
}

void delay(int time) {
  int current = millis();
  while (millis () < current+time) Thread.yield();
}

void LoadConfig(boolean init) {
  try {
    json = loadJSONObject("main.json");
    ParseMainConfig(json);
    
    json = loadJSONObject("note.json");
    ParseNoteConfig(json);
    
    json = loadJSONObject("cc.json");
    ParseCCConfig(json);
    
  } catch (Exception e) {
    if(init) {    
      json = parseJSONObject(mainConfig);
      ParseMainConfig(json);    
      saveJSONObject(json, "data/main.json");
      
      json = parseJSONObject(noteConfig);
      ParseNoteConfig(json);    
      saveJSONObject(json, "data/note.json");
      
      json = parseJSONObject(ccConfig);
      ParseCCConfig(json);    
      saveJSONObject(json, "data/cc.json");
    }
  }
}

void ParseMainConfig(JSONObject json) {
  if(json != null)
  {
    USE_CONFIG_REFRESH = json.getBoolean("USE_CONFIG_REFRESH");
    CONFIG_REFRESH_DELAY = json.getInt("CONFIG_REFRESH_DELAY");
  }
}

void ParseNoteConfig(JSONObject json) {
  if(json != null)
  {
    CHANNEL_MAX = json.getInt("CHANNEL_MAX");
    CHANNEL_MIN = json.getInt("CHANNEL_MIN");
    
    PITCH_MAX = json.getInt("PITCH_MAX");
    PITCH_MIN = json.getInt("PITCH_MIN");
    
    VELOCITY_MAX = json.getInt("VELOCITY_MAX");
    VELOCITY_MIN = json.getInt("VELOCITY_MIN");
    
    NOTE_TIME_MAX = json.getInt("NOTE_TIME_MAX");
    NOTE_TIME_MIN = json.getInt("NOTE_TIME_MIN");
    
    NOTE_DELAY_MAX = json.getInt("NOTE_DELAY_MAX");
    NOTE_DELAY_MIN = json.getInt("NOTE_DELAY_MIN");
    
    GEN_NOTE_DELAY_MAX = json.getInt("GEN_NOTE_DELAY_MAX");
    GEN_NOTE_DELAY_MIN = json.getInt("GEN_NOTE_DELAY_MIN");
    
    GEN_NB_NOTES_MAX = json.getInt("GEN_NB_NOTES_MAX");
    GEN_NB_NOTES_MIN = json.getInt("GEN_NB_NOTES_MIN");
    
    MAIN_LOOP_DELAY_MAX = json.getInt("MAIN_LOOP_DELAY_MAX");
    MAIN_LOOP_DELAY_MIN = json.getInt("MAIN_LOOP_DELAY_MIN");
    
    USE_SAME_CHANNEL_FOR_CURRENT_LOOP = json.getBoolean("USE_SAME_CHANNEL_FOR_CURRENT_LOOP");
    
    USE_GLOBAL_LOOP_DELAY = json.getBoolean("USE_GLOBAL_LOOP_DELAY");
    
    USE_GEN_DELAY = json.getBoolean("USE_GEN_DELAY");
  }
}

void ParseCCConfig(JSONObject json) {
  if(json != null)
  {
    USE_CC_GEN = json.getBoolean("USE_CC_GEN");;

    CC_GEN_NB_MAX = json.getInt("CC_GEN_NB_MAX");;
    CC_GEN_NB_MIN = json.getInt("CC_GEN_NB_MIN");;
    
    CC_GEN_CHANNEL_MAX = json.getInt("CC_GEN_CHANNEL_MAX");;
    CC_GEN_CHANNEL_MIN = json.getInt("CC_GEN_CHANNEL_MIN");;
    
    CC_GEN_NUMBER_MAX = json.getInt("CC_GEN_NUMBER_MAX");;
    CC_GEN_NUMBER_MIN = json.getInt("CC_GEN_NUMBER_MIN");;
    
    CC_GEN_VALUE_MAX = json.getInt("CC_GEN_VALUE_MAX");;
    CC_GEN_VALUE_MIN = json.getInt("CC_GEN_VALUE_MIN");;
    
    CC_GEN_DELAY_MAX = json.getInt("CC_GEN_DELAY_MAX");;
    CC_GEN_DELAY_MIN = json.getInt("CC_GEN_DELAY_MIN");;
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
