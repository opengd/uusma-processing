import themidibus.*; //Import the library

MidiBus myBus; // The MidiBus

ArrayList<Note> notes; // A bunch of notes

JSONObject json;

int last;
int delta;

int genLoopDelay;

int configRefreshDelayTime;

String config = "{\"CHANNEL_MAX\": 255," +
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
    "\"USE_GEN_DELAY\": true," +
    "\"USE_CONFIG_REFRESH\": true," +
    "\"CONFIG_REFRESH_DELAY\": 10000" +
    "}";

int CHANNEL_MAX = 255;
int CHANNEL_MIN = 0;

int PITCH_MAX = 100;
int PITCH_MIN = 0;

int VELOCITY_MAX = 255;
int VELOCITY_MIN = 0;

int NOTE_TIME_MAX = 10000;
int NOTE_TIME_MIN = 2000;

int NOTE_DELAY_MAX = 10000;
int NOTE_DELAY_MIN = 2000;

int GEN_NOTE_DELAY_MAX = 10000;
int GEN_NOTE_DELAY_MIN = 0;

int GEN_NB_NOTES_MAX = 20;
int GEN_NB_NOTES_MIN = 0;

int MAIN_LOOP_DELAY_MAX = 2000;
int MAIN_LOOP_DELAY_MIN = 100;

boolean USE_SAME_CHANNEL_FOR_CURRENT_LOOP = true;

boolean USE_GLOBAL_LOOP_DELAY = true;

boolean USE_GEN_DELAY = true;

boolean USE_CONFIG_REFRESH = true;

int CONFIG_REFRESH_DELAY = 1000;

void setup() {
  size(400, 400);
  background(0);
  LoadConfig();

  MidiBus.list(); // List all available Midi devices on STDOUT. This will show each device's index and name.

  myBus = new MidiBus(this, -1, "Microsoft GS Wavetable Synth"); // Create a new MidiBus with no input device and the default Java Sound Synthesizer as the output device.
    
  notes = new ArrayList<Note>();
  
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
      RefreshConfig();
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

  //int number = 0;
  //int value = 90;

  //myBus.sendControllerChange(channel, number, value); // Send a controllerChange
  
  if(USE_GLOBAL_LOOP_DELAY)
    delay(int(random(MAIN_LOOP_DELAY_MIN, MAIN_LOOP_DELAY_MAX))); //Main loop delay
}

void delay(int time) {
  int current = millis();
  while (millis () < current+time) Thread.yield();
}

void LoadConfig() {
  try {
    json = loadJSONObject("config.json");
    ParseConfig(json);
  } catch (Exception e) {
    json = parseJSONObject(config);
    ParseConfig(json);
    
    saveJSONObject(json, "data/config.json");
  }
}

void RefreshConfig() {
  try {
    json = loadJSONObject("config.json");
    ParseConfig(json);
  } catch (Exception e) {
    //json = parseJSONObject(config);
  }
}

void ParseConfig(JSONObject json) {
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
    
    USE_CONFIG_REFRESH = json.getBoolean("USE_CONFIG_REFRESH");
    CONFIG_REFRESH_DELAY = json.getInt("CONFIG_REFRESH_DELAY");
  }
}

class Note {
  
  int channel = 0;
  int pitch = 0;
  int velocity = 0;
  int time = 0;
  int delay = 0;
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
      myBus.sendNoteOn(channel, pitch, velocity); // Send a Midi noteOn
    }
    
    playing = true;
  }
  
  void Stop() {
    if(playing) {
      myBus.sendNoteOff(channel, pitch, velocity); // Send a Midi nodeOff
    }
    
    playing = false;
  }
  
  boolean IsPlaying() {
    return playing;
  }
}
