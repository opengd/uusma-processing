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

## data/piece.json
The piece.json is use to compose movments, change config based on a time value.

Example what a short piece.json can look like:

```javascript
{
    "10000": {
        "note" : {
            "PITCH_MAX": 154
        }
    },
    "15000": {
        "note" : {
            "PITCH_MIN": 1,
            "PITCH_MAX": 32
        }
    },
    "23000": {
        "note" : {
            "VELOCITY_MAX": 123
        },
        "cc" : {
            "CC_GEN_DELAY_MAX": 5000
        }
    }
}
```
This will init a delay of `10000`ms and then change the `PITCH_MAX`. Next it will take a new delay of 15000-10000=5000ms and change the pitch again. When it reach the end it will start over, so it will init the `10000`ms delay again.

Be aware if `USE_CONFIG_REFRESH` is set to `true` then it will change settings found in main/note/cc json at the same time. You can set `USE_CONFIG_REFRESH` to `false` or remove any used settings in piece from the other config files or just let i happen.


# Dependencies
art-midi-notegen is using Processing to run and the MidiBus library to create midi data. You can install MidiBus by using the in Processing IDE build in library manager (Sketch->Import Library->Add Library). 

Processing
https://processing.org/

MidiBus
http://www.smallbutdigital.com/projects/themidibus/
