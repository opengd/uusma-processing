# art-midi-notegen
Artistically generate random midi notes and cc. The object is to make the notes perform as unsync as possible an by this art-midi-notegen is not performance optimized, as missing a beat is not issue.

As it is almost just about sound (music) the art-midi-notegen will not currently show any visual details in the main window, just deep black.

# Settings
On application start art-midi-notegen will check if there is any config files in folder "./data". art-midi-notegen is using three config files to seperate settings, main.json, note.json and cc.json. If the files do not exist on start they will be created using default settings.

art-midi-notegen will auto refresh settings on run, so make any changes in any of the settings files the changes will take effect in real time. The refresh settings can be changed in main.json.

## data/main.json
The main config file for all global changes. Ex. settings refresh.

## data/notes.json
The note.json holds settings for the radom midi note generator.

## data/cc.json
The cc.json holds settings for the random Controller Change (CC) generator.

# Dependencies
art-midi-notegen is using Processing to run and the MidiBus library to create midi data. You can install MidiBus by using the in Processing IDE build in library manager (Sketch->Import Library->Add Library). 

Processing
https://processing.org/

MidiBus
http://www.smallbutdigital.com/projects/themidibus/
